import 'support/turkish_test_app.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'support/offline_game_catalog.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/screens/access_screen.dart';
import 'package:gametranslate/main.dart';
import 'package:gametranslate/services/access_service.dart';
import 'package:gametranslate/widgets/premium_status_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google;
import 'package:purchases_flutter/purchases_flutter.dart';

class _GoogleSignIn extends google.GoogleSignInPlatform {
  @override
  Future<void> init(google.InitParameters params) async {}

  @override
  Future<google.AuthenticationResults> authenticate(
    google.AuthenticateParameters params,
  ) async => throw const GoogleSignInException(
    code: GoogleSignInExceptionCode.canceled,
    description: 'Activity is cancelled by the user.',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _access = MethodChannel('com.abrebostudio.consolegametranslator/access');
const _purchases = MethodChannel('purchases_flutter');
const _ps5 = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);
const _events = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_events',
);
const _previewPath = String.fromEnvironment('SUBSCRIPTION_PREVIEW_PATH');
final _homePreviewKey = GlobalKey();
const _package = Package(
  r'$rc_lifetime',
  PackageType.lifetime,
  StoreProduct('lifetime', '', 'Premium', 999.99, '999,99 TL', 'TRY'),
  PresentedOfferingContext('default', null, null),
);

Map<String, dynamic> _customerInfo({
  String verification = 'VERIFIED',
  String entitlementVerification = 'VERIFIED',
  bool hasEntitlement = true,
}) {
  final entitlement = {
    'identifier': 'console_game_translator_premium',
    'isActive': true,
    'willRenew': true,
    'latestPurchaseDate': '2026-11-04T12:00:00Z',
    'originalPurchaseDate': '2026-11-04T12:00:00Z',
    'productIdentifier': 'consolegametranslator_premium',
    'isSandbox': true,
    'verification': entitlementVerification,
  };
  return {
    'entitlements': {
      'all': {
        if (hasEntitlement) 'console_game_translator_premium': entitlement,
      },
      'active': {
        if (hasEntitlement) 'console_game_translator_premium': entitlement,
      },
      'verification': verification,
    },
    'allPurchaseDates': <String, String>{},
    'activeSubscriptions': ['consolegametranslator_premium:monthly'],
    'allPurchasedProductIdentifiers': ['consolegametranslator_premium'],
    'nonSubscriptionTransactions': <Object>[],
    'firstSeen': '2026-11-01T12:00:00Z',
    'originalAppUserId': 'test-user',
    'allExpirationDates': <String, String>{},
    'requestDate': '2026-11-04T12:00:00Z',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = AccessService.instance;
  late Map<String, dynamic> nativeStatus;
  late List<MethodCall> accessCalls;
  late List<String> purchaseCalls;
  PlatformException? purchaseError;
  String verification = 'VERIFIED';
  String entitlementVerification = 'VERIFIED';
  var activatePurchase = true;
  Map<String, dynamic>? currentOffering;

  setUpAll(() {
    setupFirebaseCoreMocks();
    google.GoogleSignInPlatform.instance = _GoogleSignIn();
    for (final name in [
      'plugins.flutter.io/firebase_auth/auth-state/[DEFAULT]',
      'plugins.flutter.io/firebase_auth/id-token/[DEFAULT]',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
  });

  setUpAll(() async {
    // Optional local visual review only; normal CI remains independent of system fonts.
    if (_previewPath.isNotEmpty && Platform.isWindows) {
      final font = File('C:/Windows/Fonts/segoeui.ttf');
      if (await font.exists()) {
        final data = await font.readAsBytes();
        await ui.loadFontFromList(data, fontFamily: 'Roboto');
        await ui.loadFontFromList(data, fontFamily: 'Ahem');
      }
      final icons = File(
        'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (await icons.exists()) {
        await ui.loadFontFromList(
          await icons.readAsBytes(),
          fontFamily: 'MaterialIcons',
        );
      }
    }
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(_access, null);
    messenger.setMockMethodCallHandler(_purchases, null);
    messenger.setMockMethodCallHandler(_ps5, null);
    messenger.setMockMethodCallHandler(_events, null);
  });

  setUp(() async {
    nativeStatus = {'state': 'signed_out', 'freeTrialMinutes': 60};
    service.status = const AccessStatus('inactive');
    service.packages = const [];
    accessCalls = [];
    purchaseCalls = [];
    purchaseError = null;
    verification = 'VERIFIED';
    entitlementVerification = 'VERIFIED';
    activatePurchase = true;
    currentOffering = null;
    messenger.setMockMethodCallHandler(_events, (_) async => null);
    messenger.setMockMethodCallHandler(_ps5, (call) async {
      return switch (call.method) {
        'getTranslationEngine' => 'mlkit',
        'getSubtitleSettings' => {
          'sourceLanguageCode': 'en',
          'targetLanguageCode': 'tr',
        },
        'getSessionState' => {
          'active': false,
          'connected': false,
          'videoReady': false,
        },
        'isTranslationForegroundRunning' => false,
        'getDeepLSettings' || 'getGeminiSettings' => {'hasKey': false},
        _ => null,
      };
    });
    messenger.setMockMethodCallHandler(_access, (call) async {
      accessCalls.add(call);
      if (call.method == 'configuration') {
        return {
          'configured': true,
          'revenueCatKey': 'goog_test',
          'premiumEntitlementIds': [
            'console_game_translator_premium',
            'premium',
          ],
        };
      }
      if (call.method != 'prepare' && call.method != 'status') {
        throw StateError('Unexpected access call: ${call.method}');
      }
      return nativeStatus;
    });
    messenger.setMockMethodCallHandler(_purchases, (call) async {
      purchaseCalls.add(call.method);
      switch (call.method) {
        case 'isConfigured':
          return true;
        case 'isAnonymous':
          return true;
        case 'getOfferings':
          return {'all': <String, dynamic>{}, 'current': currentOffering};
        case 'purchasePackage':
          if (purchaseError != null) throw purchaseError!;
          if (activatePurchase) nativeStatus = {'state': 'lifetime'};
          return {
            'customerInfo': _customerInfo(
              verification: verification,
              entitlementVerification: entitlementVerification,
              hasEntitlement: activatePurchase,
            ),
            'transaction': {
              'transactionIdentifier': 'test-transaction',
              'productIdentifier': 'lifetime',
              'purchaseDate': '2026-11-04T12:00:00Z',
            },
          };
        case 'restorePurchases':
          if (activatePurchase) nativeStatus = {'state': 'premium'};
          return _customerInfo(
            verification: verification,
            entitlementVerification: entitlementVerification,
            hasEntitlement: activatePurchase,
          );
        default:
          fail('Unexpected purchase SDK call: ${call.method}');
      }
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await service.initialize();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    accessCalls.clear();
    purchaseCalls.clear();
  });

  Future<void> openHome(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => offlineGameCatalog.loadCatalog());
    await service.refresh(force: true);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _homePreviewKey,
        child: GameTranslateApp(gameCatalog: offlineGameCatalog),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a compact subscription card sits immediately above translation and uses the server duration',
    (tester) async {
      await openHome(tester);
      final card = find.byKey(const ValueKey('home-subscription-offer'));
      final start = find.byKey(const ValueKey('translation-start-stop'));
      expect(find.text('Hemen abone olun'), findsOneWidget);
      expect(
        find.text(
          'İsterseniz abone olmadan 60 dakika ücretsiz deneyebilirsiniz.',
        ),
        findsOneWidget,
      );
      expect(tester.getSize(card).height, lessThan(190));
      expect(
        tester.getRect(start).top - tester.getRect(card).bottom,
        inInclusiveRange(0, 16),
      );
      expect(tester.getRect(start).bottom, lessThan(844 - 76));
      if (_previewPath.isNotEmpty) {
        await tester.runAsync(() async {
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(
              image.image,
              tester.element(find.byWidget(image)),
            );
          }
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              _homePreviewKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          final file = File(_previewPath);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
          image.dispose();
        });
      }
      nativeStatus = {'state': 'signed_out', 'freeTrialMinutes': 90};
      await service.refresh(force: true);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'İsterseniz abone olmadan 90 dakika ücretsiz deneyebilirsiniz.',
        ),
        findsOneWidget,
      );
      nativeStatus = {'state': 'premium'};
      await service.refresh(force: true);
      await tester.pumpAndSettle();
      expect(card, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home does not advertise a fresh trial after expiry or while a trial is already active',
    (tester) async {
      nativeStatus = {'state': 'expired', 'freeTrialMinutes': 60};
      await openHome(tester);
      expect(
        find.textContaining('Ücretsiz denemeniz sona erdi.'),
        findsOneWidget,
      );
      expect(find.textContaining('abone olmadan 60'), findsNothing);
      nativeStatus = {
        'state': 'trial',
        'source': 'free_trial',
        'trialRemainingMs': 29 * 60 * 1000,
        'freeTrialMinutes': 60,
      };
      await service.refresh(force: true);
      await tester.pumpAndSettle();
      expect(
        find.text('Ücretsiz denemeniz devam ediyor. Kalan süre: 29:00.'),
        findsOneWidget,
      );
      expect(find.textContaining('abone olmadan 60'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      nativeStatus = {'state': 'signed_out', 'freeTrialMinutes': 60};
      await service.refresh(force: true);
    },
  );

  testWidgets(
    'view plans opens live store prices without starting a trial or purchasing',
    (tester) async {
      currentOffering = {
        'identifier': 'default',
        'serverDescription': 'Premium',
        'metadata': <String, dynamic>{},
        'availablePackages': [
          {
            'identifier': r'$rc_monthly',
            'packageType': 'MONTHLY',
            'presentedOfferingContext': {'offeringIdentifier': 'default'},
            'product': {
              'identifier': 'premium:monthly',
              'description': '',
              'title': 'Premium',
              'price': 49.99,
              'priceString': '₺49,99',
              'currencyCode': 'TRY',
              'subscriptionPeriod': 'P1M',
            },
          },
        ],
      };
      await openHome(tester);
      await tester.tap(find.byKey(const ValueKey('view-premium-plans')));
      await tester.pumpAndSettle();
      expect(find.byType(AccessScreen), findsOneWidget);
      expect(find.textContaining('₺49,99 / ay.'), findsOneWidget);
      expect(accessCalls.any((call) => call.method == 'startTrial'), isFalse);
      expect(purchaseCalls, isNot(contains('purchasePackage')));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'profile displays the connected trial countdown and keeps it after stopping translation',
    (tester) async {
      nativeStatus = {
        'state': 'available',
        'source': 'free_trial',
        'freeTrialMinutes': 60,
      };
      await openHome(tester);
      await tester.tap(find.widgetWithText(NavigationDestination, 'Profil'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ücretsiz denemen hazır. Remote Play bağlantısıyla başlar.'),
        findsOneWidget,
      );
      final deadline = DateTime(2026, 11, 16, 20).millisecondsSinceEpoch;
      nativeStatus = {
        'state': 'trial',
        'source': 'free_trial',
        'freeTrialMinutes': 60,
        'expiresAtMs': deadline,
        'trialRemainingMs': 60 * 60 * 1000,
        'translationAllowed': true,
      };
      await service.readNativeStatus();
      await tester.pumpAndSettle();
      expect(find.text('Kalan deneme: 60:00'), findsOneWidget);
      nativeStatus = {
        ...nativeStatus,
        'trialRemainingMs': 59 * 60 * 1000 + 59000,
      };
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Kalan deneme: 59:59'), findsOneWidget);
      // Disarming closes subtitle delivery, while the existing trial clock continues.
      nativeStatus = {
        ...nativeStatus,
        'translationAllowed': false,
        'trialRemainingMs': 58 * 60 * 1000,
      };
      await service.readNativeStatus();
      await tester.pumpAndSettle();
      expect(find.text('Kalan deneme: 58:00'), findsOneWidget);
      expect(service.status.canStart, isTrue);
      expect(service.status.expiresAt!.millisecondsSinceEpoch, deadline);
      expect(accessCalls.where((call) => call.method == 'startTrial'), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      nativeStatus = {'state': 'signed_out', 'freeTrialMinutes': 60};
      await service.readNativeStatus();
    },
  );

  test(
    'forced refresh reaches the native SDK even inside the cooldown',
    () async {
      await service.refresh(force: true);
      await service.refresh();
      await service.refresh(force: true);
      final prepares = accessCalls.where((call) => call.method == 'prepare');
      expect(prepares, hasLength(2));
      expect(prepares.every((call) => call.arguments['force'] == true), isTrue);
      expect(
        accessCalls.where((call) => call.method == 'status'),
        hasLength(1),
      );
    },
  );

  testWidgets('successful purchase immediately updates the home badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      TurkishTestApp(
        home: Scaffold(
          appBar: AppBar(actions: [PremiumStatusButton(onOpenDetails: () {})]),
        ),
      ),
    );
    expect(find.byTooltip('Premium aktif'), findsNothing);
    await service.purchase(_package);
    await tester.pump();
    expect(find.byTooltip('Premium aktif'), findsOneWidget);
    expect(service.status.state, 'lifetime');
    expect(
      purchaseCalls.where((call) => call == 'purchasePackage'),
      hasLength(1),
    );
    expect(accessCalls.last.arguments, {'force': true});
  });

  test(
    'already-owned purchase restores access without a second purchase',
    () async {
      purchaseError = PlatformException(
        code: PurchasesErrorCode.productAlreadyPurchasedError.index.toString(),
        message: 'This product is already active for the user.',
      );
      await service.purchase(_package);
      expect(service.status.premium, isTrue);
      expect(purchaseCalls.where((call) => call != 'isConfigured'), [
        'purchasePackage',
        'restorePurchases',
      ]);
      expect(accessCalls.last.arguments, {'force': true});
    },
  );

  test('store cancellation does not restore or activate access', () async {
    purchaseError = PlatformException(
      code: PurchasesErrorCode.purchaseCancelledError.index.toString(),
    );
    await expectLater(
      service.purchase(_package),
      throwsA(isA<PlatformException>()),
    );
    expect(purchaseCalls, isNot(contains('restorePurchases')));
    expect(service.status.premium, isFalse);
  });

  test('an unverified purchase never activates access', () async {
    verification = 'FAILED';
    await expectLater(service.purchase(_package), throwsStateError);
    expect(service.status.premium, isFalse);
    expect(accessCalls, isEmpty);
  });

  test(
    'the live entitlement verification is checked on purchase and restore',
    () async {
      entitlementVerification = 'FAILED';
      await expectLater(service.purchase(_package), throwsStateError);
      purchaseError = PlatformException(
        code: PurchasesErrorCode.productAlreadyPurchasedError.index.toString(),
      );
      await expectLater(service.purchase(_package), throwsStateError);
      expect(purchaseCalls, contains('restorePurchases'));
      expect(service.status.premium, isFalse);
      expect(accessCalls, isEmpty);
    },
  );

  test(
    'missing entitlement explains a paid purchase without granting access',
    () async {
      activatePurchase = false;
      await expectLater(
        service.purchase(_package),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Yeniden ödeme yapma'),
          ),
        ),
      );
      expect(service.status.premium, isFalse);
      expect(
        accessCalls.where((call) => call.method == 'prepare'),
        hasLength(3),
      );
    },
  );

  testWidgets(
    'SDK customer updates refresh the home badge inside the cooldown',
    (tester) async {
      await service.refresh(force: true);
      nativeStatus = {'state': 'premium'};
      await messenger.handlePlatformMessage(
        _purchases.name,
        _purchases.codec.encodeMethodCall(
          MethodCall('Purchases-CustomerInfoUpdated', _customerInfo()),
        ),
        (_) {},
      );
      await tester.pump();
      expect(service.status.premium, isTrue);
      expect(
        accessCalls.where((call) => call.method == 'prepare'),
        hasLength(2),
      );
      expect(accessCalls.last.arguments, {'force': false});
    },
  );

  testWidgets('account selection failure is visible on the trial screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TurkishTestApp(home: AccessScreen(forTranslation: true)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Google hesabınızla 60 dakika ücretsiz deneyebilirsiniz.'),
      findsOneWidget,
    );
    expect(
      find.text('Ödeme bilgisi gerekmez. Otomatik abonelik başlamaz.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('start-free-trial')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Google girişi tamamlanmadı'), findsOneWidget);
    expect(service.status.canStart, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the offer follows remote duration changes without a new build', (
    tester,
  ) async {
    nativeStatus = {'state': 'signed_out', 'freeTrialMinutes': 90};
    await tester.pumpWidget(
      const TurkishTestApp(home: AccessScreen(forTranslation: true)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Google hesabınızla 90 dakika ücretsiz deneyebilirsiniz.'),
      findsOneWidget,
    );
    expect(find.text('Google ile ücretsiz dene'), findsOneWidget);
    expect(find.textContaining('60 dk'), findsNothing);
    nativeStatus = {'state': 'signed_out', 'freeTrialMinutes': 15};
    await service.refresh(force: true);
    await tester.pumpAndSettle();
    expect(
      find.text('Google hesabınızla 15 dakika ücretsiz deneyebilirsiniz.'),
      findsOneWidget,
    );
    expect(find.text('Google ile ücretsiz dene'), findsOneWidget);
  });

  testWidgets(
    'an unavailable duration does not advertise sixty minutes or start a trial',
    (tester) async {
      nativeStatus = {'state': 'signed_out'};
      await tester.pumpWidget(
        const TurkishTestApp(home: AccessScreen(forTranslation: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Abone olmadan deneyin'), findsOneWidget);
      expect(find.textContaining('Deneme süresi alınamadı'), findsOneWidget);
      final button = find.byKey(const ValueKey('start-free-trial'));
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(find.textContaining('60 dakika'), findsNothing);
      nativeStatus = {'state': 'signed_out', 'freeTrialMinutes': 120};
      await service.refresh(force: true);
      await tester.pumpAndSettle();
      expect(
        find.text('Google hesabınızla 120 dakika ücretsiz deneyebilirsiniz.'),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    },
  );

  testWidgets('an old trial does not inherit the new campaign duration', (
    tester,
  ) async {
    nativeStatus = {
      'state': 'trial',
      'source': 'free_trial',
      'trialRemainingMs': 29 * 60 * 1000,
      'freeTrialMinutes': 120,
    };
    await tester.pumpWidget(
      const TurkishTestApp(home: AccessScreen(forTranslation: true)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Kalan deneme: 29:00.'), findsOneWidget);
    expect(find.textContaining('120'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    nativeStatus = {'state': 'signed_out', 'freeTrialMinutes': 120};
    await service.refresh(force: true);
  });

  testWidgets(
    'the compact trial offer remains visible without overwhelming the plans screen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const TurkishTestApp(home: AccessScreen(forTranslation: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Premium'), findsOneWidget);
      expect(
        find.text('Google hesabınızla 60 dakika ücretsiz deneyebilirsiniz.'),
        findsOneWidget,
      );
      expect(find.text('Google ile ücretsiz dene'), findsOneWidget);
      final button = find.byKey(const ValueKey('start-free-trial'));
      expect(tester.getSize(button).height, inInclusiveRange(48, 56));
      expect(
        tester.getSize(find.byKey(const ValueKey('free-trial-offer'))).height,
        lessThan(350),
      );
      expect(tester.getRect(button).bottom, lessThan(844));
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final state in ['expired', 'verification_required', 'premium']) {
    testWidgets('does not advertise a fresh free trial for $state access', (
      tester,
    ) async {
      nativeStatus = {'state': state};
      await service.refresh(force: true);
      await tester.pumpWidget(
        const TurkishTestApp(home: AccessScreen(forTranslation: true)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('free-trial-offer')), findsNothing);
      expect(find.byKey(const ValueKey('start-free-trial')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'the compact trial offer remains usable on a narrow screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        const TurkishTestApp(home: AccessScreen(forTranslation: true)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('start-free-trial')),
      );
      expect(find.text('Google ile ücretsiz dene'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final launchFlag in [null, true, false]) {
    testWidgets(
      'launch pricing follows remote offering metadata ($launchFlag) and preserves the store price',
      (tester) async {
        currentOffering = {
          'identifier': 'default',
          'serverDescription': 'Premium',
          'metadata': {'launch_pricing_enabled': ?launchFlag},
          'availablePackages': [
            {
              'identifier': r'$rc_monthly',
              'packageType': 'MONTHLY',
              'presentedOfferingContext': {'offeringIdentifier': 'default'},
              'product': {
                'identifier': 'premium:monthly',
                'description': '',
                'title': 'Premium',
                'price': 49.99,
                'priceString': '₺49,99',
                'currencyCode': 'TRY',
                'subscriptionPeriod': 'P1M',
              },
            },
          ],
        };
        tester.view.physicalSize = const Size(320, 1200);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(const TurkishTestApp(home: AccessScreen()));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('launch-pricing-banner')),
          launchFlag == false ? findsNothing : findsOneWidget,
        );
        expect(find.textContaining('₺49,99 / ay.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (launchFlag != false) {
          currentOffering!['metadata'] = {'launch_pricing_enabled': false};
          await service.loadPackages();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('launch-pricing-banner')),
            findsNothing,
          );
        }
      },
    );
  }

  test(
    'named native errors keep their message and never throw a format error',
    () {
      expect(
        AccessService.errorMessage(
          PlatformException(
            code: 'TRIAL_FAILED',
            message: 'Deneme durumu alınamadı.',
          ),
        ),
        'Deneme durumu alınamadı.',
      );
      expect(
        AccessService.errorMessage(
          PlatformException(
            code: PurchasesErrorCode.productAlreadyPurchasedError.index
                .toString(),
            message: 'This product is already active for the user.',
          ),
        ),
        contains('zaten aktif'),
      );
      expect(
        AccessService.errorMessage(PlatformException(code: '-1')),
        'İşlem tamamlanamadı. Biraz sonra tekrar dene.',
      );
    },
  );
}
