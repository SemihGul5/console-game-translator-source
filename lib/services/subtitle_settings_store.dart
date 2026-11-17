import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/subtitle_settings.dart';

/// Stores only subtitle presentation and normalized video-area settings.
class SubtitleSettingsStore {
  const SubtitleSettingsStore();

  static const defaultTranslationEngine = 'opus';

  static const _channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );

  Future<SubtitleSettings> load() async {
    try {
      final value = await _channel.invokeMapMethod<Object?, Object?>(
        'getSubtitleSettings',
      );
      return SubtitleSettings.fromMap(value);
    } on MissingPluginException {
      return const SubtitleSettings();
    } on PlatformException {
      return const SubtitleSettings();
    }
  }

  Future<void> save(SubtitleSettings settings) async {
    try {
      await _channel.invokeMethod<void>(
        'saveSubtitleSettings',
        settings.toMap(),
      );
    } on MissingPluginException {
      // Keep the settings usable in unsupported desktop previews.
    }
  }

  Future<List<SubtitleProfile>> loadProfiles() async {
    try {
      final raw = await _channel.invokeMethod<String>('getSubtitleProfiles');
      final values = raw == null ? const <Object?>[] : jsonDecode(raw) as List;
      return values.whereType<Map>().map(SubtitleProfile.fromMap).toList();
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  Future<void> saveProfiles(List<SubtitleProfile> profiles) async {
    try {
      await _channel.invokeMethod<void>(
        'saveSubtitleProfiles',
        profiles.map((profile) => profile.toMap()).toList(),
      );
    } on MissingPluginException {
      // Profiles are available only in the Android app.
    }
  }

  Future<List<TranslationLanguageModel>> loadTranslationLanguages() async {
    final values = await _channel.invokeListMethod<Object?>(
      'getTranslationLanguageModels',
    );
    return (values ?? const <Object?>[])
        .whereType<Map>()
        .map(TranslationLanguageModel.fromMap)
        .toList();
  }

  Future<void> downloadTranslationLanguage(String code) async {
    await _channel.invokeMethod<void>('downloadTranslationLanguage', code);
  }

  Future<String> loadTranslationEngine() async =>
      await _channel.invokeMethod<String>('getTranslationEngine') ??
      defaultTranslationEngine;

  Future<bool> isOpusModelInstalled() async =>
      await _channel.invokeMethod<bool>('getOpusModelStatus') ?? false;

  Future<bool> isHpltModelInstalled() async =>
      await _channel.invokeMethod<bool>('getHpltModelStatus') ?? false;

  Future<List<Map<String, dynamic>>> loadOfflineTranslationModels() async {
    final values = await _channel.invokeMethod<List<dynamic>>(
      'getOfflineTranslationModels',
    );
    return (values ?? const <dynamic>[])
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
  }

  Future<List<Map<String, dynamic>>> selectOfflineTranslationTarget(
    String target,
  ) async {
    final values = await _channel.invokeMethod<List<dynamic>>(
      'selectOfflineTranslationTarget',
      target,
    );
    return (values ?? const <dynamic>[])
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
  }

  Future<void> selectTranslationEngine(String engine) =>
      _channel.invokeMethod<void>('setTranslationEngine', engine);

  Future<bool> hasDeepLApiKey() async {
    final settings = await _channel.invokeMapMethod<String, dynamic>(
      'getDeepLSettings',
    );
    return settings?['hasKey'] == true;
  }

  Future<bool> hasGeminiApiKey() async {
    final settings = await loadGeminiSettings();
    return settings?['hasKey'] == true;
  }

  /// Returns only count and opaque identifiers; saved credentials never cross to Flutter.
  Future<Map<String, dynamic>?> loadGeminiSettings() =>
      _channel.invokeMapMethod<String, dynamic>('getGeminiSettings');

  Future<Map<String, dynamic>?> removeGeminiApiKey(String id) =>
      _channel.invokeMapMethod<String, dynamic>('removeGeminiApiKey', id);

  Future<void> saveGeminiApiKey(String key) =>
      _channel.invokeMethod<void>('saveGeminiApiKey', key.trim());

  Future<void> testGeminiConnection() =>
      _channel.invokeMethod<void>('testGeminiConnection');

  Future<void> clearGeminiApiKey() =>
      _channel.invokeMethod<void>('clearGeminiApiKey');

  /// Local runtime state only; this never contacts Google's API.
  Future<Map<String, dynamic>?> loadGeminiRuntimeStatus() =>
      _channel.invokeMapMethod<String, dynamic>('getGeminiRuntimeStatus');

  Future<void> saveDeepLApiKey(String key) =>
      _channel.invokeMethod<void>('saveDeepLApiKey', key.trim());

  Future<void> testDeepLConnection() =>
      _channel.invokeMethod<void>('testDeepLConnection');

  Future<Map<String, dynamic>?> loadDeepLUsage() =>
      _channel.invokeMapMethod<String, dynamic>('getDeepLUsage');

  Future<void> clearDeepLApiKey() =>
      _channel.invokeMethod<void>('clearDeepLApiKey');

  Future<Map<String, List<TranslationLanguageModel>>>
  loadDeepLLanguages() async {
    final values = await _channel.invokeMapMethod<String, dynamic>(
      'getDeepLTranslationLanguages',
    );
    return {
      for (final type in ['source', 'target'])
        type: (values?[type] as List? ?? const [])
            .whereType<Map>()
            .map(TranslationLanguageModel.fromMap)
            .toList(),
    };
  }

  Future<void> downloadOpusModel(String target) =>
      _channel.invokeMethod<void>('downloadOpusModel', target);

  Future<void> downloadHpltModel() =>
      _channel.invokeMethod<void>('downloadHpltModel');

  Future<Uint8List?> loadSnapshot(String? snapshotId) async {
    if (snapshotId == null || snapshotId.isEmpty) return null;
    try {
      return await _channel.invokeMethod<Uint8List>(
        'getSubtitleSnapshot',
        snapshotId,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<Map<String, Object?>?> captureSnapshot() async {
    try {
      final value = await _channel.invokeMapMethod<Object?, Object?>(
        'captureSubtitleSnapshot',
      );
      if (value == null) return null;
      return {
        'id': value['id']?.toString(),
        'image': value['image'] as Uint8List?,
      };
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

class TranslationLanguageModel {
  const TranslationLanguageModel({
    required this.code,
    required this.name,
    required this.downloaded,
    this.englishName = '',
    this.nativeName = '',
  });

  final String code;
  final String name;
  final String englishName;
  final String nativeName;
  final bool downloaded;

  factory TranslationLanguageModel.fromMap(Map value) =>
      TranslationLanguageModel(
        code: value['code']?.toString() ?? '',
        name: value['name']?.toString() ?? value['code']?.toString() ?? '',
        englishName: value['englishName']?.toString() ?? '',
        nativeName: value['nativeName']?.toString() ?? '',
        downloaded: value['downloaded'] == true,
      );
}

class SubtitleProfile {
  const SubtitleProfile({
    required this.name,
    required this.settings,
    this.snapshotId,
    this.isDefault = false,
  });

  final String name;
  final SubtitleSettings settings;
  final String? snapshotId;
  final bool isDefault;

  factory SubtitleProfile.fromMap(Map value) => SubtitleProfile(
    name: value['name']?.toString() ?? 'Oyun',
    settings: SubtitleSettings.fromMap(value['settings']),
    snapshotId: value['snapshotId']?.toString(),
    isDefault: value['isDefault'] == true,
  );

  Map<String, Object?> toMap() => {
    'name': name,
    'settings': settings.toMap(),
    if (snapshotId != null) 'snapshotId': snapshotId,
    'isDefault': isDefault,
  };
}
