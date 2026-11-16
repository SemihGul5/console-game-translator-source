import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/widgets/gemini_settings_panel.dart';

import 'support/turkish_test_app.dart';

const _native = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);
const _launcher = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  late List<MethodCall> calls;
  late List<Uri> launched;
  late bool hasKey;
  late bool reject;
  late Map<String, dynamic> runtime;
  late List<Map<String, String>> savedKeys;
  var nextId = 0;

  Map<String, dynamic> metadata() => {
    'hasKey': savedKeys.isNotEmpty,
    'keys': [
      for (var i = 0; i < savedKeys.length; i++)
        {'id': savedKeys[i]['id'], 'index': i + 1},
    ],
    'keyCount': savedKeys.length,
  };

  setUp(() {
    calls = [];
    launched = [];
    hasKey = false;
    reject = false;
    savedKeys = [];
    nextId = 0;
    runtime = {'state': 'idle', 'remainingMs': 0};
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_native, (call) async {
      if (call.method == 'getGeminiRuntimeStatus') return runtime;
      if (call.method == 'getGeminiSettings') return metadata();
      calls.add(call);
      if (reject) {
        throw PlatformException(
          code: 'GEMINI_AUTH',
          message:
              'Gemini API anahtarı kabul edilmedi. Anahtarı ve proje erişimini kontrol et.',
        );
      }
      if (call.method == 'saveGeminiApiKey') {
        if (savedKeys.any((key) => key['value'] == call.arguments)) {
          throw PlatformException(
            code: 'GEMINI_KEY_DUPLICATE',
            message: 'Bu Gemini anahtarı zaten kayıtlı.',
          );
        }
        savedKeys.add({
          'id': 'opaque-${++nextId}',
          'value': call.arguments as String,
        });
      }
      if (call.method == 'removeGeminiApiKey') {
        savedKeys.removeWhere((key) => key['id'] == call.arguments);
        return metadata();
      }
      if (call.method == 'clearGeminiApiKey') savedKeys.clear();
      return true;
    });
    messenger.setMockMethodCallHandler(_launcher, (call) async {
      if (call.method == 'launch') {
        launched.add(Uri.parse((call.arguments as Map)['url'] as String));
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [_native, _launcher]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      TurkishTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, update) => GeminiSettingsPanel(
                hasKey: hasKey,
                onChanged: (value) => update(() => hasKey = value),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a provider cooldown is visible and expires without extra translation requests',
    (tester) async {
      runtime = {
        'state': 'waiting',
        'remainingMs': 60000,
        'code': 'GEMINI_RATE_LIMIT',
      };
      await open(tester);
      expect(find.textContaining('60 sn sonra'), findsOneWidget);
      expect(calls, isEmpty);
      runtime = {
        'state': 'waiting',
        'remainingMs': 19000,
        'code': 'GEMINI_RATE_LIMIT',
      };
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.textContaining('19 sn sonra'), findsOneWidget);
      runtime = {'state': 'idle', 'remainingMs': 0};
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byKey(const ValueKey('gemini-runtime-notice')), findsNothing);
      expect(calls, isEmpty);
    },
  );

  for (final entry in {
    'opus': 'Model A ile yerel çeviri kullanılıyor.',
    'mlkit': 'Model B ile yerel çeviri kullanılıyor.',
    'unavailable': 'Bu dil çifti için yerel paket yüklü değil.',
    'failed': 'Yerel paket açılamadı.',
  }.entries) {
    testWidgets(
      'cooldown explains local fallback ${entry.key} without API calls',
      (tester) async {
        runtime = {
          'state': 'waiting',
          'remainingMs': 19000,
          'code': 'GEMINI_RATE_LIMIT',
          'fallback': entry.key,
        };
        await open(tester);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(find.textContaining('19 sn sonra'), findsOneWidget);
        if (entry.key == 'unavailable' || entry.key == 'failed') {
          expect(
            find.textContaining('Önbellekteki çeviriler kullanılabilir.'),
            findsOneWidget,
          );
        }
        runtime = {'state': 'idle', 'remainingMs': 0, 'fallback': 'idle'};
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('gemini-runtime-notice')),
          findsNothing,
        );
        expect(calls, isEmpty);
      },
    );
  }

  testWidgets(
    'a daily quota is shown as paused without claiming a timed automatic retry',
    (tester) async {
      runtime = {
        'state': 'paused',
        'remainingMs': 0,
        'code': 'GEMINI_QUOTA',
        'message':
            'Gemini günlük kotası doldu. Google AI Studio kullanım ekranını kontrol et.',
      };
      await open(tester);
      expect(find.textContaining('Gemini günlük kotası doldu'), findsOneWidget);
      expect(find.textContaining('sn sonra'), findsNothing);
      expect(calls, isEmpty);
    },
  );

  testWidgets(
    'Gemini settings remain readable on a narrow screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('gemini-save-key')));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'opening settings spends no request and explains free-tier limits and text sharing',
    (tester) async {
      await open(tester);
      expect(calls, isEmpty);
      expect(find.text('Gemini 3.5 Flash-Lite'), findsOneWidget);
      expect(
        find.textContaining('faturalandırmayı etkinleştirme'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Google ürünlerini geliştirmek'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Bağlantı testi kısa bir çeviri isteği'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'keys remain masked and only an explicit save tests the connection once',
    (tester) async {
      await open(tester);
      final save = find.byKey(const ValueKey('gemini-save-key'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(hasKey, isFalse);
      await tester.enterText(find.byType(TextField), ' private-gemini-key ');
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(calls.single.method, 'saveGeminiApiKey');
      expect(calls.single.arguments, 'private-gemini-key');
      expect(hasKey, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'a rejected key is not marked saved and a saved key can be tested and deleted',
    (tester) async {
      await open(tester);
      reject = true;
      await tester.enterText(find.byType(TextField), 'bad-key');
      final save = find.byKey(const ValueKey('gemini-save-key'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(hasKey, isFalse);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'bad-key',
      );
      reject = false;
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(hasKey, isTrue);
      calls.clear();
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(calls.single.method, 'testGeminiConnection');
      expect(calls.single.arguments, isNull);
      await tester.ensureVisible(find.text('Anahtarı sil'));
      await tester.tap(find.text('Anahtarı sil'));
      await tester.pumpAndSettle();
      expect(calls.last.method, 'clearGeminiApiKey');
      expect(hasKey, isFalse);
    },
  );

  testWidgets(
    'multiple keys are appended, stay private and can be removed independently',
    (tester) async {
      await open(tester);
      final save = find.byKey(const ValueKey('gemini-save-key'));
      for (final key in ['first-secret', 'second-secret']) {
        await tester.enterText(find.byType(TextField), key);
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
      }
      expect(savedKeys.length, 2);
      expect(find.text('Anahtar 1'), findsOneWidget);
      expect(find.text('Anahtar 2'), findsOneWidget);
      expect(find.textContaining('first-secret'), findsNothing);
      expect(find.textContaining('second-secret'), findsNothing);
      expect(
        calls.where((call) => call.method == 'saveGeminiApiKey').length,
        2,
      );
      runtime = {'state': 'idle', 'activeKeyIndex': 2};
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Kullanılıyor'), findsOneWidget);
      final removeFirst = find.byKey(const ValueKey('gemini-remove-opaque-1'));
      await tester.ensureVisible(removeFirst);
      await tester.tap(removeFirst);
      await tester.pumpAndSettle();
      expect(savedKeys.single['value'], 'second-secret');
      expect(hasKey, isTrue);
      final removeLast = find.byKey(const ValueKey('gemini-remove-opaque-2'));
      await tester.ensureVisible(removeLast);
      await tester.tap(removeLast);
      await tester.pumpAndSettle();
      expect(savedKeys, isEmpty);
      expect(hasKey, isFalse);
      expect(
        calls
            .where((call) => call.method == 'removeGeminiApiKey')
            .map((call) => call.arguments),
        ['opaque-1', 'opaque-2'],
      );
      expect(
        calls.where((call) => call.method == 'testGeminiConnection'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'a rejected extra key preserves the saved key and explains shared project quota',
    (tester) async {
      await open(tester);
      final save = find.byKey(const ValueKey('gemini-save-key'));
      await tester.enterText(find.byType(TextField), 'first-secret');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      reject = true;
      await tester.enterText(find.byType(TextField), 'bad-extra-secret');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(hasKey, isTrue);
      expect(savedKeys.single['value'], 'first-secret');
      expect(find.text('Anahtar 1'), findsOneWidget);
      expect(
        find.textContaining('Anahtar eklemek proje kotasını artırmaz'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'bad-extra-secret',
      );
    },
  );

  testWidgets('key creation and usage buttons open the official Google pages', (
    tester,
  ) async {
    await open(tester);
    for (final key in ['gemini-free-api-link', 'gemini-usage-link']) {
      final button = find.byKey(ValueKey(key));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }
    expect(
      launched.map((url) => url.host),
      everyElement('aistudio.google.com'),
    );
    expect(launched[0].path, '/apikey');
    expect(launched[1].path, '/rate-limit');
    expect(calls, isEmpty);
  });
}
