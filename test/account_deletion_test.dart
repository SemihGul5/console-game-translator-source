import 'support/turkish_test_app.dart';
import 'support/purchases_customer_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart'
    as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/screens/access_screen.dart';
import 'package:gametranslate/screens/profile_tab.dart';
import 'package:gametranslate/services/access_service.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google;

class _AuthPlatform extends auth.FirebaseAuthPlatform {
  final events = <String>[];
  auth.UserPlatform? signedInUser;

  @override
  auth.FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  auth.FirebaseAuthPlatform setInitialValues({
    auth.InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  auth.UserPlatform? get currentUser => signedInUser;

  @override
  set currentUser(auth.UserPlatform? value) => signedInUser = value;

  @override
  Future<void> signOut() async {
    events.add('firebase.signOut');
    signedInUser = null;
  }
}

class _MultiFactor extends auth.MultiFactorPlatform {
  _MultiFactor(super.auth);
}

class _Credential extends auth.UserCredentialPlatform {
  _Credential({required super.auth, required super.user});
}

class _User extends auth.UserPlatform {
  _User(this.owner)
    : super(
        owner,
        _MultiFactor(owner),
        auth.InternalUserDetails(
          userInfo: auth.InternalUserInfo(
            uid: 'app-user',
            email: 'player@example.com',
            displayName: 'Oyuncu',
            isAnonymous: false,
            isEmailVerified: true,
          ),
          providerData: [
            {
              'uid': 'google-user',
              'providerId': 'google.com',
              'email': 'player@example.com',
              'isAnonymous': false,
              'isEmailVerified': true,
            },
          ],
        ),
      );

  final _AuthPlatform owner;
  final deleteErrors = <FirebaseAuthException>[];
  int deleteAttempts = 0;
  int reauthentications = 0;

  @override
  Future<void> delete() async {
    owner.events.add('user.delete');
    deleteAttempts++;
    if (deleteErrors.isNotEmpty) throw deleteErrors.removeAt(0);
    owner.signedInUser = null;
  }

  @override
  Future<auth.UserCredentialPlatform> reauthenticateWithCredential(
    auth.AuthCredential credential,
  ) async {
    owner.events.add('user.reauthenticate');
    expect(credential.providerId, 'google.com');
    reauthentications++;
    return _Credential(auth: owner, user: this);
  }
}

class _GooglePlatform extends google.GoogleSignInPlatform {
  _GooglePlatform(this.events);
  final List<String> events;
  String accountId = 'google-user';
  google.GoogleSignInException? authenticationError;
  Object? signOutError;

  @override
  Future<void> init(google.InitParameters params) async {}

  @override
  Future<google.AuthenticationResults> authenticate(
    google.AuthenticateParameters params,
  ) async {
    events.add('google.authenticate');
    if (authenticationError != null) throw authenticationError!;
    return google.AuthenticationResults(
      user: google.GoogleSignInUserData(
        email: 'player@example.com',
        id: accountId,
      ),
      authenticationTokens: const google.AuthenticationTokenData(
        idToken: 'google-token',
      ),
    );
  }

  @override
  Future<void> signOut(google.SignOutParams params) async {
    events.add('google.signOut');
    if (signOutError != null) throw signOutError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const accessChannel = MethodChannel(
    'com.abrebostudio.consolegametranslator/access',
  );
  const purchasesChannel = MethodChannel('purchases_flutter');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final firebase = _AuthPlatform();
  final googleSignIn = _GooglePlatform(firebase.events);
  final service = AccessService.instance;
  late _User account;
  late bool clearFails;
  var revenueCatAnonymous = false;

  setUpAll(() {
    setupFirebaseCoreMocks();
    auth.FirebaseAuthPlatform.instance = firebase;
    google.GoogleSignInPlatform.instance = googleSignIn;
  });

  setUp(() async {
    firebase.events.clear();
    account = _User(firebase);
    firebase.signedInUser = account;
    googleSignIn.accountId = 'google-user';
    googleSignIn.authenticationError = null;
    googleSignIn.signOutError = null;
    clearFails = false;
    revenueCatAnonymous = false;
    service.status = const AccessStatus('inactive');
    service.packages = const [];
    messenger.setMockMethodCallHandler(accessChannel, (call) async {
      switch (call.method) {
        case 'configuration':
          return {'configured': true, 'revenueCatKey': 'goog_test'};
        case 'prepare':
        case 'status':
          return {'state': 'inactive'};
        case 'clear':
          firebase.events.add('native.clear');
          if (clearFails) throw PlatformException(code: 'CLEAR_FAILED');
          return true;
        default:
          fail('Unexpected access request: ${call.method}');
      }
    });
    messenger.setMockMethodCallHandler(purchasesChannel, (call) async {
      if (call.method == 'isConfigured') return true;
      if (call.method == 'getAppUserID') return 'app-user';
      if (call.method == 'isAnonymous') return revenueCatAnonymous;
      if (call.method == 'logOut') {
        firebase.events.add('purchases.logOut');
        revenueCatAnonymous = true;
        return purchasesCustomerInfo();
      }
      if (call.method == 'getOfferings') {
        return {'all': <String, dynamic>{}, 'current': null};
      }
      fail('Deleting an account must not purchase or restore: ${call.method}');
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await service.initialize();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  tearDownAll(() {
    messenger.setMockMethodCallHandler(accessChannel, null);
    messenger.setMockMethodCallHandler(purchasesChannel, null);
  });

  test(
    'recently signed-in account deletes and signs out without opening Google accounts',
    () async {
      await service.deleteAccount();
      expect(firebase.events, [
        'user.delete',
        'native.clear',
        'firebase.signOut',
        'google.signOut',
        'purchases.logOut',
      ]);
      expect(service.user, isNull);
      expect(service.status.state, 'signed_out');
      expect(account.deleteAttempts, 1);
    },
  );

  test(
    'only a recent-login requirement opens Google and then retries the original deletion',
    () async {
      account.deleteErrors.add(
        FirebaseAuthException(code: 'requires-recent-login'),
      );
      await service.deleteAccount();
      expect(firebase.events, [
        'user.delete',
        'google.authenticate',
        'user.reauthenticate',
        'user.delete',
        'native.clear',
        'firebase.signOut',
        'google.signOut',
        'purchases.logOut',
      ]);
      expect(account.deleteAttempts, 2);
      expect(account.reauthentications, 1);
      expect(service.user, isNull);
    },
  );

  test(
    'selecting a different Google account never deletes or signs out the current user',
    () async {
      account.deleteErrors.add(
        FirebaseAuthException(code: 'requires-recent-login'),
      );
      googleSignIn.accountId = 'another-google-user';
      await expectLater(
        service.deleteAccount(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'user-mismatch',
          ),
        ),
      );
      expect(account.deleteAttempts, 1);
      expect(account.reauthentications, 0);
      expect(service.user?.uid, 'app-user');
      expect(firebase.events, isNot(contains('native.clear')));
      expect(
        AccessService.errorMessage(
          FirebaseAuthException(code: 'user-mismatch'),
        ),
        contains('giriş yaptığın Google hesabını seç'),
      );
    },
  );

  test(
    'canceling required verification leaves the account and session intact',
    () async {
      account.deleteErrors.add(
        FirebaseAuthException(code: 'requires-recent-login'),
      );
      googleSignIn.authenticationError = const google.GoogleSignInException(
        code: google.GoogleSignInExceptionCode.canceled,
      );
      await expectLater(
        service.deleteAccount(),
        throwsA(isA<google.GoogleSignInException>()),
      );
      expect(service.user?.uid, 'app-user');
      expect(account.deleteAttempts, 1);
      expect(firebase.events, isNot(contains('native.clear')));
    },
  );

  test(
    'a deletion network error does not reopen sign-in or clear the signed-in account',
    () async {
      account.deleteErrors.add(
        FirebaseAuthException(code: 'network-request-failed'),
      );
      await expectLater(
        service.deleteAccount(),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(firebase.events, ['user.delete']);
      expect(service.user?.uid, 'app-user');
    },
  );

  test('a signed-out deletion never signs in or creates an account', () async {
    firebase.signedInUser = null;
    await expectLater(service.deleteAccount(), throwsStateError);
    expect(firebase.events, isEmpty);
  });

  test(
    'native cleanup failure still clears Firebase and Google after deletion',
    () async {
      clearFails = true;
      await expectLater(
        service.deleteAccount(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('hesabın silindi'),
          ),
        ),
      );
      expect(firebase.events, [
        'user.delete',
        'native.clear',
        'firebase.signOut',
        'google.signOut',
        'purchases.logOut',
      ]);
      expect(service.user, isNull);
      expect(service.status.state, 'signed_out');
    },
  );

  test(
    'Google cleanup failure reports an already-deleted account accurately',
    () async {
      googleSignIn.signOutError = StateError('Google cleanup failed');
      await expectLater(
        service.deleteAccount(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('hesabın silindi'),
          ),
        ),
      );
      expect(account.deleteAttempts, 1);
      expect(service.user, isNull);
      expect(service.status.state, 'signed_out');
    },
  );

  for (final profile in [true, false]) {
    testWidgets(
      '${profile ? 'profile' : 'premium'} deletion confirms, removes the account and displays success',
      (tester) async {
        await tester.pumpWidget(
          TurkishTestApp(
            home: profile
                ? Scaffold(
                    body: ProfileTab(
                      onOpenSubscription: () {},
                      setupCompleted: false,
                      onOpenSetup: () {},
                      onOpenFaq: () {},
                    ),
                  )
                : const AccessScreen(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Hesabımı sil'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Hesabımı sil'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Uygulamadaki hesabın kalıcı olarak silinir'),
          findsOneWidget,
        );
        expect(account.deleteAttempts, 0);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Hesabımı sil'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Hesabın silindi ve oturumun kapatıldı.'),
          findsOneWidget,
        );
        expect(service.user, isNull);
        expect(find.text('Hesabımı sil'), findsNothing);
        expect(firebase.events, isNot(contains('google.authenticate')));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
