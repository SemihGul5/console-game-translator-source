import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/main.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/services/game_translation_catalog.dart';
import 'package:gametranslate/widgets/game_cover_card.dart';

class _LanguageAssets extends CachingAssetBundle {
  _LanguageAssets({this.targets = const ['tr', 'th', 'id']});
  final List<String> targets;
  @override
  Future<ByteData> load(String key) async {
    final data = key.endsWith('catalog.json')
        ? [
            for (final target in targets)
              {
                'id': 'shared-en-$target',
                'gameId': 'shared',
                'name': 'Shared Game',
                'sourceLanguage': 'en',
                'targetLanguage': target,
                'targetLanguageName': {
                  'tr': 'Türkçe',
                  'th': 'Tayca',
                  'id': 'Endonezce',
                  'ar': 'Arapça',
                }[target],
                'targetLanguageNativeName': {
                  'tr': 'Türkçe',
                  'th': 'ไทย',
                  'id': 'Bahasa Indonesia',
                  'ar': 'العربية',
                }[target],
                'file': 'assets/games/$target.json',
              },
          ]
        : {
            'schemaVersion': 2,
            'game': 'shared',
            'source': 'en',
            'target': key.split('/').last.split('.').first,
            'entries': [
              {
                'id': '1',
                'sourceText': 'Come here!',
                'targetText': 'Example translation',
              },
            ],
          };
    return ByteData.sublistView(
      Uint8List.fromList(utf8.encode(jsonEncode(data))),
    );
  }
}

Future<void> _openLibrary(
  WidgetTester tester,
  GameTranslationCatalog catalog, {
  Locale systemLocale = const Locale('en'),
}) async {
  tester.platformDispatcher.localesTestValue = [systemLocale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(GameTranslateApp(gameCatalog: catalog));
  await tester.pump(const Duration(milliseconds: 1100));
  await tester.pumpAndSettle();
  final turkish = find.widgetWithText(NavigationDestination, 'Altyazı');
  await tester.tap(
    turkish.evaluate().isNotEmpty
        ? turkish
        : find.widgetWithText(NavigationDestination, 'Subtitles'),
  );
  await tester.pumpAndSettle();
}

void main() {
  const native = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );
  const access = MethodChannel('com.abrebostudio.consolegametranslator/access');
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  testWidgets(
    'only targets with uploaded game packs appear even with a stale saved target',
    (tester) async {
      messenger.setMockMethodCallHandler(native, (call) async {
        if (call.method == 'getSubtitleSettings')
          return const SubtitleSettings().toMap();
        if (call.method == 'getGameLibraryTargetLanguage') return 'th';
        return null;
      });
      messenger.setMockMethodCallHandler(
        access,
        (_) async => {'configured': false},
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(native, null);
        messenger.setMockMethodCallHandler(access, null);
      });
      final catalog = GameTranslationCatalog.testing(
        catalogUri: Uri.parse('https://example.com/catalog.json'),
        cacheDirectory: () async => null,
        bundle: _LanguageAssets(targets: const ['tr']),
        token: () async => throw StateError('offline'),
      );
      await tester.runAsync(catalog.loadCatalog);
      await _openLibrary(tester, catalog);
      final picker = find.descendant(
        of: find.byKey(const ValueKey('game-library-language-tr')),
        matching: find.byType(DropdownButton<String>),
      );
      expect(
        tester
            .widget<DropdownButton<String>>(picker)
            .items!
            .map((item) => item.value),
        ['tr'],
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final failThai in [false, true]) {
    testWidgets(
      failThai
          ? 'failed Thai selection preserves the active Turkish pack'
          : 'library filters by language and commits the game and target together',
      (tester) async {
        final commits = <Map>[];
        final memories = <Map>[];
        final cached = <String>{};
        messenger.setMockMethodCallHandler(native, (call) async {
          switch (call.method) {
            case 'getSubtitleSettings':
              return const SubtitleSettings().toMap();
            case 'getGameLibraryTargetLanguage':
              return 'tr';
            case 'isTranslationForegroundRunning':
              return false;
            case 'activateCachedGameTranslationMemory':
              return {
                'loaded': cached.contains(
                  (call.arguments as Map)['contentKey'],
                ),
              };
            case 'setGameTranslationMemory':
              final value = call.arguments as Map;
              if (failThai && value['targetLanguage'] == 'th')
                throw PlatformException(code: 'INVALID_PACK');
              memories.add(value);
              cached.add(value['contentKey'] as String);
              return {'loaded': true, 'entryCount': 1};
            case 'commitGameTranslationSelection':
              commits.add(call.arguments as Map);
              return null;
            default:
              return null;
          }
        });
        messenger.setMockMethodCallHandler(
          access,
          (_) async => {'configured': false},
        );
        addTearDown(() {
          messenger.setMockMethodCallHandler(native, null);
          messenger.setMockMethodCallHandler(access, null);
        });
        final catalog = GameTranslationCatalog.testing(
          catalogUri: Uri.parse('https://example.com/catalog.json'),
          cacheDirectory: () async => null,
          bundle: _LanguageAssets(),
          token: () async => throw StateError('offline'),
        );
        await tester.runAsync(catalog.loadCatalog);
        await _openLibrary(tester, catalog);
        expect(find.byType(GameCoverCard), findsOneWidget);
        if (failThai) {
          await tester.tap(find.byType(GameCoverCard));
          await tester.pumpAndSettle();
          expect(commits.single['targetLanguage'], 'tr');
        }
        await tester.tap(
          find.byKey(const ValueKey('game-library-language-tr')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Tayca'), findsNothing);
        expect(find.text('Endonezce'), findsNothing);
        await tester.tap(find.text('ไทย').last);
        await tester.pumpAndSettle();
        expect(find.byType(GameCoverCard), findsOneWidget);
        expect(
          tester
              .widget<GameCoverCard>(find.byType(GameCoverCard))
              .game
              .targetLanguage,
          'th',
        );
        await tester.tap(find.byType(GameCoverCard));
        await tester.pumpAndSettle();
        if (failThai) {
          expect(commits, hasLength(1));
          expect(find.textContaining('Selected: Shared Game'), findsOneWidget);
        } else {
          expect(commits.single['packId'], 'shared-en-th');
          expect(commits.single['gameId'], 'shared');
          expect(commits.single['targetLanguage'], 'th');
          expect(memories.single['gameId'], 'shared');
          expect(jsonDecode(memories.single['json'])['target'], 'th');
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scenario in [
    (
      preference: 'system',
      device: const Locale('tr', 'TR'),
      target: 'tr',
      picker: false,
    ),
    (
      preference: 'system',
      device: const Locale('ar', 'SA'),
      target: 'ar',
      picker: false,
    ),
    (preference: 'tr', device: const Locale('ar'), target: 'ar', picker: false),
    (preference: 'en', device: const Locale('ar'), target: 'ar', picker: false),
    (
      preference: 'system',
      device: const Locale('en', 'US'),
      target: 'th',
      picker: true,
    ),
  ]) {
    testWidgets(
      'library follows device ${scenario.device} with legacy preference ${scenario.preference}',
      (tester) async {
        final commits = <MethodCall>[];
        messenger.setMockMethodCallHandler(native, (call) async {
          if (call.method == 'getAppLanguage') return scenario.preference;
          if (call.method == 'getSubtitleSettings')
            return const SubtitleSettings().toMap();
          if (call.method == 'getGameLibraryTargetLanguage') return 'th';
          if (call.method == 'commitGameTranslationSelection')
            commits.add(call);
          return null;
        });
        messenger.setMockMethodCallHandler(
          access,
          (_) async => {'configured': false},
        );
        addTearDown(() {
          messenger.setMockMethodCallHandler(native, null);
          messenger.setMockMethodCallHandler(access, null);
        });
        final catalog = GameTranslationCatalog.testing(
          catalogUri: Uri.parse('https://example.com/catalog.json'),
          cacheDirectory: () async => null,
          bundle: _LanguageAssets(targets: const ['tr', 'ar', 'th']),
          token: () async => throw StateError('offline'),
        );
        await tester.runAsync(catalog.loadCatalog);
        await _openLibrary(tester, catalog, systemLocale: scenario.device);
        expect(find.byType(GameCoverCard), findsOneWidget);
        expect(
          tester
              .widget<GameCoverCard>(find.byType(GameCoverCard))
              .game
              .targetLanguage,
          scenario.target,
        );
        final picker = find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              ((widget.key! as ValueKey<String>).value).startsWith(
                'game-library-language-',
              ),
        );
        expect(picker, scenario.picker ? findsOneWidget : findsNothing);
        expect(
          commits,
          isEmpty,
        ); // Browsing never changes the active game/translation pair.
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'missing system-language pack shows an empty library instead of another language',
    (tester) async {
      messenger.setMockMethodCallHandler(native, (call) async {
        if (call.method == 'getSubtitleSettings')
          return const SubtitleSettings().toMap();
        return null;
      });
      messenger.setMockMethodCallHandler(
        access,
        (_) async => {'configured': false},
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(native, null);
        messenger.setMockMethodCallHandler(access, null);
      });
      final catalog = GameTranslationCatalog.testing(
        catalogUri: Uri.parse('https://example.com/catalog.json'),
        cacheDirectory: () async => null,
        bundle: _LanguageAssets(targets: const ['tr']),
        token: () async => throw StateError('offline'),
      );
      await tester.runAsync(catalog.loadCatalog);
      await _openLibrary(tester, catalog, systemLocale: const Locale('ar'));
      expect(find.byType(GameCoverCard), findsNothing);
      expect(
        find.byKey(const ValueKey('game-library-language-tr')),
        findsNothing,
      );
      expect(
        find.text('No game packs are available in this language yet.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'system language changes update library filtering without switching the active pack',
    (tester) async {
      final commits = <MethodCall>[];
      messenger.setMockMethodCallHandler(native, (call) async {
        if (call.method == 'getSubtitleSettings')
          return const SubtitleSettings().toMap();
        if (call.method == 'getGameLibraryTargetLanguage') return 'tr';
        if (call.method == 'commitGameTranslationSelection') commits.add(call);
        return null;
      });
      messenger.setMockMethodCallHandler(
        access,
        (_) async => {'configured': false},
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(native, null);
        messenger.setMockMethodCallHandler(access, null);
      });
      final catalog = GameTranslationCatalog.testing(
        catalogUri: Uri.parse('https://example.com/catalog.json'),
        cacheDirectory: () async => null,
        bundle: _LanguageAssets(targets: const ['tr', 'ar']),
        token: () async => throw StateError('offline'),
      );
      await tester.runAsync(catalog.loadCatalog);
      await _openLibrary(tester, catalog, systemLocale: const Locale('ar'));
      expect(
        tester
            .widget<GameCoverCard>(find.byType(GameCoverCard))
            .game
            .targetLanguage,
        'ar',
      );
      tester.platformDispatcher.localesTestValue = const [Locale('en')];
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('game-library-language-tr')),
        findsOneWidget,
      );
      tester.platformDispatcher.localesTestValue = const [Locale('tr')];
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('game-library-language-tr')),
        findsNothing,
      );
      expect(
        tester
            .widget<GameCoverCard>(find.byType(GameCoverCard))
            .game
            .targetLanguage,
        'tr',
      );
      expect(commits, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
