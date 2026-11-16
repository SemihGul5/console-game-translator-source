import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/widgets/deepl_settings_panel.dart';

import 'support/turkish_test_app.dart';

const _channel = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);
const _launcher = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  late List<MethodCall> calls;
  late bool failSaving;
  late bool hasKey;
  late bool failUsage;
  late Map<String, int> usage;
  late List<Uri> launched;

  setUp(() {
    calls = [];
    failSaving = false;
    hasKey = false;
    failUsage = false;
    usage = {'characterCount': 12345, 'characterLimit': 500000};
    launched = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_launcher, (call) async {
          if (call.method == 'launch') {
            launched.add(Uri.parse((call.arguments as Map)['url'] as String));
            return true;
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          if (call.method == 'getDeepLUsage') {
            if (failUsage) throw PlatformException(code: 'DEEPL_NETWORK');
            return usage;
          }
          if (call.method == 'saveDeepLApiKey' && failSaving) {
            throw PlatformException(
              code: 'DEEPL_AUTH',
              message:
                  'DeepL API anahtarı kabul edilmedi. Anahtarını kontrol et.',
            );
          }
          return null;
        });
  });

  tearDown(() {
    for (final channel in [_channel, _launcher]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      TurkishTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => DeepLSettingsPanel(
                hasKey: hasKey,
                onChanged: (value) => setState(() => hasKey = value),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('requires a key, saves a masked key and clears the editor', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Test et ve kaydet'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(find.text('Geçerli bir DeepL API anahtarı gir.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' test-key:fx ');
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
    await tester.tap(find.text('Test et ve kaydet'));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'saveDeepLApiKey');
    expect(calls.single.arguments, 'test-key:fx');
    expect(hasKey, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      find.text('DeepL bağlantısı başarılı. Çeviri için hazır.'),
      findsOneWidget,
    );
  });

  testWidgets('saved key can be tested without exposing it and removed', (
    tester,
  ) async {
    hasKey = true;
    await open(tester);
    await tester.tap(find.text('Test et ve kaydet'));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'testDeepLConnection');
    expect(calls.single.arguments, isNull);
    await tester.tap(find.text('Anahtarı sil'));
    await tester.pumpAndSettle();
    expect(calls.last.method, 'clearDeepLApiKey');
    expect(hasKey, isFalse);
  });

  testWidgets('rejected key stays editable and is not marked saved', (
    tester,
  ) async {
    failSaving = true;
    await open(tester);
    await tester.enterText(find.byType(TextField), 'invalid-key');
    await tester.tap(find.text('Test et ve kaydet'));
    await tester.pumpAndSettle();
    expect(hasKey, isFalse);
    expect(
      find.text('DeepL API anahtarı kabul edilmedi. Anahtarını kontrol et.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'invalid-key',
    );
  });

  testWidgets('key controls fit a narrow phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    hasKey = true;
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Test et ve kaydet'), findsOneWidget);
    expect(find.text('Anahtarı sil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usage is fetched only on demand and shows the account count', (
    tester,
  ) async {
    hasKey = true;
    await open(tester);
    expect(calls, isEmpty);
    await tester.tap(find.text('Kullanımı göster'));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'getDeepLUsage');
    expect(calls.single.arguments, isNull);
    expect(find.text('DeepL hesabı: 12345 / 500000 karakter'), findsOneWidget);
    expect(find.text('Kalan: 487655 karakter (%97,5)'), findsOneWidget);
    expect(
      find.text('DeepL sayacı birkaç dakika gecikmeli güncellenebilir.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Anahtarı sil'));
    await tester.pumpAndSettle();
    expect(find.text('DeepL hesabı: 12345 / 500000 karakter'), findsNothing);
    expect(find.textContaining('Kalan:'), findsNothing);
  });

  testWidgets('usage failure does not invent a zero count', (tester) async {
    hasKey = true;
    failUsage = true;
    await open(tester);
    await tester.tap(find.text('Kullanımı göster'));
    await tester.pumpAndSettle();
    expect(
      find.text('DeepL kullanım bilgisi alınamadı. Tekrar dene.'),
      findsOneWidget,
    );
    expect(find.textContaining('DeepL hesabı:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'free API link opens the official developer page without a saved key',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('deepl-free-api-link')));
      await tester.pumpAndSettle();
      expect(launched, [Uri.parse('https://www.deepl.com/en/developers')]);
      expect(calls, isEmpty);
    },
  );

  for (final quota in [0, 100]) {
    testWidgets(
      'zero or exhausted quota never divides by zero or shows negative remaining ($quota)',
      (tester) async {
        hasKey = true;
        usage = {'characterCount': 120, 'characterLimit': quota};
        await open(tester);
        await tester.tap(find.text('Kullanımı göster'));
        await tester.pumpAndSettle();
        expect(find.text('Kalan: 0 karakter (%0,0)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('unlimited account does not invent a remaining percentage', (
    tester,
  ) async {
    hasKey = true;
    usage = {'characterCount': 120, 'characterLimit': 1000000000000};
    await open(tester);
    await tester.tap(find.text('Kullanımı göster'));
    await tester.pumpAndSettle();
    expect(find.text('Kalan: Limitsiz'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });
}
