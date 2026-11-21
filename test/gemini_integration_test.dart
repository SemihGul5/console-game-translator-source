import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/main.dart';
import 'package:gametranslate/widgets/gemini_settings_panel.dart';

import 'support/offline_game_catalog.dart';

const _native = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);
const _access = MethodChannel('com.abrebostudio.consolegametranslator/access');
const _events = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_events',
);

void main() {
  late String engine;
  late bool hasKey;
  late bool running;
  late Map<String, Object> settings;
  late List<MethodCall> calls;

  setUp(() {
    engine = 'mlkit';
    hasKey = true;
    running = false;
    settings = {'sourceLanguageCode': 'en', 'targetLanguageCode': 'tr'};
    calls = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_events, (_) async => null);
    messenger.setMockMethodCallHandler(
      _access,
      (call) async =>
          call.method == 'configuration' ? {'configured': false} : null,
    );
    messenger.setMockMethodCallHandler(_native, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'getTranslationEngine':
          return engine;
        case 'setTranslationEngine':
          engine = call.arguments as String;
          return null;
        case 'getGeminiSettings':
          return {'hasKey': hasKey};
        case 'getSubtitleSettings':
          return settings;
        case 'saveSubtitleSettings':
          settings = Map<String, Object>.from(call.arguments as Map);
          return null;
        case 'getTranslationLanguageModels':
          return [
            {
              'code': 'en',
              'name': 'English',
              'nativeName': 'English',
              'downloaded': false,
            },
            {
              'code': 'tr',
              'name': 'Türkçe',
              'nativeName': 'Türkçe',
              'downloaded': false,
            },
            {
              'code': 'de',
              'name': 'Almanca',
              'nativeName': 'Deutsch',
              'downloaded': false,
            },
            {
              'code': 'ar',
              'name': 'Arapça',
              'nativeName': 'العربية',
              'downloaded': false,
            },
            {
              'code': 'hi',
              'name': 'Hintçe',
              'nativeName': 'हिन्दी',
              'downloaded': false,
            },
            {
              'code': 'th',
              'name': 'Tayca',
              'nativeName': 'ไทย',
              'downloaded': false,
            },
          ];
        case 'getSessionState':
          return {
            'active': running,
            'connected': running,
            'videoReady': running,
          };
        case 'isTranslationForegroundRunning':
          return running;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [_native, _access, _events]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  Future<void> open(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => offlineGameCatalog.loadCatalog());
    await tester.pumpWidget(GameTranslateApp(gameCatalog: offlineGameCatalog));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<String>),
      400,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('home-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'selects and persists Gemini without requiring offline language downloads',
    (tester) async {
      await open(tester);
      final selector = find.byKey(const ValueKey('mlkit-0'));
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gemini (ücretsiz katman)').last);
      await tester.pumpAndSettle();
      expect(engine, 'gemini');
      expect(find.byType(GeminiSettingsPanel), findsOneWidget);
      expect(find.text('Dilleri görüntüle ve indir'), findsNothing);
      expect(
        calls.any(
          (call) =>
              call.method == 'testGeminiConnection' ||
              call.method == 'saveGeminiApiKey',
        ),
        isFalse,
      );
      expect(
        calls.any((call) => call.method == 'downloadTranslationLanguage'),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('restores Gemini and preserves a supported saved language pair', (
    tester,
  ) async {
    engine = 'gemini';
    settings = {'sourceLanguageCode': 'de', 'targetLanguageCode': 'tr'};
    await open(tester);
    expect(find.byType(GeminiSettingsPanel), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Deutsch'),
      -200,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('home-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Deutsch'), findsWidgets);
    expect(find.text('Almanca'), findsNothing);
    expect(settings['sourceLanguageCode'], 'de');
    expect(settings['targetLanguageCode'], 'tr');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'restores Gemini and exposes Arabic without an offline download',
    (tester) async {
      engine = 'gemini';
      settings = {'sourceLanguageCode': 'en', 'targetLanguageCode': 'ar'};
      await open(tester);
      await tester.scrollUntilVisible(
        find.text('العربية'),
        -200,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('home-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('العربية'), findsWidgets);
      expect(find.textContaining('• indirilmedi'), findsNothing);
      expect(
        calls.any((call) => call.method == 'downloadTranslationLanguage'),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('blocks changing provider while translation is running', (
    tester,
  ) async {
    running = true;
    await open(tester);
    final selector = find.byKey(const ValueKey('mlkit-0'));
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gemini (ücretsiz katman)').last);
    await tester.pumpAndSettle();
    expect(engine, 'mlkit');
    expect(
      calls.where((call) => call.method == 'setTranslationEngine'),
      isEmpty,
    );
    expect(find.text('Model değiştirilemez'), findsOneWidget);
  });
}
