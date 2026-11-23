import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'access_action_guard.dart';

class AccessStatus {
  // Defensive display bound, matching Firestore validation; the actual offer
  // comes from appConfig/freeTrial and is never capped at the old 60 minutes.
  static const maxFreeTrialDuration = Duration(days: 1);
  const AccessStatus(
    this.state, {
    this.expiresAt,
    this.willRenew = false,
    this.source = 'store',
    this.trialRemaining = Duration.zero,
    this.freeTrialMinutes,
  });
  factory AccessStatus.fromMap(Map<String, dynamic> map) => AccessStatus(
    map['state'] as String? ?? 'inactive',
    expiresAt: (map['expiresAtMs'] as num? ?? 0) > 0
        ? DateTime.fromMillisecondsSinceEpoch(
            (map['expiresAtMs'] as num).toInt(),
          )
        : null,
    willRenew: map['willRenew'] == true,
    source: map['source'] as String? ?? 'store',
    freeTrialMinutes: switch (map['freeTrialMinutes']) {
      final int minutes when minutes >= 1 && minutes <= 1440 => minutes,
      _ => null,
    },
    trialRemaining: Duration(
      milliseconds: ((map['trialRemainingMs'] as num?)?.toInt() ?? 0)
          .clamp(0, maxFreeTrialDuration.inMilliseconds)
          .toInt(),
    ),
  );
  final String state;
  final DateTime? expiresAt;
  final bool willRenew;
  final String source;
  final Duration trialRemaining;
  final int? freeTrialMinutes;
  bool get premium =>
      state == 'premium' ||
      state == 'lifetime' ||
      (state == 'trial' && source == 'store');
  bool get canStart =>
      premium ||
      (state == 'trial' &&
          source == 'free_trial' &&
          trialRemaining > Duration.zero);
  bool get canPrepareTranslation =>
      canStart ||
      (state == 'available' &&
          source == 'free_trial' &&
          freeTrialMinutes != null);
  String get remainingLabel {
    final seconds = (trialRemaining.inMilliseconds / 1000).ceil();
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

/// One calendar trial in Firestore; RevenueCat owns store purchases.
class AccessService extends ChangeNotifier {
  AccessService._() {
    actions.addListener(notifyListeners);
  }
  static final instance = AccessService._();
  static const _channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/access',
  );
  Future<void>? _initializing;
  Future<AccessStatus>? _refreshing;
  Future<void>? _syncingIdentity;
  String? _revenueCatUid;
  bool _identitySynced = false;
  bool _signingOut = false;
  int _sessionVersion = 0;
  final actions = AccessActionGuard();
  final _refreshClock = Stopwatch()..start();
  Duration? _lastRefresh;
  bool _initialized = false;
  Timer? _countdown;
  bool _readingStatus = false;
  List<String> _premiumEntitlementIds = const ['premium'];
  bool get configured => _initialized;
  String privacyUrl = '';
  String termsUrl = '';
  AccessStatus status = const AccessStatus('inactive');
  List<Package> packages = const [];
  User? get user => _initialized ? FirebaseAuth.instance.currentUser : null;

  Future<void> initialize() async {
    if (_initialized) return;
    final pending = _initializing;
    if (pending != null) return pending;
    _initializing = _initialize();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw StateError(
        'Satın alma sistemi şu anda Android için kullanılabilir.',
      );
    }
    final config = await _channel.invokeMapMethod<String, dynamic>(
      'configuration',
    );
    if (config?['configured'] != true) {
      throw StateError('Satın alma hizmeti henüz kullanıma hazır değil.');
    }
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    await GoogleSignIn.instance.initialize(
      serverClientId: config!['googleWebClientId'] as String?,
    );
    if (!await Purchases.isConfigured) {
      await Purchases.configure(
        PurchasesConfiguration(config['revenueCatKey'] as String)
          ..appUserID = FirebaseAuth.instance.currentUser?.uid
          ..entitlementVerificationMode =
              EntitlementVerificationMode.informational,
      );
    }
    privacyUrl = config['privacyUrl'] as String? ?? '';
    termsUrl = config['termsUrl'] as String? ?? '';
    _premiumEntitlementIds =
        (config['premiumEntitlementIds'] as List?)?.cast<String>() ??
        const ['premium'];
    await _syncIdentity();
    _initialized = true;
    Purchases.addCustomerInfoUpdateListener(_customerInfoUpdated);
  }

  void _customerInfoUpdated(CustomerInfo _) {
    _lastRefresh = null;
    if (_syncingIdentity != null || _signingOut) return;
    unawaited(_refreshCustomerInfo());
  }

  PlatformException _accountChanged() =>
      PlatformException(code: 'ACCESS_CHANGED', message: 'Hesap değişti.');

  void _clearLocalAccess() {
    _sessionVersion++;
    _lastRefresh = null;
    _countdown?.cancel();
    _countdown = null;
    status = const AccessStatus('inactive');
    packages = const [];
    notifyListeners();
  }

  /// Use the same unguessable account ID on every device. Anonymous purchases
  /// made by older versions may merge through RevenueCat's normal login behavior.
  Future<void> _syncIdentity() async {
    if (_signingOut) throw _accountChanged();
    final pending = _syncingIdentity;
    if (pending != null) {
      await pending;
      return _syncIdentity();
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_identitySynced && _revenueCatUid == uid) return;
    final request = _setRevenueCatIdentity(uid);
    _syncingIdentity = request;
    try {
      await request;
    } finally {
      _syncingIdentity = null;
    }
    if (FirebaseAuth.instance.currentUser?.uid != uid) await _syncIdentity();
  }

  Future<void> _setRevenueCatIdentity(String? uid) async {
    final mustChange = uid == null
        ? !await Purchases.isAnonymous
        : await Purchases.appUserID != uid;
    if (mustChange) {
      _identitySynced = false;
      _clearLocalAccess();
      // Disarm native translation and invalidate requests for the old customer
      // before switching the SDK's shared customer identity.
      await _channel.invokeMethod<void>('clear');
      if (_signingOut || FirebaseAuth.instance.currentUser?.uid != uid) {
        throw _accountChanged();
      }
      if (uid == null) {
        await Purchases.logOut();
      } else {
        await Purchases.logIn(uid);
      }
    }
    if (_signingOut || FirebaseAuth.instance.currentUser?.uid != uid) {
      throw _accountChanged();
    }
    _revenueCatUid = uid;
    _identitySynced = true;
  }

  Future<void> _refreshCustomerInfo() async {
    try {
      await refresh();
    } catch (_) {
      // Background updates are best effort; user actions report failures.
    }
  }

  Future<AccessStatus> refresh({bool force = false}) async {
    await initialize();
    await _syncIdentity();
    final pending = _refreshing;
    if (pending != null) {
      if (!force) return pending;
      try {
        await pending;
      } catch (_) {
        // A purchase or translation check must get its own fresh result.
      }
      return refresh(force: true);
    }
    if (!force &&
        _lastRefresh != null &&
        _refreshClock.elapsed - _lastRefresh! < const Duration(seconds: 30)) {
      await readNativeStatus();
      return status;
    }
    final request = _refresh(force: force);
    _refreshing = request;
    try {
      return await request;
    } finally {
      _refreshing = null;
    }
  }

  Future<AccessStatus> _refresh({required bool force}) async {
    final version = _sessionVersion;
    final map = await _channel.invokeMapMethod<String, dynamic>('prepare', {
      'force': force,
    });
    if (version != _sessionVersion || _signingOut) throw _accountChanged();
    if (map == null) throw StateError('Satın alma durumu alınamadı.');
    _setStatus(map);
    _lastRefresh = _refreshClock.elapsed;
    return status;
  }

  Future<void> refreshManually({bool loadProducts = false}) =>
      actions.run(AccessAction.refresh, () async {
        await refresh(force: true);
        if (loadProducts && !status.premium) await loadPackages();
      });

  Future<void> readNativeStatus() async {
    if (_readingStatus || _signingOut || _syncingIdentity != null) return;
    _readingStatus = true;
    final version = _sessionVersion;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('status');
      if (map == null || version != _sessionVersion) return;
      _setStatus(map);
    } on MissingPluginException {
      // Display only; the native controller still enforces access.
    } on PlatformException {
      // A display refresh never grants access.
    } finally {
      _readingStatus = false;
    }
  }

  void _setStatus(Map<String, dynamic> map) {
    status = AccessStatus.fromMap(map);
    if (status.source == 'free_trial' && status.state == 'trial') {
      _countdown ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(readNativeStatus()),
      );
    } else {
      _countdown?.cancel();
      _countdown = null;
    }
    notifyListeners();
  }

  Future<void> signIn() async {
    await initialize();
    if (user == null) {
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) throw StateError('Google hesabı doğrulanamadı.');
      final credential = GoogleAuthProvider.credential(idToken: token);
      await FirebaseAuth.instance.signInWithCredential(credential);
    }
    await _syncIdentity();
    _lastRefresh = null;
    notifyListeners();
  }

  Future<AccessStatus> prepareTranslation() async {
    await initialize();
    await _syncIdentity();
    // Eligibility only. Native code commits the trial once Remote Play connects,
    // before OCR starts; Google sign-in and setup do not consume trial time.
    final prepared = await refresh(force: true);
    if (prepared.canPrepareTranslation) return prepared;
    throw StateError(
      'Deneme henüz hazır değil. İnternet bağlantını kontrol edip tekrar dene.',
    );
  }

  Future<void> signOut() async {
    _signingOut = true;
    _clearLocalAccess();
    Object? firstError;
    StackTrace? firstStack;
    // Each layer must be cleared even if another layer's cleanup fails.
    for (final cleanup in <Future<void> Function()>[
      () async {
        await _channel.invokeMethod<void>('clear');
      },
      FirebaseAuth.instance.signOut,
      GoogleSignIn.instance.signOut,
      () async {
        final pending = _syncingIdentity;
        if (pending != null) {
          try {
            await pending;
          } catch (_) {
            // Still remove the SDK identity if a login failed or was canceled.
          }
        }
        if (await Purchases.isConfigured && !await Purchases.isAnonymous) {
          await Purchases.logOut();
        }
      },
    ]) {
      try {
        await cleanup();
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }
    _identitySynced = false;
    _revenueCatUid = null;
    _signingOut = false;
    status = const AccessStatus('signed_out');
    notifyListeners();
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }

  Future<void> deleteAccount() async {
    await initialize();
    final account = user;
    if (account == null) {
      throw StateError('Hesabını silmek için önce giriş yap.');
    }
    try {
      await account.delete();
    } on FirebaseAuthException catch (error) {
      if (error.code != 'requires-recent-login') rethrow;
      await _reauthenticateForDeletion(account);
      await account.delete();
    }
    try {
      await signOut();
    } catch (_) {
      throw StateError(
        'Uygulamadaki hesabın silindi. Oturum temizliği tamamlanamadı; uygulamayı kapatıp yeniden aç.',
      );
    }
  }

  Future<void> _reauthenticateForDeletion(User account) async {
    final googleAccount = await GoogleSignIn.instance.authenticate();
    if (user?.uid != account.uid) {
      throw StateError(
        'Oturumun değişti. Hesap silme işlemini yeniden başlat.',
      );
    }
    for (final provider in account.providerData) {
      if (provider.providerId == 'google.com' &&
          provider.uid != null &&
          provider.uid != googleAccount.id) {
        throw FirebaseAuthException(code: 'user-mismatch');
      }
    }
    final token = googleAccount.authentication.idToken;
    if (token == null) {
      throw StateError('Google hesabı doğrulanamadı. Hesabın silinmedi.');
    }
    await account.reauthenticateWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  }

  Future<void> loadPackages() async {
    await initialize();
    await _syncIdentity();
    final offering = (await Purchases.getOfferings()).current;
    const order = [
      PackageType.weekly,
      PackageType.monthly,
      PackageType.annual,
      PackageType.lifetime,
    ];
    packages =
        (offering?.availablePackages ?? [])
            .where((p) => order.contains(p.packageType))
            .toList()
          ..sort(
            (a, b) => order
                .indexOf(a.packageType)
                .compareTo(order.indexOf(b.packageType)),
          );
    notifyListeners();
  }

  Future<void> purchase(Package package) async {
    await initialize();
    await _syncIdentity();
    final version = _sessionVersion;
    // The app's server-configured trial is separate from store billing. Purchase
    // the base plan explicitly instead of automatically selecting a Play trial.
    final basePlans =
        package.storeProduct.subscriptionOptions
            ?.where((option) => option.isBasePlan)
            .toList() ??
        <SubscriptionOption>[];
    final lifetime = package.packageType == PackageType.lifetime;
    if (!lifetime && basePlans.isEmpty) {
      throw StateError(
        'Abonelik planı yüklenemedi. Paketleri yenileyip tekrar dene.',
      );
    }
    final PurchaseResult result;
    try {
      result = await Purchases.purchase(
        lifetime
            ? PurchaseParams.package(package)
            : PurchaseParams.subscriptionOption(basePlans.first),
      );
    } on PlatformException catch (error) {
      if (version != _sessionVersion || _signingOut) throw _accountChanged();
      if (_purchaseErrorCode(error) !=
          PurchasesErrorCode.productAlreadyPurchasedError) {
        rethrow;
      }
      // Play already owns the product. Reconcile that purchase instead of
      // leaving the user on the paywall with a raw SDK error.
      await _restore();
      return;
    }
    if (version != _sessionVersion || _signingOut) throw _accountChanged();
    await _refreshAfterPurchase(result.customerInfo);
  }

  void _verifyCustomerInfo(CustomerInfo info) {
    if (info.entitlements.verification == VerificationResult.failed ||
        _premiumEntitlementIds.any(
          (id) =>
              info.entitlements.active[id]?.verification ==
              VerificationResult.failed,
        )) {
      throw StateError(
        'Satın alma yanıtı doğrulanamadı. Satın alımları geri yüklemeyi dene.',
      );
    }
  }

  Future<void> restore() => actions.run(AccessAction.restore, _restore);

  Future<void> _restore() async {
    await initialize();
    await _syncIdentity();
    final version = _sessionVersion;
    final info = await Purchases.restorePurchases();
    if (version != _sessionVersion || _signingOut) throw _accountChanged();
    await _refreshAfterPurchase(info);
  }

  Future<void> _refreshAfterPurchase(CustomerInfo info) async {
    _verifyCustomerInfo(info);
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) await Future<void>.delayed(Duration(seconds: attempt));
      if ((await refresh(force: true)).premium) return;
    }
    if (info.activeSubscriptions.isNotEmpty ||
        info.nonSubscriptionTransactions.isNotEmpty) {
      throw StateError(
        'Google Play satın alımın bulundu ancak Premium erişimin doğrulanamadı. '
        'Yeniden ödeme yapma. Satın alımları geri yükle veya destekle iletişime geç.',
      );
    }
    throw StateError(
      'Aktif satın alma bulunamadı. Ödeme bekliyorsa tamamlandıktan sonra tekrar dene.',
    );
  }

  static PurchasesErrorCode? _purchaseErrorCode(PlatformException error) {
    // The same channel also returns named native errors (ACCESS_*, TRIAL_*).
    // PurchasesErrorHelper assumes a numeric code and throws for those errors.
    final code = int.tryParse(error.code);
    if (code == null || code < 0 || code >= PurchasesErrorCode.values.length) {
      return null;
    }
    return PurchasesErrorCode.values[code];
  }

  static String errorMessage(Object error) {
    if (error is GoogleSignInException) {
      // Credential Manager can report configuration failures as cancellation
      // after account selection, so this must not silently dismiss the action.
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled =>
          'Google girişi tamamlanmadı. İptal etmediysen tekrar dene; '
              'sorun sürerse destekle iletişime geç.',
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          'Google girişi bu sürümde kullanılamıyor. Destekle iletişime geç.',
        _ => 'Google hesabına giriş yapılamadı. Tekrar dene.',
      };
    }
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'network-request-failed' =>
          'Google hesabı doğrulanamadı. İnternet bağlantını kontrol edip tekrar dene.',
        'user-mismatch' =>
          'Uygulamada giriş yaptığın Google hesabını seçerek tekrar dene.',
        'requires-recent-login' =>
          'Hesabını silmek için yeniden giriş yapıp tekrar dene.',
        _ => 'Google hesabı doğrulanamadı. Tekrar giriş yapmayı dene.',
      };
    }
    if (error is PlatformException) {
      if (error.code.startsWith('ACCESS_') || error.code.startsWith('TRIAL_')) {
        return error.message ?? 'Erişim durumu alınamadı. Tekrar dene.';
      }
      return switch (_purchaseErrorCode(error)) {
        PurchasesErrorCode.purchaseCancelledError => '',
        PurchasesErrorCode.productAlreadyPurchasedError =>
          'Bu satın alım Google Play hesabında zaten aktif. Satın alımları geri yükle.',
        PurchasesErrorCode.paymentPendingError =>
          'Ödemen Google Play onayı bekliyor. Tamamlandığında erişim durumunu yenile.',
        PurchasesErrorCode.networkError ||
        PurchasesErrorCode.offlineConnectionError ||
        PurchasesErrorCode.apiEndpointBlocked =>
          'Satın alma hizmetine bağlanılamadı. İnternet bağlantını kontrol edip tekrar dene.',
        PurchasesErrorCode.receiptAlreadyInUseError ||
        PurchasesErrorCode.receiptInUseByOtherSubscriberError =>
          'Satın alım başka bir hesaba bağlı görünüyor. Satın aldığın Google Play hesabını kontrol et veya destekle iletişime geç.',
        PurchasesErrorCode.purchaseNotAllowedError =>
          'Google Play bu hesapta satın almaya izin vermiyor. Mağaza hesabını kontrol et.',
        PurchasesErrorCode.configurationError ||
        PurchasesErrorCode.invalidCredentialsError =>
          'Satın alma hizmeti şu anda kullanılamıyor. Destekle iletişime geç.',
        PurchasesErrorCode.signatureVerificationFailed =>
          'Satın alma yanıtı doğrulanamadı. Satın alımları geri yüklemeyi dene.',
        _ => 'İşlem tamamlanamadı. Biraz sonra tekrar dene.',
      };
    }
    if (error is StateError) return error.message.toString();
    return 'Hizmete bağlanılamadı. İnternet bağlantını kontrol edip tekrar dene.';
  }
}
