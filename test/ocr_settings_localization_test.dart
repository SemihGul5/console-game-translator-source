import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/l10n/app_language.dart';
import 'package:gametranslate/l10n/app_localizations.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/screens/ps5_stream_screen.dart';

void main() {
  const native = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );
  const events = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_events',
  );
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(events, (_) async => null);
    messenger.setMockMethodCallHandler(
      native,
      (call) async => switch (call.method) {
        'getSubtitleSettings' => const SubtitleSettings().toMap(),
        'getSessionState' => {'active': false},
        _ => null,
      },
    );
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(native, null);
    messenger.setMockMethodCallHandler(events, null);
  });

  for (final config in [
    (language: 'th', width: 390.0, scale: 1.0),
    (language: 'th', width: 320.0, scale: 1.6),
    (language: 'hu', width: 320.0, scale: 1.6),
    (language: 'ar', width: 320.0, scale: 1.6),
    (language: 'en', width: 320.0, scale: 1.6),
    (language: 'tr', width: 320.0, scale: 1.6),
  ]) {
    testWidgets(
      '${config.language} OCR 1 fits ${config.width} at text scale ${config.scale}',
      (tester) async {
        tester.view.physicalSize = Size(config.width, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = config.scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final locale = Locale(config.language);
        final text = AppLocalizations(locale);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: AppLanguage.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: const Ps5StreamScreen(openSubtitleSettingsOnStart: true),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(text.text('OCR alanı')).first);
        await tester.tap(find.text(text.text('OCR alanı')).first);
        await tester.pumpAndSettle();
        expect(find.text('OCR 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (config.language == 'th') {
          Future<void> selectOption(String key, String label) async {
            final dropdown = find.byKey(ValueKey(key));
            await Scrollable.ensureVisible(
              tester.element(dropdown),
              alignment: 0.5,
            );
            await tester.pumpAndSettle();
            await tester.tap(dropdown);
            await tester.pumpAndSettle();
            final option = find.text(text.text(label)).last;
            await tester.ensureVisible(option);
            await tester.tap(option);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          await selectOption(
            'ocr-preprocessing-0-0',
            'Yerel kontrast (ışık/parlama)',
          );
          expect(
            find.byKey(const ValueKey('ocr-preprocessing-0-4')),
            findsOneWidget,
          );
          await selectOption('ocr-scale-0-1.0', '2× · küçük yazı');
          expect(find.byKey(const ValueKey('ocr-scale-0-2.0')), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
