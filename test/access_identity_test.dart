import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart'
    as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/services/access_service.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'support/purchases_customer_info.dart';

class _Auth extends auth.FirebaseAuthPlatform {
  auth.UserPlatform? account;
  String nextUid = 'review-uid';

  @override
  auth.FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  auth.FirebaseAuthPlatform setInitialValues({
    auth.InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  auth.UserPlatform? get currentUser => account;

  @override
  Future<auth.UserCredentialPlatform> signInWithCredential(
    auth.AuthCredential credential,
  ) async {
    account = _User(this, nextUid);
    return _Credential(auth: this, user: account!);
  }

  @override
  Future<void> signOut() async => account = null;
}

class _MultiFactor extends auth.MultiFactorPlatform {
  _MultiFactor(super.auth);
}

class _User extends auth.UserPlatform {
  _User(_Auth owner, String uid)
    : super(
        owner,
        _MultiFactor(owner),
        auth.InternalUserDetails(
          userInfo: auth.InternalUserInfo(
            uid: uid,
            email: '$uid@example.com',
            isAnonymous: false,
            isEmailVerified: true,
          ),
          providerData: [
            {'uid': 'google-$uid', 'providerId': 'google.com'},
          ],
        ),
      );
}

class _Credential extends auth.UserCredentialPlatform {
  _Credential({required super.auth, required super.user});
}

class _Google extends google.GoogleSignInPlatform {
  @override
  Future<void> init(google.InitParameters params) async {}

  @override
  Future<google.AuthenticationResults> authenticate(
    google.AuthenticateParameters params,
  ) async => const google.AuthenticationResults(
    user: google.GoogleSignInUserData(
      email: 'review@example.com',
      id: 'google-review',
    ),
    authenticationTokens: google.AuthenticationTokenData(idToken: 'token'),
  );

  @override
  Future<void> signOut(google.SignOutParams params) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const access = MethodChannel('com.abrebostudio.consolegametranslator/access');
  const purchases = MethodChannel('purchases_flutter');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final firebase = _Auth();
  final service = AccessService.instance;
  var sdkConfigured = false;
  var customerId = r'$RCAnonymousID:initial';
  final events = <String>[];
  final grants = <String>{};
  Map<String, dynamic> nativeStatus = {'state': 'inactive'};
  Completer<void>? loginGate;
  Completer<Map<String, dynamic>>? prepareGate;
  Completer<Map<String, dynamic>>? purchaseGate;
  PlatformException? loginError;
  PlatformException? logoutError;
  late Completer<void> loginStarted;
  late Completer<void> prepareStarted;
  late Completer<void> purchaseStarted;

  Future<void> initialize() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await service.initialize();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  setUpAll(() async {
    setupFirebaseCoreMocks();
    auth.FirebaseAuthPlatform.instance = firebase;
    google.GoogleSignInPlatform.instance = _Google();
    await Firebase.initializeApp();
  });

  setUp(() async {
    loginGate = null;
    prepareGate = null;
    purchaseGate = null;
    loginError = null;
    logoutError = null;
    loginStarted = Completer<void>();
    prepareStarted = Completer<void>();
    purchaseStarted = Completer<void>();
    messenger.setMockMethodCallHandler(access, (call) async {
      events.add('native.${call.method}');
      switch (call.method) {
        case 'configuration':
          return {
            'configured': true,
            'revenueCatKey': 'goog_test',
            'premiumEntitlementIds': ['console_game_translator_premium'],
          };
        case 'clear':
          nativeStatus = {'state': 'inactive'};
          return true;
        case 'prepare':
          events.add('prepare:$customerId');
          if (!prepareStarted.isCompleted) prepareStarted.complete();
          if (prepareGate != null) return prepareGate!.future;
          nativeStatus = {
            'state': grants.contains(customerId) ? 'lifetime' : 'available',
            'source': grants.contains(customerId) ? 'store' : 'free_trial',
            'freeTrialMinutes': 60,
          };
          return nativeStatus;
        case 'status':
          return nativeStatus;
        case 'startTrial':
          fail('Sign-in and setup must not create a trial deadline');
        default:
          fail('Unexpected native call: ${call.method}');
      }
    });
    messenger.setMockMethodCallHandler(purchases, (call) async {
      events.add('sdk.${call.method}');
      switch (call.method) {
        case 'isConfigured':
          return sdkConfigured;
        case 'setupPurchases':
          sdkConfigured = true;
          customerId = call.arguments['appUserId'] as String? ?? customerId;
          return null;
        case 'getAppUserID':
          return customerId;
        case 'isAnonymous':
          return customerId.startsWith(r'$RCAnonymousID:');
        case 'logIn':
          final uid = call.arguments['appUserID'] as String;
          events.add('login:$uid');
          if (!loginStarted.isCompleted) loginStarted.complete();
          if (loginGate != null) await loginGate!.future;
          if (loginError != null) throw loginError!;
          // Model RevenueCat's documented first-login alias of a guest purchase.
          if (customerId.startsWith(r'$RCAnonymousID:') &&
              grants.contains(customerId)) {
            grants.add(uid);
          }
          customerId = uid;
          return {
            'created': true,
            'customerInfo': purchasesCustomerInfo(
              userId: uid,
              premium: grants.contains(uid),
            ),
          };
        case 'logOut':
          if (logoutError != null) throw logoutError!;
          customerId = r'$RCAnonymousID:after-logout';
          return purchasesCustomerInfo(userId: customerId);
        case 'purchasePackage':
          if (purchaseGate == null) fail('Unexpected purchase');
          purchaseStarted.complete();
          return purchaseGate!.future;
        default:
          fail('Identity sync must not purchase or restore: ${call.method}');
      }
    });
    await service.signOut();
    firebase.account = null;
    firebase.nextUid = 'review-uid';
    customerId = r'$RCAnonymousID:clean-install';
    nativeStatus = {'state': 'inactive'};
    grants.clear();
    events.clear();
  });

  tearDown(() async {
    loginError = null;
    logoutError = null;
    await service.signOut();
  });

  tearDownAll(() {
    messenger.setMockMethodCallHandler(access, null);
    messenger.setMockMethodCallHandler(purchases, null);
  });

  test(
    'startup configures RevenueCat with the persisted Firebase UID',
    () async {
      firebase.account = _User(firebase, 'restored-uid');
      await initialize();
      expect(customerId, 'restored-uid');
      expect(events, contains('sdk.setupPurchases'));
      expect(events, isNot(contains('sdk.logIn')));
      await service.refresh(force: true);
      expect(events, contains('prepare:restored-uid'));
    },
  );

  test(
    'Google sign-in identifies the customer before reading access',
    () async {
      await initialize();
      await service.signIn();
      await service.refresh(force: true);
      expect(service.user?.uid, 'review-uid');
      expect(customerId, 'review-uid');
      expect(
        events.indexOf('native.clear'),
        lessThan(events.indexOf('login:review-uid')),
      );
      expect(
        events.indexOf('login:review-uid'),
        lessThan(events.indexOf('prepare:review-uid')),
      );
      expect(service.status.premium, isFalse);
    },
  );

  test(
    'a dashboard grant is found on a clean install without a trial',
    () async {
      await initialize();
      grants.add('review-uid');
      await service.signIn();
      await service.prepareTranslation();
      expect(service.status.state, 'lifetime');
      expect(events, isNot(contains('native.startTrial')));
      expect(events, isNot(contains('sdk.restorePurchases')));
      expect(events, isNot(contains('sdk.purchasePackage')));
    },
  );

  test('manual refresh sees a grant made after the first login', () async {
    await initialize();
    await service.signIn();
    await service.refresh(force: true);
    expect(service.status.premium, isFalse);
    grants.add('review-uid');
    await service.refresh(force: true);
    expect(service.status.premium, isTrue);
  });

  test(
    'a verified account can prepare translation without starting its trial clock',
    () async {
      await initialize();
      await service.signIn();
      await service.prepareTranslation();
      expect(service.status.canStart, isFalse);
      expect(service.status.canPrepareTranslation, isTrue);
      expect(service.status.expiresAt, isNull);
      expect(service.status.trialRemaining, Duration.zero);
      expect(service.status.source, 'free_trial');
      expect(events.where((event) => event == 'native.startTrial'), isEmpty);
      expect(customerId, 'review-uid');
    },
  );

  test(
    'an anonymous store customer can use Premium without Google sign-in',
    () async {
      await initialize();
      grants.add(customerId);
      await service.refresh(force: true);
      expect(service.user, isNull);
      expect(service.status.premium, isTrue);
      expect(customerId, startsWith(r'$RCAnonymousID:'));
      expect(events, isNot(contains('sdk.logIn')));
      expect(events, isNot(contains('native.startTrial')));
    },
  );

  test(
    'first sign-in preserves an existing guest purchase through SDK aliasing',
    () async {
      await initialize();
      grants.add(customerId);
      await service.refresh(force: true);
      expect(service.status.premium, isTrue);
      events.clear();
      await service.signIn();
      await service.refresh(force: true);
      expect(customerId, 'review-uid');
      expect(service.status.premium, isTrue);
      expect(events, contains('login:review-uid'));
      expect(events, isNot(contains('sdk.logOut')));
      expect(events, isNot(contains('sdk.restorePurchases')));
    },
  );

  test(
    'signing out and selecting another account clears previous Premium',
    () async {
      await initialize();
      grants.add('review-uid');
      await service.signIn();
      await service.refresh(force: true);
      expect(service.status.premium, isTrue);
      await service.signOut();
      expect(service.status.canStart, isFalse);
      expect(customerId, startsWith(r'$RCAnonymousID:'));
      firebase.nextUid = 'different-uid';
      await service.signIn();
      await service.refresh(force: true);
      expect(customerId, 'different-uid');
      expect(service.status.premium, isFalse);
      expect(events, contains('sdk.logOut'));
    },
  );

  test('a RevenueCat login error cannot leave old Premium active', () async {
    await initialize();
    service.status = const AccessStatus('lifetime');
    loginError = PlatformException(code: '10', message: 'Offline');
    await expectLater(service.signIn(), throwsA(isA<PlatformException>()));
    expect(service.status.canStart, isFalse);
    expect(events, isNot(contains('native.prepare')));
    loginError = null;
    await service.refresh(force: true);
    expect(customerId, 'review-uid');
    expect(service.status.premium, isFalse);
  });

  test('concurrent access requests share one account login', () async {
    await initialize();
    firebase.account = _User(firebase, 'review-uid');
    loginGate = Completer<void>();
    final first = service.refresh(force: true);
    await loginStarted.future;
    final second = service.refresh();
    loginGate!.complete();
    await Future.wait([first, second]);
    expect(events.where((event) => event == 'login:review-uid'), hasLength(1));
    expect(customerId, 'review-uid');
  });

  test(
    'an access response arriving after logout cannot reactivate Premium',
    () async {
      await initialize();
      await service.signIn();
      prepareGate = Completer<Map<String, dynamic>>();
      final pending = service.refresh(force: true);
      final rejected = expectLater(
        pending,
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'ACCESS_CHANGED',
          ),
        ),
      );
      await prepareStarted.future;
      await service.signOut();
      prepareGate!.complete({'state': 'lifetime'});
      await rejected;
      expect(service.status.state, 'signed_out');
      expect(service.status.canStart, isFalse);
    },
  );

  test(
    'failed SDK logout still clears Google and blocks old access until retry',
    () async {
      await initialize();
      grants.add('review-uid');
      await service.signIn();
      await service.refresh(force: true);
      logoutError = PlatformException(code: '10', message: 'Offline');
      await expectLater(service.signOut(), throwsA(isA<PlatformException>()));
      expect(service.user, isNull);
      expect(service.status.canStart, isFalse);
      logoutError = null;
      await service.refresh(force: true);
      expect(customerId, startsWith(r'$RCAnonymousID:'));
      expect(service.status.premium, isFalse);
    },
  );

  test(
    'logout waits for a pending SDK login and then removes its identity',
    () async {
      await initialize();
      loginGate = Completer<void>();
      final login = service.signIn();
      final rejected = expectLater(login, throwsA(isA<PlatformException>()));
      await loginStarted.future;
      final logout = service.signOut();
      loginGate!.complete();
      await Future.wait([rejected, logout]);
      expect(service.user, isNull);
      expect(customerId, startsWith(r'$RCAnonymousID:'));
      expect(service.status.canStart, isFalse);
    },
  );

  test(
    'an old already-owned response cannot restore into another session',
    () async {
      await initialize();
      await service.signIn();
      purchaseGate = Completer<Map<String, dynamic>>();
      const package = Package(
        r'$rc_lifetime',
        PackageType.lifetime,
        StoreProduct('lifetime', '', 'Premium', 1, '1.00', 'USD'),
        PresentedOfferingContext('default', null, null),
      );
      final purchase = service.purchase(package);
      final rejected = expectLater(
        purchase,
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'ACCESS_CHANGED',
          ),
        ),
      );
      await purchaseStarted.future;
      await service.signOut();
      purchaseGate!.completeError(
        PlatformException(
          code: PurchasesErrorCode.productAlreadyPurchasedError.index
              .toString(),
        ),
      );
      await rejected;
      expect(events, isNot(contains('sdk.restorePurchases')));
      expect(service.status.canStart, isFalse);
    },
  );
}
