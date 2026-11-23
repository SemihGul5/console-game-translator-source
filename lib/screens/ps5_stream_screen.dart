import '../l10n/app_localizations.dart';
import 'dart:async';
import '../services/access_service.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/subtitle_cover.dart';
import '../models/subtitle_settings.dart';
import '../services/subtitle_settings_store.dart';
import '../services/tv_output_service.dart';
import '../widgets/normalized_rect_editor.dart';
import '../widgets/game_subtitle_text.dart';

const _ps5Channel = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);
const _ps5Events = EventChannel(
  'com.abrebostudio.consolegametranslator/ps5_events',
);
const _videoViewType = 'com.abrebostudio.consolegametranslator/chiaki_video';

class Ps5StreamScreen extends StatefulWidget {
  const Ps5StreamScreen({
    super.key,
    this.autoConnect = false,
    this.openSubtitleSettingsOnStart = false,
    this.activateSubtitlesOnStart = false,
    this.onBackgroundTranslation,
    this.onTranslationReady,
    this.initialProfileName,
  });

  final bool autoConnect;
  final bool openSubtitleSettingsOnStart;
  final bool activateSubtitlesOnStart;
  final Future<bool?> Function()? onBackgroundTranslation;
  final Future<bool?> Function()? onTranslationReady;
  final String? initialProfileName;

  @override
  State<Ps5StreamScreen> createState() => _Ps5StreamScreenState();
}

class _Ps5StreamScreenState extends State<Ps5StreamScreen>
    with WidgetsBindingObserver {
  StreamSubscription<dynamic>? _eventsSubscription;
  String _status = 'Hazır';
  String? _error;
  bool _starting = false;
  bool _stopping = false;
  bool _sessionActive = false;
  bool _remotePlaySessionConnected = false;
  bool _remotePlayVideoReady = false;
  bool _remotePlayConnected = false;
  bool _mobilePreviewHidden = false;
  bool _hidePreviewDuringAutoStart = false;
  bool _pictureInPictureMode = false;
  bool _returnedHomeForTranslation = false;
  bool _allowExitAfterTranslationStop = false;
  bool _forgettingConsole = false;
  Future<bool>? _disconnectFuture;
  SubtitleSettings _subtitleSettings = const SubtitleSettings();
  bool _subtitleSettingsVisible = false;
  bool _editingSubtitleBounds = false;
  List<String> _subtitleTexts = <String>[];
  String get _subtitleText =>
      _subtitleTexts.where((text) => text.isNotEmpty).join('\n');
  // Covers of every OCR area drawing over the English, flat for drawing and
  // for the TV, and by area so each area's update replaces only its own.
  List<SubtitleCover> _subtitleCovers = const <SubtitleCover>[];
  Map<int, List<SubtitleCover>> _coversByArea = <int, List<SubtitleCover>>{};
  // Areas whose translation carries controller button icons, by area index.
  Map<int, SubtitleRichText> _subtitleRich = <int, SubtitleRichText>{};
  List<Map<String, Object>> _richForTv() => [
    for (var index = 0; index < _subtitleTexts.length; index++)
      _subtitleRich[index]?.toMap() ?? const <String, Object>{},
  ];
  // One sticky font step for the whole session, so cover text does not change
  // size from line to line.
  double _coverFontScale = 1;
  double? _coverFontBase;
  bool get _coverModeActive => _subtitleSettings.coversAnyEnglish;
  bool _coversArea(int index) => _subtitleSettings.coversEnglishFor(index);
  bool get _subtitleBoxLocked =>
      _editingSubtitleBounds && _coversArea(_selectedSubtitleIndex);

  /// Replaces one area's covers ([covers] empty removes them).
  void _setAreaCovers(int area, List<SubtitleCover> covers) {
    final byArea = Map<int, List<SubtitleCover>>.of(_coversByArea);
    if (covers.isEmpty) {
      byArea.remove(area);
    } else {
      byArea[area] = covers;
    }
    final areas = byArea.keys.toList()..sort();
    _coversByArea = byArea;
    _subtitleCovers = List<SubtitleCover>.unmodifiable([
      for (final index in areas) ...byArea[index]!,
    ]);
  }

  void _clearCovers() {
    _coversByArea = <int, List<SubtitleCover>>{};
    _subtitleCovers = const <SubtitleCover>[];
  }
  String _ocrDebugText = '';
  String _ocrStatus = 'OCR bekliyor';
  String _ocrTiming = '';
  bool _settingsLoaded = false;
  int _selectedOcrIndex = 0;
  int _selectedSubtitleIndex = 0;
  final TvOutputService _tvSubtitleClient = TvOutputService.instance;
  Timer? _runtimeSettingsTimer;
  Timer? _subtitleSettingsSaveTimer;
  bool _subtitleSettingsDirty = false;
  final GlobalKey _rectangleControlsKey = GlobalKey();
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _manualDisconnectRequested = false;
  bool _hasConnectedThisScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hidePreviewDuringAutoStart = widget.activateSubtitlesOnStart;
    _subtitleSettingsVisible = widget.openSubtitleSettingsOnStart;
    _editingSubtitleBounds = widget.openSubtitleSettingsOnStart;
    // Keep the Remote Play preview visible by default. The user can hide it
    // explicitly without stopping the native video surface or OCR sampling.
    _mobilePreviewHidden = false;
    _eventsSubscription = _ps5Events.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (Object error) => setState(() => _error = error.toString()),
    );
    unawaited(_refreshSessionState());
    const SubtitleSettingsStore().load().then((settings) async {
      if (!mounted) return;
      setState(() {
        _subtitleSettings = settings;
        _settingsLoaded = true;
      });
      if (widget.activateSubtitlesOnStart) {
        _tvSubtitleClient.updateSettings(settings);
        await _ps5Channel.invokeMethod<void>(
          'updateSubtitleSettingsRuntime',
          settings.toMap(),
        );
      }
    });
    if (widget.autoConnect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _connect();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshSessionStateAfterResume());
    } else {
      unawaited(_persistSubtitleSettings());
    }
  }

  Future<void> _refreshSessionStateAfterResume() async {
    final wasStarting = _starting;
    await _refreshSessionState(force: true);
    if (!mounted || _sessionActive || _manualDisconnectRequested) return;
    if (_hasConnectedThisScreen && _reconnectTimer == null) {
      _handleEvent({
        'type': 'disconnected',
        'message': context.tr(
          "Arka plan dönüşü için Remote Play yeniden kuruluyor.",
        ),
      });
    } else if (wasStarting) {
      _scheduleReconnect(initialFailure: !_hasConnectedThisScreen);
    }
  }

  void _handleEvent(dynamic raw) {
    if (!mounted || raw is! Map) return;
    final event = Map<String, dynamic>.from(raw);
    switch (event['type']) {
      case 'translationNotificationTapped':
        _showHomeForTranslation();
        break;
      case 'pictureInPictureModeChanged':
        final active = event['active'] == true;
        if (_pictureInPictureMode != active) {
          setState(() => _pictureInPictureMode = active);
        }
        break;
      case 'connecting':
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        setState(() {
          _status = "PS5’e bağlanıyor…";
          _error = null;
          _sessionActive = true;
          _remotePlaySessionConnected = false;
          _remotePlayVideoReady = false;
          _remotePlayConnected = false;
          _starting = true;
          _stopping = false;
        });
        break;
      case 'connected':
        _hasConnectedThisScreen = true;
        _remotePlaySessionConnected = true;
        _remotePlayVideoReady = true;
        _remotePlayConnected = true;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        _reconnectAttempt = 0;
        setState(() {
          _status = "Bağlandı";
          _sessionActive = true;
          _starting = false;
          _stopping = false;
        });
        _returnHomeAfterTranslationStarts();
        break;
      case 'videoOutputRecovering':
        setState(() {
          _remotePlayVideoReady = false;
          _remotePlayConnected = false;
          _status = "Görüntü yenileniyor…";
        });
        break;
      case 'videoOutputReady':
        if (_remotePlaySessionConnected) {
          setState(() {
            _remotePlayVideoReady = true;
            _remotePlayConnected = true;
            _status = "Bağlandı";
          });
        }
        break;
      case 'loginPinRequired':
        setState(() {
          _status = "PS5 kullanıcı giriş PIN’i gerekiyor";
          _error =
              "Konsol kullanıcı PIN ekranını bekliyor. Bu uygulamada PIN girişi henüz eklenmedi.";
        });
        break;
      case 'disconnected':
      case 'stopped':
        if (event['userInitiated'] == true) {
          _manualDisconnectRequested = true;
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
        }
        _remotePlayConnected = false;
        _remotePlaySessionConnected = false;
        _remotePlayVideoReady = false;
        final wasConnecting = _starting;
        final hadConnected = _hasConnectedThisScreen;
        final shouldReconnect =
            !_manualDisconnectRequested &&
            (hadConnected || wasConnecting) &&
            !_forgettingConsole &&
            _reconnectAttempt < 4;
        setState(() {
          _status = "Bağlantı kesildi";
          _sessionActive = false;
          _starting = false;
          _stopping = false;
          if (!hadConnected) _hidePreviewDuringAutoStart = false;
        });
        if (event['message'] != null) {
          setState(() => _error = event['message'].toString());
        }
        if (shouldReconnect) {
          final message = event['message']?.toString().toLowerCase() ?? '';
          final minimumDelay = message.contains('already in use')
              ? 8
              : message.contains('yüzey') || message.contains('arka plan')
              ? 5
              : null;
          _scheduleReconnect(
            initialFailure: !hadConnected,
            minimumSeconds: minimumDelay,
          );
        }
        break;
      case 'error':
        _remotePlayConnected = false;
        _remotePlaySessionConnected = false;
        _remotePlayVideoReady = false;
        final wasConnecting = _starting;
        final hadConnected = _hasConnectedThisScreen;
        final shouldReconnect =
            !_manualDisconnectRequested &&
            (hadConnected || wasConnecting) &&
            !_forgettingConsole &&
            _reconnectAttempt < 4;
        setState(() {
          _status = "Bağlantı hatası";
          _error = event['message']?.toString();
          _starting = false;
          if (!hadConnected) _hidePreviewDuringAutoStart = false;
        });
        if (shouldReconnect) {
          final message = event['message']?.toString().toLowerCase() ?? '';
          _scheduleReconnect(
            initialFailure: !hadConnected,
            minimumSeconds: message.contains('already in use') ? 30 : null,
          );
        }
        break;
      case 'ocrDebug':
        final timings = event['timings'];
        setState(() {
          _ocrDebugText = event['text']?.toString() ?? '';
          if (timings is Map) {
            _ocrTiming =
                "kopya ${timings['copyMs'] ?? '?'} ms, kırpma ${timings['cropMs'] ?? '?'} ms, filtre ${timings['preprocessMs'] ?? '?'} ms, OCR ${timings['ocrMs'] ?? '?'} ms (güven ${timings['ocrConfidence'] ?? context.tr("kıyas")}) , ${timings['cropWidth'] ?? '?'}×${timings['cropHeight'] ?? '?'}";
          }
        });
        break;
      case 'subtitleOcrStatus':
        setState(() => _ocrStatus = event['status']?.toString() ?? '');
        break;
      case 'accessChanged':
        unawaited(AccessService.instance.readNativeStatus());
        break;
      case 'accessDenied':
        _manualDisconnectRequested = true;
        _reconnectTimer?.cancel();
        setState(
          () => _error =
              "Çeviri erişimi sona erdi veya doğrulanamadı. Premium ekranını kontrol et.",
        );
        unawaited(AccessService.instance.readNativeStatus());
        break;
      case 'subtitleText':
        final text = event['text']?.toString() ?? '';
        final index = (event['regionIndex'] as num?)?.toInt() ?? 0;
        final rich = SubtitleRichText.fromEvent(event);
        setState(() {
          while (_subtitleTexts.length <= index) {
            _subtitleTexts.add('');
          }
          _subtitleTexts[index] = text;
          if (rich == null) {
            _subtitleRich.remove(index);
          } else {
            _subtitleRich[index] = rich;
          }
        });
        _tvSubtitleClient.updateSubtitles(
          _subtitleTexts,
          _subtitleSettings,
          rich: _richForTv(),
        );
        if (event['diagnostics'] == true) {
          final memory = event['translationMemory'];
          final id = memory is Map ? memory['id'] : null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final current =
                index < _subtitleTexts.length && _subtitleTexts[index] == text;
            final inRegion =
                index >= 0 &&
                index < _subtitleSettings.effectiveSubtitleRegions.length;
            final result = !current
                ? 'superseded'
                : !_remotePlayConnected
                ? 'disconnected'
                : !inRegion
                ? 'outside_regions'
                : _mobilePreviewHidden && !_pictureInPictureMode
                ? 'preview_hidden'
                : 'frame_built';
            unawaited(
              _ps5Channel
                  .invokeMethod<void>('reportSubtitlePresentation', {
                    'area': index + 1,
                    'result': result,
                    'id': id,
                    'chars': text.length,
                  })
                  .catchError((Object _) {}),
            );
          });
        }
        break;
      case 'subtitleCleared':
        final rawIndex = (event['regionIndex'] as num?)?.toInt();
        setState(() {
          if (rawIndex == null) {
            _subtitleTexts = <String>[];
            _clearCovers();
            _subtitleRich = <int, SubtitleRichText>{};
          } else if (rawIndex >= 0 && rawIndex < _subtitleTexts.length) {
            _subtitleTexts[rawIndex] = '';
            _subtitleRich.remove(rawIndex);
          }
        });
        _tvSubtitleClient.updateSubtitles(
          _subtitleTexts,
          _subtitleSettings,
          covers: rawIndex == null ? const [] : null,
          rich: _richForTv(),
        );
        break;
      case 'subtitleCovers':
        final index = (event['regionIndex'] as num?)?.toInt() ?? 0;
        if (index < 0) break;
        final rawItems = event['items'];
        final covers = rawItems is List
            ? rawItems
                  .map(SubtitleCover.tryParse)
                  .whereType<SubtitleCover>()
                  .toList(growable: false)
            : const <SubtitleCover>[];
        setState(() => _setAreaCovers(index, covers));
        _tvSubtitleClient.updateCovers(
          _subtitleCovers.map((cover) => cover.toMap()).toList(growable: false),
          _subtitleSettings,
        );
        break;
    }
  }

  SubtitleSettings get _selectedSubtitleSettings =>
      _subtitleSettings.settingsForSubtitle(_selectedSubtitleIndex);

  OcrRegionSettings get _selectedOcrSettings =>
      _subtitleSettings.effectiveOcrSettings[_selectedOcrIndex];

  void _updateSelectedSubtitleSettings(SubtitleSettings settings) =>
      _updateSubtitleSettings(
        _subtitleSettings.withSubtitleStyle(_selectedSubtitleIndex, settings),
      );

  void _updateSelectedOcrSettings(OcrRegionSettings settings) =>
      _updateSubtitleSettings(
        _subtitleSettings.withOcrSettings(_selectedOcrIndex, settings),
      );

  void _setCoverEnglishSubtitle(int index, bool enabled) {
    final all = _subtitleSettings.effectiveOcrSettings;
    if (index < 0 || index >= all.length) return;
    final current = all[index];
    if (current.coverEnglishSubtitle == enabled) return;
    setState(() {
      _setAreaCovers(index, const <SubtitleCover>[]);
      _coverFontScale = 1;
      _coverFontBase = null;
    });
    _updateSubtitleSettings(
      _subtitleSettings.withOcrSettings(
        index,
        current.copyWith(coverEnglishSubtitle: enabled),
      ),
    );
  }

  void _updateSubtitleSettings(SubtitleSettings settings) {
    if (!_settingsLoaded) return;
    // Subtitle areas that follow their OCR area move with it.
    settings = settings.withFollowingSubtitles();
    setState(() {
      _subtitleSettings = settings;
    });
    _subtitleSettingsDirty = true;
    _subtitleSettingsSaveTimer?.cancel();
    _subtitleSettingsSaveTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_persistSubtitleSettings());
    });
    _tvSubtitleClient.updateSettings(settings);
    _runtimeSettingsTimer?.cancel();
    _runtimeSettingsTimer = Timer(const Duration(milliseconds: 120), () {
      _ps5Channel.invokeMethod<void>(
        'updateSubtitleSettingsRuntime',
        settings.toMap(),
      );
    });
  }

  void _openSubtitleSettings() {
    final isOpening = !_subtitleSettingsVisible;
    if (!isOpening) unawaited(_persistSubtitleSettings());
    setState(() {
      _subtitleSettingsVisible = !_subtitleSettingsVisible;
      if (isOpening) _editingSubtitleBounds = true;
    });
  }

  Future<void> _showHomeForTranslation() async {
    await _refreshSessionStateAfterResume();
    if (!mounted) return;
    final openSettings = await widget.onBackgroundTranslation?.call();
    if (openSettings == true && mounted) _openSubtitleSettings();
  }

  void _returnHomeAfterTranslationStarts() {
    if (!widget.activateSubtitlesOnStart ||
        _returnedHomeForTranslation ||
        widget.onTranslationReady == null) {
      return;
    }
    _returnedHomeForTranslation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final homeRoute = widget.onTranslationReady!.call();
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted && _hidePreviewDuringAutoStart) {
        setState(() => _hidePreviewDuringAutoStart = false);
      }
      final openSettings = await homeRoute;
      if (openSettings == true && mounted) _openSubtitleSettings();
    });
  }

  Future<bool> _persistSubtitleSettings({bool force = false}) async {
    _subtitleSettingsSaveTimer?.cancel();
    if (!_settingsLoaded || (!_subtitleSettingsDirty && !force)) return true;
    final settings = _subtitleSettings;
    _subtitleSettingsDirty = false;
    try {
      const store = SubtitleSettingsStore();
      // The translation languages are chosen on the home screen. This screen
      // keeps a copy loaded when it opened, so write back the stored language
      // pair instead of a choice that may have changed since.
      final stored = await store.load();
      await store.save(
        settings.copyWith(
          sourceLanguageCode: stored.sourceLanguageCode,
          targetLanguageCode: stored.targetLanguageCode,
        ),
      );
      return true;
    } on PlatformException catch (error) {
      if (identical(_subtitleSettings, settings)) _subtitleSettingsDirty = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr("Altyazı ayarları kaydedilemedi: {0}", [
                error.message ?? error.code,
              ]),
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _saveSubtitleSettings({bool closePanel = false}) async {
    if (!await _persistSubtitleSettings(force: true)) return;
    if (!mounted) return;
    setState(() {
      _subtitleSettingsVisible = !closePanel;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr("Altyazı ayarları kaydedildi."))),
    );
  }

  Future<void> _refreshSessionState({bool force = false}) async {
    try {
      final state = await _ps5Channel.invokeMapMethod<String, dynamic>(
        'getSessionState',
      );
      if (!mounted || state == null) return;
      final active = state['active'] == true;
      final sessionConnected = state['connected'] == true;
      final videoReady = state['videoReady'] == true;
      final connected = sessionConnected && videoReady;
      if (active) {
        // Reattach the preview; the decoder and OCR keep the same output
        // while the Activity or route is hidden.
        unawaited(_ps5Channel.invokeMethod<void>('recoverVideoOutput'));
      }
      if (_starting && !active && !force) return;
      setState(() {
        _sessionActive = active;
        _remotePlaySessionConnected = sessionConnected;
        _remotePlayVideoReady = videoReady;
        _remotePlayConnected = connected;
        _starting = active && !sessionConnected;
        if (connected) {
          _status = "Bağlandı";
          _hasConnectedThisScreen = true;
        } else if (sessionConnected) {
          _status = "Görüntü yenileniyor…";
        } else if (active) {
          _status = "PS5’e bağlanıyor…";
        } else {
          _status = "Remote Play açık değil";
        }
      });
      if (connected) _returnHomeAfterTranslationStarts();
    } on PlatformException {
      if (mounted && !_starting && !force) {
        setState(() {
          _sessionActive = false;
          _remotePlaySessionConnected = false;
          _remotePlayVideoReady = false;
          _remotePlayConnected = false;
        });
      }
    }
  }

  Future<void> _testOcrSelectedRegion() async {
    setState(() => _ocrStatus = "Seçili alan tek karede taranıyor…");
    try {
      await _ps5Channel.invokeMethod<Object?>(
        'testOcrSelectedRegion',
        _selectedOcrIndex,
      );
    } on PlatformException catch (error) {
      if (mounted) setState(() => _ocrStatus = error.message ?? error.code);
    }
  }

  Future<void> _resetEditedRect() async {
    const defaults = SubtitleSettings();
    final subtitleIndex = _selectedSubtitleIndex;
    if (_editingSubtitleBounds &&
        subtitleIndex > 0 &&
        subtitleIndex < _subtitleSettings.effectiveOcrRegions.length) {
      // An added area's subtitle goes back onto its OCR area and follows it again.
      _updateSubtitleSettings(
        _subtitleSettings.withSubtitleFollowing({subtitleIndex: true}),
      );
      if (await _persistSubtitleSettings() && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr("Seçili alan sıfırlandı ve kaydedildi.")),
          ),
        );
      }
      return;
    }
    final updated = _subtitleSettings.copyWith(
      ocrRegion: _editingSubtitleBounds
          ? _subtitleSettings.ocrRegion
          : _subtitleSettings.effectiveOcrRegions[_selectedOcrIndex],
      ocrRegions: _editingSubtitleBounds
          ? _subtitleSettings.ocrRegions
          : _replaceOcrRegion(defaults.ocrRegion),
      subtitleBounds: _editingSubtitleBounds
          ? _subtitleSettings.effectiveSubtitleRegions.first
          : _subtitleSettings.subtitleBounds,
      subtitleRegions: _editingSubtitleBounds
          ? _replaceSubtitleRegion(defaults.subtitleBounds)
          : _subtitleSettings.subtitleRegions,
    );
    _updateSubtitleSettings(updated);
    if (await _persistSubtitleSettings() && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr("Seçili alan sıfırlandı ve kaydedildi.")),
        ),
      );
    }
  }

  List<NormalizedRect> _replaceOcrRegion(NormalizedRect value) {
    final regions = List<NormalizedRect>.of(
      _subtitleSettings.effectiveOcrRegions,
    );
    regions[_selectedOcrIndex] = value;
    return regions;
  }

  NormalizedRect get _selectedSubtitleBounds =>
      _subtitleSettings.effectiveSubtitleRegions[_selectedSubtitleIndex.clamp(
        0,
        _subtitleSettings.effectiveSubtitleRegions.length - 1,
      )];

  NormalizedRect get _editedRect => _editingSubtitleBounds
      ? _selectedSubtitleBounds
      : _subtitleSettings.effectiveOcrRegions[_selectedOcrIndex.clamp(
          0,
          _subtitleSettings.effectiveOcrRegions.length - 1,
        )];

  void _updateEditedRect(NormalizedRect value) {
    if (_editingSubtitleBounds) {
      _updateSelectedSubtitleRegion(value);
    } else {
      _updateSubtitleSettings(
        _subtitleSettings.copyWith(
          ocrRegion: value,
          ocrRegions: _replaceOcrRegion(value),
        ),
      );
    }
  }

  void _centerAllEditedRegions() {
    NormalizedRect centered(NormalizedRect rect) => NormalizedRect(
      left: (1 - rect.width) / 2,
      top: (1 - rect.height) / 2,
      width: rect.width,
      height: rect.height,
    );

    if (_editingSubtitleBounds) {
      final regions = _subtitleSettings.effectiveSubtitleRegions
          .map(centered)
          .toList(growable: false);
      _updateSubtitleSettings(
        _subtitleSettings
            .copyWith(subtitleBounds: regions.first, subtitleRegions: regions)
            .withSubtitleFollowing({
              for (var index = 0; index < regions.length; index++) index: false,
            }),
      );
    } else {
      final regions = _subtitleSettings.effectiveOcrRegions
          .map(centered)
          .toList(growable: false);
      _updateSubtitleSettings(
        _subtitleSettings.copyWith(
          ocrRegion: regions.first,
          ocrRegions: regions,
        ),
      );
    }
  }

  String _percentLabel(double value) {
    final percent = value * 100;
    return percent == percent.roundToDouble()
        ? '${percent.round()}%'
        : '${percent.toStringAsFixed(1)}%';
  }

  Widget _coordinateControl({
    required String title,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    VoidCallback? onCenter,
    Color? accent,
  }) {
    final color = accent ?? const Color(0xFF36D6BE);
    final safeValue = value.clamp(min, max).toDouble();
    var divisions = ((max - min) * 200).round().clamp(2, 200);
    if (divisions.isOdd) divisions++;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 8, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF121D30),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF26364D)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFD8E1F0),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _percentLabel(safeValue),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              if (onCenter != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: context.tr("Tam ortaya hizala · %50"),
                  visualDensity: VisualDensity.compact,
                  onPressed: onCenter,
                  icon: Icon(Icons.filter_center_focus, color: color, size: 19),
                ),
              ],
            ],
          ),
          if (max - min >= 0.005)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.18),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.12),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: safeValue,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr("Bu ölçü için konum sabit."),
                  style: TextStyle(color: Color(0xFF8D9AAF), fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRectangleControls() {
    final rect = _editedRect;
    final centerX = rect.left + rect.width / 2;
    final centerY = rect.top + rect.height / 2;
    final minX = rect.width / 2;
    final maxX = 1 - rect.width / 2;
    final minY = rect.height / 2;
    final maxY = 1 - rect.height / 2;
    final maxWidth = math
        .min(centerX * 2, (1 - centerX) * 2)
        .clamp(0.04, 1.0)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _editingSubtitleBounds &&
                        !_selectedSubtitleSettings.backgroundFitToText
                    ? context.tr("Arka plan konumu ve boyutu")
                    : context.tr("Konum ve boyut"),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _centerAllEditedRegions,
              icon: const Icon(Icons.center_focus_strong, size: 17),
              label: Text(context.tr("Tümünü ortala")),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF36D6BE),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        Text(
          context.tr(
            "Alanı sürükleyebilir veya değerleri hassas biçimde ayarlayabilirsin.",
          ),
          style: TextStyle(fontSize: 12, color: Color(0xFF929DB4)),
        ),
        const SizedBox(height: 10),
        _coordinateControl(
          title: context.tr("Yatay merkez"),
          icon: Icons.swap_horiz_rounded,
          value: centerX,
          min: minX,
          max: maxX,
          onCenter: () => _updateEditedRect(
            NormalizedRect(
              left: (1 - rect.width) / 2,
              top: rect.top,
              width: rect.width,
              height: rect.height,
            ),
          ),
          onChanged: (value) => _updateEditedRect(
            NormalizedRect(
              left: value - rect.width / 2,
              top: rect.top,
              width: rect.width,
              height: rect.height,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _coordinateControl(
          title: context.tr("Dikey merkez"),
          icon: Icons.swap_vert_rounded,
          value: centerY,
          min: minY,
          max: maxY,
          onCenter: () => _updateEditedRect(
            NormalizedRect(
              left: rect.left,
              top: (1 - rect.height) / 2,
              width: rect.width,
              height: rect.height,
            ),
          ),
          onChanged: (value) => _updateEditedRect(
            NormalizedRect(
              left: rect.left,
              top: value - rect.height / 2,
              width: rect.width,
              height: rect.height,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _coordinateControl(
          title: context.tr("Genişlik"),
          icon: Icons.crop_16_9_rounded,
          value: rect.width,
          min: 0.04,
          max: maxWidth,
          accent: const Color(0xFF9A8CFF),
          onChanged: (value) => _updateEditedRect(
            NormalizedRect(
              left: centerX - value / 2,
              top: rect.top,
              width: value,
              height: rect.height,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _coordinateControl(
          title: context.tr("Yükseklik"),
          icon: Icons.height,
          value: rect.height,
          min: 0.04,
          // Let the area grow beyond its current distance to an edge. Keep
          // the center where possible, then shift it inward as needed so the
          // enlarged rectangle remains inside the video frame.
          max: 1.0,
          accent: const Color(0xFF9A8CFF),
          onChanged: (value) {
            final nextCenterY = centerY
                .clamp(value / 2, 1 - value / 2)
                .toDouble();
            _updateEditedRect(
              NormalizedRect(
                left: rect.left,
                top: nextCenterY - value / 2,
                width: rect.width,
                height: value,
              ),
            );
          },
        ),
      ],
    );
  }

  List<NormalizedRect> _replaceSubtitleRegion(NormalizedRect value) {
    final regions = List<NormalizedRect>.of(
      _subtitleSettings.effectiveSubtitleRegions,
    );
    final index = _selectedSubtitleIndex.clamp(0, regions.length - 1);
    regions[index] = value;
    return regions;
  }

  void _updateSelectedSubtitleRegion(NormalizedRect value) {
    final regions = _replaceSubtitleRegion(value);
    final index = _selectedSubtitleIndex.clamp(0, regions.length - 1);
    // Moving the subtitle area by hand gives it its own place.
    _updateSubtitleSettings(
      _subtitleSettings
          .copyWith(subtitleBounds: regions.first, subtitleRegions: regions)
          .withSubtitleFollowing({index: false}),
    );
  }

  void _addSubtitleRegion() {
    if (_subtitleSettings.effectiveSubtitleRegions.length >= 12) return;
    final regions =
        List<NormalizedRect>.of(_subtitleSettings.effectiveSubtitleRegions)
          ..add(
            const NormalizedRect(
              left: 0.28,
              top: 0.70,
              width: 0.44,
              height: 0.12,
            ),
          );
    setState(() => _selectedSubtitleIndex = regions.length - 1);
    _updateSubtitleSettings(
      _subtitleSettings.copyWith(
        subtitleBounds: regions.first,
        subtitleRegions: regions,
        subtitleStyles: [
          ..._subtitleSettings.effectiveSubtitleStyles,
          const SubtitleAppearance(),
        ],
      ),
    );
  }

  void _removeSelectedSubtitleRegion() {
    final regions = List<NormalizedRect>.of(
      _subtitleSettings.effectiveSubtitleRegions,
    );
    if (regions.length <= 1) return;
    final removed = _selectedSubtitleIndex.clamp(0, regions.length - 1);
    final styles = _subtitleSettings.effectiveSubtitleStyles;
    styles.removeAt(removed);
    regions.removeAt(removed);
    setState(() => _selectedSubtitleIndex = 0);
    // Later subtitle areas moved up a number, so they no longer match their
    // OCR areas; they keep their places instead of following.
    final ocrCount = _subtitleSettings.effectiveOcrRegions.length;
    _updateSubtitleSettings(
      styles.first
          .applyTo(_subtitleSettings)
          .copyWith(
            subtitleBounds: regions.first,
            subtitleRegions: regions,
            subtitleStyles: styles,
          )
          .withSubtitleFollowing({
            for (var index = removed; index < ocrCount; index++) index: false,
          }),
    );
  }

  void _removeSelectedOcrRegion() {
    final ocrSettings = _subtitleSettings.effectiveOcrSettings;
    if (ocrSettings.length <= 1) return;
    final index = _selectedOcrIndex.clamp(0, ocrSettings.length - 1);
    final followed = ocrSettings[index].subtitleFollowsOcr;
    final regions = List<NormalizedRect>.of(
      _subtitleSettings.effectiveOcrRegions,
    )..removeAt(index);
    final settings = ocrSettings..removeAt(index);
    final modes = List<int>.of(
      _subtitleSettings.effectiveOcrPreprocessingModes,
    )..removeAt(index);
    final dialogueFilters = List<bool>.of(
      _subtitleSettings.effectiveOcrDialogueFilters,
    )..removeAt(index);
    final subtitleRegions = List<NormalizedRect>.of(
      _subtitleSettings.effectiveSubtitleRegions,
    );
    final styles = _subtitleSettings.effectiveSubtitleStyles;
    // The subtitle area made for this OCR area goes with it. Otherwise the
    // subtitle areas keep their numbers while later OCR areas move up, so
    // those no longer follow.
    final removeSubtitle =
        followed && index < subtitleRegions.length && subtitleRegions.length > 1;
    if (removeSubtitle) {
      subtitleRegions.removeAt(index);
      styles.removeAt(index);
    } else {
      for (var later = index; later < settings.length; later++) {
        settings[later] = settings[later].copyWith(subtitleFollowsOcr: false);
      }
    }
    setState(() {
      _selectedOcrIndex = 0;
      if (_selectedSubtitleIndex >= subtitleRegions.length) {
        _selectedSubtitleIndex = 0;
      }
    });
    final base = removeSubtitle
        ? styles.first.applyTo(_subtitleSettings)
        : _subtitleSettings;
    _updateSubtitleSettings(
      base.copyWith(
        ocrRegion: regions.first,
        ocrRegions: regions,
        ocrRegionSettings: settings,
        sampleRateHz: settings.first.sampleRateHz,
        ocrCaptureScale: settings.first.ocrCaptureScale,
        holdSeconds: settings.first.holdSeconds,
        autoHideAfterSeconds: settings.first.autoHideAfterSeconds,
        ocrPreprocessingMode: settings.first.ocrPreprocessingMode,
        ocrDialogueFilter: settings.first.ocrDialogueFilter,
        ocrPreprocessingModes: modes,
        ocrDialogueFilters: dialogueFilters,
        subtitleBounds: subtitleRegions.first,
        subtitleRegions: subtitleRegions,
        subtitleStyles: styles,
      ),
    );
  }

  void _addOcrRegion() {
    if (_subtitleSettings.effectiveOcrRegions.length >= 12) return;
    final existing = _subtitleSettings.effectiveOcrRegions;
    final regions = List<NormalizedRect>.of(existing)
      ..add(defaultAddedOcrRegion(existing.length));
    // A new OCR area gets its subtitle area in the same place, which follows
    // it until the user moves the subtitle somewhere else.
    final index = regions.length - 1;
    final subtitleRegions = List<NormalizedRect>.of(
      _subtitleSettings.effectiveSubtitleRegions,
    );
    final styles = _subtitleSettings.effectiveSubtitleStyles;
    final createsSubtitle = subtitleRegions.length <= index;
    while (subtitleRegions.length <= index) {
      subtitleRegions.add(regions[subtitleRegions.length]);
      styles.add(styles.first);
    }
    final settings = [
      ..._subtitleSettings.effectiveOcrSettings,
      OcrRegionSettings(subtitleFollowsOcr: createsSubtitle),
    ];
    setState(() => _selectedOcrIndex = index);
    _updateSubtitleSettings(
      _subtitleSettings.copyWith(
        ocrRegions: regions,
        ocrRegionSettings: settings,
        ocrPreprocessingModes: settings
            .map((s) => s.ocrPreprocessingMode)
            .toList(),
        ocrDialogueFilters: settings.map((s) => s.ocrDialogueFilter).toList(),
        subtitleBounds: subtitleRegions.first,
        subtitleRegions: subtitleRegions,
        subtitleStyles: styles,
      ),
    );
  }

  Rect _pixelsFor(NormalizedRect rect, Size size) => Rect.fromLTWH(
    rect.left * size.width,
    rect.top * size.height,
    rect.width * size.width,
    rect.height * size.height,
  );

  Widget _buildVideoSurface() => AspectRatio(
    aspectRatio: 16 / 9,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            const AndroidView(
              viewType: _videoViewType,
              creationParamsCodec: StandardMessageCodec(),
            ),
            if (!_remotePlayConnected)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_outlined,
                          size: 34,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.trMessage(
                            _starting ||
                                    _reconnectTimer != null ||
                                    (_remotePlaySessionConnected &&
                                        !_remotePlayVideoReady)
                                ? _status
                                : context.tr("Remote Play açık değil"),
                          ),
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _starting ||
                                  _reconnectTimer != null ||
                                  (_remotePlaySessionConnected &&
                                      !_remotePlayVideoReady)
                              ? context.tr(
                                  "Remote Play bağlantısı korunuyor; görüntü yüzeyi yenileniyor.",
                                )
                              : context.tr(
                                  "Canlı oyun görüntüsü bağlantı kurulunca görünür.",
                                ),
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if ((_remotePlayConnected && _subtitleText.isNotEmpty) ||
                (_subtitleSettingsVisible && _editingSubtitleBounds))
              for (
                var index = 0;
                index < _subtitleSettings.effectiveSubtitleRegions.length;
                index++
              )
                if (!_coversArea(index))
                  Positioned.fromRect(
                    key: ValueKey('subtitle-output-$index'),
                    rect: _pixelsFor(
                      _subtitleSettings.effectiveSubtitleRegions[index],
                      size,
                    ),
                    child: IgnorePointer(
                      child: _buildSubtitlePreview(index, size),
                    ),
                  ),
            if (_coverModeActive && _remotePlayConnected)
              for (final cover in _subtitleCovers)
                if (_coversArea(cover.area)) _buildSubtitleCover(cover, size),
            if (_subtitleSettingsVisible &&
                _subtitleBoxLocked &&
                ((_coversByArea[_selectedSubtitleIndex]?.isEmpty ?? true) ||
                    !_remotePlayConnected))
              _buildSubtitleCover(_sampleCover(_selectedSubtitleIndex), size),
            if (_subtitleSettingsVisible && !_subtitleBoxLocked)
              NormalizedRectEditor(
                value: _editingSubtitleBounds
                    ? _selectedSubtitleBounds
                    : _subtitleSettings.effectiveOcrRegions[_selectedOcrIndex
                          .clamp(
                            0,
                            _subtitleSettings.effectiveOcrRegions.length - 1,
                          )],
                onChanged: (value) {
                  if (_editingSubtitleBounds) {
                    _updateSelectedSubtitleRegion(value);
                  } else {
                    _updateSubtitleSettings(
                      _subtitleSettings.copyWith(
                        ocrRegion: value,
                        ocrRegions: _replaceOcrRegion(value),
                      ),
                    );
                  }
                },
                label: _editingSubtitleBounds
                    ? (_selectedSubtitleSettings.backgroundFitToText
                          ? context.tr("Altyazı alanı")
                          : context.tr("Arka plan alanı"))
                    : context.tr("OCR alanı"),
                fillArea: !_editingSubtitleBounds,
                color: _editingSubtitleBounds
                    ? const Color(0xFF36D6BE)
                    : const Color(0xFFFFC857),
              ),
          ],
        );
      },
    ),
  );

  /// A sample line over OCR area [area] so the look can be tuned without live text.
  SubtitleCover _sampleCover(int area) {
    final regions = _subtitleSettings.effectiveOcrRegions;
    final ocr = regions[area.clamp(0, regions.length - 1)];
    final height = math.min(ocr.height * 0.4, 0.05);
    return SubtitleCover(
      id: -1,
      text: context.tr("Altyazı önizlemesi"),
      rect: NormalizedRect(
        left: ocr.left + ocr.width * 0.25,
        top: ocr.top + (ocr.height - height) / 2,
        width: ocr.width * 0.5,
        height: height,
      ),
      lineHeight: height,
      area: area,
    );
  }

  double _coverFontScaleFor(
    String text,
    double fontSize,
    double maxWidth,
    SubtitleSettings settings,
  ) {
    if (_coverFontBase != settings.fontSize) {
      _coverFontBase = settings.fontSize;
      _coverFontScale = 1;
    }
    if (_coverFontScale < 1 || text.isEmpty || maxWidth <= 0) {
      return _coverFontScale;
    }
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1,
          fontWeight: settings.bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    // Shrink once, then keep that size for the rest of the session.
    if (lines > 3) _coverFontScale = 0.8;
    return _coverFontScale;
  }

  /// Draws a translation over the English line it replaces. The box keeps a
  /// margin around the English text and grows with the translation, but stays
  /// centred on the original line.
  Widget _buildSubtitleCover(SubtitleCover cover, Size size) {
    final settings = _subtitleSettings
        .settingsForSubtitle(cover.area)
        .copyWith(centered: true);
    final tvHeightDp = _tvSubtitleClient.tvDisplayHeightDp;
    final previewScale = tvHeightDp == null || tvHeightDp <= 0
        ? 1.0
        : size.height / tvHeightDp;
    final box = _pixelsFor(cover.rect, size);
    if (cover.fit) {
      return _buildLabelCover(cover, box, settings, previewScale);
    }
    final margin = math.max(3.0, cover.lineHeight * size.height * 0.35);
    final minWidth = math.min(size.width, box.width + margin * 2);
    final minHeight = math.min(size.height, box.height + margin * 2);
    final maxWidth = math.min(
      size.width * 0.92,
      math.max(minWidth, math.max(box.width * 1.6, size.width * 0.5)),
    );
    final baseFont = settings.fontSize * previewScale;
    final fontSize =
        baseFont *
        _coverFontScaleFor(cover.text, baseFont, maxWidth - 8, settings);
    final maxHeight = math.min(
      size.height,
      math.max(minHeight, fontSize * 4.6 + 6),
    );
    var rect = Rect.fromCenter(
      center: box.center,
      width: maxWidth,
      height: maxHeight,
    );
    rect = rect.shift(
      Offset(
        rect.left < 0
            ? -rect.left
            : (rect.right > size.width ? size.width - rect.right : 0),
        rect.top < 0
            ? -rect.top
            : (rect.bottom > size.height ? size.height - rect.bottom : 0),
      ),
    );
    final background = Color(settings.effectiveBackgroundColor);
    return Positioned.fromRect(
      key: ValueKey('subtitle-cover-${cover.id}'),
      rect: rect,
      child: IgnorePointer(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: math.min(minWidth, maxWidth),
              minHeight: math.min(minHeight, maxHeight),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Always fully opaque: the English text must not show through.
                color: background.withValues(alpha: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: GameSubtitleText(
                    text: cover.text,
                    settings: settings,
                    fontSize: fontSize,
                    icons: cover.icons,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One label of a button-prompt row or a HUD line: written at the English
  /// label's size (never larger than the subtitle font) and shrunk to its
  /// width, so the game's buttons beside it stay visible. Matches the TV.
  Widget _buildLabelCover(
    SubtitleCover cover,
    Rect box,
    SubtitleSettings settings,
    double previewScale,
  ) {
    final maxFont = settings.fontSize * previewScale;
    final background = Color(settings.effectiveBackgroundColor);
    // Several English lines (a phone message): the translation wraps inside the
    // same block, starting at the English line height; GameSubtitleText shrinks
    // it until it fits there. Matches the TV.
    if (cover.rect.height >= cover.lineHeight * 1.6) {
      final lineHeightPx = box.height * cover.lineHeight / cover.rect.height;
      return Positioned.fromRect(
        key: ValueKey('subtitle-cover-${cover.id}'),
        rect: box.inflate(2),
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Always fully opaque: the English text must not show through.
              color: background.withValues(alpha: 1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GameSubtitleText(
                  text: cover.text,
                  settings: settings.copyWith(centered: false),
                  fontSize: math.max(6.0, math.min(maxFont, lineHeightPx * 0.95)),
                ),
              ),
            ),
          ),
        ),
      );
    }
    var fontSize = math.max(6.0, math.min(maxFont, box.height * 0.95));
    double measure(double size) {
      final painter = TextPainter(
        text: TextSpan(
          text: cover.text,
          style: TextStyle(
            fontSize: size,
            height: 1,
            fontWeight: settings.bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    // Exactly over the English label: the translation shrinks (to half size
    // at most) instead of growing the box over the button beside it.
    final allowed = box.width * 1.05;
    final width = measure(fontSize);
    if (width > allowed && width > 0) {
      fontSize = math.max(fontSize * 0.5, fontSize * allowed / width);
    }
    final textWidth = measure(fontSize) + 4;
    final rect = Rect.fromCenter(
      center: box.center,
      width: math.max(box.width + 2, textWidth),
      height: math.max(box.height + 2, fontSize * 1.1 + 2),
    );
    return Positioned.fromRect(
      key: ValueKey('subtitle-cover-${cover.id}'),
      rect: rect,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Always fully opaque: the English text must not show through.
            color: background.withValues(alpha: 1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Center(
              child: GameSubtitleText(
                text: cover.text,
                settings: settings,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverModeInfo() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF36D6BE).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF36D6BE).withValues(alpha: 0.45),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.layers_outlined,
              color: Color(0xFF36D6BE),
              size: 19,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr("Altyazı {0} İngilizce metnin üstünde", [
                  _selectedSubtitleIndex + 1,
                ]),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(
            "Çeviri, OCR {0} alanının okuduğu İngilizce metnin tam üstünde görünür ve onunla birlikte yer değiştirir; art arda konuşan kişiler ayrı kutularda, düğme ipuçları tek tek gösterilir. Bu yüzden sabit konum ayarı kapalı. Yazı boyutu, renk ve arka plan ayarları geçerli.",
            [_selectedSubtitleIndex + 1],
          ),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFB8C1D3),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () =>
              _setCoverEnglishSubtitle(_selectedSubtitleIndex, false),
          icon: const Icon(Icons.push_pin_outlined, size: 18),
          label: Text(context.tr("Sabit konuma dön")),
        ),
      ],
    ),
  );

  Widget _buildSubtitlePreview(int regionIndex, Size videoPreviewSize) {
    final settings = _subtitleSettings.settingsForSubtitle(regionIndex);
    final tvHeightDp = _tvSubtitleClient.tvDisplayHeightDp;
    final previewScale = tvHeightDp == null || tvHeightDp <= 0
        ? 1.0
        : videoPreviewSize.height / tvHeightDp;
    final liveText = regionIndex < _subtitleTexts.length
        ? _subtitleTexts[regionIndex]
        : '';
    final rich = liveText.isNotEmpty ? _subtitleRich[regionIndex] : null;
    final text = GameSubtitleText(
      text: rich != null
          ? rich.text
          : liveText.isNotEmpty
          ? liveText
          : _subtitleSettingsVisible
          ? context.tr("Altyazı önizlemesi")
          : '',
      settings: settings,
      fontSize: settings.fontSize * previewScale,
      icons: rich?.icons ?? const <String>[],
    );
    final decoration = BoxDecoration(
      color: Color(settings.effectiveBackgroundColor),
      borderRadius: BorderRadius.circular(8),
    );
    final alignment = settings.centered
        ? Alignment.center
        : Alignment.centerLeft;
    if (!settings.backgroundFitToText) {
      return DecoratedBox(
        key: ValueKey('subtitle-background-$regionIndex'),
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          child: Align(alignment: alignment, child: text),
        ),
      );
    }
    return Align(
      alignment: alignment,
      child: DecoratedBox(
        key: ValueKey('subtitle-background-$regionIndex'),
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          child: text,
        ),
      ),
    );
  }

  String _samplingRateLabel(double rate) {
    if (rate < 1) return 'Her ${(1 / rate).round()} sn';
    return '${rate.toStringAsFixed(rate == rate.roundToDouble() ? 0 : 1)}/sn';
  }

  Widget _buildSubtitleSettings() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              (_editingSubtitleBounds
                      ? const Color(0xFF36D6BE)
                      : const Color(0xFFFFC857))
                  .withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                (_editingSubtitleBounds
                        ? const Color(0xFF36D6BE)
                        : const Color(0xFFFFC857))
                    .withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr("Önizleme üzerinde hangi alanı ayarlayacaksın?"),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _areaModeButton(
                    label: context.tr("OCR alanı"),
                    icon: Icons.document_scanner_outlined,
                    selected: !_editingSubtitleBounds,
                    color: const Color(0xFFFFC857),
                    onPressed: () =>
                        setState(() => _editingSubtitleBounds = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _areaModeButton(
                    label: context.tr("Altyazı yeri"),
                    icon: Icons.subtitles_outlined,
                    selected: _editingSubtitleBounds,
                    color: const Color(0xFF36D6BE),
                    onPressed: () =>
                        setState(() => _editingSubtitleBounds = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _editingSubtitleBounds
                  ? context.tr(
                      "Her altyazı alanının konumunu ve görünümünü ayrı düzenleyebilirsin. Yeni alanlar varsayılan ayarlarla eklenir.",
                    )
                  : context.tr(
                      "Her OCR alanının konumunu ve tarama ayarlarını ayrı düzenleyebilirsin. Yeni alanlar varsayılan ayarlarla eklenir.",
                    ),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB8C1D3),
                height: 1.35,
              ),
            ),
            if (_editingSubtitleBounds) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (
                    var index = 0;
                    index < _subtitleSettings.effectiveSubtitleRegions.length;
                    index++
                  )
                    ChoiceChip(
                      label: Text(context.tr("Altyazı {0}", [index + 1])),
                      selected: _selectedSubtitleIndex == index,
                      onSelected: (_) =>
                          setState(() => _selectedSubtitleIndex = index),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(context.tr("Altyazı alanı ekle")),
                    onPressed:
                        _subtitleSettings.effectiveSubtitleRegions.length >= 12
                        ? null
                        : _addSubtitleRegion,
                  ),
                  if (_subtitleSettings.effectiveSubtitleRegions.length > 1)
                    ActionChip(
                      avatar: const Icon(Icons.remove_circle_outline, size: 18),
                      label: Text(context.tr("Seçili alanı sil")),
                      onPressed: _removeSelectedSubtitleRegion,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 8),
      const SizedBox(height: 12),
      if (!_editingSubtitleBounds)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC857).withValues(alpha: 0.10),
            border: Border.all(
              color: const Color(0xFFFFC857).withValues(alpha: 0.55),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr("SARI ALANLAR • OCR NEREDEN OKUSUN?"),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(
                  "Oyun görüntüsünde metnin bulunduğu yeri seç. OCR yalnızca seçtiğin alanları tarar. Her alanı ayrı taşıyıp boyutlandırabilirsin.",
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF929DB4),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (
                    var index = 0;
                    index < _subtitleSettings.effectiveOcrRegions.length;
                    index++
                  )
                    ChoiceChip(
                      label: Text('OCR ${index + 1}'),
                      selected: _selectedOcrIndex == index,
                      onSelected: (_) =>
                          setState(() => _selectedOcrIndex = index),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(context.tr("OCR alanı ekle")),
                    onPressed:
                        _subtitleSettings.effectiveOcrRegions.length >= 12
                        ? null
                        : _addOcrRegion,
                  ),
                  if (_subtitleSettings.effectiveOcrRegions.length > 1)
                    ActionChip(
                      avatar: const Icon(Icons.remove_circle_outline, size: 18),
                      label: Text(context.tr("Seçili OCR alanını sil")),
                      onPressed: _removeSelectedOcrRegion,
                    ),
                ],
              ),
            ],
          ),
        )
      else
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF36D6BE).withValues(alpha: 0.10),
            border: Border.all(
              color: const Color(0xFF36D6BE).withValues(alpha: 0.55),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr("TURKUAZ KUTULAR • ALTYAZILAR NEREDE GÖRÜNSÜN?"),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                context.tr(
                  "Her turkuaz alan aynı çevrilmiş altyazıyı seçtiğin konumda gösterir. OCR alanlarından bağımsızdır; birden fazla yere ekleyebilirsin.",
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF929DB4),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      if (!_editingSubtitleBounds) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF20243A),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF4A456B)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: Color(0xFFFFD166),
                size: 19,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.tr(
                    'OCR ipucu: Oyun ayarları izin veriyorsa İngilizce altyazının arka planını açıp opaklığını artır. Koyu zemin ve açık renk yazı, metnin daha net okunmasına ve çevirinin iyileşmesine yardımcı olabilir.',
                  ),
                  style: TextStyle(
                    color: Color(0xFFD5D9E5),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 10),
      if (_subtitleBoxLocked) ...[
        _buildCoverModeInfo(),
        const SizedBox(height: 10),
      ] else ...[
        if (_editingSubtitleBounds &&
            _selectedSubtitleIndex <
                _subtitleSettings.effectiveOcrRegions.length) ...[
          _settingsCard(
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeThumbColor: const Color(0xFF36D6BE),
              activeTrackColor: const Color(
                0xFF36D6BE,
              ).withValues(alpha: 0.45),
              title: Text(
                context.tr("Altyazı {0}, OCR {1} alanıyla birlikte taşınsın", [
                  _selectedSubtitleIndex + 1,
                  _selectedSubtitleIndex + 1,
                ]),
              ),
              subtitle: Text(
                context.tr(
                  "Açıkken altyazı OCR alanının tam üstünde durur ve onu taşıdıkça o da taşınır. Altyazı kutusunu elle taşırsan kendi yerinde kalır.",
                ),
                style: const TextStyle(color: Color(0xFF929DB4), fontSize: 12),
              ),
              value: _subtitleSettings
                  .effectiveOcrSettings[_selectedSubtitleIndex]
                  .subtitleFollowsOcr,
              onChanged: (follow) => _updateSubtitleSettings(
                _subtitleSettings.withSubtitleFollowing({
                  _selectedSubtitleIndex: follow,
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        KeyedSubtree(
          key: _rectangleControlsKey,
          child: _buildRectangleControls(),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _resetEditedRect,
            icon: const Icon(Icons.restart_alt),
            label: Text(
              _editingSubtitleBounds
                  ? context.tr("Altyazı kutusunu sıfırla")
                  : context.tr("Seçili OCR alanını sıfırla"),
            ),
          ),
        ),
      ],
      // OCR settings belong to the OCR area mode only.
      if (!_editingSubtitleBounds) ...[
        _settingsCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_ocrDebugText.isNotEmpty) ...[
                Text(
                  context.tr("Son OCR: {0}\n{1}", [
                    _ocrDebugText,
                    context.trMessage(_ocrTiming),
                  ]),
                  style: const TextStyle(color: Color(0xFFB8C1D3), fontSize: 12),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.trMessage(_ocrStatus),
                      style: const TextStyle(color: Color(0xFFD8E1F0)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _sessionActive ? _testOcrSelectedRegion : null,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(context.tr("Ham/filtreli OCR kıyasla")),
                  ),
                ],
              ),
            ],
          ),
        ),
        _settingsCard(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr("OCR {0} tarama sıklığı: {1}", [
                        _selectedOcrIndex + 1,
                        _samplingRateLabel(_selectedOcrSettings.sampleRateHz),
                      ]),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(
                        "Düşük değer daha az pil harcar; metni daha geç yakalayabilir.",
                      ),
                      style: TextStyle(color: Color(0xFF929DB4), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<double>(
                value: _selectedOcrSettings.sampleRateHz,
                dropdownColor: const Color(0xFF131A2B),
                items: subtitleOcrSamplingRatesHz
                    .map(
                      (rate) => DropdownMenuItem<double>(
                        value: rate,
                        child: Text(_samplingRateLabel(rate)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateSelectedOcrSettings(
                      _selectedOcrSettings.copyWith(sampleRateHz: value),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        _settingsCard(
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            activeThumbColor: const Color(0xFF36D6BE),
            activeTrackColor: const Color(0xFF36D6BE).withValues(alpha: 0.45),
            title: Text(
              context.tr("OCR {0} diyalog filtresi", [_selectedOcrIndex + 1]),
            ),
            subtitle: Text(
              _subtitleSettings.ocrDialogueFilterFor(_selectedOcrIndex)
                  ? context.tr(
                      "Konuşmacı adı, cümle yapısı ve konuma göre diyalog benzeri satırları seçer.",
                    )
                  : context.tr(
                      "Kapalı: seçili OCR alanındaki tüm metinler tanınır.",
                    ),
              style: const TextStyle(color: Color(0xFF929DB4), fontSize: 12),
            ),
            value: _subtitleSettings.ocrDialogueFilterFor(_selectedOcrIndex),
            onChanged: (enabled) {
              _updateSelectedOcrSettings(
                _selectedOcrSettings.copyWith(ocrDialogueFilter: enabled),
              );
            },
          ),
        ),
        _settingsCard(
          SwitchListTile.adaptive(
            key: ValueKey('cover-english-$_selectedOcrIndex'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            activeThumbColor: const Color(0xFF36D6BE),
            activeTrackColor: const Color(0xFF36D6BE).withValues(alpha: 0.45),
            title: Text(
              context.tr("Çeviriyi İngilizce altyazının üstünde göster"),
            ),
            subtitle: Text(
              _coversArea(_selectedOcrIndex)
                  ? context.tr(
                      "Açık: çeviri, okunan İngilizce metnin tam üstünde çıkar; art arda konuşan kişiler ayrı ayrı, düğme ipuçları (SEÇ, GERİ…) her biri kendi yazısının üstünde gösterilir ve oyundaki düğme simgeleri görünür kalır. Bu alanın sabit altyazı konumu kullanılmaz.",
                    )
                  : context.tr(
                      "Kapalı: çeviri, Altyazı {0} için seçtiğin sabit yerde gösterilir.",
                      [_selectedOcrIndex + 1],
                    ),
              style: const TextStyle(color: Color(0xFF929DB4), fontSize: 12),
            ),
            value: _coversArea(_selectedOcrIndex),
            onChanged: (enabled) =>
                _setCoverEnglishSubtitle(_selectedOcrIndex, enabled),
          ),
        ),
        _settingsCard(
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey(
                    'ocr-preprocessing-$_selectedOcrIndex-${_selectedOcrSettings.ocrPreprocessingMode}',
                  ),
                  initialValue: _subtitleSettings.ocrPreprocessingModeFor(
                    _selectedOcrIndex,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr("OCR {0} görüntü ön işlemesi", [
                      _selectedOcrIndex + 1,
                    ]),
                    filled: true,
                    fillColor: const Color(0xFF0B1324),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF26364D)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF26364D)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(context.tr("Ham görüntü")),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text(context.tr("Gri tonlama + kontrast")),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(context.tr("Adaptif eşikleme")),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text(context.tr("Kenar keskinleştirme")),
                    ),
                    DropdownMenuItem(
                      value: 4,
                      child: Text(context.tr("Yerel kontrast (ışık/parlama)")),
                    ),
                    DropdownMenuItem(
                      value: 5,
                      child: Text(context.tr("Hassas eşik · açık yazı")),
                    ),
                    DropdownMenuItem(
                      value: 6,
                      child: Text(context.tr("Hassas eşik · koyu yazı")),
                    ),
                    DropdownMenuItem(
                      value: 7,
                      child: Text(context.tr("Hassas eşik · otomatik yön")),
                    ),
                    DropdownMenuItem(
                      value: 8,
                      child: Text(context.tr("Sarı yazı · mavi/soğuk zemin")),
                    ),
                    DropdownMenuItem(
                      value: 9,
                      child: Text(context.tr("Otomatik renk kanalı")),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updateSelectedOcrSettings(
                        _selectedOcrSettings.copyWith(
                          ocrPreprocessingMode: value,
                        ),
                      );
                    }
                  },
                ),
              ),
              _settingInfoButton(
                context.tr("OCR görüntü ön işlemesi"),
                context.tr(
                  "Yalnızca seçili OCR kırpımına uygulanır. Otomatik renk kanalı her karede kırpımdaki RGB kanallarının kontrastını ölçüp o sahnede en çok ayrım sağlayanı seçer; farklı yazı ve arka plan renklerine uyum sağlamayı dener. Sarı yazı seçeneği yalnızca sarı yazı/mavi-soğuk zemin içindir.",
                ),
              ),
            ],
          ),
        ),
        _settingsCard(
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: DropdownButtonFormField<double>(
                  key: ValueKey(
                    'ocr-scale-$_selectedOcrIndex-${_selectedOcrSettings.ocrCaptureScale}',
                  ),
                  initialValue: _selectedOcrSettings.ocrCaptureScale,
                  decoration: InputDecoration(
                    labelText: context.tr("OCR alanı büyütme"),
                    filled: true,
                    fillColor: const Color(0xFF0B1324),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF26364D)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF26364D)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 1,
                      child: Text(context.tr("1× · hızlı")),
                    ),
                    DropdownMenuItem(value: 1.5, child: Text('1,5× · dengeli')),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(context.tr("2× · küçük yazı")),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updateSelectedOcrSettings(
                        _selectedOcrSettings.copyWith(ocrCaptureScale: value),
                      );
                    }
                  },
                ),
              ),
              _settingInfoButton(
                context.tr("OCR alanı büyütme"),
                context.tr(
                  "Ölçek uygulamadan seçilir ve yalnızca OCR kırpımına uygulanır; oyun görüntüsü değişmez. 1× en hızlısı, 1,5× genelde dengeli seçim, 2× küçük karakterler içindir. 1600 piksel genişlik sınırı korunur.",
                ),
              ),
            ],
          ),
        ),
        _sliderSetting(
          label: context.tr("OCR alanı boş kalırsa tut: {0} sn", [
            _selectedOcrSettings.holdSeconds.toStringAsFixed(1),
          ]),
          value: _selectedOcrSettings.holdSeconds,
          min: 0,
          max: 10,
          divisions: 20,
          onChanged: (value) => _updateSelectedOcrSettings(
            _selectedOcrSettings.copyWith(holdSeconds: value),
          ),
        ),
        _sliderSetting(
          label: context.tr("Metin yenilenmezse gizle: {0} sn", [
            _selectedOcrSettings.autoHideAfterSeconds.toStringAsFixed(1),
          ]),
          value: _selectedOcrSettings.autoHideAfterSeconds,
          min: 0.5,
          max: 30,
          divisions: 59,
          onChanged: (value) => _updateSelectedOcrSettings(
            _selectedOcrSettings.copyWith(autoHideAfterSeconds: value),
          ),
          info: context.tr(
            "OCR alanında yeni metin algılanmazsa altyazı seçtiğin süre sonunda gizlenir.",
          ),
        ),
      ],
      // Subtitle look and size belong to the subtitle position mode only.
      if (_editingSubtitleBounds) ...[
        // The over-the-English subtitle has no fixed box to size.
        if (!_subtitleBoxLocked) ...[
          _sliderSetting(
            label: context.tr("Altyazı {0} genişliği: {1}%", [
              _selectedSubtitleIndex + 1,
              (_selectedSubtitleBounds.width * 100).round(),
            ]),
            value: _selectedSubtitleBounds.width.clamp(0.10, 1.0).toDouble(),
            min: 0.10,
            max: 1,
            divisions: 180,
            onChanged: (value) {
              final bounds = _selectedSubtitleBounds;
              final width = value.clamp(0.10, 1.0).toDouble();
              _updateSelectedSubtitleRegion(
                NormalizedRect(
                  left: bounds.left.clamp(0.0, 1.0 - width).toDouble(),
                  top: bounds.top,
                  width: width,
                  height: bounds.height,
                ),
              );
            },
          ),
          _sliderSetting(
            label: context.tr("Altyazı {0} yüksekliği: {1}%", [
              _selectedSubtitleIndex + 1,
              (_selectedSubtitleBounds.height * 100).round(),
            ]),
            value: _selectedSubtitleBounds.height.clamp(0.05, 0.70).toDouble(),
            min: 0.05,
            max: 0.70,
            divisions: 130,
            onChanged: (value) {
              final bounds = _selectedSubtitleBounds;
              final height = value.clamp(0.05, 0.70).toDouble();
              _updateSelectedSubtitleRegion(
                NormalizedRect(
                  left: bounds.left,
                  top: bounds.top.clamp(0.0, 1.0 - height).toDouble(),
                  width: bounds.width,
                  height: height,
                ),
              );
            },
          ),
        ],
        _sliderSetting(
          label: context.tr("Yazı boyutu: {0}", [
            _selectedSubtitleSettings.fontSize.toStringAsFixed(1),
          ]),
          value: _selectedSubtitleSettings.fontSize,
          min: 4,
          max: 64,
          divisions: 120,
          onChanged: (value) => _updateSelectedSubtitleSettings(
            _selectedSubtitleSettings.copyWith(fontSize: value),
          ),
        ),
        _settingsCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr("Yazı tipi")),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const ValueKey('subtitle-font-game'),
                    label: Text(context.tr("Oyun fontu")),
                    selected: _selectedSubtitleSettings.useGameFont,
                    onSelected: (_) => _updateSelectedSubtitleSettings(
                      _selectedSubtitleSettings.copyWith(useGameFont: true),
                    ),
                  ),
                  ChoiceChip(
                    key: const ValueKey('subtitle-font-system'),
                    label: Text(context.tr("Sistem fontu")),
                    selected: !_selectedSubtitleSettings.useGameFont,
                    onSelected: (_) => _updateSelectedSubtitleSettings(
                      _selectedSubtitleSettings.copyWith(useGameFont: false),
                    ),
                  ),
                ],
              ),
              Text(
                context.tr(
                  "Oyun fontu yoksa sistem fontu kullanılır. Diğer görünüm ve konum ayarların korunur.",
                ),
                style: const TextStyle(fontSize: 12, color: Color(0xFF929DB4)),
              ),
            ],
          ),
        ),
        _sliderSetting(
          label: context.tr("Arka plan saydamlığı: {0}%", [
            ((1 - _selectedSubtitleSettings.backgroundOpacity) * 100).round(),
          ]),
          value: 1 - _selectedSubtitleSettings.backgroundOpacity,
          min: 0,
          max: 1,
          divisions: 100,
          onChanged: (value) {
            _updateSelectedSubtitleSettings(
              _selectedSubtitleSettings.copyWith(backgroundOpacity: 1 - value),
            );
          },
          info: context.tr(
            "Saydamlık %0 iken arka plan tamamen opaktır. Saydamlık %100 iken arka plan tamamen görünmez olur.",
          ),
        ),
        _settingsCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_subtitleBoxLocked) ...[
                const SizedBox(height: 6),
                Text(context.tr("Arka plan kutusu")),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      label: Text(context.tr("Yalnızca yazı kadar")),
                      selected: _selectedSubtitleSettings.backgroundFitToText,
                      onSelected: (_) => _updateSelectedSubtitleSettings(
                        _selectedSubtitleSettings.copyWith(
                          backgroundFitToText: true,
                        ),
                      ),
                    ),
                    ChoiceChip(
                      label: Text(context.tr("Seçili alanı doldur")),
                      selected: !_selectedSubtitleSettings.backgroundFitToText,
                      onSelected: (_) {
                        setState(() => _editingSubtitleBounds = true);
                        _updateSelectedSubtitleSettings(
                          _selectedSubtitleSettings.copyWith(
                            backgroundFitToText: false,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedSubtitleSettings.backgroundFitToText
                      ? context.tr("Arka plan yazıyla birlikte büyüyüp küçülür.")
                      : context.tr(
                          "Arka plan turkuaz alanın tamamını doldurur. Kutuyu sürükleyebilir, kenarlarından boyutlandırabilir veya alan ayarlarını kullanabilirsin.",
                        ),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF929DB4)),
                ),
                if (!_selectedSubtitleSettings.backgroundFitToText)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _editingSubtitleBounds = true);
                      final target = _rectangleControlsKey.currentContext;
                      if (target != null) {
                        Scrollable.ensureVisible(
                          target,
                          duration: const Duration(milliseconds: 250),
                        );
                      }
                    },
                    icon: const Icon(Icons.crop_free),
                    label: Text(context.tr("Arka plan alanını ayarla")),
                  ),
              ],
              const SizedBox(height: 6),
              Text(context.tr("Arka plan rengi")),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final color in const [
                    Color(0xB3000000),
                    Color(0xB3333333),
                    Color(0xB31B5E20),
                    Color(0xB38E2400),
                    Color(0xB300315B),
                    Color(0xB34A148C),
                    Color(0xB3AD1457),
                    Color(0xB3F9A825),
                  ])
                    _colorChoice(
                      color: color,
                      selected:
                          (Color(
                                _selectedSubtitleSettings.backgroundColor,
                              ).toARGB32() &
                              0x00FFFFFF) ==
                          (color.toARGB32() & 0x00FFFFFF),
                      onTap: () => _updateSelectedSubtitleSettings(
                        _selectedSubtitleSettings.copyWith(
                          backgroundColor: color.toARGB32(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _chooseBackgroundColor,
                  icon: Icon(
                    Icons.palette_outlined,
                    color: Color(
                      _selectedSubtitleSettings.effectiveBackgroundColor,
                    ),
                  ),
                  label: Text(context.tr("Özel arka plan rengi seç")),
                ),
              ),
              const SizedBox(height: 8),
              Text(context.tr("Yazı rengi")),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final color in const [
                    Colors.white,
                    Color(0xFFFFEB3B),
                    Color(0xFF80DEEA),
                    Color(0xFFA5D6A7),
                    Color(0xFFFFAB91),
                    Color(0xFFCE93D8),
                    Color(0xFF212121),
                  ])
                    _textColorChoice(color),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _chooseTextColor,
                  icon: Icon(
                    Icons.color_lens_outlined,
                    color: Color(_selectedSubtitleSettings.textColor),
                  ),
                  label: Text(
                    context.tr("Özel yazı rengi seç · #{0}", [
                      _selectedSubtitleSettings.textColor
                          .toRadixString(16)
                          .padLeft(8, '0')
                          .substring(2)
                          .toUpperCase(),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(context.tr("Hizalama ve kalınlık")),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _formatChoice(
                    label: _selectedSubtitleSettings.centered
                        ? context.tr("Ortala")
                        : context.tr("Sola hizala"),
                    icon: _selectedSubtitleSettings.centered
                        ? Icons.format_align_center
                        : Icons.format_align_left,
                    onTap: () => _updateSelectedSubtitleSettings(
                      _selectedSubtitleSettings.copyWith(
                        centered: !_selectedSubtitleSettings.centered,
                      ),
                    ),
                  ),
                  _formatChoice(
                    label: _selectedSubtitleSettings.bold
                        ? context.tr("Kalın")
                        : context.tr("Normal"),
                    icon: Icons.format_bold,
                    selected: _selectedSubtitleSettings.bold,
                    onTap: () => _updateSelectedSubtitleSettings(
                      _selectedSubtitleSettings.copyWith(
                        bold: !_selectedSubtitleSettings.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ],
  );

  Widget _areaModeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onPressed,
  }) => selected
      ? FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: FilledButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.85),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        )
      : OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: color),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: color.withValues(alpha: 0.75)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        );

  Widget _textColorChoice(Color color) {
    final selected =
        (Color(_selectedSubtitleSettings.textColor).toARGB32() & 0x00FFFFFF) ==
        (color.toARGB32() & 0x00FFFFFF);
    return InkWell(
      onTap: () => _updateSelectedSubtitleSettings(
        _selectedSubtitleSettings.copyWith(textColor: color.toARGB32()),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Tooltip(
        message:
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.white38,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  size: 18,
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _chooseTextColor() async {
    final color = await _pickSubtitleColor(
      Color(_selectedSubtitleSettings.textColor),
    );
    if (color == null || !mounted) return;
    _updateSelectedSubtitleSettings(
      _selectedSubtitleSettings.copyWith(textColor: color.toARGB32()),
    );
  }

  Future<void> _chooseBackgroundColor() async {
    final current = Color(_selectedSubtitleSettings.effectiveBackgroundColor);
    final color = await _pickSubtitleColor(current);
    if (color == null || !mounted) return;
    _updateSelectedSubtitleSettings(
      _selectedSubtitleSettings.copyWith(backgroundColor: color.toARGB32()),
    );
  }

  Future<Color?> _pickSubtitleColor(Color initial) async {
    var hsv = HSVColor.fromColor(initial);
    return showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171D30),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr("Renk seç · #{0}", [
                    hsv
                        .toColor()
                        .toARGB32()
                        .toRadixString(16)
                        .padLeft(8, '0')
                        .substring(2)
                        .toUpperCase(),
                  ]),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: hsv.toColor(),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 14),
                _hsvSlider(
                  label: context.tr("Ton"),
                  value: hsv.hue,
                  min: 0,
                  max: 360,
                  color: hsv.toColor(),
                  onChanged: (value) =>
                      setSheetState(() => hsv = hsv.withHue(value)),
                ),
                _hsvSlider(
                  label: context.tr("Doygunluk"),
                  value: hsv.saturation,
                  min: 0,
                  max: 1,
                  color: hsv.toColor(),
                  onChanged: (value) =>
                      setSheetState(() => hsv = hsv.withSaturation(value)),
                ),
                _hsvSlider(
                  label: context.tr("Parlaklık"),
                  value: hsv.value,
                  min: 0,
                  max: 1,
                  color: hsv.toColor(),
                  onChanged: (value) =>
                      setSheetState(() => hsv = hsv.withValue(value)),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, hsv.toColor()),
                  icon: const Icon(Icons.check),
                  label: Text(context.tr("Rengi uygula")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hsvSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label: ${value.toStringAsFixed(2)}'),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        activeColor: color,
        onChanged: onChanged,
      ),
    ],
  );

  Widget _colorChoice({
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: _selectedSubtitleSettings.backgroundOpacity,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : Colors.white54,
          width: selected ? 3 : 1,
        ),
      ),
      child: selected ? const Icon(Icons.check, size: 18) : null,
    ),
  );

  Widget _formatChoice({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool selected = false,
  }) => ActionChip(
    avatar: Icon(icon, size: 18, color: color),
    label: Text(label),
    onPressed: onTap,
    backgroundColor: selected
        ? Theme.of(context).colorScheme.primaryContainer
        : null,
  );

  Widget _settingsCard(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
    decoration: BoxDecoration(
      color: const Color(0xFF121D30),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFF26364D)),
    ),
    child: child,
  );

  Widget _sliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? info,
  }) => _settingsCard(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD8E1F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (info != null) _settingInfoButton(label, info),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF36D6BE),
            inactiveTrackColor: const Color(0xFF36D6BE).withValues(alpha: 0.18),
            thumbColor: const Color(0xFF36D6BE),
            overlayColor: const Color(0xFF36D6BE).withValues(alpha: 0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );

  Widget _settingInfoButton(String title, String message) => IconButton(
    tooltip: 'Bilgi: $title',
    visualDensity: VisualDensity.compact,
    icon: const Icon(Icons.info_outline, size: 20),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr("Anladım")),
          ),
        ],
      ),
    ),
  );

  Future<void> _connect() async {
    if (_starting || _stopping || _reconnectTimer != null) return;
    _manualDisconnectRequested = false;
    // The native Chiaki session outlives this Flutter route. Reuse it when
    // the user returns instead of trying to create a second session.
    try {
      final state = await _ps5Channel.invokeMapMethod<String, dynamic>(
        'getSessionState',
      );
      if (!mounted) return;
      if (state?['active'] == true) {
        final sessionConnected = state?['connected'] == true;
        final videoReady = state?['videoReady'] == true;
        final connected = sessionConnected && videoReady;
        setState(() {
          _sessionActive = true;
          _remotePlaySessionConnected = sessionConnected;
          _remotePlayVideoReady = videoReady;
          _remotePlayConnected = connected;
          _starting = !sessionConnected;
          _status = connected
              ? "Bağlandı"
              : sessionConnected
              ? "Görüntü yenileniyor…"
              : "PS5’e bağlanıyor…";
          _error = null;
        });
        if (sessionConnected) _hasConnectedThisScreen = true;
        if (connected) _returnHomeAfterTranslationStarts();
        return;
      }
    } on PlatformException {
      // Older native builds can still fall through to startSession.
    }
    setState(() {
      _starting = true;
      _status = "Görüntü alanı hazırlanıyor…";
      _error = null;
    });
    try {
      final surfaceReady = await _waitForVideoSurface();
      if (!mounted) return;
      if (!surfaceReady) {
        setState(() {
          _starting = false;
          _hidePreviewDuringAutoStart = false;
          _status = "Görüntü alanı hazır değil";
          _error =
              "Remote Play görüntüsü oluşturulamadı. Ekranı yenileyip tekrar dene.";
        });
        return;
      }
      setState(() => _status = "PS5’e bağlanıyor…");
      await _ps5Channel.invokeMethod<bool>('startSession');
    } on PlatformException catch (error) {
      if (!mounted) return;
      final shouldRetry =
          (_hasConnectedThisScreen || _starting) &&
          !_manualDisconnectRequested &&
          _reconnectAttempt < 4;
      setState(() {
        _starting = false;
        _hidePreviewDuringAutoStart = false;
        _status = "Bağlantı başlatılamadı";
        _error = error.message ?? error.code;
      });
      if (shouldRetry) {
        _scheduleReconnect(initialFailure: !_hasConnectedThisScreen);
      }
    }
  }

  Future<bool> _waitForVideoSurface() async {
    for (var attempt = 0; attempt < 60; attempt++) {
      if (!mounted) return false;
      try {
        if (await _ps5Channel.invokeMethod<bool>('isVideoSurfaceReady') ==
            true) {
          return true;
        }
      } on PlatformException {
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return false;
  }

  void _scheduleReconnect({bool initialFailure = false, int? minimumSeconds}) {
    if (_reconnectTimer != null || _manualDisconnectRequested || !mounted) {
      return;
    }
    final attempt = ++_reconnectAttempt;
    var seconds = initialFailure ? attempt * 20 : attempt * 4;
    if (minimumSeconds != null && seconds < minimumSeconds) {
      seconds = minimumSeconds;
    }
    setState(() {
      _status =
          "Remote Play yeniden bağlanıyor… $seconds sn. Lütfen bekleyin ($attempt/4)";
    });
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      if (mounted && !_manualDisconnectRequested && !_sessionActive) {
        _connect();
      }
    });
  }

  Future<bool> _disconnect() {
    final existing = _disconnectFuture;
    if (existing != null) return existing;
    final operation = _performDisconnect();
    _disconnectFuture = operation;
    return operation.whenComplete(() {
      if (identical(_disconnectFuture, operation)) _disconnectFuture = null;
    });
  }

  Future<bool> _performDisconnect() async {
    _manualDisconnectRequested = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    setState(() {
      _stopping = true;
      _status = "PS5 bağlantısı kapatılıyor…";
      _error = null;
    });
    try {
      await _persistSubtitleSettings();
      await _ps5Channel.invokeMethod<bool>('stopSession');
      if (!mounted) return true;
      setState(() {
        _sessionActive = false;
        _remotePlaySessionConnected = false;
        _remotePlayVideoReady = false;
        _remotePlayConnected = false;
        _starting = false;
        _stopping = false;
        _status = "Bağlantı kesildi";
      });
      return true;
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _stopping = false;
          _error = error.message ?? error.code;
        });
      }
      return false;
    }
  }

  Future<void> _stopTranslationAndExit() async {
    final stopped = await _disconnect();
    if (!stopped || !mounted) return;
    _tvSubtitleClient.updateSubtitle('', _subtitleSettings);
    setState(() {
      _subtitleTexts = <String>[];
      _clearCovers();
      _subtitleRich = <int, SubtitleRichText>{};
    });
    _allowExitAfterTranslationStop = true;
    Navigator.of(context).pop(true);
  }

  Future<void> _disconnectAndForgetConsole() async {
    _manualDisconnectRequested = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    setState(() {
      _forgettingConsole = true;
      _error = null;
    });
    try {
      await _ps5Channel.invokeMethod<bool>('deleteSavedConsole');
      if (mounted) Navigator.of(context).pop();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _forgettingConsole = false;
          _error = error.message ?? error.code;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _runtimeSettingsTimer?.cancel();
    // Flush before leaving even if the slider's debounce has not elapsed.
    unawaited(_persistSubtitleSettings());
    _eventsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop:
          !widget.activateSubtitlesOnStart ||
          !_sessionActive ||
          _allowExitAfterTranslationStop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop &&
            widget.activateSubtitlesOnStart &&
            _sessionActive &&
            !_allowExitAfterTranslationStop) {
          unawaited(_showHomeForTranslation());
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF090D18),
        appBar: _pictureInPictureMode || _hidePreviewDuringAutoStart
            ? null
            : AppBar(
                title: _subtitleSettingsVisible
                    ? null
                    : Text(context.tr("PS5 Remote Play")),
                actions: [
                  if (_subtitleSettingsVisible)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        onPressed: _settingsLoaded
                            ? () => _saveSubtitleSettings(closePanel: false)
                            : null,
                        icon: const Icon(Icons.save_outlined, size: 19),
                        label: Text(context.tr("Kaydet")),
                      ),
                    ),
                ],
              ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _pictureInPictureMode
                ? ColoredBox(
                    color: Colors.black,
                    child: SizedBox.expand(child: _buildVideoSurface()),
                  )
                : SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final previewHeight = (constraints.maxHeight * 0.34)
                            .clamp(170.0, 260.0)
                            .toDouble();
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: previewHeight,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(
                                    color: Colors.black,
                                    child: Center(child: _buildVideoSurface()),
                                  ),
                                  if (_mobilePreviewHidden)
                                    ColoredBox(
                                      color: Colors.black,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.closed_caption,
                                              color: Colors.white54,
                                              size: 28,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              context.tr(
                                                "Görüntü gizli • Remote Play ve OCR çalışıyor",
                                              ),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => setState(
                                                () => _mobilePreviewHidden =
                                                    false,
                                              ),
                                              icon: const Icon(
                                                Icons.visibility,
                                              ),
                                              label: Text(
                                                context.tr("Görüntüyü göster"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else if (widget.activateSubtitlesOnStart)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Material(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(18),
                                        child: IconButton(
                                          tooltip: context.tr(
                                            "Mobil görüntüyü gizle",
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => setState(
                                            () => _mobilePreviewHidden = true,
                                          ),
                                          icon: const Icon(
                                            Icons.visibility_off,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_subtitleSettingsVisible)
                              Expanded(
                                child: Material(
                                  color: const Color(0xF0101728),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      18,
                                    ),
                                    child: _buildSubtitleSettings(),
                                  ),
                                ),
                              )
                            else
                              Expanded(child: _buildConnectionControls()),
                          ],
                        );
                      },
                    ),
                  ),
            if (_hidePreviewDuringAutoStart && !_pictureInPictureMode)
              ColoredBox(
                color: Color(0xFF090D18),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        SizedBox(height: 18),
                        Text(
                          context.tr("PS5’e bağlanılıyor"),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          context.tr("Çeviri hazırlanıyor…"),
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: AccessService.instance,
                  builder: (context, child) {
                    final access = AccessService.instance.status;
                    if (access.source != 'free_trial' ||
                        !const ['trial', 'expired'].contains(access.state)) {
                      return const SizedBox.shrink();
                    }
                    return IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            access.state == 'expired'
                                ? context.tr("Deneme bitti")
                                : 'Deneme ${access.remainingLabel}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionControls() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: const Color(0xFF171D30),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF4DE2D0)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(
                      "Ana kullanıcıda oynamak için Remote Play oturumunu açık tut. PS5’e bağlı kumandada PS tuşuna basıp ana kullanıcıyı seç; Remote Play hesabından çıkma veya bağlantıyı kesme.",
                    ),
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.trMessage(_status),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            context.trMessage(_error!),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.orangeAccent),
          ),
        ],
        OutlinedButton.icon(
          onPressed: _openSubtitleSettings,
          icon: const Icon(Icons.closed_caption),
          label: Text(context.tr("Altyazı alanlarını ve ayarlarını aç")),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _stopping || _forgettingConsole || _reconnectTimer != null
              ? null
              : (_starting || _sessionActive
                    ? (widget.activateSubtitlesOnStart
                          ? _stopTranslationAndExit
                          : _disconnect)
                    : _connect),
          icon: _starting || _stopping || _reconnectTimer != null
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_sessionActive ? Icons.link_off : Icons.play_arrow),
          label: Text(
            _stopping
                ? context.tr("Bağlantı kesiliyor…")
                : _starting
                ? context.tr("Bağlantıyı iptal et")
                : _reconnectTimer != null
                ? context.tr("PS5 yeniden denenecek…")
                : (_sessionActive
                      ? (widget.activateSubtitlesOnStart
                            ? context.tr("Çeviriyi durdur")
                            : context.tr("Bağlantıyı kes"))
                      : context.tr("PS5’e bağlan")),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _forgettingConsole ? null : _disconnectAndForgetConsole,
          icon: _forgettingConsole
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: Text(
            _forgettingConsole
                ? context.tr("PS5 kaydı siliniyor…")
                : context.tr("Bağlantıyı kes, kayıtları sil ve çık"),
          ),
        ),
      ],
    ),
  );
}
