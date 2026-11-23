import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/services/lan_tv_address.dart';
import 'package:gametranslate/services/lg_webos_client.dart';
import 'package:gametranslate/services/samsung_tv_session.dart';
import 'package:gametranslate/services/tv_output_service.dart';
import 'package:gametranslate/services/tv_secure_transport.dart';

Future<void> eventually(bool Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition did not become true');
}

class FakeLg {
  late HttpServer server;
  final sockets = <WebSocket>[];
  final messages = <Map>[];
  bool rejectPairing = false;
  bool rejectUnsigned = false;
  bool prompt = false;
  bool rejectToasts = false;
  bool acknowledgeToasts = true;
  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.transform(WebSocketTransformer()).listen((socket) {
      sockets.add(socket);
      socket.listen((raw) {
        final message = jsonDecode(raw as String) as Map;
        messages.add(message);
        if (message['type'] == 'register') {
          final manifest = (message['payload'] as Map)['manifest'] as Map;
          final unsigned = !manifest.containsKey('signatures');
          if (prompt && !(rejectUnsigned && unsigned)) {
            socket.add(
              jsonEncode({
                'type': 'response',
                'id': 'register',
                'payload': {'pairingType': 'PROMPT', 'returnValue': true},
              }),
            );
          }
          socket.add(
            jsonEncode(
              rejectPairing || (rejectUnsigned && unsigned)
                  ? {'type': 'error', 'id': 'register', 'error': '403 denied'}
                  : {
                      'type': 'registered',
                      'id': 'register',
                      'payload': {'client-key': 'private-lg-key'},
                    },
            ),
          );
        } else if (message['type'] == 'request' && acknowledgeToasts) {
          socket.add(
            jsonEncode({
              'type': rejectToasts ? 'error' : 'response',
              'id': message['id'],
              'payload': {'returnValue': !rejectToasts},
            }),
          );
        }
      });
    });
  }

  LgWebOsClient client() => LgWebOsClient.forTesting(
    openSocket: (uri, fingerprint) {
      expect(uri.host, '192.168.1.25');
      expect(uri.port, 3000);
      return WebSocket.connect('ws://127.0.0.1:${server.port}');
    },
  );
  List<Map> get toasts =>
      messages.where((m) => m['type'] == 'request').toList();
  Future<void> close() async {
    for (final socket in sockets) {
      await socket.close();
    }
    await server.close(force: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final overrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = overrides);
  });

  test('TV addresses accept only literal RFC1918 IPv4', () {
    for (final address in [
      '192.168.1.25',
      '10.1.2.3',
      '172.16.0.1',
      '172.31.255.254',
    ]) {
      expect(LanTvAddress.isPrivateIpv4(address), isTrue, reason: address);
    }
    for (final address in [
      '127.0.0.1',
      '0.0.0.0',
      '255.255.255.255',
      '224.0.0.1',
      '8.8.8.8',
      '172.32.0.1',
      '169.254.1.2',
      '::1',
      'lg.local',
      'http://192.168.1.2',
      '192.168.1.2:3000',
      '192.168.1.256',
      '192.168.01.2',
    ]) {
      expect(LanTvAddress.isPrivateIpv4(address), isFalse, reason: address);
    }
  });

  test(
    'LG pairs with only notification permission and sends Unicode text',
    () async {
      final tv = FakeLg();
      await tv.start();
      final client = tv.client();
      addTearDown(() async {
        await client.disconnect();
        await tv.close();
      });
      await client.connect('192.168.1.25', encrypted: false);
      expect(client.isConnected, isTrue);
      expect(client.clientKey, 'private-lg-key');
      final manifest = (tv.messages.first['payload'] as Map)['manifest'] as Map;
      expect(manifest['permissions'], ['WRITE_NOTIFICATION_TOAST']);
      expect(manifest.containsKey('signed'), isFalse);
      await client.testNotification('Türkçe 日本語 🎮 <img>');
      expect(
        tv.toasts.single['uri'],
        'ssap://system.notifications/createToast',
      );
      expect(
        (tv.toasts.single['payload'] as Map)['message'],
        'Türkçe 日本語 🎮 <img>',
      );
      client.updateSubtitles(['Birinci alan', 'İkinci alan']);
      await eventually(() => tv.toasts.length == 2);
      expect(
        (tv.toasts.last['payload'] as Map)['message'],
        'Birinci alan\nİkinci alan',
      );
    },
  );

  test(
    'LG keeps only the latest subtitle and cancels pending text on clear',
    () async {
      final tv = FakeLg();
      await tv.start();
      final client = tv.client()
        ..toastInterval = const Duration(milliseconds: 120);
      addTearDown(() async {
        await client.disconnect();
        await tv.close();
      });
      await client.connect('192.168.1.25', encrypted: false);
      client.updateSubtitles(['first']);
      await eventually(() => tv.toasts.length == 1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      client.updateSubtitles(['old']);
      client.updateSubtitles(['newest']);
      await eventually(() => tv.toasts.length == 2);
      expect((tv.toasts.last['payload'] as Map)['message'], 'newest');
      client.updateSubtitles(['newest']);
      client.updateSubtitles(['must not appear']);
      client.updateSubtitles(['']);
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(tv.toasts.length, 2);
    },
  );

  test(
    'LG rejects denied registration and denied or missing notification ACK',
    () async {
      final tv = FakeLg()..rejectPairing = true;
      await tv.start();
      final client = tv.client();
      addTearDown(() async {
        await client.disconnect();
        await tv.close();
      });
      await expectLater(
        client.connect('192.168.1.25', encrypted: false),
        throwsStateError,
      );
      expect(client.isConnected, isFalse);
      tv.rejectPairing = false;
      await client.connect('192.168.1.25', encrypted: false);
      tv.rejectToasts = true;
      await expectLater(client.testNotification('test'), throwsStateError);
      tv.rejectToasts = false;
      tv.acknowledgeToasts = false;
      await expectLater(
        client.testNotification('test'),
        throwsA(isA<TimeoutException>()),
      );
    },
  );

  test(
    'LG retries with the signed manifest when the TV refuses the unsigned one',
    () async {
      final tv = FakeLg()
        ..rejectUnsigned = true
        ..prompt = true;
      await tv.start();
      final client = tv.client();
      addTearDown(() async {
        await client.disconnect();
        await tv.close();
      });
      await client.connect('192.168.1.25', encrypted: false);
      expect(client.isConnected, isTrue);
      final registers = tv.messages
          .where((m) => m['type'] == 'register')
          .map((m) => (m['payload'] as Map)['manifest'] as Map)
          .toList();
      expect(registers, hasLength(2));
      expect(registers.first.containsKey('signed'), isFalse);
      expect(registers.last.containsKey('signed'), isTrue);
      expect(registers.last['permissions'], ['WRITE_NOTIFICATION_TOAST']);
      await client.testNotification('ok');
      expect(tv.toasts, hasLength(1));
    },
  );

  test('LG does not retry after the user denies the TV prompt', () async {
    final tv = FakeLg()
      ..prompt = true
      ..rejectPairing = true;
    await tv.start();
    final client = tv.client();
    addTearDown(() async {
      await client.disconnect();
      await tv.close();
    });
    await expectLater(
      client.connect('192.168.1.25', encrypted: false),
      throwsStateError,
    );
    expect(tv.messages.where((m) => m['type'] == 'register'), hasLength(1));
    expect(client.lastError, contains('reddetti'));
    expect(client.lastErrorCode, '3000 denied: 403 denied');
  });

  test('LG reports a closed port and suggests the other connection type', () async {
    final client = LgWebOsClient.forTesting(
      openSocket: (_, _) async =>
          throw const SocketException('Connection refused'),
      probePort: (_, port) async => port == 3001,
    );
    addTearDown(client.disconnect);
    await expectLater(
      client.connect('192.168.1.25', encrypted: false),
      throwsA(isA<SocketException>()),
    );
    expect(client.lastError, contains('“Şifreli bağlantı” seçeneğini açıp'));
    expect(client.lastErrorCode, '3000 kapalı, 3001 açık');
  });

  test('LG cancellation closes a socket that finishes opening late', () async {
    final tv = FakeLg();
    await tv.start();
    final gate = Completer<WebSocket>();
    final client = LgWebOsClient.forTesting(openSocket: (_, _) => gate.future);
    addTearDown(() async {
      await client.disconnect();
      await tv.close();
    });
    final connect = client.connect('192.168.1.25', encrypted: false);
    final failed = expectLater(connect, throwsStateError);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await client.disconnect();
    gate.complete(await WebSocket.connect('ws://127.0.0.1:${tv.server.port}'));
    await failed;
    expect(client.isConnected, isFalse);
    expect(tv.messages, isEmpty);
  });

  test(
    'LG pins the saved certificate and never falls back or sends a key after rotation',
    () async {
      final context = SecurityContext()
        ..useCertificateChain('test/fixtures/tv_tls/b-cert.pem')
        ..usePrivateKey('test/fixtures/tv_tls/b-key.pem');
      final tv = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      addTearDown(() => tv.close(force: true));
      var requests = 0, opens = 0;
      tv.listen((request) {
        requests++;
        request.response.close();
      });
      final pem = File('test/fixtures/tv_tls/a-cert.pem').readAsStringSync();
      final fingerprint = sha256
          .convert(
            base64Decode(
              pem
                  .split('\n')
                  .map((line) => line.trim())
                  .where((l) => !l.startsWith('---'))
                  .join(),
            ),
          )
          .toString();
      final client = LgWebOsClient.forTesting(
        openSocket: (uri, pinned) async {
          opens++;
          expect(uri.scheme, 'wss');
          expect(uri.port, 3001);
          expect(pinned, fingerprint);
          final http = TvSecureTransport.pinnedClient(pinned!);
          try {
            return await WebSocket.connect(
              'wss://127.0.0.1:${tv.port}',
              customClient: http,
            );
          } finally {
            http.close();
          }
        },
      );
      addTearDown(client.disconnect);
      await expectLater(
        client.connect(
          '192.168.1.25',
          savedKey: 'private-key',
          fingerprint: fingerprint,
        ),
        throwsA(isA<HandshakeException>()),
      );
      expect(requests, 0);
      expect(opens, 1);
      expect(client.isConnected, isFalse);
    },
  );

  test(
    'output routing switches from LG to the existing Android TV wire protocol',
    () async {
      const channel = MethodChannel(
        'com.abrebostudio.consolegametranslator/ps5_registration',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final writes = <Object?>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'saveSmartTvPairing') writes.add(call.arguments);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final tv = FakeLg();
      await tv.start();
      final client = tv.client();
      final output = TvOutputService.instance;
      addTearDown(() async {
        await output.disconnect();
        await tv.close();
      });
      await client.connect('192.168.1.25', encrypted: false);
      await output.activateLg(client);
      expect(output.kind, TvOutputKind.lg);
      expect(
        (jsonDecode(writes.last as String) as Map)['key'],
        'private-lg-key',
      );
      output.updateSubtitles(['LG çeviri'], const SubtitleSettings());
      await eventually(() => tv.toasts.isNotEmpty);
      await output.cancelConnectionAttempt();
      expect(output.isConnected, isFalse);
      expect(output.sessionToken, 'private-lg-key');
      await output.retrySavedPairing();
      expect(output.isConnected, isTrue);
      expect(
        (tv.messages.where((m) => m['type'] == 'register').last['payload']
            as Map)['client-key'],
        'private-lg-key',
      );
      await output.disconnect();
      expect(output.sessionToken, isNull);
      expect(output.address, isNull);
      expect(writes.last, isNull);
      await client.connect('192.168.1.25', encrypted: false);
      await output.activateLg(client);
      final android = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final messages = <Map>[], sockets = <WebSocket>[];
      android.transform(WebSocketTransformer()).listen((socket) {
        sockets.add(socket);
        socket.listen((raw) {
          final packet = jsonDecode(raw as String) as Map;
          if (packet['type'] == 'pair') {
            socket.add(
              jsonEncode({'type': 'paired', 'sessionToken': 'a' * 48}),
            );
          } else {
            messages.add(packet);
          }
        });
      });
      addTearDown(() async {
        for (final socket in sockets) {
          await socket.close();
        }
        await android.close(force: true);
      });
      await output.connect('127.0.0.1:${android.port}', '123456');
      expect(output.kind, TvOutputKind.android);
      expect(client.isConnected, isFalse);
      output.updateSubtitles([
        'Android çeviri',
        'İkinci alan',
      ], const SubtitleSettings());
      await eventually(
        () => messages.any((m) => m['text'] == 'Android çeviri\nİkinci alan'),
      );
      expect(writes.last, isNull);
    },
  );

  Future<SamsungTvSession> samsung() async {
    final session = SamsungTvSession();
    await session.start(
      bindAddress: InternetAddress.loopbackIPv4,
      localAddresses: ['192.168.1.3'],
      archive: Uint8List.fromList([80, 75, 3, 4]),
    );
    addTearDown(session.stop);
    return session;
  }

  Future<(WebSocket, StreamIterator<dynamic>)> receiver(
    SamsungTvSession session,
  ) async {
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:${session.port}/subtitles',
    );
    final messages = StreamIterator<dynamic>(socket);
    addTearDown(() async {
      await socket.close();
      await messages.cancel();
    });
    return (socket, messages);
  }

  Future<Map> next(StreamIterator<dynamic> messages) async {
    expect(
      await messages.moveNext().timeout(const Duration(seconds: 3)),
      isTrue,
    );
    return jsonDecode(messages.current as String) as Map;
  }

  test(
    'Samsung serves source archive and requires PIN plus physical HDMI confirmation',
    () async {
      final session = await samsung();
      expect(session.pairingCode, matches(RegExp(r'^\d{6}$')));
      final http = HttpClient();
      addTearDown(() => http.close(force: true));
      final response = await (await http.getUrl(
        Uri.parse('http://127.0.0.1:${session.port}/receiver.zip'),
      )).close();
      expect(response.statusCode, 200);
      expect(await response.expand((bytes) => bytes).toList(), [80, 75, 3, 4]);
      final (socket, messages) = await receiver(session);
      socket.add(jsonEncode({'type': 'pair', 'code': session.pairingCode}));
      final paired = await next(messages);
      expect(paired['type'], 'paired');
      expect(
        (paired['sessionToken'] as String).length,
        greaterThanOrEqualTo(40),
      );
      expect(session.pairingCode, isNull);
      expect(session.isConnected, isFalse);
      socket.add('{"type":"ready","hdmiVisible":false}');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(session.isConnected, isFalse);
      socket.add('{"type":"ready","hdmiVisible":true}');
      expect((await next(messages))['type'], 'clear');
      expect(session.isConnected, isTrue);
      session.updateSubtitles([
        'Çeviri 🎮',
        '日本語',
      ], const SubtitleSettings(fontSize: 32));
      final subtitle = await next(messages);
      expect(subtitle['texts'], ['Çeviri 🎮', '日本語']);
      expect((subtitle['presentation'] as Map)['fontSize'], 32);
      session.updateSubtitles([], const SubtitleSettings());
      expect((await next(messages))['type'], 'clear');
    },
  );

  test(
    'Samsung rejects bad PIN, malformed data, and a second receiver',
    () async {
      final session = await samsung();
      final (bad, badMessages) = await receiver(session);
      bad.add('{"type":"pair","code":"wrong"}');
      expect(await badMessages.moveNext(), isFalse);
      expect(bad.closeCode, WebSocketStatus.policyViolation);
      final (malformed, malformedMessages) = await receiver(session);
      malformed.add('[');
      expect(await malformedMessages.moveNext(), isFalse);
      final (socket, messages) = await receiver(session);
      socket.add(jsonEncode({'type': 'pair', 'code': session.pairingCode}));
      final paired = await next(messages);
      final (other, otherMessages) = await receiver(session);
      other.add(
        jsonEncode({'type': 'resume', 'sessionToken': paired['sessionToken']}),
      );
      expect(await otherMessages.moveNext(), isFalse);
      expect(other.closeCode, WebSocketStatus.policyViolation);
    },
  );

  test(
    'Samsung reconnect requires token and fresh HDMI confirmation; stop revokes session',
    () async {
      final session = await samsung();
      final (socket, messages) = await receiver(session);
      socket.add(jsonEncode({'type': 'pair', 'code': session.pairingCode}));
      final token = (await next(messages))['sessionToken'];
      socket.add('{"type":"ready","hdmiVisible":true}');
      await next(messages);
      session.updateSubtitles(['stale'], const SubtitleSettings());
      await next(messages);
      await socket.close();
      await eventually(() => !session.hasReceiver);
      final (resumed, resumedMessages) = await receiver(session);
      resumed.add(jsonEncode({'type': 'resume', 'sessionToken': token}));
      expect((await next(resumedMessages))['type'], 'paired');
      expect(session.isConnected, isFalse);
      resumed.add('{"type":"ready","hdmiVisible":true}');
      expect((await next(resumedMessages))['type'], 'clear');
      resumed.add('{"type":"notReady"}');
      await eventually(() => !session.isConnected);
      await session.stop();
      expect(session.isRunning, isFalse);
      expect(session.pairingCode, isNull);
      expect(session.endpoints, isEmpty);
      expect(session.addresses, isEmpty);
    },
  );

  test('Samsung PIN expires and locks after five wrong attempts', () async {
    var now = DateTime.utc(2026, 11, 5);
    final session = SamsungTvSession(now: () => now);
    addTearDown(session.stop);
    Future<void> start() => session.start(
      bindAddress: InternetAddress.loopbackIPv4,
      localAddresses: ['192.168.1.3'],
      archive: Uint8List(0),
    );
    await start();
    final expiredPin = session.pairingCode;
    now = now.add(const Duration(minutes: 3));
    final (expired, expiredMessages) = await receiver(session);
    expired.add(jsonEncode({'type': 'pair', 'code': expiredPin}));
    expect(await expiredMessages.moveNext(), isFalse);
    await start();
    for (var i = 0; i < 5; i++) {
      final (bad, badMessages) = await receiver(session);
      bad.add('{"type":"pair","code":"wrong"}');
      expect(await badMessages.moveNext(), isFalse);
    }
    final (locked, lockedMessages) = await receiver(session);
    locked.add(jsonEncode({'type': 'pair', 'code': session.pairingCode}));
    expect(await lockedMessages.moveNext(), isFalse);
  });
}
