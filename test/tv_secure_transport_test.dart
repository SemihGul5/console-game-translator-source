import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/services/tv_secure_transport.dart';
import 'package:gametranslate/services/tv_subtitle_client.dart';

// These certificates and private keys are public TEST fixtures only.
String fixtureFingerprint(String identity) {
  final pem = File(
    'test/fixtures/tv_tls/$identity-cert.pem',
  ).readAsStringSync();
  final der = base64Decode(
    pem
        .split('\n')
        .map((line) => line.trim())
        .where((line) => !line.startsWith('-----') && line.trim().isNotEmpty)
        .join(),
  );
  return sha256.convert(der).toString();
}

class Receiver {
  Receiver(this.server);
  final HttpServer server;
  final sockets = <WebSocket>[];
  final messages = <Map<String, dynamic>>[];
  final updates = StreamController<Map<String, dynamic>>.broadcast();
  late final StreamSubscription<HttpRequest> subscription;
  static final token = List.filled(43, 'a').join();
  String get address => 'wss://127.0.0.1:${server.port}';

  static Future<Receiver> start([String identity = 'a']) async {
    final context = SecurityContext()
      ..useCertificateChain('test/fixtures/tv_tls/$identity-cert.pem')
      ..usePrivateKey('test/fixtures/tv_tls/$identity-key.pem');
    final receiver = Receiver(
      await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context),
    );
    receiver.subscription = receiver.server.listen(
      (request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        receiver.sockets.add(socket);
        socket.listen((data) {
          final message = Map<String, dynamic>.from(
            jsonDecode(data as String) as Map,
          );
          receiver.messages.add(message);
          if (message['type'] == 'pair' || message['type'] == 'resume') {
            socket.add(
              jsonEncode({
                'type': 'paired',
                'sessionToken': token,
                'displayHeightDp': 1080,
              }),
            );
          } else {
            if (!receiver.updates.isClosed) receiver.updates.add(message);
          }
        }, onError: (_) {});
      },
      onError: (_) {
        // The certificate probe intentionally aborts TLS before any HTTP data.
      },
    );
    return receiver;
  }

  Future<Map<String, dynamic>> nextUpdate() =>
      updates.stream.first.timeout(const Duration(seconds: 5));

  Future<void> close() async {
    for (final socket in sockets) {
      await socket.close();
    }
    await subscription.cancel();
    await server.close(force: true);
    await updates.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );
  late TvSubtitleClient client;
  final saved = <Map<dynamic, dynamic>>[];
  final settings = SubtitleSettings.fromMap({'enabled': false, 'fontSize': 28});

  setUp(() async {
    client = TvSubtitleClient.forTesting();
    final overrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = overrides);
    await client.disconnect();
    saved.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'saveTvPairing') saved.add(call.arguments as Map);
          return null;
        });
  });
  tearDown(() async {
    await client.disconnect();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('probe obtains identity without sending a PIN or token', () async {
    final receiver = await Receiver.start();
    addTearDown(receiver.close);
    expect(
      await TvSecureTransport.inspect('127.0.0.1', receiver.server.port),
      fixtureFingerprint('a'),
    );
    expect(receiver.messages, isEmpty);
    expect(receiver.sockets, isEmpty);
  });

  test(
    'verified WSS keeps subtitles, appearance, clear and saved pin intact',
    () async {
      final receiver = await Receiver.start();
      addTearDown(receiver.close);
      client.updateSubtitles([
        'Çevrilmiş altyazı 🎮',
        'İkinci bölge',
      ], settings);
      final initial = receiver.nextUpdate();
      await client.connect(
        receiver.address,
        '123456',
        verifyCertificate: (code) async {
          expect(receiver.messages, isEmpty);
          expect(
            code,
            TvSecureTransport.verificationCode(fixtureFingerprint('a')),
          );
          return true;
        },
      );
      final subtitle = await initial;
      expect(client.isConnected, isTrue);
      expect(client.usesSecureTransport, isTrue);
      expect(client.tvDisplayHeightDp, 1080);
      expect(subtitle['texts'], ['Çevrilmiş altyazı 🎮', 'İkinci bölge']);
      expect((subtitle['presentation'] as Map)['enabled'], isTrue);
      expect(saved.single['certificateFingerprint'], fixtureFingerprint('a'));
      expect(saved.single['address'], receiver.address);

      final appearance = receiver.nextUpdate();
      client.updateSettings(settings.copyWith(fontSize: 32));
      final presentation = await appearance;
      expect(presentation['type'], 'presentation');
      expect(presentation['texts'], subtitle['texts']);
      expect((presentation['presentation'] as Map)['fontSize'], 32);

      final clear = receiver.nextUpdate();
      client.updateSubtitle('', settings);
      expect((await clear)['type'], 'clear');
    },
  );

  test(
    'rejecting identity sends no credentials and saves no pairing',
    () async {
      final receiver = await Receiver.start();
      addTearDown(receiver.close);
      await expectLater(
        client.connect(
          receiver.address,
          '123456',
          verifyCertificate: (_) async => false,
        ),
        throwsA(isA<HandshakeException>()),
      );
      expect(receiver.messages, isEmpty);
      expect(saved, isEmpty);
      expect(client.isConnected, isFalse);
    },
  );

  test('WSS cannot pair without explicit identity confirmation', () async {
    final receiver = await Receiver.start();
    addTearDown(receiver.close);
    await expectLater(
      client.connect(receiver.address, '123456'),
      throwsA(isA<HandshakeException>()),
    );
    expect(receiver.messages, isEmpty);
  });

  test(
    'cancel during identity confirmation cannot create a connection',
    () async {
      final receiver = await Receiver.start();
      addTearDown(receiver.close);
      final verifying = Completer<void>();
      final approval = Completer<bool>();
      final attempt = client.connect(
        receiver.address,
        '123456',
        verifyCertificate: (_) {
          verifying.complete();
          return approval.future;
        },
      );
      final result = expectLater(attempt, throwsA(isA<HandshakeException>()));
      await verifying.future;
      await client.cancelConnectionAttempt();
      approval.complete(true);
      await result;
      expect(receiver.messages, isEmpty);
      expect(saved, isEmpty);
    },
  );

  test(
    'reconnect uses pinned TLS and resends the latest subtitle/settings',
    () async {
      final receiver = await Receiver.start();
      addTearDown(receiver.close);
      final initial = receiver.nextUpdate();
      await client.connect(
        receiver.address,
        '123456',
        verifyCertificate: (_) async => true,
      );
      await initial;
      final disconnected = client.statusChanges.firstWhere(
        (connected) => !connected,
      );
      await receiver.sockets.single.close();
      await disconnected;
      client.updateSubtitles([
        'Bağlantı sonrası güncel altyazı',
        'İkinci bölge',
      ], settings.copyWith(fontSize: 36));
      final latest = receiver.nextUpdate();
      await client.retrySavedPairing();
      expect(client.isConnected, isTrue);
      expect(
        receiver.messages
            .where((m) => m['type'] == 'resume')
            .single['sessionToken'],
        Receiver.token,
      );
      expect((await latest)['texts'], [
        'Bağlantı sonrası güncel altyazı',
        'İkinci bölge',
      ]);
      expect(saved.last['certificateFingerprint'], fixtureFingerprint('a'));
    },
  );

  test('changed certificate receives no saved token', () async {
    final receiver = await Receiver.start('b');
    addTearDown(receiver.close);
    await client.restorePairing(
      receiver.address,
      Receiver.token,
      certificateFingerprint: fixtureFingerprint('a'),
    );
    await client.cancelConnectionAttempt();
    expect(receiver.messages, isEmpty);
    expect(client.isConnected, isFalse);
    expect(saved, isEmpty);
  });

  test('a saved secure endpoint without its pin is never contacted', () async {
    final receiver = await Receiver.start();
    addTearDown(receiver.close);
    await client.restorePairing(receiver.address, Receiver.token);
    expect(receiver.messages, isEmpty);
    expect(client.isConnecting, isFalse);
  });

  test('a saved TLS pin cannot be restored with a plaintext address', () async {
    final receiver = await Receiver.start();
    addTearDown(receiver.close);
    await client.restorePairing(
      '127.0.0.1:${receiver.server.port}',
      Receiver.token,
      certificateFingerprint: fixtureFingerprint('a'),
    );
    expect(receiver.messages, isEmpty);
    expect(client.sessionToken, isNull);
    expect(client.isConnecting, isFalse);
  });
}
