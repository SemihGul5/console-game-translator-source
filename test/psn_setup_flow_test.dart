import 'support/turkish_test_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/screens/ps5_registration_screen.dart';
import 'package:gametranslate/screens/psn_login_screen.dart';

const _accountChannel = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);
const _eventsChannel = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_events',
);
const _launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');

Finder get _continueButton =>
    find.widgetWithText(ElevatedButton, 'Sonraki adım: PS5 konsolunu bağla');

Future<void> _openLogin(WidgetTester tester) async {
  await tester.pumpWidget(const TurkishTestApp(home: PsnLoginScreen()));
  await tester.pumpAndSettle();
}

Future<void> _openSetupFromMenu(WidgetTester tester) async {
  await tester.pumpWidget(
    TurkishTestApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Ana menü')),
          body: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PsnLoginScreen()),
            ),
            child: const Text('PS5’i kur'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('PS5’i kur'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(_continueButton);
  await tester.tap(_continueButton);
  await tester.pumpAndSettle();
}

Future<void> _submitConsole(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.ensureVisible(fields.first);
  await tester.enterText(fields.first, '192.168.1.50');
  await tester.ensureVisible(fields.last);
  await tester.enterText(fields.last, '12345678');
  await tester.ensureVisible(find.text('PS5 bağlantısını başlat'));
  await tester.tap(find.text('PS5 bağlantısını başlat'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String? clipboardText;
  late Uri? loginUri;
  late List<String> exchangedCodes;
  late bool verifiedAccount;
  late bool registrationFails;

  setUp(() {
    clipboardText = null;
    loginUri = null;
    exchangedCodes = [];
    verifiedAccount = false;
    registrationFails = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_accountChannel, (call) async {
      switch (call.method) {
        case 'getPsnAccountIdState':
          return verifiedAccount;
        case 'exchangePsnCode':
          exchangedCodes.add((call.arguments as Map)['code'] as String);
          verifiedAccount = true;
          return true;
        case 'registerPs5':
          if (registrationFails) {
            throw PlatformException(
              code: 'INVALID_PIN',
              message: 'PIN kodu geçersiz.',
            );
          }
          return <String, Object>{
            'status': 'success',
            'host': (call.arguments as Map)['host'] as String,
            'nickname': 'Salon PS5',
          };
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(_eventsChannel, (_) async => null);
    messenger.setMockMethodCallHandler(_launcherChannel, (call) async {
      if (call.method == 'launch') {
        loginUri = Uri.parse((call.arguments as Map)['url'] as String);
        return true;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return clipboardText == null
            ? null
            : <String, String>{'text': clipboardText!};
      }
      return null;
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      _accountChannel,
      _eventsChannel,
      _launcherChannel,
      SystemChannels.platform,
    ]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  testWidgets('paste and verify advances from account step to console step', (
    tester,
  ) async {
    await _openLogin(tester);
    expect(find.text('1/2'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(_continueButton).onPressed, isNull);
    final initialFieldHeight = tester.getSize(find.byType(TextField)).height;
    expect(initialFieldHeight, lessThan(80));

    await tester.ensureVisible(find.text('PSN ile giriş yap'));
    await tester.tap(find.text('PSN ile giriş yap'));
    await tester.pumpAndSettle();
    final state = loginUri!.queryParameters['state']!;
    clipboardText =
        'https://remoteplay.dl.playstation.net/remoteplay/redirect'
        '?code=test-code&state=$state';
    await tester.ensureVisible(find.text('Yapıştır'));
    await tester.tap(find.text('Yapıştır'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      clipboardText,
    );
    expect(tester.getSize(find.byType(TextField)).height, lessThan(80));
    await tester.ensureVisible(find.text('PSN hesabını doğrula'));
    await tester.tap(find.text('PSN hesabını doğrula'));
    await tester.pumpAndSettle();

    expect(exchangedCodes, ['test-code']);
    expect(find.textContaining('Doğrulama başarılı.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.ensureVisible(_continueButton);
    await tester.tap(_continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(Ps5RegistrationScreen), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('PS5 Bağlantısı'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('empty clipboard keeps the next step disabled', (tester) async {
    await _openLogin(tester);
    await tester.ensureVisible(find.text('Yapıştır'));
    await tester.tap(find.text('Yapıştır'));
    await tester.pumpAndSettle();

    expect(
      find.text('Panoda yapıştırılacak bir bağlantı yok.'),
      findsOneWidget,
    );
    expect(tester.widget<ElevatedButton>(_continueButton).onPressed, isNull);
    expect(exchangedCodes, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'an already verified account can continue without signing in again',
    (tester) async {
      verifiedAccount = true;
      await _openLogin(tester);

      expect(find.textContaining('Doğrulama başarılı.'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(_continueButton).onPressed,
        isNotNull,
      );
      expect(exchangedCodes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'successful pairing shows a dialog and OK returns to the main menu',
    (tester) async {
      verifiedAccount = true;
      await _openSetupFromMenu(tester);
      await _submitConsole(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('PS5 bağlantısı hazır!'), findsOneWidget);
      expect(
        find.textContaining('Salon PS5 başarıyla eşleştirildi.'),
        findsOneWidget,
      );
      expect(find.text('Ana menü'), findsNothing);

      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();

      expect(find.text('Ana menü'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(PsnLoginScreen, skipOffstage: false), findsNothing);
      expect(
        find.byType(Ps5RegistrationScreen, skipOffstage: false),
        findsNothing,
      );
      expect(
        Navigator.of(tester.element(find.text('Ana menü'))).canPop(),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('failed pairing stays on setup without a success dialog', (
    tester,
  ) async {
    verifiedAccount = true;
    registrationFails = true;
    await _openSetupFromMenu(tester);
    await _submitConsole(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Ps5RegistrationScreen), findsOneWidget);
    expect(find.textContaining('PIN kodu geçersiz.'), findsOneWidget);
    expect(find.text('Ana menü'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
