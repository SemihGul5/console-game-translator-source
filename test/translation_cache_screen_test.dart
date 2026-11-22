import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/screens/profile_tab.dart';
import 'package:gametranslate/screens/translation_cache_screen.dart';

import 'support/turkish_test_app.dart';

const _channel = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);

void main() {
  late Map<String, dynamic> policy;
  late List<MethodCall> calls;
  late Map<String, int> counts;
  late bool running;
  late bool cancelPicker;
  late bool rejectImport;
  late bool rejectSave;
  late bool noEmail;
  late int contributionCount;

  Map<String, dynamic> status() => {
    'policy': policy,
    'translationRunning': running,
    'providers': [
      for (final entry in counts.entries)
        {
          'provider': entry.key,
          'count': entry.value,
          'bytes': entry.value == 0 ? 0 : 1048576,
        },
    ],
  };

  setUp(() {
    policy = {'maxEntries': 50000, 'days': 90, 'maxMiB': 32};
    calls = [];
    counts = {'deepl': 12, 'gemini': 20};
    running = false;
    cancelPicker = false;
    rejectImport = false;
    rejectSave = false;
    noEmail = false;
    contributionCount = 15;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'getTranslationCacheStatus':
              return status();
            case 'saveTranslationCachePolicy':
              if (rejectSave) {
                throw PlatformException(
                  code: 'CACHE_TRANSLATING',
                  message: 'Önbelleği değiştirmeden önce çeviriyi durdur.',
                );
              }
              policy = Map<String, dynamic>.from(call.arguments as Map);
              return status();
            case 'resetTranslationCachePolicy':
              policy = {'maxEntries': 50000, 'days': 90, 'maxMiB': 32};
              return status();
            case 'clearTranslationCache':
              counts[call.arguments as String] = 0;
              return status();
            case 'exportTranslationCache':
              return {'cancelled': cancelPicker};
            case 'previewTranslationCacheImport':
              if (rejectImport) {
                throw PlatformException(
                  code: 'CACHE_OPERATION',
                  message:
                      'Önbellek işlemi tamamlanamadı. Dosyayı ve kullanılabilir alanı kontrol et.',
                );
              }
              return cancelPicker
                  ? {'cancelled': true}
                  : {
                      'cancelled': false,
                      'token': 'opaque-stage',
                      'valid': 7,
                      'expired': 2,
                      'duplicates': 3,
                    };
            case 'commitTranslationCacheImport':
              counts['gemini'] = 27;
              return status();
            case 'cancelTranslationCacheImport':
              return true;
            case 'prepareTranslationCacheContribution':
              return {
                'token': 'contribution-token',
                'count': contributionCount,
                'bytes': 10240,
                'recipient': 'abrebostudio@gmail.com',
              };
            case 'openTranslationCacheContributionDraft':
              if (noEmail) {
                throw PlatformException(
                  code: 'CACHE_NO_EMAIL',
                  message:
                      'E-posta uygulaması bulunamadı. Önbelleği dışarı aktararak abrebostudio@gmail.com adresine gönderebilirsin.',
                );
              }
              return {'opened': true};
            case 'discardTranslationCacheContribution':
              return true;
            default:
              return null;
          }
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null),
  );

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      const TurkishTestApp(home: TranslationCacheScreen()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    if (finder.evaluate().isEmpty) {
      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: scrollable,
        maxScrolls: 40,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await reveal(tester, key);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opening settings reads only local counts and shows per-provider usage',
    (tester) async {
      await open(tester);
      expect(find.text('12 çeviri • 1.00 MiB'), findsOneWidget);
      expect(find.text('20 çeviri • 1.00 MiB'), findsOneWidget);
      expect(calls.map((call) => call.method), ['getTranslationCacheStatus']);
      await reveal(tester, 'cache-export');
      expect(
        find.textContaining('API anahtarlarını ve hesap bilgilerini içermez'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'policy can be changed, loaded again and reset without clearing cache',
    (tester) async {
      await open(tester);
      await tap(tester, 'cache-days-90');
      await tester.tap(find.text('180 gün').last);
      await tester.pumpAndSettle();
      await tap(tester, 'cache-save');
      expect(policy['days'], 180);
      expect(calls.last.arguments, {
        'maxEntries': 50000,
        'days': 180,
        'maxMiB': 32,
      });
      expect(counts, {'deepl': 12, 'gemini': 20});
      await tester.pumpWidget(const SizedBox());
      await open(tester);
      expect(find.byKey(const ValueKey('cache-days-180')), findsOneWidget);
      await tap(tester, 'cache-reset');
      expect(policy['days'], 90);
      expect(counts, {'deepl': 12, 'gemini': 20});
      expect(
        calls.where((call) => call.method == 'clearTranslationCache'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'import is previewed before confirmation and cancellation never commits',
    (tester) async {
      await open(tester);
      await tap(tester, 'cache-import');
      expect(find.textContaining('Geçerli kayıt: 7'), findsOneWidget);
      expect(
        find.textContaining('Süresi dolmuş veya ileri tarihli: 2'),
        findsOneWidget,
      );
      expect(
        calls.where((call) => call.method == 'commitTranslationCacheImport'),
        isEmpty,
      );
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(counts['gemini'], 20);
      expect(calls.last.method, 'cancelTranslationCacheImport');
      await tap(tester, 'cache-import');
      await tap(tester, 'cache-confirm-import');
      expect(counts['gemini'], 27);
      expect(
        calls
            .singleWhere(
              (call) => call.method == 'commitTranslationCacheImport',
            )
            .arguments,
        'opaque-stage',
      );
      await reveal(tester, 'cache-message');
      expect(find.text('Önbellek içeri alındı.'), findsOneWidget);
    },
  );

  testWidgets(
    'invalid imports and cancelled pickers preserve all existing data',
    (tester) async {
      await open(tester);
      rejectImport = true;
      await tap(tester, 'cache-import');
      await reveal(tester, 'cache-message');
      expect(
        find.textContaining('Dosyayı ve kullanılabilir alanı kontrol et.'),
        findsOneWidget,
      );
      rejectImport = false;
      cancelPicker = true;
      await tap(tester, 'cache-import');
      await tap(tester, 'cache-export');
      expect(find.text('Önbellek dosyası kaydedildi.'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(counts, {'deepl': 12, 'gemini': 20});
      expect(
        calls.where((call) => call.method == 'commitTranslationCacheImport'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'clearing requires confirmation and affects only the selected provider',
    (tester) async {
      await open(tester);
      await tap(tester, 'cache-clear-gemini');
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(
        calls.where((call) => call.method == 'clearTranslationCache'),
        isEmpty,
      );
      await tap(tester, 'cache-clear-gemini');
      await tester.tap(find.text('Temizle'));
      await tester.pumpAndSettle();
      expect(counts, {'deepl': 12, 'gemini': 0});
      expect(
        calls
            .singleWhere((call) => call.method == 'clearTranslationCache')
            .arguments,
        'gemini',
      );
    },
  );

  testWidgets('while translating only inspection and export remain available', (
    tester,
  ) async {
    running = true;
    await open(tester);
    expect(
      find.text('Önbelleği değiştirmeden önce çeviriyi durdur.'),
      findsOneWidget,
    );
    await reveal(tester, 'cache-save');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('cache-save')))
          .onPressed,
      isNull,
    );
    await reveal(tester, 'cache-import');
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('cache-import')))
          .onPressed,
      isNull,
    );
    await reveal(tester, 'cache-clear-deepl');
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('cache-clear-deepl')))
          .onPressed,
      isNull,
    );
    await tap(tester, 'cache-export');
    expect(calls.last.method, 'exportTranslationCache');
    await reveal(tester, 'cache-message');
    expect(find.text('Önbellek dosyası kaydedildi.'), findsOneWidget);
  });

  testWidgets(
    'native refusal after translation starts is displayed without clearing entries',
    (tester) async {
      await open(tester);
      rejectSave = true;
      await tap(tester, 'cache-save');
      await reveal(tester, 'cache-message');
      expect(
        find.text('Önbelleği değiştirmeden önce çeviriyi durdur.'),
        findsOneWidget,
      );
      expect(counts, {'deepl': 12, 'gemini': 20});
    },
  );

  testWidgets(
    'cache management is reachable from the profile tab',
    (tester) async {
      await tester.pumpWidget(
        TurkishTestApp(
          home: Scaffold(
            body: ProfileTab(
              onOpenSubscription: () {},
              setupCompleted: false,
              onOpenSetup: () {},
              onOpenFaq: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Çeviri önbelleği'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Çeviri önbelleği'));
      await tester.pumpAndSettle();
      expect(find.byType(TranslationCacheScreen), findsOneWidget);
      expect(find.text('12 çeviri • 1.00 MiB'), findsOneWidget);
    },
  );

  testWidgets(
    'developer contribution is optional and opens a draft only after confirmation',
    (tester) async {
      await open(tester);
      expect(
        calls.where((call) => call.method.contains('Contribution')),
        isEmpty,
      );
      await tap(tester, 'cache-contribute');
      expect(
        find.textContaining(
          'API anahtarların ve uygulama hesabı bilgilerin eklenmez',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('uygulamayı geliştirmek için kullanılır'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Alıcı: abrebostudio@gmail.com'),
        findsOneWidget,
      );
      expect(
        calls.where(
          (call) => call.method == 'openTranslationCacheContributionDraft',
        ),
        isEmpty,
      );
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(calls.last.method, 'discardTranslationCacheContribution');
      expect(
        calls.where(
          (call) => call.method == 'openTranslationCacheContributionDraft',
        ),
        isEmpty,
      );
      await tap(tester, 'cache-contribute');
      await tap(tester, 'cache-confirm-contribution');
      final args =
          calls
                  .singleWhere(
                    (call) =>
                        call.method == 'openTranslationCacheContributionDraft',
                  )
                  .arguments
              as Map;
      expect(args['token'], 'contribution-token');
      expect(args['body'], contains('isteğe bağlı olarak paylaşıyorum'));
      expect(args.keys.toSet(), {'token', 'subject', 'body', 'chooserTitle'});
      await reveal(tester, 'cache-message');
      expect(
        find.text('Gönderimi e-posta uygulamasından tamamlayabilirsin.'),
        findsOneWidget,
      );
      expect(counts, {'deepl': 12, 'gemini': 20});
    },
  );

  testWidgets(
    'empty contributions and unavailable email apps preserve the cache',
    (tester) async {
      await open(tester);
      contributionCount = 0;
      await tap(tester, 'cache-contribute');
      await reveal(tester, 'cache-message');
      expect(find.text('Paylaşılacak çeviri kaydı yok.'), findsOneWidget);
      expect(
        calls.where(
          (call) => call.method == 'openTranslationCacheContributionDraft',
        ),
        isEmpty,
      );
      contributionCount = 15;
      noEmail = true;
      await tap(tester, 'cache-contribute');
      await tap(tester, 'cache-confirm-contribution');
      await reveal(tester, 'cache-message');
      expect(
        find.textContaining('E-posta uygulaması bulunamadı.'),
        findsOneWidget,
      );
      expect(calls.last.method, 'discardTranslationCacheContribution');
      expect(counts, {'deepl': 12, 'gemini': 20});
    },
  );

  testWidgets(
    'contribution confirmation fits a narrow screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      await tap(tester, 'cache-contribute');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'controls and import summary fit a narrow screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      await tap(tester, 'cache-import');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
