import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/services/tv_subtitle_client.dart';

// Opt-in integration test. Install the debug TV APK on a disposable emulator.
// This resets that emulator's TV pairing and never targets a physical device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const serial = String.fromEnvironment('TV_NATIVE_SERIAL');
  const adbPath = String.fromEnvironment('TV_NATIVE_ADB', defaultValue: 'adb');
  const package = 'com.abrebostudio.consolegametranslator_tv';

  test(
    'native WSS delivery survives background, screen off and saved restore',
    () async {
      expect(serial.startsWith('emulator-'), isTrue);
      Future<String> adb(List<String> arguments) async {
        final result = await Process.run(
          adbPath,
          ['-s', serial, ...arguments],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        if (result.exitCode != 0) {
          throw StateError('Emulator command failed: ${result.stderr}');
        }
        return (result.stdout as String).trim();
      }

      Future<String> preferences() => adb([
        'shell',
        'run-as',
        package,
        'cat',
        'shared_prefs/tv_settings.xml',
      ]);
      Future<void> awaitSubtitle(String expected) async {
        final limit = DateTime.now().add(const Duration(seconds: 5));
        while (DateTime.now().isBefore(limit)) {
          if ((await preferences()).contains(expected)) return;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        fail('The native receiver did not receive the expected subtitle.');
      }

      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousOverrides);
      const channel = MethodChannel(
        'com.abrebostudio.consolegametranslator/ps5_registration',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final client = TvSubtitleClient.forTesting();
      addTearDown(client.disconnect);

      await adb(['shell', 'am', 'start', '-W', '-n', '$package/.MainActivity']);
      await Future<void>.delayed(const Duration(seconds: 3));
      await adb([
        'shell',
        'run-as',
        package,
        'am',
        'start-foreground-service',
        '--user',
        '0',
        '-n',
        '$package/.TvReceiverService',
        '-a',
        '$package.RESET_PAIRING',
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final code = RegExp(
        r'<string name="receiver_pairing_code">(\d{6})</string>',
      ).firstMatch(await preferences())?.group(1);
      expect(code, isNotNull);
      final securePort = await adb(['forward', 'tcp:0', 'tcp:43823']);
      final plainPort = await adb(['forward', 'tcp:0', 'tcp:43822']);
      addTearDown(() async {
        await adb(['shell', 'input', 'keyevent', '224']);
        await adb(['forward', '--remove', 'tcp:$securePort']);
        await adb(['forward', '--remove', 'tcp:$plainPort']);
      });

      final address = 'wss://127.0.0.1:$securePort';
      final settings = SubtitleSettings.fromMap({
        'enabled': true,
        'fontSize': 28,
      });
      client.updateSubtitles(['Native çeviri 🎮', 'İkinci bölge'], settings);
      await client.connect(
        address,
        code!,
        verifyCertificate: (_) async => true,
      );
      await awaitSubtitle('Native çeviri');
      final token = client.sessionToken!;
      final fingerprint = client.certificateFingerprint!;

      await adb(['shell', 'input', 'keyevent', '3']);
      client.updateSubtitles(['Arka plan aktarimi', 'İkinci bölge'], settings);
      await awaitSubtitle('Arka plan aktarimi');
      await adb(['shell', 'input', 'keyevent', '223']);
      // Cross the production client's 15-second ping interval while asleep.
      await Future<void>.delayed(const Duration(seconds: 17));
      expect(client.isConnected, isTrue);
      for (var i = 0; i < 100; i++) {
        client.updateSubtitles([
          'Ekran kapali aktarim $i',
          'İkinci bölge',
        ], settings);
      }
      await awaitSubtitle('Ekran kapali aktarim 99');
      client.updateSettings(settings.copyWith(fontSize: 36));
      await client.disconnect();
      await client.restorePairing(
        address,
        token,
        certificateFingerprint: fingerprint,
      );
      expect(client.isConnected, isTrue);
      client.updateSubtitle('Guvenli yeniden baglanti', settings);
      await awaitSubtitle('Guvenli yeniden baglanti');

      final plain = await WebSocket.connect(
        'ws://127.0.0.1:$plainPort/subtitles',
      );
      plain.add(jsonEncode({'type': 'resume', 'sessionToken': token}));
      final rejection =
          jsonDecode(
                await plain.first.timeout(const Duration(seconds: 3)) as String,
              )
              as Map;
      expect(rejection['type'], 'pairRejected');
      await plain.close();
      expect(client.isConnected, isTrue);
      client.updateSubtitle('', settings);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        (await preferences()).contains(
          '<string name="receiver_subtitle"></string>',
        ),
        isTrue,
      );
    },
    skip: serial.isEmpty,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
