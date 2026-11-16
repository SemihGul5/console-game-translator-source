import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/screens/ps5_stream_screen.dart';
import 'package:gametranslate/services/game_translation_pack.dart';
import 'package:gametranslate/widgets/game_subtitle_text.dart';

const _native = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);
const _events = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_events',
);
const _previewDirectory = String.fromEnvironment('GAME_JSON_PREVIEW_DIR');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final config =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString())
            as Map;
    final flutter = (config['packages'] as List).cast<Map>().firstWhere(
      (p) => p['name'] == 'flutter',
    );
    final root = Directory.fromUri(
      Uri.parse(flutter['rootUri'] as String),
    ).parent.parent;
    final loader = FontLoader('Roboto')
      ..addFont(
        File(
          '${root.path}/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await loader.load();
  });

  testWidgets(
    'JSON translation events render unchanged in the live overlay and clear cleanly',
    (tester) async {
      final fixture = await tester.runAsync(
        () => File(
          'android/app/src/test/resources/game-json-display.json',
        ).readAsString(),
      );
      final pack = GameTranslationPack.decode(
        fixture!,
        gameId: 'display-test',
        sourceLanguage: 'en',
        targetLanguage: 'tr',
      );
      final rows = (pack['entries'] as List).cast<Map>();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final presentations = <Map>[];
      messenger.setMockMethodCallHandler(_native, (call) async {
        if (call.method == 'reportSubtitlePresentation') {
          presentations.add(call.arguments as Map);
          return null;
        }
        if (call.method == 'getSessionState') {
          return {'active': true, 'connected': true, 'videoReady': true};
        }
        if (call.method == 'getSubtitleSettings') {
          return const SubtitleSettings().toMap();
        }
        return null;
      });
      messenger.setMockMethodCallHandler(_events, (_) async => null);
      messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
        call,
      ) async {
        if (call.method == 'create') return 1;
        if (call.method == 'resize') {
          final args = call.arguments as Map;
          return {'width': args['width'], 'height': args['height']};
        }
        return null;
      });
      addTearDown(() {
        for (final channel in [
          _native,
          _events,
          SystemChannels.platform_views,
        ]) {
          messenger.setMockMethodCallHandler(channel, null);
        }
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final preview = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
          ),
          home: RepaintBoundary(key: preview, child: const Ps5StreamScreen()),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> emit(Map<String, Object?> event) async {
        await messenger.handlePlatformMessage(
          _events.name,
          const StandardMethodCodec().encodeSuccessEnvelope(event),
          (_) {},
        );
        await tester.pumpAndSettle();
      }

      const expected = [
        'Sweet: Gece çökmeden gitmeliyiz.\nÇıkış şu köşede.',
        'Isabella: Evin girişini gözetle.',
        'Eski depoya ulaş.',
      ];
      for (var index = 0; index < rows.length; index++) {
        // These text payloads are also asserted against actual matcher output by
        // GameSubtitleEventTest on the JVM, using the same JSON fixture.
        await emit({
          'type': 'subtitleText',
          'text': expected[index],
          'regionIndex': 0,
          'translationEngine': 'game_memory',
          'translationMemory': {'id': rows[index]['id']},
          'diagnostics': true,
        });
        final overlay = find.byType(GameSubtitleText);
        expect(overlay, findsOneWidget);
        expect(tester.widget<GameSubtitleText>(overlay).text, expected[index]);
        expect(find.text(expected[index]), findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(expected[index]),
        );
        final lastCharacter = paragraph.getBoxesForSelection(
          TextSelection(
            baseOffset: expected[index].length - 1,
            extentOffset: expected[index].length,
          ),
        );
        expect(lastCharacter, isNotEmpty);
        expect(
          lastCharacter.last.bottom,
          lessThanOrEqualTo(paragraph.size.height + 0.5),
          reason:
              'The final subtitle line must remain visible in the selected region',
        );
        expect(find.text(rows[index]['english'] as String), findsNothing);
        expect(tester.takeException(), isNull);
        expect(presentations.last['result'], 'frame_built');
        expect(presentations.last['chars'], expected[index].length);
        if (_previewDirectory.isNotEmpty) {
          final boundary =
              preview.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(_previewDirectory).create(recursive: true);
            await File(
              '$_previewDirectory/json-subtitle-$index.png',
            ).writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      for (final text in ['Otur!', 'Beni yine soymayacaksın değil mi?']) {
        await emit({
          'type': 'subtitleText',
          'text': text,
          'regionIndex': 0,
          'translationEngine': 'game_memory',
          'diagnostics': true,
          'translationMemory': {'id': 'logged-short-dialogue'},
        });
        expect(find.text(text), findsOneWidget);
        expect(presentations.last['result'], 'frame_built');
        expect(presentations.last['chars'], text.length);
      }
      await emit({'type': 'subtitleCleared', 'regionIndex': 0});
      expect(find.byType(GameSubtitleText), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
