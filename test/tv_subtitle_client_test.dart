import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/services/tv_subtitle_client.dart';
import 'package:gametranslate/services/game_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'TV subtitles stay enabled across appearance updates and clear on stop',
    () async {
      // Use a loopback TV receiver so the test checks the actual wire messages.
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverrides);
      const channel = MethodChannel(
        'com.abrebostudio.consolegametranslator/ps5_registration',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final received = StreamController<Map<String, dynamic>>.broadcast();
      final allMessages = <Map<String, dynamic>>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <WebSocket>[];
      final connections = server.transform(WebSocketTransformer()).listen((
        socket,
      ) {
        sockets.add(socket);
        socket.listen((data) {
          final message = Map<String, dynamic>.from(
            jsonDecode(data as String) as Map,
          );
          if (message['type'] == 'pair') {
            socket.add(
              jsonEncode({
                'type': 'paired',
                'sessionToken': List.filled(48, 'a').join(),
              }),
            );
          } else {
            allMessages.add(message);
            received.add(message);
          }
        });
      });
      final client = TvSubtitleClient.instance;
      addTearDown(() async {
        GameFonts.active.value = null;
        await client.disconnect();
        for (final socket in sockets) {
          await socket.close();
        }
        await connections.cancel();
        await server.close(force: true);
        await received.close();
      });

      final settings = SubtitleSettings.fromMap(<String, Object>{
        'enabled': false,
        'fontSize': 28,
      });
      client.updateSubtitles(['Çevrilmiş altyazı', 'İkinci satır'], settings);
      final initialSubtitle = received.stream.first.timeout(
        const Duration(seconds: 5),
      );
      await client.connect('127.0.0.1:${server.port}', '123456');
      final subtitle = await initialSubtitle;
      expect(subtitle['type'], 'subtitle');
      expect(subtitle['texts'], ['Çevrilmiş altyazı', 'İkinci satır']);
      expect((subtitle['presentation'] as Map)['enabled'], isTrue);

      final nextPresentation = received.stream.first.timeout(
        const Duration(seconds: 5),
      );
      client.updateSettings(settings.copyWith(fontSize: 32));
      final presentation = await nextPresentation;
      expect(presentation['type'], 'presentation');
      expect(presentation['texts'], subtitle['texts']);
      expect((presentation['presentation'] as Map)['fontSize'], 32);
      expect((presentation['presentation'] as Map)['enabled'], isTrue);

      final fontMap =
          jsonDecode(
                await File(
                  'server/game-catalog/profiles/font-assets.json',
                ).readAsString(),
              )
              as Map;
      final descriptor = fontMap['Inter-Regular'] as Map;
      final bytes = await File(
        'server/game-catalog/fonts/${descriptor['sha256']}.ttf',
      ).readAsBytes();
      final font = LoadedGameFont(
        sha256: descriptor['sha256'] as String,
        bytes: bytes,
      );
      GameFonts.active.value = font;
      final downloadedFontPackets = received.stream
          .take(2)
          .toList()
          .timeout(const Duration(seconds: 5));
      client.updateSettings(settings);
      final packets = await downloadedFontPackets;
      expect(packets.map((packet) => packet['type']), ['font', 'presentation']);
      expect(base64Decode(packets.first['data'] as String), bytes);
      expect((packets.last['presentation'] as Map)['fontSha256'], font.sha256);
      final fontUpdate = received.stream.first.timeout(
        const Duration(seconds: 5),
      );
      client.updateSettings(settings.copyWith(fontSize: 33));
      expect((await fontUpdate)['type'], 'presentation');
      expect(
        allMessages.where((message) => message['type'] == 'font'),
        hasLength(1),
      );
      final systemFontUpdate = received.stream.first.timeout(
        const Duration(seconds: 5),
      );
      client.updateSettings(settings.copyWith(useGameFont: false));
      final systemPresentation =
          (await systemFontUpdate)['presentation'] as Map;
      expect(systemPresentation.containsKey('fontSha256'), isFalse);
      expect(systemPresentation['fontSize'], settings.fontSize);
      expect(GameFonts.active.value, same(font));
      final restoreGameFont = received.stream.first.timeout(
        const Duration(seconds: 5),
      );
      client.updateSettings(settings.copyWith(useGameFont: true));
      expect(
        ((await restoreGameFont)['presentation'] as Map)['fontSha256'],
        font.sha256,
      );
      expect(
        allMessages.where((message) => message['type'] == 'font'),
        hasLength(1),
      );
      GameFonts.active.value = null;

      final nextClear = received.stream.first.timeout(
        const Duration(seconds: 5),
      );
      client.updateSubtitle('', settings);
      final cleared = await nextClear;
      expect(cleared['type'], 'clear');
      expect(cleared['text'], isEmpty);
      expect(
        (cleared['presentation'] as Map).containsKey('fontSha256'),
        isFalse,
      );
    },
  );
}
