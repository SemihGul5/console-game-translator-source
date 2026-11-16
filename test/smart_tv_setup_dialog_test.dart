import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/l10n/app_localizations.dart';
import 'package:gametranslate/services/tv_output_service.dart';
import 'package:gametranslate/widgets/smart_tv_setup_dialog.dart';

Future<void> open(
  WidgetTester tester,
  TvOutputKind kind, {
  bool english = false,
}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(english ? 'en' : 'tr'),
      supportedLocales: const [Locale('en'), Locale('tr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => SmartTvSetupDialog(kind: kind),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'LG option explains limitations and cannot accept before the physical sample test',
    (tester) async {
      await open(tester, TvOutputKind.lg);
      expect(find.text('LG webOS • Beta'), findsOneWidget);
      expect(find.text('Beta TV desteği'), findsOneWidget);
      expect(find.textContaining('hataları yaşanabilir'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'TV’de örnek yazıyı gördüm'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), '8.8.8.8');
      await tester.ensureVisible(find.text('Bağlan ve örnek yazı gönder'));
      await tester.tap(find.text('Bağlan ve örnek yazı gönder'));
      await tester.pumpAndSettle();
      expect(find.textContaining('LG bağlantısı kurulamadı.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Samsung option requires a separate receiver and does not claim connected on open',
    (tester) async {
      await open(tester, TvOutputKind.samsung, english: true);
      expect(find.text('Samsung Tizen • Beta'), findsOneWidget);
      expect(find.text('Beta TV support'), findsOneWidget);
      expect(find.textContaining('errors may occur'), findsOneWidget);
      expect(find.text('Download the TV app'), findsOneWidget);
      expect(find.text('Get TV connection support'), findsOneWidget);
      expect(find.textContaining('Experimental'), findsNothing);
      expect(
        find.textContaining('Open our “Console Game Translator TV” app'),
        findsOneWidget,
      );
      expect(find.textContaining('README'), findsNothing);
      expect(find.textContaining('receiver.zip'), findsNothing);
      await tester.ensureVisible(find.text('TV app not installed yet?'));
      await tester.tap(find.text('TV app not installed yet?'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Windows setup assistant on our website'),
        findsOneWidget,
      );
      expect(find.textContaining('unencrypted LAN'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Use connection'),
            )
            .onPressed,
        isNull,
      );
      expect(TvOutputService.instance.isConnected, isFalse);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );
}
