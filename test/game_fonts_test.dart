import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/services/game_fonts.dart';
import 'package:gametranslate/services/game_translation_catalog.dart';
import 'package:gametranslate/widgets/game_subtitle_text.dart';

class _EmptyCatalog extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode('[]')));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late Directory directory;
  late String json;
  late Map<String, dynamic> font;
  late Uint8List fontBytes;
  late List<String> requests;
  var corrupt = false;
  GameTranslationCatalog catalog({bool offline = false}) =>
      GameTranslationCatalog.testing(
        catalogUri: Uri.parse('http://127.0.0.1:${server.port}/catalog.json'),
        cacheDirectory: () async => directory,
        bundle: _EmptyCatalog(),
        token: () async =>
            offline ? throw StateError('Offline') : 'test-app-check-token',
      );

  setUp(() async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previous);
    GameFonts.active.value = null;
    addTearDown(() => GameFonts.active.value = null);
    directory = await Directory.systemTemp.createTemp('game-font-test-');
    addTearDown(() async {
      final target = Directory(await directory.resolveSymbolicLinks());
      expect(
        target.parent.path,
        await Directory.systemTemp.resolveSymbolicLinks(),
      );
      expect(
        target.path.split(Platform.pathSeparator).last,
        startsWith('game-font-test-'),
      );
      await target.delete(recursive: true);
    });
    final profileText = await File(
      'server/game-catalog/profiles/games/alan-wake-2.jsonl',
    ).readAsString();
    final profile = jsonDecode(profileText) as Map;
    json = jsonEncode({'gameProfile': profile});
    font = Map<String, dynamic>.from((profile['fonts'] as List).single as Map);
    fontBytes = await File(
      'server/game-catalog/fonts/${font['sha256']}.ttf',
    ).readAsBytes();
    requests = [];
    corrupt = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      requests.add(request.uri.path);
      expect(
        request.headers.value('X-Firebase-AppCheck'),
        'test-app-check-token',
      );
      if (request.uri.path == '/${font['file']}') {
        request.response.headers.contentType = ContentType('font', 'ttf');
        request.response.add(
          corrupt ? List<int>.filled(fontBytes.length, 0) : fontBytes,
        );
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });
  });

  test(
    'real font downloads once, shares its hash across games, and works offline after restart',
    () async {
      final service = catalog();
      final loaded = await GameFonts.prepare(json, service);
      expect(loaded, isNotNull);
      expect(loaded!.sha256, crypto.sha256.convert(fontBytes).toString());
      expect(loaded.bytes, fontBytes);
      final re2 = await File(
        'server/game-catalog/profiles/games/resident-evil-2-remake.jsonl',
      ).readAsString();
      expect(
        (await GameFonts.prepare(
          jsonEncode({'gameProfile': jsonDecode(re2)}),
          service,
        ))!.sha256,
        loaded.sha256,
      );
      expect(requests, ['/${font['file']}']);
      final restored = await GameFonts.prepare(json, catalog(offline: true));
      expect(restored!.family, loaded.family);
      expect(requests, hasLength(1));
      final mafia = await File(
        'server/game-catalog/profiles/games/mafia-old-country.jsonl',
      ).readAsString();
      expect(
        await GameFonts.prepare(
          jsonEncode({'gameProfile': jsonDecode(mafia)}),
          service,
        ),
        isNull,
      );
    },
  );

  test(
    'prepared fonts restore immediately by pack version and forget on deletion',
    () async {
      const key = 'font-cache-test:v1';
      addTearDown(() => GameFonts.forgetGame('font-cache-test'));
      final loaded = await GameFonts.prepare(json, catalog(), contentKey: key);
      expect(loaded, isNotNull);
      GameFonts.active.value = null;
      expect(GameFonts.restorePrepared(key), isTrue);
      expect(GameFonts.active.value, same(loaded));
      expect(
        GameFonts.forSettings(const SubtitleSettings(useGameFont: false)),
        isNull,
      );
      // Restoring a prepared game must not parse JSON or fetch a font again.
      expect(
        await GameFonts.prepare(
          'invalid JSON',
          catalog(offline: true),
          contentKey: key,
        ),
        same(loaded),
      );
      expect(requests, hasLength(1));
      expect(GameFonts.restorePrepared('font-cache-test:v2'), isFalse);
      const systemKey = 'font-cache-test:system';
      expect(
        await GameFonts.prepare(
          '{"gameProfile":{"regions":[]}}',
          catalog(),
          contentKey: systemKey,
        ),
        isNull,
      );
      expect(GameFonts.restorePrepared(systemKey), isTrue);
      expect(GameFonts.active.value, isNull);
      GameFonts.forgetGame('font-cache-test');
      expect(GameFonts.restorePrepared(key), isFalse);
      expect(GameFonts.restorePrepared(systemKey), isFalse);
    },
  );

  test(
    'a large TrueType font downloads, renders and remains cached across restart',
    () async {
      final padded = Uint8List(GameTranslationCatalog.maxFontBytes)
        ..setRange(0, fontBytes.length, fontBytes);
      fontBytes = padded;
      font = {
        ...font,
        'bytes': padded.length,
        'sha256': crypto.sha256.convert(padded).toString(),
        'file': 'fonts/large-font.ttf',
      };
      final pack = jsonDecode(json) as Map<String, dynamic>;
      (pack['gameProfile'] as Map)['fonts'] = [font];
      json = jsonEncode(pack);
      final loaded = await GameFonts.prepare(json, catalog());
      expect(loaded!.bytes, padded);
      expect(requests, ['/${font['file']}']);
      final restored = await GameFonts.prepare(json, catalog(offline: true));
      expect(restored!.sha256, loaded.sha256);
      expect(requests, hasLength(1));
      await expectLater(
        catalog().loadFont({
          ...font,
          'bytes': GameTranslationCatalog.maxFontBytes + 1,
        }),
        throwsFormatException,
      );
      expect(requests, hasLength(1));
    },
  );

  test(
    'corrupted and external font references cannot reach the renderer',
    () async {
      corrupt = true;
      await expectLater(
        GameFonts.prepare(json, catalog()),
        throwsFormatException,
      );
      await expectLater(
        catalog().loadFont({
          ...font,
          'file': 'https://foreign.example/font.ttf',
        }),
        throwsFormatException,
      );
      expect(GameFonts.active.value, isNull);
    },
  );

  testWidgets(
    'the live subtitle widget renders downloaded Inter with Turkish glyphs and returns to system font',
    (tester) async {
      const sample = 'İğne ışığı: ÇÖŞÜ çğöşü 123';
      Future<void> draw({bool useGameFont = true}) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GameSubtitleText(
                key: ValueKey('live-subtitle'),
                text: sample,
                settings: SubtitleSettings(useGameFont: useGameFont),
                fontSize: 28,
              ),
            ),
          ),
        ),
      );
      await draw();
      final fallbackWidth = tester.getSize(find.text(sample)).width;
      final loaded = await tester.runAsync(
        () => GameFonts.prepare(json, catalog()),
      );
      expect(loaded, isNotNull);
      GameFonts.active.value = loaded;
      await tester.pump();
      final rendered = tester.widget<Text>(find.text(sample));
      expect(rendered.style!.fontFamily, loaded!.family);
      expect(
        tester.getSize(find.text(sample)).width,
        isNot(closeTo(fallbackWidth, 1)),
      );
      expect(tester.takeException(), isNull);
      await draw(useGameFont: false);
      expect(GameFonts.active.value, same(loaded));
      expect(tester.widget<Text>(find.text(sample)).style!.fontFamily, isNull);
      expect(
        tester.getSize(find.text(sample)).width,
        closeTo(fallbackWidth, 0.01),
      );
      await draw();
      expect(
        tester.widget<Text>(find.text(sample)).style!.fontFamily,
        loaded.family,
      );
      GameFonts.active.value = null;
      await tester.pump();
      expect(tester.widget<Text>(find.text(sample)).style!.fontFamily, isNull);
      expect(
        tester.getSize(find.text(sample)).width,
        closeTo(fallbackWidth, 0.01),
      );
    },
  );
}
