import 'package:flutter/material.dart';
import 'support/offline_game_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/main.dart';

void main() {
  testWidgets('app name and supplied artwork follow system language changes', (
    tester,
  ) async {
    const channel = MethodChannel(
      'com.abrebostudio.consolegametranslator/ps5_registration',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.runAsync(() => offlineGameCatalog.loadCatalog());

    tester.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    await tester.pumpWidget(GameTranslateApp(gameCatalog: offlineGameCatalog));
    expect(find.text('AnlaOyna'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/branding/app_icon_tr.png')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    for (final locale in const [
      Locale('tr', 'CY'),
      Locale('en', 'US'),
      Locale('de', 'DE'),
      Locale('az', 'AZ'),
      Locale('tr', 'TR'),
    ]) {
      tester.platformDispatcher.localesTestValue = [locale];
      await tester.pumpAndSettle();
      final turkish = locale.languageCode == 'tr';
      expect(
        find.text(
          turkish ? 'AnlaOyna' : 'Console Game Translator',
        ),
        findsOneWidget,
      );
      expect(
        find.image(
          AssetImage('assets/branding/app_icon_${turkish ? 'tr' : 'all'}.png'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          turkish ? 'Console Game Translator' : 'AnlaOyna',
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
