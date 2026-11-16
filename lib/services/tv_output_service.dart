import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/subtitle_settings.dart';
import 'lg_webos_client.dart';
import 'samsung_tv_session.dart';
import 'tv_subtitle_client.dart';
import 'game_fonts.dart';

export 'tv_subtitle_client.dart' show TvSubtitleConnectionState;

enum TvOutputKind { android, lg, samsung }

/// Routes subtitle output without changing the proven Android TV protocol.
class TvOutputService {
  TvOutputService._() {
    _android.connectionStateChanges.listen((_) => _emit());
    samsung.changes.listen((_) => _emit());
    GameFonts.active.addListener(() {
      final settings = _latestSettings;
      if (settings != null) updateSettings(settings);
    });
  }
  static final instance = TvOutputService._();
  static const _storage = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );
  final _android = TvSubtitleClient.instance;
  final samsung = SamsungTvSession();
  LgWebOsClient? _lg;
  StreamSubscription<void>? _lgSubscription;
  final _states = StreamController<TvSubtitleConnectionState>.broadcast();
  TvOutputKind kind = TvOutputKind.android;
  SubtitleSettings? _latestSettings;

  String get name => switch (kind) {
    TvOutputKind.android => 'Android TV',
    TvOutputKind.lg => 'LG webOS',
    TvOutputKind.samsung => 'Samsung Tizen',
  };
  bool get isConnected => switch (kind) {
    TvOutputKind.android => _android.isConnected,
    TvOutputKind.lg => _lg?.isConnected ?? false,
    TvOutputKind.samsung => samsung.isConnected,
  };
  bool get isConnecting => switch (kind) {
    TvOutputKind.android => _android.isConnecting,
    TvOutputKind.lg => _lg?.isConnecting ?? false,
    TvOutputKind.samsung => false,
  };
  String? get address => switch (kind) {
    TvOutputKind.android => _android.address,
    TvOutputKind.lg => _lg?.host,
    TvOutputKind.samsung => samsung.endpoints.firstOrNull,
  };
  String? get sessionToken => switch (kind) {
    TvOutputKind.android => _android.sessionToken,
    TvOutputKind.lg => _lg?.clientKey,
    TvOutputKind.samsung => null,
  };
  String? get certificateFingerprint => switch (kind) {
    TvOutputKind.android => _android.certificateFingerprint,
    TvOutputKind.lg => _lg?.certificateFingerprint,
    TvOutputKind.samsung => null,
  };
  bool get usesSecureTransport => kind == TvOutputKind.android
      ? _android.usesSecureTransport
      : kind == TvOutputKind.lg && (_lg?.secure ?? false);
  double? get tvDisplayHeightDp =>
      kind == TvOutputKind.android ? _android.tvDisplayHeightDp : 540;
  Stream<TvSubtitleConnectionState> get connectionStateChanges =>
      _states.stream;

  void _emit() => _states.add(
    isConnected
        ? TvSubtitleConnectionState.connected
        : isConnecting
        ? TvSubtitleConnectionState.connecting
        : TvSubtitleConnectionState.disconnected,
  );

  Future<List<String>> discoverReceivers() => _android.discoverReceivers();
  Future<void> restorePairing(
    String address,
    String token, {
    String? certificateFingerprint,
  }) async {
    kind = TvOutputKind.android;
    await _android.restorePairing(
      address,
      token,
      certificateFingerprint: certificateFingerprint,
    );
  }

  Future<void> connect(
    String address,
    String code, {
    Future<bool> Function(String)? verifyCertificate,
  }) async {
    await _android.connect(address, code, verifyCertificate: verifyCertificate);
    await _lg?.disconnect();
    await samsung.stop();
    kind = TvOutputKind.android;
    await _save(null);
    _emit();
  }

  Future<void> activateLg(LgWebOsClient client) async {
    await _save({
      'kind': 'lg',
      'host': client.host,
      'key': client.clientKey,
      'secure': client.secure,
      'fingerprint': client.certificateFingerprint,
    });
    await _android.disconnect();
    await samsung.stop();
    await _lgSubscription?.cancel();
    await _lg?.disconnect();
    _lg = client;
    kind = TvOutputKind.lg;
    _lgSubscription = client.changes.listen((_) => _emit());
    _emit();
  }

  Future<void> startSamsung() async {
    await samsung.start();
    try {
      // Samsung credentials are session-only; opening setup is not a saved pairing.
      await _save(null);
    } catch (_) {
      await samsung.stop();
      rethrow;
    }
    await _android.disconnect();
    await _lg?.disconnect();
    kind = TvOutputKind.samsung;
    _emit();
  }

  Future<bool> restoreSmartPairing() async {
    // Multiple home routes share one output instance during translation.
    if (kind != TvOutputKind.android &&
        (isConnected || isConnecting || samsung.isRunning)) {
      return true;
    }
    try {
      final raw = await _storage.invokeMethod<String>('getSmartTvPairing');
      if (raw == null) return false;
      final record = jsonDecode(raw);
      if (record is! Map) return false;
      if (record['kind'] == 'samsung') {
        // Older builds saved the chosen brand before a receiver had even paired.
        // There are no persistent Samsung credentials to restore.
        kind = TvOutputKind.android;
        await _save(null);
        _emit();
        return false;
      }
      if (record['kind'] != 'lg' ||
          record['host'] is! String ||
          record['key'] is! String ||
          record['secure'] is! bool ||
          (record['secure'] == true && record['fingerprint'] is! String)) {
        return false;
      }
      kind = TvOutputKind.lg;
      final client = LgWebOsClient();
      _lg = client;
      _lgSubscription = client.changes.listen((_) => _emit());
      unawaited(
        client
            .connect(
              record['host'] as String,
              savedKey: record['key'] as String,
              encrypted: record['secure'] as bool,
              fingerprint: record['fingerprint'] as String?,
            )
            .catchError((Object _) {}),
      );
      _emit();
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on FormatException {
      return false;
    }
  }

  Future<void> _save(Map<String, Object?>? value) async {
    try {
      await _storage.invokeMethod<void>(
        'saveSmartTvPairing',
        value == null ? null : jsonEncode(value),
      );
    } on MissingPluginException {
      /* Desktop preview. */
    }
  }

  Future<void> disconnect() async {
    switch (kind) {
      case TvOutputKind.android:
        await _android.disconnect();
      case TvOutputKind.lg:
        await _lg?.disconnect();
        _lg?.clientKey = null;
        _lg?.certificateFingerprint = null;
        _lg?.host = null;
      case TvOutputKind.samsung:
        await samsung.stop();
    }
    await _save(null);
    _emit();
  }

  Future<void> cancelConnectionAttempt() async {
    switch (kind) {
      case TvOutputKind.android:
        await _android.cancelConnectionAttempt();
      case TvOutputKind.lg:
        await _lg?.disconnect();
      case TvOutputKind.samsung:
        await samsung.stop();
    }
    _emit();
  }

  Future<void> retrySavedPairing() async {
    if (kind == TvOutputKind.android) await _android.retrySavedPairing();
    if (kind == TvOutputKind.lg) await _lg?.retry();
  }

  void updateSubtitle(String text, SubtitleSettings settings) =>
      updateSubtitles([text], settings);
  void updateSubtitles(List<String> texts, SubtitleSettings settings) {
    _latestSettings = settings;
    switch (kind) {
      case TvOutputKind.android:
        _android.updateSubtitles(texts, settings);
      case TvOutputKind.lg:
        _lg?.updateSubtitles(texts);
      case TvOutputKind.samsung:
        samsung.updateSubtitles(texts, settings);
    }
  }

  void updateSettings(SubtitleSettings settings) {
    _latestSettings = settings;
    if (kind == TvOutputKind.android) _android.updateSettings(settings);
    if (kind == TvOutputKind.samsung) samsung.updateSettings(settings);
  }
}
