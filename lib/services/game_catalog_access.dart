import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// App attestation protects only the catalog API. Existing Firebase products'
/// enforcement settings and Google sign-in requirements are left unchanged.
class GameCatalogAccess {
  static Future<void>? _initializing;

  static Future<void> _initialize() async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    String? debugToken;
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      try {
        debugToken = await const MethodChannel(
          'com.abrebostudio.consolegametranslator/ps5_registration',
        ).invokeMethod<String>('getGameCatalogAppCheckDebugToken');
      } on PlatformException {
        // Standard debug-provider registration remains available on old builds.
      } on MissingPluginException {
        // Desktop and unit-test hosts don't expose the Android debug setting.
      }
    }
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(debugToken: debugToken)
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }

  static Future<String> token() async {
    try {
      await (_initializing ??= _initialize());
    } catch (_) {
      _initializing = null;
      rethrow;
    }
    final token = await FirebaseAppCheck.instance.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Oyun erişimi doğrulanamadı.');
    }
    return token;
  }
}
