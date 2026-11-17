import 'package:flutter/material.dart';
import 'support/offline_game_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/l10n/app_localizations.dart';
import 'package:gametranslate/l10n/messages_en.dart';
import 'package:gametranslate/main.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String savedLanguage;
  late bool keepAwake;
  late List<MethodCall> calls;

  setUp(() {
    savedLanguage = 'system';
    keepAwake = false;
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_events, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_native, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'getTranslationEngine':
              return 'mlkit';
            case 'getAppLanguage':
              return savedLanguage;
            case 'setAppLanguage':
              savedLanguage = call.arguments as String;
              return true;
            case 'getPersonalizationSettings':
              return {'keepScreenAwake': keepAwake};
            case 'savePersonalizationSettings':
              keepAwake = (call.arguments as Map)['keepScreenAwake'] == true;
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
        savedLanguage = code == 'tr' ? 'en' : 'tr';
        await _open(tester, Locale(code));
        final turkish = code == 'tr';
        for (final title
            in turkish
                ? ['Altyazı', 'Ana sayfa', 'Profil', 'Ayarlar']
                : ['Subtitles', 'Home', 'Profile', 'Settings']) {
          expect(
            find.widgetWithText(NavigationDestination, title),
            findsOneWidget,
          );
        }
        expect(
          find.text(turkish ? 'ÇEVİRİYİ BAŞLAT' : 'START TRANSLATION'),
          findsOneWidget,
        );
        await tester.tap(
          find.text(turkish ? 'ÇEVİRİYİ BAŞLAT' : 'START TRANSLATION'),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(turkish ? 'PS5 gerekli' : 'PS5 required'),
          findsOneWidget,
        );
        expect(
          find.text(
            turkish
                ? 'Önce PlayStation 5’i kurup kaydet.'
                : 'Set up and register your PlayStation 5 first.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'system language changes immediately, ignores legacy preference and keeps state',
    (tester) async {
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      savedLanguage = 'en';
      await _open(tester, const Locale('tr'));
      final home = tester.state(find.byType(HomeScreen));
      await _tab(tester, 'Ayarlar');
      expect(find.text('Uygulama dili'), findsNothing);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(keepAwake, isTrue);

      for (final code in ['en', 'de', 'ar', 'tr']) {
        tester.platformDispatcher.localesTestValue = [Locale(code)];
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(
            NavigationDestination,
            code == 'tr' ? 'Ayarlar' : 'Settings',
          ),
          findsOneWidget,
        );
        expect(find.text('Uygulama dili'), findsNothing);
        expect(find.text('App language'), findsNothing);
        expect(tester.state(find.byType(HomeScreen)), same(home));
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isTrue,
        );
      }
      expect(calls.where((c) => c.method == 'saveSubtitleSettings'), isEmpty);
      expect(
        calls.where(
          (c) => c.method == 'getAppLanguage' || c.method == 'setAppLanguage',
        ),
        isEmpty,
      );
      expect(savedLanguage, 'en');
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
    await _tab(tester, 'Settings');
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
    await tester.pageBack();
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
    'English screens fit a small screen with large text without a language picker',
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
      await _tab(tester, 'Settings');
      expect(find.widgetWithText(SettingsEntry, 'App language'), findsNothing);
      expect(find.text('System language'), findsNothing);
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
}
