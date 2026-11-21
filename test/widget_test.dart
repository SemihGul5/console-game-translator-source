// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/services.dart';
import 'support/offline_game_catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gametranslate/main.dart';

void main() {
  testWidgets('Home shows the setup and PS5 actions', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    const channel = MethodChannel(
      'com.abrebostudio.consolegametranslator/ps5_registration',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => null,
    );
    await tester.runAsync(() => offlineGameCatalog.loadCatalog());
    await tester.pumpWidget(GameTranslateApp(gameCatalog: offlineGameCatalog));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(find.text('PlayStation 5'), findsOneWidget);
    expect(find.text('PS5’i kur'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('opus-0')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('opus-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('mlkit-0')), findsNothing);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });
}
