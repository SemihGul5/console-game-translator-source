import 'support/turkish_test_app.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/screens/access_screen.dart';

void main() {
  const channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/access',
  );

  testWidgets(
    'missing production configuration never grants trial access or offers fake prices',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'configuration') return {'configured': false};
        fail('An unconfigured client must not request a trial or a purchase');
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      });
      await tester.pumpWidget(
        const TurkishTestApp(home: AccessScreen(forTranslation: true)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Satın alma hizmeti henüz kullanıma hazır değil.'),
        findsOneWidget,
      );
      expect(find.text('Google ile devam et'), findsNothing);
      expect(find.text('Hesabımı sil'), findsNothing);
      expect(find.text('Ücretsiz denemeyi başlat'), findsNothing);
      expect(find.textContaining('24,99'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
