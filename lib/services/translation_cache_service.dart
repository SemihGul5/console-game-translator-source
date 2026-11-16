import 'package:flutter/services.dart';

class TranslationCachePolicy {
  const TranslationCachePolicy({
    this.maxEntries = 50000,
    this.days = 90,
    this.maxMiB = 32,
  });

  factory TranslationCachePolicy.fromMap(Map value) => TranslationCachePolicy(
    maxEntries: (value['maxEntries'] as num).toInt(),
    days: (value['days'] as num).toInt(),
    maxMiB: (value['maxMiB'] as num).toInt(),
  );

  final int maxEntries;
  final int days;
  final int maxMiB;

  Map<String, int> toMap() => {
    'maxEntries': maxEntries,
    'days': days,
    'maxMiB': maxMiB,
  };
}

/// Only policy, counts and opaque import tokens cross this channel; never keys or subtitles.
class TranslationCacheService {
  const TranslationCacheService();
  static const _channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );

  Future<Map<String, dynamic>> _map(String method, [Object? arguments]) async =>
      await _channel.invokeMapMethod<String, dynamic>(method, arguments) ?? {};

  Future<Map<String, dynamic>> status() => _map('getTranslationCacheStatus');
  Future<Map<String, dynamic>> save(TranslationCachePolicy policy) =>
      _map('saveTranslationCachePolicy', policy.toMap());
  Future<Map<String, dynamic>> reset() => _map('resetTranslationCachePolicy');
  Future<Map<String, dynamic>> clear(String provider) =>
      _map('clearTranslationCache', provider);
  Future<Map<String, dynamic>> export() => _map('exportTranslationCache');
  Future<Map<String, dynamic>> previewImport() =>
      _map('previewTranslationCacheImport');
  Future<Map<String, dynamic>> commitImport(String token) =>
      _map('commitTranslationCacheImport', token);
  Future<void> cancelImport() =>
      _channel.invokeMethod<void>('cancelTranslationCacheImport');

  Future<Map<String, dynamic>> prepareContribution() =>
      _map('prepareTranslationCacheContribution');
  Future<Map<String, dynamic>> openContributionDraft({
    required String token,
    required String subject,
    required String body,
    required String chooserTitle,
  }) => _map('openTranslationCacheContributionDraft', {
    'token': token,
    'subject': subject,
    'body': body,
    'chooserTitle': chooserTitle,
  });
  Future<void> discardContribution(String token) =>
      _channel.invokeMethod<void>('discardTranslationCacheContribution', token);
}
