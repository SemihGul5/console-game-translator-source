import 'package:flutter/material.dart';
import 'support/offline_game_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/l10n/app_localizations.dart';
import 'package:gametranslate/l10n/app_language.dart';
import 'package:gametranslate/l10n/messages_ar.dart';
import 'package:gametranslate/l10n/messages_en.dart';
import 'package:gametranslate/main.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/widgets/settings_section.dart';

const _native = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);
const _access = MethodChannel('com.abrebostudio.consolegametranslator/access');
const _events = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_events',
);

Future<void> _open(WidgetTester tester, Locale locale) async {
  tester.platformDispatcher.localesTestValue = [locale];
  await tester.runAsync(() => offlineGameCatalog.loadCatalog());
  await tester.pumpWidget(GameTranslateApp(gameCatalog: offlineGameCatalog));
  await tester.pump(const Duration(milliseconds: 1100));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, String title) async {
  await tester.tap(find.widgetWithText(NavigationDestination, title));
  await tester.pumpAndSettle();
}

Future<void> _revealProfile(WidgetTester tester, String title) async {
  final target = find.text(title);
  await tester.scrollUntilVisible(
    target,
    150,
    scrollable: find
        .descendant(
          of: find.byKey(const PageStorageKey('profile-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.4);
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String source) =>
    AppLocalizations.of(tester.element(find.byType(HomeScreen))).text(source);

Future<void> _pickLanguage(WidgetTester tester, String preference) async {
  await _tab(tester, _text(tester, 'Profil'));
  final title = _text(tester, 'Uygulama dili');
  await _revealProfile(tester, title);
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('app-language-choice-$preference')));
  await tester.pumpAndSettle();
}

Future<void> _pickEngine(
  WidgetTester tester,
  String current,
  String next,
) async {
  await _tab(tester, _text(tester, 'Ana sayfa'));
  final selector = find.byKey(ValueKey('$current-0'));
  await tester.scrollUntilVisible(
    selector,
    200,
    scrollable: find
        .descendant(
          of: find.byKey(const PageStorageKey('home-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await Scrollable.ensureVisible(tester.element(selector), alignment: 0.4);
  await tester.pumpAndSettle();
  final label = _text(tester, switch (next) {
    'opus' => 'Model A - Yerel Kaliteli',
    'mlkit' => 'Model B - Yerel Hızlı',
    'deepl' => 'DeepL (önerilen)',
    _ => 'Gemini (ücretsiz katman)',
  });
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String savedLanguage;
  late String? savedEngine;
  late SubtitleSettings savedSettings;
  late bool rejectLanguageSave;
  late bool rejectSettingsSave;
  late bool nativeRunning;
  late List<MethodCall> calls;

  setUp(() {
    savedLanguage = 'system';
    savedEngine = 'mlkit';
    savedSettings = const SubtitleSettings();
    rejectLanguageSave = false;
    rejectSettingsSave = false;
    nativeRunning = false;
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_events, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_native, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'getTranslationEngine':
              return savedEngine;
            case 'setTranslationEngine':
              savedEngine = call.arguments as String;
              return true;
            case 'getSubtitleSettings':
              return savedSettings.toMap();
            case 'saveSubtitleSettings':
              if (rejectSettingsSave)
                throw PlatformException(code: 'SUBTITLE_SETTINGS_SAVE_FAILED');
              savedSettings = SubtitleSettings.fromMap(call.arguments as Map);
              return true;
            case 'isTranslationForegroundRunning':
              return nativeRunning;
            case 'getTranslationLanguageModels':
              return [
                for (final code in ['en', 'tr', 'ar', 'de'])
                  {
                    'code': code,
                    'name': code,
                    'nativeName': AppLanguage.nativeName(code),
                    'downloaded': true,
                  },
              ];
            case 'getOfflineTranslationModels':
            case 'selectOfflineTranslationTarget':
              return [
                {
                  'target': 'tr',
                  'label': 'Türkçe',
                  'installed': false,
                  'selected': true,
                },
                {'target': 'de', 'label': 'Almanca', 'installed': false},
              ];
            case 'getAppLanguage':
              return savedLanguage;
            case 'setAppLanguage':
              if (rejectLanguageSave)
                throw PlatformException(code: 'APP_LANGUAGE_SAVE_FAILED');
              savedLanguage = call.arguments as String;
              return true;
            default:
              return null;
          }
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _access,
          (call) async =>
              call.method == 'configuration' ? {'configured': false} : null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_events, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_native, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_access, null);
  });

  for (final code in ['tr', 'en', 'de', 'ar', 'az']) {
    testWidgets(
      '$code device gets a fully localized navigation and start action',
      (tester) async {
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        await _open(tester, Locale(code));
        final turkish = code == 'tr';
        final arabic = code == 'ar';
        for (final title
            in turkish
                ? ['Altyazı', 'Ana sayfa', 'Profil']
                : arabic
                ? ['الترجمة', 'الرئيسية', 'الملف الشخصي']
                : ['Subtitles', 'Home', 'Profile']) {
          expect(
            find.widgetWithText(NavigationDestination, title),
            findsOneWidget,
          );
        }
        expect(
          find.text(
            turkish
                ? 'ÇEVİRİYİ BAŞLAT'
                : arabic
                ? 'بدء الترجمة'
                : 'START TRANSLATION',
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.text(
            turkish
                ? 'ÇEVİRİYİ BAŞLAT'
                : arabic
                ? 'بدء الترجمة'
                : 'START TRANSLATION',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            turkish
                ? 'PS5 gerekli'
                : arabic
                ? 'يلزم PS5'
                : 'PS5 required',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            turkish
                ? 'Önce PlayStation 5’i kurup kaydet.'
                : arabic
                ? 'أعدّ جهاز PlayStation 5 وسجّله أولًا.'
                : 'Set up and register your PlayStation 5 first.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(HomeScreen))),
          arabic ? TextDirection.rtl : TextDirection.ltr,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'system language changes update the interface and Model B while keeping state',
    (tester) async {
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await _open(tester, const Locale('tr'));
      final home = tester.state(find.byType(HomeScreen));
      await _tab(tester, 'Profil');
      await _revealProfile(tester, 'Uygulama dili');
      expect(find.text('Uygulama dili'), findsOneWidget);

      for (final code in ['en', 'de', 'ar', 'tr']) {
        tester.platformDispatcher.localesTestValue = [Locale(code)];
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(
            NavigationDestination,
            code == 'tr'
                ? 'Profil'
                : code == 'ar'
                ? 'الملف الشخصي'
                : 'Profile',
          ),
          findsOneWidget,
        );
        expect(tester.state(find.byType(HomeScreen)), same(home));
        expect(
          savedSettings.targetLanguageCode,
          AppLanguage.resolve(Locale(code)).languageCode,
        );
      }
      expect(calls.where((c) => c.method == 'setAppLanguage'), isEmpty);
      expect(savedLanguage, 'system');
      await tester.pumpWidget(const SizedBox.shrink());
      await _open(tester, const Locale('tr'));
      expect(
        find.widgetWithText(NavigationDestination, 'Ana sayfa'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('English settings, FAQ and setup translate stored content', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _open(tester, const Locale('de'));
    await _tab(tester, 'Profile');
    await _revealProfile(tester, 'Frequently asked questions');
    await tester.tap(find.text('Frequently asked questions'));
    await tester.pumpAndSettle();
    final question = find.text(
      "My PS5 cannot be found or will not connect. What should I do?",
    );
    expect(question, findsOneWidget);
    await tester.tap(question);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Your phone and PS5 must be on the same local network',
      ),
      findsOneWidget,
    );
    await tester.tap(question);
    await tester.pumpAndSettle();
    final backgroundQuestion = find.text(
      'Does translation continue in the background or with the phone screen off?',
    );
    await tester.scrollUntilVisible(backgroundQuestion, 200);
    await tester.tap(backgroundQuestion);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Remote Play and OCR run in the background'),
      findsOneWidget,
    );
    expect(find.textContaining('small video window'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _tab(tester, 'Home');
    await tester.tap(find.text('Setup guide'));
    await tester.pumpAndSettle();
    expect(
      find.text('1. Connect your phone, PS5, and TV to the same network'),
      findsOneWidget,
    );
    expect(find.text('Setup video'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'profile language persists, preserves the current screen and updates Model B target',
    (tester) async {
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await _open(tester, const Locale('tr'));
      final home = tester.state(find.byType(HomeScreen));
      await _pickLanguage(tester, 'ar');
      expect(savedLanguage, 'ar');
      expect(savedEngine, 'mlkit');
      expect(savedSettings.targetLanguageCode, 'ar');
      expect(savedSettings.sourceLanguageCode, 'en');
      expect(
        Directionality.of(tester.element(find.byType(HomeScreen))),
        TextDirection.rtl,
      );
      expect(tester.state(find.byType(HomeScreen)), same(home));
      expect(find.text('Oyun Çevirmeni', skipOffstage: false), findsOneWidget);
      tester.platformDispatcher.localesTestValue = const [Locale('en')];
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(NavigationDestination, 'الملف الشخصي'),
        findsOneWidget,
      );
      expect(savedSettings.targetLanguageCode, 'ar');
      await tester.pumpWidget(const SizedBox.shrink());
      await _open(tester, const Locale('en'));
      expect(
        Directionality.of(tester.element(find.byType(HomeScreen))),
        TextDirection.rtl,
      );
      await _pickLanguage(tester, 'en');
      expect(savedSettings.targetLanguageCode, 'en');
      expect(savedSettings.sourceLanguageCode, isNot('en'));
      await _pickLanguage(tester, 'tr');
      expect(savedSettings.targetLanguageCode, 'tr');
      expect(savedSettings.sourceLanguageCode, isNot('tr'));
      await _pickLanguage(tester, 'system');
      expect(savedLanguage, 'system');
      expect(savedSettings.targetLanguageCode, 'en');
      expect(savedEngine, 'mlkit');
      expect(
        calls.where((call) => call.method == 'setTranslationEngine'),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final engine in ['opus', 'deepl', 'gemini']) {
    testWidgets(
      'changing language retains saved $engine and applies the language when Model B is selected',
      (tester) async {
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        savedEngine = engine;
        savedSettings = const SubtitleSettings(
          sourceLanguageCode: 'en',
          targetLanguageCode: 'de',
        );
        await _open(tester, const Locale('tr'));
        await _pickLanguage(tester, 'ar');
        expect(savedLanguage, 'ar');
        expect(savedEngine, engine);
        expect(savedSettings.targetLanguageCode, 'de');
        expect(
          calls.where((call) => call.method == 'setTranslationEngine'),
          isEmpty,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await _open(tester, const Locale('tr'));
        expect(savedEngine, engine);
        expect(savedSettings.targetLanguageCode, 'de');
        await _pickEngine(tester, engine, 'mlkit');
        expect(savedEngine, 'mlkit');
        expect(savedSettings.targetLanguageCode, 'ar');
        expect(savedSettings.sourceLanguageCode, 'en');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'Model B is the initial default and every later engine choice survives reopening',
    (tester) async {
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      savedEngine = null;
      await _open(tester, const Locale('tr'));
      expect(
        calls.where((call) => call.method == 'setTranslationEngine'),
        isEmpty,
      );
      var current = 'mlkit';
      for (final engine in ['opus', 'deepl', 'gemini', 'mlkit']) {
        await _pickEngine(tester, current, engine);
        expect(savedEngine, engine);
        final saves = calls
            .where((call) => call.method == 'setTranslationEngine')
            .length;
        await tester.pumpWidget(const SizedBox.shrink());
        await _open(tester, const Locale('tr'));
        expect(savedEngine, engine);
        expect(
          calls.where((call) => call.method == 'setTranslationEngine').length,
          saves,
        );
        current = engine;
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'language save failures leave the old interface and target intact',
    (tester) async {
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await _open(tester, const Locale('tr'));
      rejectLanguageSave = true;
      await _pickLanguage(tester, 'ar');
      expect(savedLanguage, 'system');
      expect(savedSettings.targetLanguageCode, 'tr');
      expect(
        find.text('Dil tercihi kaydedilemedi. Tekrar dene.'),
        findsOneWidget,
      );
      expect(
        Directionality.of(tester.element(find.byType(HomeScreen))),
        TextDirection.ltr,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('language cannot change while translation is active', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _open(tester, const Locale('tr'));
    nativeRunning = true;
    await _pickLanguage(tester, 'ar');
    expect(savedLanguage, 'system');
    expect(savedSettings.targetLanguageCode, 'tr');
    expect(find.text('Dil değiştirilemez'), findsOneWidget);
    expect(calls.where((call) => call.method == 'setAppLanguage'), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'English screens and the language picker fit a small screen with large text',
    (tester) async {
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester, const Locale('de'));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      await tester.pumpAndSettle();
      await _tab(tester, 'Subtitles');
      expect(find.text('Subtitle appearance'), findsOneWidget);
      await _tab(tester, 'Profile');
      await tester.scrollUntilVisible(
        find.text('My subscription'),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('profile-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await _revealProfile(tester, 'My subscription');
      await tester.tap(find.text('My subscription'));
      await tester.pumpAndSettle();
      expect(
        find.text('Experience your game in your language'),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(
        find.text("The purchase service isn't ready yet."),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _tab(tester, 'Profile');
      await _revealProfile(tester, 'App language');
      expect(
        find.widgetWithText(SettingsEntry, 'App language'),
        findsOneWidget,
      );
      await tester.tap(find.text('App language'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('app-language-choice-ar')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('app-language-choice-system')),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 'Home');
      await tester.scrollUntilVisible(
        find.text('Set up PS5'),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('home-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.text('Set up PS5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set up PS5'));
      await tester.pumpAndSettle();
      expect(find.text('PSN account connection'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Sign in with PSN'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sign in with PSN'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'a failed Model B target update restores the previous language preference',
    (tester) async {
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await _open(tester, const Locale('tr'));
      rejectSettingsSave = true;
      await _pickLanguage(tester, 'ar');
      expect(savedLanguage, 'system');
      expect(savedSettings.targetLanguageCode, 'tr');
      expect(
        Directionality.of(tester.element(find.byType(HomeScreen))),
        TextDirection.ltr,
      );
      expect(
        find.text('Dil tercihi kaydedilemedi. Tekrar dene.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('translations retain every placeholder and preserve dynamic values', () {
    final placeholders = RegExp(r'\{\d+\}');
    for (final message in englishMessages.entries) {
      expect(
        placeholders.allMatches(message.value).map((m) => m[0]).toList()
          ..sort(),
        placeholders.allMatches(message.key).map((m) => m[0]).toList()..sort(),
        reason: message.key,
      );
    }
    const english = AppLocalizations(Locale('en'));
    const turkish = AppLocalizations(Locale('tr'));
    expect(
      english.message('Ghost of Tsushima seçili'),
      'Ghost of Tsushima selected',
    );
    expect(
      turkish.message('Ghost of Tsushima seçili'),
      'Ghost of Tsushima seçili',
    );
    expect(
      english.message(
        'Dil paketi indirilemedi. İnternet bağlantını kontrol edip yeniden dene.',
      ),
      "Couldn't download the language pack. Check your internet connection and try again.",
    );
    expect(english.text('{0} seçili', [r'$name {1}']), r'$name {1} selected');
    expect(
      english.message(
        'Remote Play yeniden bağlanıyor… 20 sn. Lütfen bekleyin (1/4)',
      ),
      'Reconnecting Remote Play… 20 s. Please wait (1/4)',
    );
  });

  test('Arabic covers every message and retains all placeholders', () {
    expect(arabicMessages.keys.toSet(), englishMessages.keys.toSet());
    final placeholders = RegExp(r'\{\d+\}');
    for (final entry in arabicMessages.entries) {
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      expect(
        placeholders.allMatches(entry.value).map((m) => m[0]).toList()..sort(),
        placeholders.allMatches(entry.key).map((m) => m[0]).toList()..sort(),
        reason: entry.key,
      );
    }
    expect(AppLanguage.resolve(const Locale('ar', 'SA')), const Locale('ar'));
    expect(AppLanguage.resolve(const Locale('ar', 'EG')), const Locale('ar'));
    expect(AppLocalizations.delegate.isSupported(const Locale('ar')), isTrue);
    const arabic = AppLocalizations(Locale('ar'));
    expect(arabic.text('Console Game Translator'), 'Console Game Translator');
    expect(arabic.text('Oyun Çevirmeni'), 'Console Game Translator');
    expect(
      arabic.message('Ghost of Tsushima seçili'),
      'تم تحديد Ghost of Tsushima',
    );
    expect(arabic.text('{0} seçili', [r'$name {1}']), r'تم تحديد $name {1}');
    expect(
      arabic.message(
        'Remote Play yeniden bağlanıyor… 20 sn. Lütfen bekleyin (1/4)',
      ),
      arabic.text(
        'Remote Play yeniden bağlanıyor… {0} sn. Lütfen bekleyin ({1}/4)',
        [20, 1],
      ),
    );
    expect(
      arabic.message('Bad state: Dil paketi indirilemedi.'),
      'تعذّر تنزيل حزمة اللغة.',
    );
    expect(arabic.message('Çeviri başarısız (503)'), 'فشلت الترجمة (503)');
    expect(
      arabic.message('PS5 kaydı başarılı.\nKonsol: Living Room\n'),
      'تم تسجيل PS5 بنجاح.\nجهاز الألعاب: Living Room\n',
    );
  });

  testWidgets('Arabic help, setup and subtitle screens fit with large text', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester, const Locale('ar', 'EG'));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    await tester.pumpAndSettle();
    await _tab(tester, 'الملف الشخصي');
    await _revealProfile(tester, 'الأسئلة الشائعة');
    await tester.tap(find.text('الأسئلة الشائعة'));
    await tester.pumpAndSettle();
    final question = find.text(
      'لم يُعثر على PS5 أو تعذّر الاتصال به. ماذا أفعل؟',
    );
    await tester.tap(question);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('يجب أن يكون الهاتف وPS5 على الشبكة المحلية نفسها'),
      findsOneWidget,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _tab(tester, 'الترجمة');
    expect(find.text('مظهر الترجمة'), findsOneWidget);
    await _tab(tester, 'الرئيسية');
    await tester.ensureVisible(find.text('دليل الإعداد'));
    await tester.tap(find.text('دليل الإعداد'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('1. توصيل الهاتف وPS5 والتلفزيون بالشبكة نفسها'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('1. توصيل الهاتف وPS5 والتلفزيون بالشبكة نفسها'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
