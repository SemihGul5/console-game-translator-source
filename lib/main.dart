import 'dart:async';

import 'package:flutter/material.dart';
import 'services/game_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_branding.dart';
import 'l10n/app_language.dart';
import 'l10n/app_localizations.dart';
import 'widgets/game_cover_card.dart';
import 'models/subtitle_settings.dart';
import 'models/game_catalog_entry.dart';
import 'screens/psn_login_screen.dart';
import 'screens/ps5_stream_screen.dart';
import 'screens/help_screen.dart';
import 'screens/setup_guide_screen.dart';
import 'services/subtitle_settings_store.dart';
import 'services/game_translation_catalog.dart';
import 'services/game_library_search.dart';
import 'services/app_links.dart';
import 'services/tv_output_service.dart';
import 'widgets/smart_tv_setup_dialog.dart';
import 'widgets/tv_platform_selector.dart';
import 'services/access_service.dart';
import 'screens/access_screen.dart';
import 'screens/profile_tab.dart';
import 'widgets/settings_section.dart';
import 'widgets/setup_notice.dart';
import 'widgets/premium_status_button.dart';
import 'services/deepl_languages.dart';
import 'widgets/deepl_settings_panel.dart';
import 'widgets/gemini_settings_panel.dart';
import 'widgets/subscription_offer_card.dart';

void main() {
  runApp(const GameTranslateApp());
}

const bg = Color(0xFF090D18);
const panel = Color(0xFF131A2B);
const purple = Color(0xFF0070D1);
const cyan = Color(0xFF4DE2D0);
const muted = Color(0xFF929DB4);

class GameTranslateApp extends StatefulWidget {
  const GameTranslateApp({super.key, this.gameCatalog});
  final GameTranslationCatalog? gameCatalog;

  @override
  State<GameTranslateApp> createState() => _GameTranslateAppState();
}

class _GameTranslateAppState extends State<GameTranslateApp>
    with WidgetsBindingObserver {
  String _languagePreference = 'system';
  bool _languageReady = false;
  bool _changingLanguage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final preference = await const AppLanguagePreferences().load();
    if (!mounted) return;
    setState(() {
      _languagePreference = preference;
      _languageReady = true;
    });
  }

  Future<void> _changeLanguage(String preference) async {
    if (_changingLanguage || preference == _languagePreference) return;
    setState(() => _changingLanguage = true);
    try {
      await const AppLanguagePreferences().save(preference);
      if (mounted) setState(() => _languagePreference = preference);
    } finally {
      if (mounted) setState(() => _changingLanguage = false);
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final systemLocale =
        WidgetsBinding.instance.platformDispatcher.locales.firstOrNull ??
        const Locale('en');
    return AppLanguageScope(
      systemLocale: systemLocale,
      preference: _languagePreference,
      ready: _languageReady,
      changing: _changingLanguage,
      onChanged: _changeLanguage,
      child: MaterialApp(
        locale: AppLanguage.localeFor(_languagePreference, systemLocale),
        debugShowCheckedModeBanner: false,
        onGenerateTitle: AppBranding.nameOf,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLanguage.supportedLocales,
        localeResolutionCallback: AppBranding.resolveLocale,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: purple,
            brightness: Brightness.dark,
          ),
          fontFamily: 'Roboto',
        ),
        home: _SplashGate(gameCatalog: widget.gameCatalog),
      ),
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate({this.gameCatalog});
  final GameTranslationCatalog? gameCatalog;

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1050), () {
      if (mounted) setState(() => _showHome = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 280),
    child: _showHome
        ? HomeScreen(gameCatalog: widget.gameCatalog)
        : const _BrandSplash(),
  );
}

class _BrandSplash extends StatelessWidget {
  const _BrandSplash();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF001028),
    body: Stack(
      children: [
        Positioned(
          top: -160,
          right: -130,
          child: Container(
            width: 390,
            height: 390,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF147BFF).withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -220,
          left: -120,
          child: Container(
            width: 440,
            height: 440,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2769D8).withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape =
                  MediaQuery.sizeOf(context).width >
                  MediaQuery.sizeOf(context).height;
              final mark = Container(
                width: landscape ? 150 : 174,
                height: landscape ? 150 : 174,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1682FF).withValues(alpha: 0.3),
                      blurRadius: 48,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  AppBranding.iconOf(context),
                  fit: BoxFit.cover,
                ),
              );
              final branding = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: landscape
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Text(
                    AppBranding.nameOf(context),
                    textAlign: landscape ? TextAlign.start : TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    context.tr("Oyununu kendi dilinde yaşa"),
                    textAlign: landscape ? TextAlign.start : TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB9CAE4),
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 27),
                  SizedBox(
                    width: landscape ? 210 : 190,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Color(0xFF1D3558),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF62B8FF),
                        ),
                      ),
                    ),
                  ),
                ],
              );
              return landscape
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        mark,
                        const SizedBox(width: 34),
                        Flexible(child: branding),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [mark, const SizedBox(height: 28), branding],
                    );
            },
          ),
        ),
      ],
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.showSubtitleSetupPrompt = false,
    this.translationRunningOnOpen = false,
    this.gameCatalog,
  });

  final bool showSubtitleSetupPrompt;
  final bool translationRunningOnOpen;
  final GameTranslationCatalog? gameCatalog;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _LocalLanguageOption {
  const _LocalLanguageOption({
    required this.code,
    required this.name,
    required this.downloaded,
  });
  final String code;
  final String name;
  final bool downloaded;
}

enum _AppTab { subtitles, home, profile }

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _ps5Channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );

  _AppTab _selectedTab = _AppTab.home;
  final Set<_AppTab> _visitedTabs = {_AppTab.home};

  Map<String, dynamic>? _savedPs5;
  late final GameTranslationCatalog _gameCatalog =
      widget.gameCatalog ?? GameTranslationCatalog();
  List<GameCatalogEntry> _games = const [];
  final _gameSearchController = TextEditingController();
  final _gameLibraryHeaderKey = GlobalKey();
  bool _loadingGames = true;
  bool _refreshingGames = false;
  bool _gamesRefreshStarted = false;
  bool _gamesRefreshFailed = false;
  Timer? _gameRefreshCooldownTimer;
  String? _gamesError;
  String? _selectedGameId;
  String _libraryTargetLanguage = 'tr';
  bool _selectingGame = false;
  bool _gameMemoryLoading = false;
  String? _gameMemoryError;
  String? _appliedGameContentKey;
  int _gameSelectionGeneration = 0;
  Future<void> _gameMemoryLoadFuture = Future<void>.value();
  bool _loadingPs5 = true;
  bool _openingPs5 = false;
  bool _waitingForGameMemory = false;
  bool _remotePlayActive = false;
  bool _remotePlaySessionConnected = false;
  bool _remotePlayVideoReady = false;
  bool _remotePlayConnected = false;
  bool _translationRunning = false;
  Timer? _translationStateTimer;
  List<bool> _setupGuideChecklist = List<bool>.filled(
    SetupGuideScreen.totalSteps,
    false,
  );
  bool _setupWarningOpen = false;
  bool _refreshingAccess = false;

  String sourceLanguageCode = 'en';
  String targetLanguageCode = 'tr';
  SubtitleSettings _translationSettings = const SubtitleSettings();
  List<TranslationLanguageModel> _translationModels = const [];
  bool _loadingTranslationModels = true;
  String? _translationModelsError;
  String _translationEngine = SubtitleSettingsStore.defaultTranslationEngine;
  bool _translationPreferencesReady = false;
  bool _changingAppLanguage = false;
  String? _lastInterfaceLanguage;
  Future<void> _modelBLanguageUpdate = Future<void>.value();
  int _translationEngineDropdownRevision = 0;
  bool _deepLConfigured = false;
  bool _geminiConfigured = false;
  List<TranslationLanguageModel> _deepLSourceLanguages = deepLSourceLanguages;
  List<TranslationLanguageModel> _deepLTargetLanguages = deepLTargetLanguages;
  String? _deepLLanguagesError;
  bool _opusModelInstalled = false;
  bool _hpltModelInstalled = false;
  String _offlineTarget = 'tr';
  List<Map<String, dynamic>> _offlineModels = const [];
  bool _opusDownloading = false;
  bool _hpltDownloading = false;
  final Set<String> _downloadingLanguageCodes = <String>{};
  bool _tvPairing = false;
  bool _tvConnecting = false;
  String? _savedTvAddress;
  bool _hasSavedTvPairing = false;
  bool _loadingTvAddress = true;
  StreamSubscription<TvSubtitleConnectionState>? _tvStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AccessService.instance.addListener(_accessChanged);
    unawaited(_refreshAccessStatus());
    _translationRunning = widget.translationRunningOnOpen;
    if (widget.translationRunningOnOpen) {
      _translationStateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!_translationRunning) {
          _translationStateTimer?.cancel();
          _translationStateTimer = null;
          return;
        }
        unawaited(_refreshTranslationState());
      });
    }
    if (widget.showSubtitleSetupPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_showSubtitleSetupPrompt());
      });
    }
    _refreshTranslationState();
    _gameMemoryLoadFuture = _loadGamesAndSelectedGame();
    _loadSavedPs5();
    _initializeTranslationPreferences();
    _loadTranslationModels();
    _loadTvPairingAddress();
    _loadSetupGuideChecklist();
    _tvPairing = TvOutputService.instance.isConnected;
    _tvConnecting = TvOutputService.instance.isConnecting;
    _tvStatusSubscription = TvOutputService.instance.connectionStateChanges
        .listen((connectionState) {
          if (mounted) {
            setState(() {
              _tvPairing =
                  connectionState == TvSubtitleConnectionState.connected;
              _tvConnecting =
                  connectionState == TvSubtitleConnectionState.connecting;
              if (_tvPairing) {
                _savedTvAddress = TvOutputService.instance.address;
                _hasSavedTvPairing = true;
              }
            });
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppLanguageScope.maybeOf(context);
    if (scope == null || !scope.ready) return;
    final language = scope.interfaceLocale.languageCode;
    if (_lastInterfaceLanguage == language) return;
    _lastInterfaceLanguage = language;
    if (_translationPreferencesReady && !_changingAppLanguage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_syncModelBLanguage(language).catchError((_) {}));
        }
      });
    }
  }

  Future<void> _initializeTranslationPreferences() async {
    await _loadTranslationEngine();
    await _loadTranslationPreferences();
    if (!mounted) return;
    setState(() => _translationPreferencesReady = true);
    final scope = AppLanguageScope.maybeOf(context);
    if (scope?.ready == true) {
      await _syncModelBLanguage(
        scope!.interfaceLocale.languageCode,
      ).catchError((_) {});
    }
  }

  SubtitleSettings _modelBSettings(SubtitleSettings settings, String target) {
    var source = settings.sourceLanguageCode.split('-').first;
    if (source == target) source = target == 'en' ? 'tr' : 'en';
    return settings.copyWith(
      sourceLanguageCode: source,
      targetLanguageCode: target,
    );
  }

  Future<void> _syncModelBLanguage(String language) {
    final operation = _modelBLanguageUpdate.then((_) async {
      if (!mounted || _translationEngine != 'mlkit') return;
      if (await _isTranslationActive()) return;
      final store = const SubtitleSettingsStore();
      final settings = await store.load();
      if (!mounted || _translationEngine != 'mlkit') return;
      final updated = _modelBSettings(settings, language);
      if (settings.sourceLanguageCode != updated.sourceLanguageCode ||
          settings.targetLanguageCode != updated.targetLanguageCode) {
        await store.save(updated);
      }
      if (!mounted) return;
      setState(() {
        _translationSettings = updated;
        sourceLanguageCode = updated.sourceLanguageCode;
        targetLanguageCode = updated.targetLanguageCode;
        if (_translationModelsError == 'Dil seçilemedi') {
          _translationModelsError = null;
        }
      });
    });
    _modelBLanguageUpdate = operation.catchError((Object error) {
      if (mounted) {
        setState(() => _translationModelsError = 'Dil seçilemedi');
      }
    });
    return operation;
  }

  Future<void> _changeAppLanguage(String preference) async {
    final scope = AppLanguageScope.maybeOf(context);
    if (scope?.onChanged == null ||
        scope?.ready != true ||
        !_translationPreferencesReady ||
        _changingAppLanguage) {
      return;
    }
    if (_openingPs5 || _selectingGame || await _isTranslationActive()) {
      if (mounted) {
        showMessage(
          'Dil değiştirilemez',
          'Dili veya oyunu değiştirmek için çeviriyi durdur.',
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _changingAppLanguage = true);
    var preferenceSaved = false;
    try {
      await scope!.onChanged!(preference);
      preferenceSaved = true;
      if (!mounted) return;
      final language = AppLanguage.localeFor(
        preference,
        scope.systemLocale,
      ).languageCode;
      _lastInterfaceLanguage = language;
      await _syncModelBLanguage(language);
    } catch (_) {
      if (preferenceSaved && mounted) {
        try {
          await scope!.onChanged!(scope.preference);
          _lastInterfaceLanguage = scope.interfaceLocale.languageCode;
        } catch (_) {
          // The storage error is reported below even if rollback also fails.
        }
      }
      if (mounted) {
        showMessage(
          'Ayar kaydedilemedi',
          'Dil tercihi kaydedilemedi. Tekrar dene.',
        );
      }
    } finally {
      if (mounted) setState(() => _changingAppLanguage = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSavedPs5();
      _refreshTranslationState();
      if (_selectedTab == _AppTab.home &&
          ModalRoute.of(context)?.isCurrent == true) {
        unawaited(_refreshAccessStatus());
      }
      unawaited(TvOutputService.instance.retrySavedPairing());
    }
  }

  Future<void> _loadTranslationEngine() async {
    try {
      final store = const SubtitleSettingsStore();
      final values = await Future.wait([
        store.loadTranslationEngine(),
        store.isOpusModelInstalled(),
        store.loadOfflineTranslationModels(),
        store.isHpltModelInstalled(),
        store.hasDeepLApiKey().catchError((_) => false),
        store.hasGeminiApiKey().catchError((_) => false),
      ]);
      if (!mounted) return;
      setState(() {
        final savedEngine = values[0] as String;
        _translationEngine =
            const {'mlkit', 'opus', 'deepl', 'gemini'}.contains(savedEngine)
            ? savedEngine
            : SubtitleSettingsStore.defaultTranslationEngine;
        _opusModelInstalled = values[1] as bool;
        _offlineModels = (values[2] as List<Map<String, dynamic>>);
        _hpltModelInstalled = values[3] as bool;
        _deepLConfigured = values[4] as bool;
        _geminiConfigured = values[5] as bool;
        _offlineTarget =
            (_offlineModels.firstWhere(
                  (model) => model['selected'] == true,
                  orElse: () => <String, dynamic>{'target': 'tr'},
                )['target']
                as String?) ??
            'tr';
      });
      if (_translationEngine == 'deepl' && _deepLConfigured) {
        await _loadDeepLLanguages();
      }
    } catch (_) {
      // Keep Model B selected when the native preference cannot be read.
    }
  }

  Future<void> _downloadOpusModel() async {
    await _downloadOfflineTarget(_offlineTarget);
  }

  Future<void> _downloadHpltModel() async {
    if (mounted) setState(() => _hpltDownloading = true);
    try {
      await const SubtitleSettingsStore().downloadHpltModel();
      await _loadTranslationEngine();
      if (mounted) {
        showMessage(
          "Model C hazır",
          "HPLT İngilizce → Türkçe paketi çevrimdışı kullanıma hazır.",
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        showMessage(
          "Model C indirilemedi",
          error.message ?? "İnternet bağlantını kontrol edip tekrar dene.",
        );
      }
    } finally {
      if (mounted) setState(() => _hpltDownloading = false);
    }
  }

  Future<void> _downloadOfflineTarget(String target) async {
    await _selectOfflineTarget(target);
    setState(() => _opusDownloading = true);
    try {
      await const SubtitleSettingsStore().downloadOpusModel(target);
      await _loadTranslationEngine();
      if (mounted) {
        showMessage(
          "Dil paketi hazır",
          "Seçilen hedef dil çevrimdışı kullanıma hazır.",
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {});
        showMessage(
          "Model indirilemedi",
          error.message ?? "İnternet bağlantını kontrol et.",
        );
      }
    } finally {
      if (mounted) setState(() => _opusDownloading = false);
    }
  }

  Future<void> _selectOfflineTarget(String target) async {
    final store = const SubtitleSettingsStore();
    try {
      final models = await store.selectOfflineTranslationTarget(target);
      final settings = await store.load();
      final updated = settings.copyWith(
        sourceLanguageCode: 'en',
        targetLanguageCode: target,
      );
      await store.save(updated);
      if (!mounted) return;
      setState(() {
        _offlineTarget = target;
        _offlineModels = models;
        _translationSettings = updated;
        sourceLanguageCode = 'en';
        targetLanguageCode = target;
        _opusModelInstalled = models.any(
          (model) => model['target'] == target && model['installed'] == true,
        );
      });
    } on PlatformException catch (error) {
      if (mounted) {
        showMessage("Dil seçilemedi", error.message ?? "Tekrar dene.");
      }
    }
  }

  Future<void> _selectTranslationEngine(String engine) async {
    if (engine == _translationEngine) return;
    if (await _isTranslationActive()) {
      if (!mounted) return;
      setState(() => _translationEngineDropdownRevision++);
      showMessage(
        "Model değiştirilemez",
        "Çeviri devam ederken model değiştirilemez. Önce çeviriyi durdurup tekrar dene.",
      );
      return;
    }

    try {
      final store = const SubtitleSettingsStore();
      if (engine == 'mlkit') {
        final settings = await store.load();
        if (!mounted) return;
        final language = AppLocalizations.of(context).locale.languageCode;
        await store.save(_modelBSettings(settings, language));
      } else if (engine == 'gemini') {
        final settings = await store.load();
        String supportedCode(String code, String fallback) {
          final base = code.split('-').first;
          return _translationModels.any((model) => model.code == base)
              ? base
              : fallback;
        }

        final source = supportedCode(settings.sourceLanguageCode, 'en');
        var target = supportedCode(settings.targetLanguageCode, 'tr');
        if (source == target) target = source == 'tr' ? 'en' : 'tr';
        await store.save(
          settings.copyWith(
            sourceLanguageCode: source,
            targetLanguageCode: target,
          ),
        );
        await _loadTranslationPreferences();
      }
      if (engine == 'opus') {
        await _selectOfflineTarget(_offlineTarget);
      } else if (engine == 'hplt') {
        final settings = await store.load();
        final updated = settings.copyWith(
          sourceLanguageCode: 'en',
          targetLanguageCode: 'tr',
        );
        await store.save(updated);
        if (mounted) {
          setState(() {
            _translationSettings = updated;
            sourceLanguageCode = 'en';
            targetLanguageCode = 'tr';
          });
        }
      }
      await store.selectTranslationEngine(engine);
      if (mounted) setState(() => _translationEngine = engine);
      if (engine == 'mlkit') await _loadTranslationPreferences();
      if (engine == 'deepl' && _deepLConfigured) await _loadDeepLLanguages();
    } on PlatformException catch (error) {
      if (mounted) {
        showMessage(
          "Motor seçilemedi",
          error.message ?? "Dil çiftine uygun paketi seçip indir.",
        );
      }
    }
  }

  Future<void> _loadDeepLLanguages() async {
    try {
      final store = const SubtitleSettingsStore();
      final languages = await store.loadDeepLLanguages();
      if (!mounted || _translationEngine != 'deepl') return;
      final sources = languages['source']!;
      final targets = languages['target']!;
      if (sources.isEmpty || targets.isEmpty) return;
      final settings = await store.load();
      if (!mounted || _translationEngine != 'deepl') return;
      final selectedGame = _games
          .where((game) => game.id == _selectedGameId)
          .firstOrNull;
      final source =
          selectedGame?.sourceLanguage ??
          (sources.any((row) => row.code == settings.sourceLanguageCode)
              ? settings.sourceLanguageCode
              : 'en');
      var target = selectedGame?.targetLanguage ?? settings.targetLanguageCode;
      if (selectedGame == null && !targets.any((row) => row.code == target)) {
        target = switch (target) {
          'en' => 'en-us',
          'pt' => 'pt-pt',
          'zh' => 'zh-hans',
          _ => 'tr',
        };
      }
      if (selectedGame == null &&
          (!targets.any((row) => row.code == target) ||
              source == target.split('-').first)) {
        target = source == 'tr' ? 'en-us' : 'tr';
      }
      final updated = settings.copyWith(
        sourceLanguageCode: source,
        targetLanguageCode: target,
      );
      if (source != settings.sourceLanguageCode ||
          target != settings.targetLanguageCode) {
        await store.save(updated);
      }
      if (!mounted) return;
      setState(() {
        _deepLSourceLanguages = sources;
        _deepLTargetLanguages = targets;
        _deepLLanguagesError = null;
        _translationSettings = updated;
        sourceLanguageCode = source;
        targetLanguageCode = target;
      });
    } on PlatformException catch (error) {
      if (mounted) setState(() => _deepLLanguagesError = error.message);
    } on MissingPluginException {
      // Older native builds do not expose DeepL language discovery.
    }
  }

  Future<bool> _isTranslationActive() async {
    var active = _translationRunning;
    try {
      active =
          active ||
          await _ps5Channel.invokeMethod<bool>(
                'isTranslationForegroundRunning',
              ) ==
              true;
    } on PlatformException {
      // Use the last known screen state if native service state is unavailable.
    } on MissingPluginException {
      // Preview hosts have no native translation service.
    }
    if (active && mounted && !_translationRunning) {
      setState(() => _translationRunning = true);
    }
    return active;
  }

  Future<void> _refreshTranslationState() async {
    var foregroundRunning = false;
    var sessionActive = false;
    var sessionConnected = false;
    var videoReady = false;
    try {
      foregroundRunning =
          await _ps5Channel.invokeMethod<bool>(
            'isTranslationForegroundRunning',
          ) ==
          true;
    } on PlatformException {
      // Keep the home screen usable if native session state is unavailable.
    }
    try {
      final state = await _ps5Channel.invokeMapMethod<String, dynamic>(
        'getSessionState',
      );
      sessionActive = state?['active'] == true;
      sessionConnected = state?['connected'] == true;
      videoReady = state?['videoReady'] == true;
    } on PlatformException {
      // The foreground service state still determines the button when needed.
    }
    if (foregroundRunning) await AccessService.instance.readNativeStatus();
    if (mounted) {
      setState(() {
        _translationRunning =
            foregroundRunning ||
            (widget.translationRunningOnOpen && sessionActive);
        _remotePlayActive = sessionActive;
        _remotePlaySessionConnected = sessionConnected;
        _remotePlayVideoReady = videoReady;
        _remotePlayConnected = sessionConnected && videoReady;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AccessService.instance.removeListener(_accessChanged);
    _translationStateTimer?.cancel();
    _gameRefreshCooldownTimer?.cancel();
    _tvStatusSubscription?.cancel();
    _gameSearchController.dispose();
    super.dispose();
  }

  void _accessChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshAccessStatus() async {
    if (_refreshingAccess) return;
    _refreshingAccess = true;
    try {
      await AccessService.instance.refresh();
    } catch (_) {
      // Keep home usable offline; translation still verifies access separately.
    } finally {
      _refreshingAccess = false;
    }
  }

  Future<void> _openAccess() async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AccessScreen()));
    if (mounted) setState(() {});
  }

  Future<bool> _ensureTranslationAccess() async {
    final service = AccessService.instance;
    try {
      await service.initialize();
      if ((await service.refresh(force: true)).canPrepareTranslation) {
        return true;
      }
    } catch (_) {
      // The account screen displays configuration and connectivity errors with retry.
    }
    if (!mounted) return false;
    return await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const AccessScreen(forTranslation: true),
          ),
        ) ==
        true;
  }

  Future<void> _loadTvPairingAddress() async {
    try {
      if (await TvOutputService.instance.restoreSmartPairing()) {
        if (mounted) {
          setState(() {
            _savedTvAddress = TvOutputService.instance.address;
            _hasSavedTvPairing = TvOutputService.instance.sessionToken != null;
          });
        }
        return;
      }
      final pairing = await _ps5Channel.invokeMapMethod<String, dynamic>(
        'getTvPairing',
      );
      final address = pairing?['address'] as String?;
      final sessionToken = pairing?['sessionToken'] as String?;
      if (mounted) {
        setState(() {
          _savedTvAddress = address;
          _hasSavedTvPairing = address != null && sessionToken != null;
        });
      }
      if (address != null && sessionToken != null) {
        unawaited(
          TvOutputService.instance.restorePairing(
            address,
            sessionToken,
            certificateFingerprint:
                pairing?['certificateFingerprint'] as String?,
          ),
        );
      }
    } on PlatformException {
      // TV pairing is optional; keep the screen usable if storage is unavailable.
    } finally {
      if (mounted) setState(() => _loadingTvAddress = false);
    }
  }

  Future<void> _loadSetupGuideChecklist() async {
    try {
      final saved = await _ps5Channel.invokeListMethod<bool>(
        'getSetupChecklist',
      );
      if (!mounted) return;
      setState(() {
        _setupGuideChecklist = List<bool>.generate(
          SetupGuideScreen.totalSteps,
          (index) => index < (saved?.length ?? 0) && saved![index],
        );
      });
    } on PlatformException {
      // Keep the guide progress available when checklist storage is unavailable.
    }
  }

  int get _setupGuideCompletedCount {
    final current = List<bool>.generate(
      SetupGuideScreen.totalSteps,
      (index) =>
          index < _setupGuideChecklist.length && _setupGuideChecklist[index],
    );
    current[2] = _savedPs5 != null;
    current[4] = _tvPairing || _hasSavedTvPairing;
    return current.where((checked) => checked).length;
  }

  Future<bool> _openPs5FromSetup() async {
    await _openPs5();
    return _savedPs5 != null;
  }

  Future<bool> _pairTvFromSetup() async {
    await _pairTv();
    return _tvPairing;
  }

  Future<void> _openSetupGuide() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SetupGuideScreen(
          ps5Ready: _savedPs5 != null,
          tvReady: _tvPairing || _hasSavedTvPairing,
          onSetupPs5: _openPs5FromSetup,
          onPairTv: _pairTvFromSetup,
        ),
      ),
    );
    await _loadSavedPs5();
    await _loadTvPairingAddress();
    await _loadSetupGuideChecklist();
  }

  Future<void> _openHelpScreen() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const HelpScreen()));
  }

  Future<bool> _confirmIncompleteSetup() async {
    if (_setupWarningOpen) return false;
    _setupWarningOpen = true;
    try {
      await _loadSetupGuideChecklist();
      if (!mounted) return false;
      final completed = _setupGuideCompletedCount;
      if (completed >= SetupGuideScreen.totalSteps) return true;

      var dismissed = false;
      try {
        dismissed =
            await _ps5Channel.invokeMethod<bool>(
              'getIncompleteSetupWarningDismissed',
            ) ??
            false;
      } on PlatformException {
        // Keep the advisory available when the preference cannot be read.
      } on MissingPluginException {
        // Older native builds keep showing the advisory.
      }
      if (!mounted) return false;
      if (dismissed) return true;

      var neverShowAgain = false;
      final startAnyway = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: panel,
            title: Text(context.tr("Kurulum henüz tamamlanmadı")),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SetupNotice(
                    title: context.tr("{0} / {1} adım tamamlandı", [
                      completed,
                      SetupGuideScreen.totalSteps,
                    ]),
                    message: context.tr(
                      "PS5 ve TV bağlantıların hazır. En iyi deneyim için kurulum rehberindeki eksik adımları tamamlamanı öneririz. İstersen çeviriyi şimdi de başlatabilirsin.",
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: neverShowAgain,
                    onChanged: (value) =>
                        setDialogState(() => neverShowAgain = value ?? false),
                    title: Text(context.tr("Bir daha gösterme")),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: setupNoticeColor,
                    checkColor: bg,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.tr("Yine de başlat")),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: FilledButton.styleFrom(
                  backgroundColor: setupNoticeColor,
                  foregroundColor: bg,
                ),
                icon: const Icon(Icons.checklist_rounded, size: 18),
                label: Text(context.tr("Kurulumu tamamla")),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return false;
      if (neverShowAgain) {
        try {
          await _ps5Channel.invokeMethod<void>(
            'setIncompleteSetupWarningDismissed',
            true,
          );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr(
                    "Tercih kaydedilemedi. Kurulum uyarısı tekrar görünebilir.",
                  ),
                ),
              ),
            );
          }
        }
      }
      if (!mounted) return false;
      if (startAnyway == false) await _openSetupGuide();
      return startAnyway == true;
    } finally {
      _setupWarningOpen = false;
    }
  }

  Future<void> _pairTv() async {
    final addressController = TextEditingController(
      text: _savedTvAddress ?? '',
    );
    final codeController = TextEditingController();
    var busy = false;
    var discovering = false;
    String? errorText;
    String? discoveryMessage;
    String? selectedAddress;
    List<String> discoveredAddresses = const [];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
          actionsPadding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.cast_connected_rounded,
                  color: cyan,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  context.tr("Android TV’yi eşleştir"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TvPlatformSelector(
                  selected: TvOutputKind.android,
                  onSelected: busy
                      ? null
                      : (kind) => _switchTvSetup(dialogContext, kind),
                ),
                const SizedBox(height: 14),
                const TvAppInstallNotice(),
                const SizedBox(height: 16),
                for (final (index, step) in [
                  context.tr(
                    'TV ve telefon aynı Wi-Fi ağında olsun; TV uygulamasını aç.',
                  ),
                  context.tr(
                    'TV’yi ağda bul’a dokun ya da TV ekranındaki adresi yaz.',
                  ),
                  context.tr('TV ekranındaki 6 haneli kodu girip eşleştir.'),
                ].indexed)
                  _pairStep(index + 1, step),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy || discovering
                      ? null
                      : () async {
                          setDialogState(() {
                            discovering = true;
                            errorText = null;
                            discoveryMessage = null;
                          });
                          try {
                            final addresses = await TvOutputService.instance
                                .discoverReceivers();
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              discovering = false;
                              discoveredAddresses = addresses;
                              if (addresses.isEmpty) {
                                discoveryMessage = context.tr(
                                  "TV bulunamadı. TV’nin açık ve iki cihazın aynı Wi-Fi ağında olduğundan emin ol.",
                                );
                                selectedAddress = null;
                              } else {
                                if (addresses.length == 1) {
                                  selectedAddress = addresses.single;
                                  addressController.text = addresses.single;
                                  discoveryMessage = context.tr(
                                    "Bir TV bulundu.",
                                  );
                                } else {
                                  selectedAddress = null;
                                  discoveryMessage = context.tr(
                                    "{0} TV bulundu. Kendi TV ekranındaki adresle eşleşeni seç.",
                                    [addresses.length],
                                  );
                                }
                              }
                            });
                          } catch (_) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              discovering = false;
                              discoveryMessage = context.tr(
                                "Ağ taraması yapılamadı. Aynı Wi-Fi ağını kontrol et.",
                              );
                            });
                          }
                        },
                  icon: discovering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find),
                  label: Text(
                    discovering
                        ? context.tr("TV aranıyor…")
                        : context.tr("TV’yi ağda bul"),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: cyan,
                    side: BorderSide(color: cyan.withValues(alpha: 0.45)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (discoveryMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      discoveryMessage!,
                      style: const TextStyle(color: cyan, fontSize: 12),
                    ),
                  ),
                if (discoveredAddresses.length > 1) ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedAddress,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        "TV ekranındaki adresle eşleşeni seç",
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: discoveredAddresses
                        .map(
                          (address) => DropdownMenuItem<String>(
                            value: address,
                            child: Text(address),
                          ),
                        )
                        .toList(),
                    onChanged: (address) {
                      if (address == null) return;
                      setDialogState(() {
                        selectedAddress = address;
                        addressController.text = address;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: addressController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: context.tr("TV ekranındaki adres"),
                    hintText: 'wss://192.168.1.25:43823',
                    prefixIcon: const Icon(Icons.tv_rounded, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr("TV ekranındaki 6 haneli kod"),
                    prefixIcon: const Icon(Icons.pin_rounded, size: 20),
                    isDense: true,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.orangeAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.trMessage(errorText!),
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (busy) {
                  await TvOutputService.instance.cancelConnectionAttempt();
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(
                busy ? context.tr("Bağlantıyı iptal et") : context.tr("İptal"),
              ),
            ),
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      setDialogState(() {
                        busy = true;
                        errorText = null;
                      });
                      try {
                        await TvOutputService.instance.connect(
                          addressController.text,
                          codeController.text,
                          verifyCertificate: (verificationCode) async {
                            if (!dialogContext.mounted) return false;
                            return await showDialog<bool>(
                                  context: dialogContext,
                                  barrierDismissible: false,
                                  builder: (verificationContext) => AlertDialog(
                                    title: Text(
                                      verificationContext.tr(
                                        'TV kimliğini doğrula',
                                      ),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          verificationContext.tr(
                                            'Bu değer TV ekranındaki “Güvenli bağlantı kimliği” ile aynı mı? Yalnızca tamamı eşleşiyorsa onayla.',
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SelectableText(
                                          verificationCode,
                                          textDirection: TextDirection.ltr,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                          verificationContext,
                                          false,
                                        ),
                                        child: Text(
                                          verificationContext.tr(
                                            'Eşleşmiyor / İptal',
                                          ),
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(
                                          verificationContext,
                                          true,
                                        ),
                                        child: Text(
                                          verificationContext.tr(
                                            'Tamamı eşleşiyor',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ) ==
                                true;
                          },
                        );
                        await _ps5Channel.invokeMethod<void>('saveTvPairing', {
                          'address': TvOutputService.instance.address,
                          'sessionToken': TvOutputService.instance.sessionToken,
                          'certificateFingerprint':
                              TvOutputService.instance.certificateFingerprint,
                        });
                        if (!mounted || !dialogContext.mounted) return;
                        setState(() {
                          _savedTvAddress = TvOutputService.instance.address;
                          _tvPairing = true;
                          _hasSavedTvPairing = true;
                          _tvConnecting = false;
                        });
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr(
                                "Android TV eşleştirildi. Altyazılar bağlantı açılınca TV’ye gönderilir.",
                              ),
                            ),
                          ),
                        );
                      } catch (_) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() {
                          busy = false;
                          errorText =
                              "TV’ye bağlanılamadı. Adres, kod ve aynı Wi-Fi ağını kontrol et.";
                        });
                      }
                    },
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cast_connected),
              label: Text(
                busy
                    ? context.tr("Bağlanıyor…")
                    : context.tr("Eşleştir ve bağlan"),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cyan,
                foregroundColor: bg,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // showDialog completes as soon as the route is popped, before its reverse
    // transition has fully removed the TextFields from the overlay.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    addressController.dispose();
    codeController.dispose();
  }

  Widget _pairStep(int number, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          padding: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cyan.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: cyan,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFC9D3E3),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );

  void _switchTvSetup(BuildContext dialogContext, TvOutputKind kind) {
    Navigator.pop(dialogContext);
    unawaited(kind == TvOutputKind.android ? _pairTv() : _openSmartTv(kind));
  }

  Future<void> _openSmartTv(TvOutputKind kind) async {
    if (!mounted) return;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SmartTvSetupDialog(
        kind: kind,
        onKindSelected: (nextKind) => _switchTvSetup(dialogContext, nextKind),
      ),
    );
    if (!mounted) return;
    setState(() {
      _savedTvAddress = TvOutputService.instance.address;
      _tvPairing = TvOutputService.instance.isConnected;
      _tvConnecting = TvOutputService.instance.isConnecting;
      _hasSavedTvPairing = TvOutputService.instance.sessionToken != null;
    });
  }

  Future<void> _disconnectTv() async {
    final android = TvOutputService.instance.kind == TvOutputKind.android;
    await TvOutputService.instance.disconnect();
    try {
      if (android) await _ps5Channel.invokeMethod<void>('clearTvPairing');
    } on PlatformException {
      // The live connection is already closed.
    }
    if (mounted) {
      setState(() {
        _tvPairing = false;
        _hasSavedTvPairing = false;
        _savedTvAddress = null;
      });
    }
  }

  Future<void> _cancelTvConnectionAttempt() async {
    await TvOutputService.instance.cancelConnectionAttempt();
  }

  Future<void> _retryTvConnection() async {
    await TvOutputService.instance.retrySavedPairing();
  }

  /// The selected game's pack is used only for its own language pair (the
  /// native side compares them exactly). Otherwise every line goes to the
  /// translation model, so the mismatch is shown instead of passing silently.
  String? get _gameLanguageWarning {
    final game = _games.where((game) => game.id == _selectedGameId).firstOrNull;
    if (game == null ||
        (game.sourceLanguage == sourceLanguageCode &&
            game.targetLanguage == targetLanguageCode)) {
      return null;
    }
    return context.tr(
      'Seçili oyunun çeviri paketi {0}, çeviri dili ise {1}. Oyunun kendi çevirileri kullanılmayacak; oyunu {1} paketiyle yeniden seç ya da çeviri dilini değiştir.',
      [game.languageLabel, targetLanguage],
    );
  }

  String get sourceLanguage => _languageName(sourceLanguageCode);
  String get targetLanguage => _languageName(targetLanguageCode);

  String _languageName(String code) {
    if (_translationEngine == 'deepl') {
      for (final language in [
        ..._deepLSourceLanguages,
        ..._deepLTargetLanguages,
      ]) {
        if (language.code == code) return _translationLanguageName(language);
      }
    }
    for (final model in _offlineModels) {
      if (model['target'] == code) {
        return context.tr(model['label'] as String? ?? code);
      }
    }
    for (final language in _translationModels) {
      if (language.code == code) return _translationLanguageName(language);
    }
    return switch (code) {
      'en' => 'English',
      'tr' => 'Türkçe',
      _ => code,
    };
  }

  bool _isLanguageDownloaded(String code) =>
      _translationModels.any((model) => model.code == code && model.downloaded);

  String _translationLanguageName(TranslationLanguageModel language) =>
      language.nativeName.isNotEmpty ? language.nativeName : language.name;

  Future<void> _loadTranslationPreferences() async {
    final store = const SubtitleSettingsStore();
    try {
      final settings = await store.load();
      if (!mounted) return;
      setState(() {
        _translationSettings = settings;
        sourceLanguageCode = settings.sourceLanguageCode;
        targetLanguageCode = settings.targetLanguageCode;
      });
    } catch (_) {
      // Keep the English → Turkish defaults if Android storage is unavailable.
    }
  }

  Future<void> _loadGamesAndSelectedGame() async {
    try {
      final games = await _gameCatalog.loadCatalog();
      String? selectedId;
      try {
        selectedId = await _ps5Channel.invokeMethod<String>(
          'getSelectedGameId',
        );
      } on MissingPluginException {
        // The game list can still be previewed outside the Android app.
      } on PlatformException {
        // A missing saved choice is equivalent to live translation.
      }
      if (!mounted) return;
      setState(() {
        _games = games;
        _loadingGames = false;
        _selectedGameId = selectedId;
        _gameMemoryError = null;
      });
      try {
        final libraryLanguage = await _ps5Channel.invokeMethod<String>(
          'getGameLibraryTargetLanguage',
        );
        if (mounted &&
            libraryLanguage != null &&
            (games.isEmpty ||
                games.any((game) => game.targetLanguage == libraryLanguage))) {
          setState(() => _libraryTargetLanguage = libraryLanguage);
        }
      } on PlatformException {
        // Older hosts use the default library language.
      } on MissingPluginException {
        // Preview hosts have no native preferences.
      }
      // Start the server check early; a first install has no packaged games.
      final refresh = _refreshGames();
      unawaited(refresh);
      if (selectedId == null) return;
      GameCatalogEntry? game;
      for (final candidate in games) {
        if (candidate.id == selectedId ||
            candidate.gameId == selectedId &&
                candidate.targetLanguage == 'tr') {
          game = candidate;
          break;
        }
      }
      if (game == null) {
        // A saved game may only appear once the server catalog has arrived.
        await refresh;
        if (!mounted) return;
        game = _games
            .where(
              (candidate) =>
                  candidate.id == selectedId ||
                  candidate.gameId == selectedId &&
                      candidate.targetLanguage == 'tr',
            )
            .firstOrNull;
        if (game == null) {
          if (!_gamesRefreshFailed) {
            setState(
              () => _gameMemoryError = "Seçili oyun katalogda bulunamadı.",
            );
          }
          return;
        }
      }
      if (mounted) setState(() => _selectedGameId = game!.id);
      final generation = ++_gameSelectionGeneration;
      await _loadGameMemory(
        game,
        generation: generation,
        persistSelection: false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingGames = false;
        _gamesError = 'Oyun kataloğu okunamadı.';
        _gameMemoryError = null;
      });
    }
  }

  Future<void> _selectGame(GameCatalogEntry? game) async {
    if (_selectingGame || _openingPs5) return;
    if (await _isTranslationActive()) {
      if (mounted)
        showMessage(
          'Dil değiştirilemez',
          'Dili veya oyunu değiştirmek için çeviriyi durdur.',
        );
      return;
    }
    if (!mounted || _selectingGame || _openingPs5) return;
    final previousId = _selectedGameId;
    final previousContentKey = _appliedGameContentKey;
    final previousFont = GameFonts.active.value;
    FocusScope.of(context).unfocus();
    final generation = ++_gameSelectionGeneration;
    setState(() {
      _selectingGame = true;
      _selectedGameId = game?.id;
      _gameMemoryLoading = game != null;
      _gameMemoryError = null;
    });
    if (game != null) _showGameLibrary();
    final operation = _finishGameSelection(
      game,
      generation,
      previousId: previousId,
      previousContentKey: previousContentKey,
      previousFont: previousFont,
    );
    _gameMemoryLoadFuture = operation;
    await operation;
  }

  Future<void> _finishGameSelection(
    GameCatalogEntry? game,
    int generation, {
    required String? previousId,
    required String? previousContentKey,
    required LoadedGameFont? previousFont,
  }) async {
    try {
      await _applyGameSelection(game, generation);
      if (_gameMemoryError != null && mounted) {
        final selectionError = _gameMemoryError;
        final rollbackGeneration = ++_gameSelectionGeneration;
        final previous = _games
            .where((candidate) => candidate.id == previousId)
            .firstOrNull;
        if (previous != null) {
          final restored = await _ps5Channel.invokeMapMethod<String, dynamic>(
            'activateCachedGameTranslationMemory',
            {
              'gameId': previous.gameId,
              'sourceLanguage': previous.sourceLanguage,
              'targetLanguage': previous.targetLanguage,
              'contentKey': previous.contentKey,
            },
          );
          if (restored?['loaded'] != true) {
            await _loadGameMemory(
              previous,
              generation: rollbackGeneration,
              persistSelection: false,
            );
          }
        } else {
          await _ps5Channel.invokeMapMethod<String, dynamic>(
            'setGameTranslationMemory',
            const {'gameId': null, 'json': null},
          );
        }
        GameFonts.active.value = previousFont;
        if (mounted)
          setState(() {
            _selectedGameId = previousId;
            _appliedGameContentKey = previousContentKey;
            _gameMemoryError = selectionError;
            _gameMemoryLoading = false;
          });
      }
    } finally {
      if (mounted) {
        setState(() {
          _selectingGame = false;
          if (generation == _gameSelectionGeneration) {
            _gameMemoryLoading = false;
          }
        });
      } else {
        _selectingGame = false;
      }
    }
  }

  void _showGameLibrary() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedTab != _AppTab.subtitles) {
        return;
      }
      final header = _gameLibraryHeaderKey.currentContext;
      if (header != null) {
        unawaited(
          Scrollable.ensureVisible(
            header,
            alignment: 0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  Future<void> _deleteGameDictionary(GameCatalogEntry game) async {
    if (_selectingGame ||
        _gameMemoryLoading ||
        _openingPs5 ||
        _translationRunning)
      return;
    void notify(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr(message))));
    }

    setState(() => _selectingGame = true);
    try {
      final downloaded = await _gameCatalog.hasDownloadedPack(game);
      if (!mounted) return;
      if (!downloaded) {
        return;
      }
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(context.tr('İndirilen çevirileri sil?')),
          content: Text(
            context.tr(
              '{0} oyununun telefondaki çevirileri silinir. Seçiliyse seçim kaldırılır. Oyunu tekrar seçerek çevirileri yeniden indirebilirsin.',
              [game.name],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('Vazgeç')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF9B8F),
              ),
              child: Text(context.tr('Sil')),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
      final operation = _removeDownloadedGame(game);
      // Keep later translation starts usable after a reported deletion error.
      _gameMemoryLoadFuture = operation.catchError((Object _) {});
      await operation;
      notify('İndirilen çeviriler silindi.');
    } catch (_) {
      notify('Çeviriler silinemedi. Tekrar dene.');
    } finally {
      if (mounted) setState(() => _selectingGame = false);
    }
  }

  Future<void> _removeDownloadedGame(GameCatalogEntry game) async {
    if (_selectedGameId == game.id) {
      GameFonts.active.value = null;
      ++_gameSelectionGeneration;
      await _ps5Channel.invokeMethod<void>('saveSelectedGameId', '');
      await _ps5Channel.invokeMapMethod<String, dynamic>(
        'setGameTranslationMemory',
        const {'gameId': null, 'json': null},
      );
      if (mounted) {
        setState(() {
          _selectedGameId = null;
          _appliedGameContentKey = null;
          _gameMemoryLoading = false;
          _gameMemoryError = null;
        });
      }
    }
    GameFonts.forgetGame(game.id);
    try {
      await _ps5Channel.invokeMethod<void>('forgetGameTranslationMemory', {
        'gameId': game.gameId,
        'sourceLanguage': game.sourceLanguage,
        'targetLanguage': game.targetLanguage,
      });
    } on MissingPluginException {
      // Older preview hosts have no native index cache.
    }
    await _gameCatalog.deleteDownloadedPack(game);
  }

  Future<void> _applyGameSelection(
    GameCatalogEntry? game,
    int generation,
  ) async {
    try {
      if (game != null) {
        await _loadGameMemory(
          game,
          generation: generation,
          persistSelection: false,
        );
        if (_appliedGameContentKey != game.contentKey ||
            _gameMemoryError != null)
          return;
        await _ps5Channel.invokeMethod<void>('commitGameTranslationSelection', {
          'packId': game.id,
          'gameId': game.gameId,
          'sourceLanguage': game.sourceLanguage,
          'targetLanguage': game.targetLanguage,
          'contentKey': game.contentKey,
        });
        if (mounted && generation == _gameSelectionGeneration) {
          setState(() {
            sourceLanguageCode = game.sourceLanguage;
            targetLanguageCode = game.targetLanguage;
            _libraryTargetLanguage = game.targetLanguage;
            _translationSettings = _translationSettings.copyWith(
              sourceLanguageCode: game.sourceLanguage,
              targetLanguageCode: game.targetLanguage,
            );
          });
        }
      } else {
        await _ps5Channel.invokeMethod<void>('saveSelectedGameId', '');
        await _ps5Channel.invokeMapMethod<String, dynamic>(
          'setGameTranslationMemory',
          const {'gameId': null, 'json': null},
        );
        if (mounted && generation == _gameSelectionGeneration) {
          GameFonts.active.value = null;
          setState(() {
            _gameMemoryError = null;
            _appliedGameContentKey = null;
          });
        }
      }
    } catch (error) {
      if (mounted && generation == _gameSelectionGeneration) {
        setState(() {
          _gameMemoryError = _gameMemoryErrorText(error);
        });
      }
    }
  }

  Future<void> _loadGameMemory(
    GameCatalogEntry game, {
    required int generation,
    required bool persistSelection,
  }) async {
    if (persistSelection) {
      await _ps5Channel.invokeMethod<void>('saveSelectedGameId', game.id);
    }
    if (mounted && generation == _gameSelectionGeneration) {
      setState(() {
        _gameMemoryLoading = true;
        _gameMemoryError = null;
      });
    }
    try {
      Map<String, dynamic>? cached;
      try {
        cached = await _ps5Channel.invokeMapMethod<String, dynamic>(
          'activateCachedGameTranslationMemory',
          {
            'gameId': game.gameId,
            'sourceLanguage': game.sourceLanguage,
            'targetLanguage': game.targetLanguage,
            'contentKey': game.contentKey,
          },
        );
      } on MissingPluginException {
        // Fall through to the existing loader on older preview hosts.
      }
      if (generation != _gameSelectionGeneration) return;
      if (cached?['loaded'] == true) {
        if (!_restoreMemoryFont(cached!, game, generation)) {
          unawaited(_restoreGameFont(game, generation));
        }
        if (mounted) {
          setState(() {
            _gameMemoryError = null;
            _appliedGameContentKey = game.contentKey;
          });
        }
        return;
      }
      Map<String, dynamic>? response;
      String? json;
      var filePath = await _gameCatalog.cachedJsonFile(game);
      if (generation != _gameSelectionGeneration) return;
      // A .json.gz pack is downloaded as a file and only ever read natively.
      if (filePath == null && game.isCompressedPack) {
        filePath = await _gameCatalog.downloadPackFile(game);
        if (generation != _gameSelectionGeneration) return;
      }
      if (filePath != null) {
        try {
          response = await _ps5Channel
              .invokeMapMethod<String, dynamic>('setGameTranslationMemory', {
                'gameId': game.gameId,
                'sourceLanguage': game.sourceLanguage,
                'targetLanguage': game.targetLanguage,
                'contentKey': game.contentKey,
                'filePath': filePath,
                'sha256': game.sha256,
                'bytes': game.bytes,
              });
        } on PlatformException {
          // A purged cache, legacy metadata or older native host can use the
          // existing verified download/conversion path instead. A gzip pack
          // has no such path: decoding it in Dart would cost far more memory.
          if (game.isCompressedPack) rethrow;
        }
      }
      if (generation != _gameSelectionGeneration) return;
      if (response?['loaded'] != true && !game.isCompressedPack) {
        json = await _gameCatalog.loadJson(game);
        if (generation != _gameSelectionGeneration) return;
        response = await _ps5Channel
            .invokeMapMethod<String, dynamic>('setGameTranslationMemory', {
              'gameId': game.gameId,
              'sourceLanguage': game.sourceLanguage,
              'targetLanguage': game.targetLanguage,
              'contentKey': game.contentKey,
              'json': json,
            });
      }
      if (response?['loaded'] != true) {
        throw StateError("Oyun çeviri verisi belleğe alınamadı.");
      }
      if (generation != _gameSelectionGeneration) return;
      // Presentation is optional: a slow/missing font must not delay the game's JSON.
      if (!_restoreMemoryFont(response!, game, generation)) {
        if (json != null) {
          unawaited(_loadGameFont(json, generation, game.contentKey));
        } else {
          unawaited(_restoreGameFont(game, generation));
        }
      }
      if (mounted && generation == _gameSelectionGeneration) {
        setState(() {
          _gameMemoryError = null;
          _appliedGameContentKey = game.contentKey;
        });
      }
    } catch (error) {
      if (mounted && generation == _gameSelectionGeneration) {
        setState(() {
          _gameMemoryError = _gameMemoryErrorText(error);
        });
      }
    } finally {
      if (mounted && generation == _gameSelectionGeneration) {
        setState(() => _gameMemoryLoading = false);
      }
    }
  }

  bool _restoreMemoryFont(
    Map<String, dynamic> memory,
    GameCatalogEntry game,
    int generation,
  ) {
    if (GameFonts.restorePrepared(game.contentKey)) return true;
    if (!memory.containsKey('gameProfile')) return false;
    final profile = memory['gameProfile'];
    if (profile != null && profile is! String) return false;
    unawaited(
      _loadGameFont(
        '{"gameProfile":${profile ?? 'null'}}',
        generation,
        game.contentKey,
      ),
    );
    return true;
  }

  Future<void> _restoreGameFont(GameCatalogEntry game, int generation) async {
    try {
      final json = await _gameCatalog.loadJson(game);
      if (generation == _gameSelectionGeneration) {
        await _loadGameFont(json, generation, game.contentKey);
      }
    } catch (_) {
      // Font restoration never delays the cached JSON memory's activation.
    }
  }

  Future<void> _loadGameFont(
    String json,
    int generation,
    String contentKey,
  ) async {
    try {
      final font = await GameFonts.prepare(
        json,
        _gameCatalog,
        contentKey: contentKey,
      );
      if (mounted && generation == _gameSelectionGeneration) {
        GameFonts.active.value = font;
      }
    } catch (_) {
      if (mounted && generation == _gameSelectionGeneration) {
        GameFonts.active.value = null;
      }
    }
  }

  String _gameMemoryErrorText(Object error) {
    if (error is PlatformException &&
        error.code == 'GAME_TRANSLATION_MEMORY_TOO_LARGE') {
      return 'Bu oyunun çeviri paketi telefonun belleğine sığmadı. Diğer uygulamaları kapatıp tekrar dene.';
    }
    final message = error.toString();
    if (message.contains('Unable to load asset')) {
      return 'Oyun çeviri dosyası bulunamadı.';
    }
    return 'Oyun çeviri verisi okunamadı.';
  }

  Future<void> _refreshGames({bool manual = false}) async {
    if (_refreshingGames ||
        !mounted ||
        (_gamesRefreshStarted && !manual) ||
        (manual && _gameCatalog.manualRefreshRemaining > Duration.zero)) {
      return;
    }
    setState(() {
      _gamesRefreshStarted = true;
      _refreshingGames = true;
      _gamesRefreshFailed = false;
    });
    unawaited(_gameCatalog.refreshDownloadedPacks(_games));
    try {
      final catalog = await (manual
          ? _gameCatalog.refreshManually()
          : _gameCatalog.refresh());
      if (!mounted) return;
      final selected = _games
          .where((game) => game.id == _selectedGameId)
          .firstOrNull;
      final replacement = selected == null
          ? null
          : catalog
                .where(
                  (game) =>
                      game.gameId == selected.gameId &&
                      game.sourceLanguage == selected.sourceLanguage &&
                      game.targetLanguage == selected.targetLanguage,
                )
                .firstOrNull;
      setState(() {
        if (replacement != null) _selectedGameId = replacement.id;
        _games = [
          ...catalog,
          // A catalog change must not remove a game from an active session.
          if (selected != null && replacement == null) selected,
        ];
        if (!_games.any(
              (game) => game.targetLanguage == _libraryTargetLanguage,
            ) &&
            _games.isNotEmpty)
          _libraryTargetLanguage = _games.first.targetLanguage;
        _gamesError = null;
      });
      unawaited(_gameCatalog.refreshDownloadedPacks(_games));
    } catch (_) {
      // Keep local games usable and offer an explicit retry instead of polling.
      if (mounted) setState(() => _gamesRefreshFailed = true);
    } finally {
      if (mounted) {
        setState(() => _refreshingGames = false);
        _gameRefreshCooldownTimer?.cancel();
        final remaining = _gameCatalog.manualRefreshRemaining;
        if (remaining > Duration.zero) {
          // A local one-shot timer only re-enables the controls; it sends no request.
          _gameRefreshCooldownTimer = Timer(remaining, () {
            if (mounted) setState(() {});
          });
        }
      }
    }
  }

  Future<bool> _ensureLatestSelectedGame() async {
    while (mounted) {
      final pending = _gameMemoryLoadFuture;
      await pending;
      if (!mounted) return false;
      if (!identical(pending, _gameMemoryLoadFuture)) continue;
      if (_selectedGameId == null) return true;
      final selected = _games
          .where((game) => game.id == _selectedGameId)
          .firstOrNull;
      if (selected == null) {
        setState(() => _gameMemoryError = 'Seçili oyun katalogda bulunamadı.');
        return false;
      }
      if (selected.contentKey == _appliedGameContentKey &&
          _gameMemoryError == null)
        return true;
      final generation = ++_gameSelectionGeneration;
      final operation = _loadGameMemory(
        selected,
        generation: generation,
        persistSelection: false,
      );
      _gameMemoryLoadFuture = operation;
      await operation;
      if (!mounted) return false;
      final latest = _games
          .where((game) => game.id == _selectedGameId)
          .firstOrNull;
      if (generation != _gameSelectionGeneration ||
          !identical(operation, _gameMemoryLoadFuture) ||
          latest?.contentKey != selected.contentKey)
        continue;
      return _appliedGameContentKey == selected.contentKey &&
          _gameMemoryError == null;
    }
    return false;
  }

  Future<bool> _confirmGameSelection() async {
    if (_selectedGameId != null) return true;
    final continueWithoutGame = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(context.tr('Oyun seçilmedi')),
        content: Text(
          context.tr(
            'Daha hızlı ve doğru çeviri için oyun kütüphanesinde oyunun varsa seç. Listede yoksa oyun seçmeden devam edebilirsin.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Seçmeden devam et')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Oyun kütüphanesini aç')),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (continueWithoutGame == false) {
      _selectTab(_AppTab.subtitles);
      _showGameLibrary();
    }
    return continueWithoutGame == true;
  }

  Future<void> _loadTranslationModels() async {
    if (mounted) {
      setState(() {
        _loadingTranslationModels = true;
        _translationModelsError = null;
      });
    }
    try {
      final models = await const SubtitleSettingsStore()
          .loadTranslationLanguages();
      if (!mounted) return;
      setState(() => _translationModels = models);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _translationModelsError = error.message ?? error.code);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _translationModelsError =
              'Seçili modelin dil paketleri okunamadı.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTranslationModels = false);
    }
  }

  Future<void> _selectTranslationLanguage({
    required bool source,
    required String code,
  }) async {
    if (_translationEngine == 'hplt') return;
    if (_translationEngine == 'opus') {
      if (source) return;
      await _selectOfflineTarget(code);
      return;
    }
    final store = const SubtitleSettingsStore();
    final settings = await store.load();
    if (!mounted) return;
    final updated = source
        ? settings.copyWith(sourceLanguageCode: code)
        : settings.copyWith(targetLanguageCode: code);
    setState(() {
      _translationSettings = updated;
      if (source) {
        sourceLanguageCode = code;
      } else {
        targetLanguageCode = code;
      }
    });
    await store.save(updated);
  }

  Future<void> _downloadLanguage(String code) async {
    setState(() {
      _downloadingLanguageCodes.add(code);
      _translationModelsError = null;
    });
    try {
      await const SubtitleSettingsStore().downloadTranslationLanguage(code);
      await _loadTranslationModels();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _translationModelsError =
              error.message ?? 'Dil paketi indirilemedi.',
        );
        showMessage(
          "Dil paketi indirilemedi",
          error.message ?? "Bağlantını kontrol edip tekrar dene.",
        );
      }
    } catch (_) {
      if (mounted) {
        showMessage(
          "Dil paketi indirilemedi",
          "Bağlantını kontrol edip tekrar dene.",
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingLanguageCodes.remove(code));
    }
  }

  Future<void> _showTranslationLanguageManager() async {
    if (_translationEngine == 'hplt') {
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        backgroundColor: panel,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr("Model C • HPLT v2.0"),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    "İngilizce → Türkçe • çevrimdışı • yaklaşık 80 MB • 64-bit ARM Android. HPLT v2.0 tabanlı INT8 CTranslate2 paketi.",
                  ),
                  style: TextStyle(color: muted, fontSize: 12, height: 1.45),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _hpltModelInstalled ? Icons.check_circle : Icons.download,
                    color: _hpltModelInstalled ? cyan : muted,
                  ),
                  title: Text(context.tr("HPLT İngilizce → Türkçe")),
                  subtitle: Text(
                    _hpltModelInstalled
                        ? context.tr("İndirildi • cihazda hazır")
                        : context.tr("İndirilmedi"),
                  ),
                  trailing: _hpltModelInstalled
                      ? Text(context.tr("Hazır"), style: TextStyle(color: cyan))
                      : _hpltDownloading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          onPressed: () async {
                            setSheetState(() => _hpltDownloading = true);
                            await _downloadHpltModel();
                            if (sheetContext.mounted) {
                              setSheetState(() => _hpltDownloading = false);
                            }
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: Text(context.tr("İndir")),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    "Atıf: HPLT, translate-en-tr-v2.0-hplt_opus; WindyTranslate INT8 dönüşümü. CC BY 4.0.",
                  ),
                  style: TextStyle(color: muted, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    final localEngine = _translationEngine == 'opus';
    if (!localEngine &&
        (_translationModels.isEmpty || _loadingTranslationModels)) {
      await _loadTranslationModels();
    }
    if (localEngine && _offlineModels.isEmpty) await _loadTranslationEngine();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: panel,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localEngine
                                ? context.tr("Model A hedef dilleri")
                                : context.tr("Model B dilleri"),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            localEngine
                                ? context.tr(
                                    "İngilizceden seçtiğin dile çevrimdışı paket indir.",
                                  )
                                : context.tr(
                                    "İndirilen diller seçili çeviri motorunda kullanılabilir.",
                                  ),
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr("Durumu yenile"),
                      onPressed: () async {
                        if (localEngine) {
                          await _loadTranslationEngine();
                        } else {
                          await _loadTranslationModels();
                        }
                        setSheetState(() {});
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              if (!localEngine && _translationModelsError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Text(
                    context.trMessage(_translationModelsError!),
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                ),
              Expanded(
                child:
                    (!localEngine &&
                        _loadingTranslationModels &&
                        _translationModels.isEmpty)
                    ? const Center(child: CircularProgressIndicator())
                    : (!localEngine && _translationModels.isEmpty)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr("Dil seçenekleri yüklenemedi."),
                                style: TextStyle(color: muted),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  await _loadTranslationModels();
                                  setSheetState(() {});
                                },
                                icon: const Icon(Icons.refresh),
                                label: Text(context.tr("Yeniden dene")),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: localEngine
                            ? _offlineModels.length
                            : _translationModels.length,
                        itemBuilder: (context, index) {
                          if (localEngine) {
                            final model = _offlineModels[index];
                            final code = model['target'] as String;
                            final installed = model['installed'] == true;
                            final downloading =
                                _opusDownloading && code == _offlineTarget;
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                installed ? Icons.check_circle : Icons.language,
                                color: installed ? cyan : muted,
                              ),
                              title: Text(
                                context.tr(model['label'] as String? ?? code),
                              ),
                              subtitle: Text(
                                installed
                                    ? context.tr(
                                        "İndirildi • İngilizceden kullanılabilir",
                                      )
                                    : context.tr(
                                        "İndirilmedi • yaklaşık 20 MB",
                                      ),
                              ),
                              trailing: installed
                                  ? TextButton(
                                      onPressed: () async {
                                        await _selectOfflineTarget(code);
                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                        }
                                      },
                                      child: Text(
                                        code == _offlineTarget
                                            ? context.tr("Seçili")
                                            : context.tr("Seç"),
                                      ),
                                    )
                                  : downloading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : TextButton.icon(
                                      onPressed: () async {
                                        setSheetState(() {
                                          _offlineTarget = code;
                                          _opusDownloading = true;
                                        });
                                        await _downloadOfflineTarget(code);
                                        if (sheetContext.mounted) {
                                          setSheetState(
                                            () => _opusDownloading = false,
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.download,
                                        size: 18,
                                      ),
                                      label: Text(context.tr("İndir")),
                                    ),
                            );
                          }
                          final model = _translationModels[index];
                          final downloading = _downloadingLanguageCodes
                              .contains(model.code);
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              model.downloaded
                                  ? Icons.check_circle
                                  : Icons.language,
                              color: model.downloaded ? cyan : muted,
                            ),
                            title: Text(_translationLanguageName(model)),
                            subtitle: Text(
                              model.downloaded
                                  ? context.tr(
                                      "İndirildi • çeviri seçiminde kullanılabilir",
                                    )
                                  : context.tr("İndirilmedi"),
                            ),
                            trailing: model.downloaded
                                ? Text(
                                    context.tr("Hazır"),
                                    style: TextStyle(color: cyan),
                                  )
                                : downloading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : TextButton.icon(
                                    onPressed: () async {
                                      setSheetState(
                                        () => _downloadingLanguageCodes.add(
                                          model.code,
                                        ),
                                      );
                                      await _downloadLanguage(model.code);
                                      if (sheetContext.mounted) {
                                        setSheetState(() {});
                                      }
                                    },
                                    icon: const Icon(Icons.download, size: 18),
                                    label: Text(context.tr("İndir")),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadSavedPs5() async {
    Map<String, dynamic>? console;
    Map<String, dynamic>? sessionState;
    var consoleReadSucceeded = false;
    try {
      console = await _ps5Channel.invokeMapMethod<String, dynamic>(
        'getSavedConsole',
      );
      consoleReadSucceeded = true;
    } on PlatformException {
      // Preserve the current session state if secure storage is temporarily unavailable.
    }
    try {
      sessionState = await _ps5Channel.invokeMapMethod<String, dynamic>(
        'getSessionState',
      );
    } on PlatformException {
      // The saved console and live session are independent pieces of state.
    }
    if (mounted) {
      setState(() {
        if (consoleReadSucceeded) _savedPs5 = console;
        if (sessionState != null) {
          _remotePlayActive = sessionState['active'] == true;
          _remotePlaySessionConnected = sessionState['connected'] == true;
          _remotePlayVideoReady = sessionState['videoReady'] == true;
          _remotePlayConnected =
              _remotePlaySessionConnected && _remotePlayVideoReady;
        }
      });
    }
    if (mounted) {
      setState(() => _loadingPs5 = false);
    }
  }

  Future<void> _startOrStopTranslation() async {
    if (_openingPs5 || _loadingPs5) return;
    if (!_translationRunning &&
        _translationEngine == 'deepl' &&
        !_deepLConfigured) {
      showMessage(
        'DeepL API anahtarı gerekli',
        'DeepL bölümüne anahtarını girip test et ve kaydet.',
      );
      _selectTab(_AppTab.home);
      return;
    }
    if (!_translationRunning &&
        _translationEngine == 'gemini' &&
        !_geminiConfigured) {
      showMessage(
        'Gemini API anahtarı gerekli',
        'Gemini bölümüne anahtarını girip test et ve kaydet.',
      );
      _selectTab(_AppTab.home);
      return;
    }
    if (!_translationRunning && _tvConnecting) {
      showMessage(
        "TV’ye bağlanılıyor",
        "Bağlantı tamamlanınca çeviriyi başlatabilirsin.",
      );
      return;
    }
    if (_translationEngine == 'opus' && !_opusModelInstalled) {
      showMessage(
        "Hedef dil paketi gerekli",
        "Model A için seçili hedef dil paketini önce indir.",
      );
      return;
    }
    if (_translationEngine == 'mlkit' &&
        !_loadingTranslationModels &&
        _translationModels.isNotEmpty &&
        (!_isLanguageDownloaded(sourceLanguageCode) ||
            !_isLanguageDownloaded(targetLanguageCode))) {
      showMessage(
        "Dil paketi gerekli",
        "Model B için seçili kaynak ve hedef dil paketlerini önce indir.",
      );
      return;
    }
    if (_translationEngine == 'hplt' && !_hpltModelInstalled) {
      showMessage(
        "Model C paketi gerekli",
        "HPLT İngilizce → Türkçe paketini önce indir.",
      );
      return;
    }
    var sessionIsActive = _translationRunning;
    try {
      final state = await _ps5Channel.invokeMapMethod<String, dynamic>(
        'getSessionState',
      );
      sessionIsActive = state?['active'] == true;
    } on PlatformException {
      // Fall back to the last known screen state.
    }
    if (!sessionIsActive && _translationRunning) {
      await _ps5Channel.invokeMethod<bool>('stopTranslationForeground');
      if (mounted) setState(() => _translationRunning = false);
      showMessage("Çeviri durdu", "Remote Play oturumu artık etkin değil.");
      return;
    }
    if (_translationRunning && sessionIsActive) {
      setState(() => _openingPs5 = true);
      try {
        await _ps5Channel.invokeMethod<bool>('stopSession');
        TvOutputService.instance.updateSubtitle('', _translationSettings);
        if (mounted) {
          setState(() {
            _translationRunning = false;
            _remotePlayActive = false;
            _remotePlaySessionConnected = false;
            _remotePlayVideoReady = false;
            _remotePlayConnected = false;
          });
          await _ps5Channel.invokeMethod<bool>('stopTranslationForeground');
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } on PlatformException catch (error) {
        if (mounted) {
          showMessage("Çeviri durdurulamadı", error.message ?? error.code);
        }
      } finally {
        if (mounted) setState(() => _openingPs5 = false);
      }
      return;
    }

    if (_savedPs5 == null) {
      showMessage("PS5 gerekli", "Önce PlayStation 5’i kurup kaydet.");
      return;
    }
    if (!_tvPairing || !TvOutputService.instance.isConnected) {
      showMessage(
        "TV gerekli",
        "Önce TV türünü seçip bağlantı testini tamamla.",
      );
      return;
    }

    if (_openingPs5) return;
    setState(() => _openingPs5 = true);
    var accessAllowed = false;
    try {
      if (!await _confirmIncompleteSetup() || !mounted) return;
      setState(() => _waitingForGameMemory = true);
      final ready = await _ensureLatestSelectedGame();
      if (!mounted) return;
      setState(() => _waitingForGameMemory = false);
      if (!ready) {
        showMessage(
          'Oyun çevirileri yüklenemedi',
          _gameMemoryError ?? 'Oyun çeviri verisi belleğe alınamadı.',
        );
        return;
      }
      if (!await _confirmGameSelection() || !mounted) return;
      // Setup, game preparation and warnings may take time; recheck the TV.
      if (!_tvPairing || !TvOutputService.instance.isConnected) {
        showMessage(
          'TV gerekli',
          'Önce TV türünü seçip bağlantı testini tamamla.',
        );
        return;
      }
      if (!mounted) return;
      if (const {'mlkit', 'deepl', 'gemini'}.contains(_translationEngine)) {
        await _ps5Channel.invokeMethod<bool>('prepareTranslationModels');
        if (_translationEngine == 'mlkit') unawaited(_loadTranslationModels());
      }
      if (!mounted) return;
      accessAllowed = await _ensureTranslationAccess();
    } on PlatformException catch (error) {
      if (mounted) {
        showMessage(
          "Dil paketleri hazırlanamadı",
          error.message ?? "İnternet bağlantını kontrol edip tekrar dene.",
        );
      }
    } finally {
      if (mounted)
        setState(() {
          _openingPs5 = false;
          _waitingForGameMemory = false;
        });
    }
    if (!mounted) return;
    if (!accessAllowed) return;

    if (!mounted) return;
    final navigator = Navigator.of(context);
    Future<bool?>? translationHomeRoute;
    Future<bool?> openTranslationHome({bool showSetupPrompt = false}) async {
      final routeResult = navigator.push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => HomeScreen(
            gameCatalog: _gameCatalog,
            showSubtitleSetupPrompt: showSetupPrompt,
            translationRunningOnOpen: true,
          ),
        ),
      );
      translationHomeRoute = routeResult;
      try {
        return await routeResult;
      } finally {
        if (identical(translationHomeRoute, routeResult)) {
          translationHomeRoute = null;
        }
      }
    }

    setState(() {
      _openingPs5 = true;
      _waitingForGameMemory = true;
    });
    try {
      final ready = await _ensureLatestSelectedGame();
      if (!mounted) return;
      setState(() => _waitingForGameMemory = false);
      if (!ready) {
        showMessage(
          'Oyun çevirileri yüklenemedi',
          _gameMemoryError ?? 'Oyun çeviri verisi belleğe alınamadı.',
        );
        return;
      }
      setState(() => _translationRunning = true);
      await _ps5Channel.invokeMethod<bool>('startTranslationForeground');
      // Let the home button's InkWell/Overlay animation finish before pushing
      // the native video route. On some Android builds an immediate push while
      // the tap overlay is active trips Flutter's Overlay deactivation assert.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      final explicitlyStopped = await navigator.push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => Ps5StreamScreen(
            // Reuse a manually opened Remote Play session instead of starting
            // a second native Chiaki session. _connect() will reattach to it.
            autoConnect: !sessionIsActive,
            activateSubtitlesOnStart: true,
            onTranslationReady: () async {
              if (!mounted) return null;
              setState(() {
                _openingPs5 = false;
                _translationRunning = true;
                _remotePlayActive = true;
                _remotePlaySessionConnected = true;
                _remotePlayVideoReady = true;
                _remotePlayConnected = true;
              });
              return openTranslationHome(showSetupPrompt: true);
            },
            onBackgroundTranslation: () =>
                translationHomeRoute ?? openTranslationHome(),
          ),
        ),
      );
      if (mounted) {
        var sessionStillActive = false;
        if (explicitlyStopped != true) {
          try {
            final state = await _ps5Channel.invokeMapMethod<String, dynamic>(
              'getSessionState',
            );
            sessionStillActive = state?['active'] == true;
          } on PlatformException {
            sessionStillActive = false;
          }
        }
        setState(() => _translationRunning = sessionStillActive);
        if (!sessionStillActive) {
          await _ps5Channel.invokeMethod<bool>('stopTranslationForeground');
        }
        // The language may have been changed on the translation screen that
        // was pushed on top of this one; show the stored choice again.
        await _loadTranslationPreferences();
        await _loadTranslationEngine();
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _translationRunning = false);
        await _ps5Channel.invokeMethod<bool>('stopTranslationForeground');
        showMessage("Çeviri başlatılamadı", error.message ?? error.code);
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingPs5 = false;
          _waitingForGameMemory = false;
        });
      }
    }
  }

  Future<void> _openPs5({bool openSubtitleSettings = false}) async {
    if (_openingPs5 || _loadingPs5) return;
    // Starting a session with the wrong pack is the costly moment to miss it.
    final languageWarning = _gameLanguageWarning;
    if (languageWarning != null && !openSubtitleSettings) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: panel,
          title: Text(context.tr('Oyun paketinin dili farklı')),
          content: Text(
            languageWarning,
            style: const TextStyle(color: muted, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('Vazgeç')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('Yine de başlat')),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    setState(() => _openingPs5 = true);
    try {
      final hasSavedPs5 = _savedPs5 != null;
      final Widget screen = !hasSavedPs5 && !openSubtitleSettings
          ? const PsnLoginScreen()
          : Ps5StreamScreen(
              autoConnect: hasSavedPs5 && !openSubtitleSettings,
              openSubtitleSettingsOnStart: openSubtitleSettings,
            );
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => screen),
      );
      await _loadSavedPs5();
    } finally {
      if (mounted) setState(() => _openingPs5 = false);
    }
  }

  Future<void> _managePs5Connection() async {
    Map<String, dynamic>? sessionState;
    try {
      sessionState = await _ps5Channel.invokeMapMethod<String, dynamic>(
        'getSessionState',
      );
    } on PlatformException {
      if (mounted) {
        showMessage(
          "PS5 durumu okunamadı",
          "Lütfen birkaç saniye sonra tekrar dene.",
        );
      }
      return;
    }
    final sessionConnected = sessionState?['connected'] == true;
    final videoReady = sessionState?['videoReady'] == true;
    final isConnected = sessionConnected && videoReady;
    final isActive = sessionState?['active'] == true;
    if (mounted) {
      setState(() {
        _remotePlayActive = isActive;
        _remotePlaySessionConnected = sessionConnected;
        _remotePlayVideoReady = videoReady;
        _remotePlayConnected = isConnected;
      });
    }

    if (isActive && !sessionConnected) {
      showMessage(
        "PS5’e bağlanılıyor",
        "Bağlantı tamamlanana kadar PS5 kaydını kaldıramazsın. Biraz bekleyip tekrar dene.",
      );
      return;
    }

    if (isActive && sessionConnected && !videoReady) {
      showMessage(
        "PS5 görüntüsü yenileniyor",
        "Remote Play bağlantısı açık. Görüntü yüzeyi hazırlanıyor.",
      );
      return;
    }

    if (isConnected) {
      await _confirmAndDisconnectRemotePlay();
      return;
    }

    await _confirmAndRemoveSavedPs5();
  }

  Future<void> _confirmAndDisconnectRemotePlay() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        title: Text(context.tr("Remote Play bağlantısı kesilsin mi?")),
        content: Text(
          context.tr(
            "PS5’teki Remote Play oturumu ve devam eden çeviri durur. PS5 kaydın korunur; daha sonra yeniden bağlanabilirsin.",
          ),
          style: TextStyle(color: muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr("İptal")),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.link_off),
            label: Text(context.tr("Bağlantıyı kes")),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await _ps5Channel.invokeMethod<bool>('stopSession');
      await _ps5Channel.invokeMethod<bool>('stopTranslationForeground');
      TvOutputService.instance.updateSubtitle('', _translationSettings);
      if (!mounted) return;
      setState(() {
        _translationRunning = false;
        _remotePlayActive = false;
        _remotePlaySessionConnected = false;
        _remotePlayVideoReady = false;
        _remotePlayConnected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr("Remote Play kesildi. PS5 kaydı korundu.")),
        ),
      );
    } on PlatformException catch (error) {
      if (mounted) {
        showMessage("Bağlantı kesilemedi", error.message ?? error.code);
      }
    }
  }

  Future<void> _confirmAndRemoveSavedPs5() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        title: Text(context.tr("Kayıtlı PS5 kaldırılsın mı?")),
        content: SingleChildScrollView(
          child: Text(
            context.tr(
              "Bu işlem telefondaki kayıtlı PS5 ve PSN eşleştirme bilgilerini siler. Tekrar eklemek için Sony hesabını doğrulayıp PS5’i yeniden kaydetmen gerekir. Kurulum genellikle yaklaşık 2–5 dakika sürer; Sony hesabı doğrulaması veya ağ bağlantısı yavaşsa daha uzun sürebilir.\n\nDevam etmek istiyor musun?",
            ),
            style: TextStyle(color: muted, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr("İptal")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr("PS5’i kaldır")),
          ),
        ],
      ),
    );
    if (!mounted || shouldRemove != true) return;
    try {
      final state = await _ps5Channel.invokeMapMethod<String, dynamic>(
        'getSessionState',
      );
      if (state?['active'] == true) {
        await _loadSavedPs5();
        if (mounted) {
          showMessage(
            "Remote Play açık",
            "Önce Remote Play bağlantısını kes. PS5 kaydı bağlantı kapandıktan sonra kaldırılabilir.",
          );
        }
        return;
      }
      await _ps5Channel.invokeMethod<bool>('deleteSavedConsole');
      await _ps5Channel.invokeMethod<bool>('stopTranslationForeground');
      TvOutputService.instance.updateSubtitle('', _translationSettings);
      await _loadSavedPs5();
      if (mounted) setState(() => _translationRunning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr("PS5 kayıtlı cihazlardan kaldırıldı.")),
          ),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        showMessage("PS5 kaldırılamadı", error.message ?? error.code);
      }
    }
  }

  void showMessage(String title, String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: panel,
        title: Text(context.trMessage(title)),
        content: Text(
          context.trMessage(message),
          style: const TextStyle(color: muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr("Tamam")),
          ),
        ],
      ),
    );
  }

  Future<void> showSubtitleSettings() async {
    final navigator = Navigator.of(context);
    final translationActive = await _isTranslationActive();
    // When this HomeScreen sits above the translation route, return to that
    // same stream even if Remote Play is reconnecting. This keeps the existing
    // video surface and OCR controller alive while the user edits settings.
    if (translationActive && navigator.canPop()) {
      navigator.pop<bool>(true);
      return;
    }

    await _openPs5(openSubtitleSettings: true);
    await _loadTranslationPreferences();
    await _refreshTranslationState();
  }

  Future<void> _showSubtitleSetupPrompt() async {
    await Future.wait([_loadSavedPs5(), _refreshTranslationState()]);
    if (!mounted) return;
    try {
      final dismissed =
          await _ps5Channel.invokeMethod<bool>(
            'getSubtitleSetupPromptDismissed',
          ) ??
          false;
      if (dismissed) return;
    } on PlatformException {
      // Show the prompt if the preference cannot be read.
    }

    if (!mounted) return;

    var neverShowAgain = false;
    final configureNow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: panel,
          title: Text(context.tr("Çeviri başladı")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  "Daha doğru sonuç için oyundaki yazıların bulunduğu OCR alanlarını ve çevrilen altyazının ekranda gösterileceği alanı ayarla. Bu ayarlar her oyun görüntüsüne göre değişebilir.",
                ),
                style: TextStyle(color: muted, height: 1.45),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: neverShowAgain,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(context.tr("Bir daha gösterme")),
                onChanged: (value) =>
                    setDialogState(() => neverShowAgain = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr("Daha sonra")),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.tune_rounded),
              label: Text(context.tr("Alanları ayarla")),
            ),
          ],
        ),
      ),
    );
    if (neverShowAgain) {
      try {
        await _ps5Channel.invokeMethod<void>(
          'setSubtitleSetupPromptDismissed',
          true,
        );
      } on PlatformException {
        // Keep the current session usable if the preference cannot be saved.
      }
    }
    if (configureNow == true && mounted) await showSubtitleSettings();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _selectedTab == _AppTab.home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedTab != _AppTab.home) {
          _selectTab(_AppTab.home);
        }
      },
      child: Scaffold(
        bottomNavigationBar: _buildBottomNavigation(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF15162C), bg, bg],
              stops: [0, 0.42, 1],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _selectedTab.index,
              sizing: StackFit.expand,
              children: [
                if (_visitedTabs.contains(_AppTab.subtitles))
                  _buildSubtitlePage()
                else
                  const SizedBox.shrink(),
                _buildHomePage(),
                if (_visitedTabs.contains(_AppTab.profile))
                  TickerMode(
                    enabled: _selectedTab == _AppTab.profile,
                    child: ProfileTab(
                      onChangeLanguage:
                          _changingAppLanguage || !_translationPreferencesReady
                          ? null
                          : _changeAppLanguage,
                      onOpenSubscription: _openAccess,
                      setupCompleted:
                          _setupGuideCompletedCount >=
                          SetupGuideScreen.totalSteps,
                      onOpenSetup: _openSetupGuide,
                      onOpenFaq: _openHelpScreen,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectTab(_AppTab tab) {
    if (_selectedTab == tab) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedTab = tab;
      _visitedTabs.add(tab);
    });
    if (tab == _AppTab.subtitles && !_loadingGames) unawaited(_refreshGames());
  }

  Widget _buildBottomNavigation() => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFF263047))),
    ),
    child: NavigationBarTheme(
      data: NavigationBarThemeData(
        height: 76,
        backgroundColor: const Color(0xFF101727),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: purple.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? Colors.white : muted,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF71BFFF)
                : muted,
            size: 24,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _selectedTab.index,
        onDestinationSelected: (index) => _selectTab(_AppTab.values[index]),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.subtitles_outlined),
            selectedIcon: Icon(Icons.subtitles_rounded),
            label: context.tr("Altyazı"),
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: context.tr("Ana sayfa"),
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: context.tr("Profil"),
          ),
        ],
      ),
    ),
  );

  Widget _buildSubtitlePage() => CustomScrollView(
    key: const PageStorageKey('subtitles-scroll'),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        sliver: SliverList.list(
          children: [
            SettingsPageHeader(
              title: context.tr("Altyazı"),
              description: context.tr(
                "Oyununu seç, altyazı görünümünü düzenle.",
              ),
            ),
            SettingsSection(
              title: context.tr("Görünüm ve alanlar"),
              children: [
                SettingsEntry(
                  icon: Icons.subtitles_rounded,
                  title: context.tr("Altyazı görünümü"),
                  subtitle: context.tr(
                    "Ekran önizlemesi, OCR alanları ve altyazı ayarları",
                  ),
                  onTap: showSubtitleSettings,
                ),
              ],
            ),
          ],
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        sliver: _buildGamesCard(),
      ),
    ],
  );

  Widget _buildHomePage() {
    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(),
              const SizedBox(height: 24),
              if (!AccessService.instance.status.premium &&
                  AccessService.instance.status.state != 'inactive' &&
                  !_translationRunning) ...[
                SubscriptionOfferCard(
                  status: AccessService.instance.status,
                  onViewPlans: _openingPs5 || _loadingPs5 ? null : _openAccess,
                ),
                const SizedBox(height: 12),
              ],
              _buildTranslateButton(),
              if (_setupGuideCompletedCount < SetupGuideScreen.totalSteps) ...[
                const SizedBox(height: 16),
                _buildHelp(),
              ],
              const SizedBox(height: 20),
              _buildConnectionCard(
                icon: Icons.sports_esports_rounded,
                title: 'PlayStation 5',
                subtitle: _savedPs5 == null
                    ? context.tr("Yeni veya kullanılmamış PSN hesabı gerekli")
                    : '${_remotePlayConnected
                          ? context.tr("Remote Play bağlı")
                          : _translationRunning && _remotePlaySessionConnected
                          ? context.tr("Çeviri açık • görüntü yenileniyor")
                          : _translationRunning
                          ? context.tr("Çeviri açık • PS5 yeniden bağlanıyor, lütfen bekleyin")
                          : _remotePlayActive
                          ? context.tr("PS5’e bağlanılıyor")
                          : context.tr("PS5 kaydı hazır")}${_savedPs5?['nickname'] == null ? '' : ' • ${_savedPs5!['nickname']}'}',
                connected: _remotePlayConnected,
                statusConnected:
                    _remotePlayConnected ||
                    (_savedPs5 != null &&
                        !_translationRunning &&
                        !_remotePlayActive),
                statusText: _savedPs5 == null
                    ? context.tr("Kurulu değil")
                    : _remotePlayConnected
                    ? context.tr("Bağlı")
                    : _translationRunning
                    ? context.tr("Yeniden bağlanıyor")
                    : _remotePlayActive
                    ? context.tr("Bağlanıyor")
                    : context.tr("Hazır"),
                loading:
                    _loadingPs5 ||
                    _openingPs5 ||
                    (_remotePlayActive && !_remotePlayConnected) ||
                    (_translationRunning && !_remotePlayConnected),
                loadingStatusText: _translationRunning
                    ? _remotePlaySessionConnected
                          ? context.tr("Görüntü yenileniyor")
                          : context.tr("Lütfen bekleyin")
                    : context.tr("Bağlanıyor"),
                accent: purple,
                buttonText: _loadingPs5
                    ? context.tr("PS5 kaydı kontrol ediliyor…")
                    : _openingPs5
                    ? context.tr("PS5 açılıyor…")
                    : _translationRunning && !_remotePlayConnected
                    ? _remotePlaySessionConnected
                          ? context.tr("Görüntü yenileniyor…")
                          : context.tr("PS5 yeniden bağlanıyor…")
                    : _remotePlayActive && !_remotePlayConnected
                    ? context.tr("PS5’e bağlanıyor…")
                    : _savedPs5 == null
                    ? context.tr("PS5’i kur")
                    : _remotePlayConnected
                    ? context.tr("Remote Play’e dön")
                    : context.tr("Remote Play’i aç"),
                onTap: _openPs5,
                secondaryButtonText: _savedPs5 == null || _loadingPs5
                    ? null
                    : (_remotePlayActive || _translationRunning) &&
                          !_remotePlayConnected
                    ? context.tr("Bağlanıyor…")
                    : _remotePlayConnected
                    ? context.tr("Bağlantıyı kes")
                    : context.tr("PS5’i listeden kaldır"),
                secondaryIcon: _remotePlayConnected
                    ? Icons.link_off_rounded
                    : Icons.delete_outline_rounded,
                onSecondaryTap:
                    _savedPs5 == null ||
                        ((_remotePlayActive || _translationRunning) &&
                            !_remotePlayConnected)
                    ? null
                    : _managePs5Connection,
              ),
              const SizedBox(height: 12),
              _buildConnectionCard(
                icon: Icons.tv_rounded,
                title: context.tr(
                  _tvPairing ? TvOutputService.instance.name : 'TV',
                ),
                subtitle: _tvConnecting
                    ? context.tr("TV’ye bağlantı kuruluyor")
                    : _tvPairing
                    ? context.tr("Bağlı • {0}", [
                        TvOutputService.instance.usesSecureTransport
                            ? context.tr("Şifreli")
                            : context.tr("Şifresiz"),
                      ])
                    : _savedTvAddress == null
                    ? context.tr("Altyazıları TV ekranında göster")
                    : context.tr("Eşleştirme kayıtlı • TV bağlı değil"),
                connected: _tvPairing,
                statusText: _tvPairing
                    ? context.tr("Bağlı")
                    : context.tr("Bağlı değil"),
                loading: _loadingTvAddress || _tvConnecting,
                loadingStatusText: _tvConnecting
                    ? context.tr("Bağlanıyor")
                    : context.tr("Kontrol ediliyor"),
                showProgress: _tvConnecting,
                accent: cyan,
                secondaryActionWhileLoading: _tvConnecting,
                buttonText: _tvConnecting
                    ? context.tr("TV’ye bağlanıyor…")
                    : _loadingTvAddress
                    ? context.tr("TV durumu kontrol ediliyor…")
                    : _tvPairing
                    ? context.tr("TV’yi yeniden eşleştir")
                    : context.tr("TV’yi eşleştir"),
                onTap: _pairTv,
                secondaryButtonText: _tvConnecting
                    ? context.tr("İptal")
                    : _tvPairing
                    ? context.tr("Bağlantıyı kes")
                    : _savedTvAddress != null &&
                          TvOutputService.instance.sessionToken != null
                    ? context.tr("Tekrar dene")
                    : null,
                secondaryIcon: _tvConnecting
                    ? Icons.close_rounded
                    : _tvPairing
                    ? Icons.link_off_rounded
                    : Icons.refresh_rounded,
                secondaryColor: !_tvPairing && !_tvConnecting ? cyan : null,
                onSecondaryTap: _tvConnecting
                    ? _cancelTvConnectionAttempt
                    : _tvPairing
                    ? _disconnectTv
                    : _savedTvAddress != null &&
                          TvOutputService.instance.sessionToken != null
                    ? _retryTvConnection
                    : null,
              ),
              const SizedBox(height: 24),
              _buildLanguageCard(),
              const SizedBox(height: 12),
              _buildTranslationEngineCard(),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  context.tr("{0}  •  OYUNUNA KENDİ DİLİNDE DEVAM ET", [
                    AppBranding.nameOf(context),
                  ]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF626D85),
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: purple.withValues(alpha: 0.24), blurRadius: 18),
            ],
          ),
          child: Image.asset(AppBranding.iconOf(context), fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppBranding.nameOf(context),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr("Oyununu kendi dilinde yaşa"),
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
        PremiumStatusButton(onOpenDetails: _openAccess),
      ],
    );
  }

  Widget _buildConnectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool connected,
    bool? statusConnected,
    String? statusText,
    bool loading = false,
    required Color accent,
    required String buttonText,
    required VoidCallback onTap,
    String? loadingStatusText,
    bool showProgress = false,
    bool secondaryActionWhileLoading = false,
    String? secondaryButtonText,
    IconData secondaryIcon = Icons.link_off_rounded,
    Color? secondaryColor,
    VoidCallback? onSecondaryTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF293249)),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(15) > 19;
              final status = _statusPill(
                statusConnected ?? connected,
                loading: loading,
                statusText: statusText,
                loadingStatusText: loadingStatusText,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 49,
                        height: 49,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: accent, size: 27),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!compact) status,
                    ],
                  ),
                  if (compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: status,
                    ),
                ],
              );
            },
          ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: 16),
          if (secondaryButtonText == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onTap,
                icon: Icon(
                  loading
                      ? Icons.hourglass_top
                      : connected
                      ? Icons.check_circle_outline
                      : Icons.add_link,
                  size: 18,
                ),
                label: Text(buttonText),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : onTap,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(
                        buttonText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: loading && !secondaryActionWhileLoading
                          ? null
                          : onSecondaryTap,
                      icon: Icon(secondaryIcon, size: 18),
                      label: Text(
                        secondaryButtonText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            secondaryColor ?? const Color(0xFFFF9B9B),
                        side: BorderSide(
                          color: (secondaryColor ?? const Color(0xFFFF9B9B))
                              .withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statusPill(
    bool connected, {
    bool loading = false,
    String? statusText,
    String? loadingStatusText,
  }) {
    final color = loading
        ? muted
        : connected
        ? cyan
        : const Color(0xFFFFC56D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              loading
                  ? loadingStatusText ?? context.tr("Kontrol ediliyor")
                  : statusText ??
                        (connected
                            ? context.tr("Kayıtlı")
                            : context.tr("Bağlı değil")),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard() {
    final localEngine = _translationEngine == 'opus';
    final hpltEngine = _translationEngine == 'hplt';
    final fixedEnglishTurkish = hpltEngine;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A29),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF263247)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.g_translate_rounded, color: cyan, size: 20),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.tr("ÇEVİRİ DİLLERİ"),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: localEngine || fixedEnglishTurkish
                    ? _fixedLanguageChip('English')
                    : _languageDropdown(true),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded, color: purple),
              ),
              Expanded(
                child: fixedEnglishTurkish
                    ? _fixedLanguageChip(context.tr("Türkçe"))
                    : _languageDropdown(false),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _buildSelectedModelStatus(source: true),
          _buildSelectedModelStatus(source: false),
        ],
      ),
    );
  }

  Widget _buildGamesCard() => ValueListenableBuilder<Set<String>>(
    valueListenable: _gameCatalog.downloadedPacks,
    builder: (context, downloadedPacks, _) =>
        _buildGameLibrary(downloadedPacks),
  );

  Widget _buildGameLibrary(Set<String> downloadedPacks) {
    final refreshWait = _gameCatalog.manualRefreshRemaining;
    final canRefreshGames =
        !_loadingGames && !_refreshingGames && refreshWait == Duration.zero;
    final languageScope = AppLanguageScope.maybeOf(context);
    // An explicit interface language also selects the library language.
    final libraryLocale =
        languageScope?.libraryLocale ?? Localizations.localeOf(context);
    final allowLanguageSelection = libraryLocale.languageCode == 'en';
    final languages = <String, GameCatalogEntry>{
      for (final game in _games) game.targetLanguage: game,
    };
    final selectedGame = _games
        .where((game) => game.id == _selectedGameId)
        .firstOrNull;
    final languageCode = allowLanguageSelection
        ? languages.containsKey(_libraryTargetLanguage)
              ? _libraryTargetLanguage
              : languages.keys.firstOrNull
        : libraryLocale.languageCode;
    final games = gameLibraryResults(
      _games,
      _gameSearchController.text,
      selectedGameId: _selectedGameId,
      targetLanguage: languageCode,
      downloadedContentKeys: downloadedPacks,
    );
    final gameIndices = {for (var i = 0; i < games.length; i++) games[i].id: i};
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF293249)),
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              key: _gameLibraryHeaderKey,
              padding: const EdgeInsets.fromLTRB(15, 16, 15, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final heading = Row(
                        children: [
                          const Icon(
                            Icons.sports_esports_rounded,
                            color: purple,
                            size: 20,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              context.tr("Oyun Kütüphanesi"),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('refresh-game-catalog'),
                            tooltip: refreshWait > Duration.zero
                                ? context.tr(
                                    'Tekrar denemek için {0} saniye bekle.',
                                    [
                                      (refreshWait.inMilliseconds / 1000)
                                          .ceil(),
                                    ],
                                  )
                                : context.tr('Oyun listesini yenile'),
                            onPressed: canRefreshGames
                                ? () => _refreshGames(manual: true)
                                : null,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            visualDensity: VisualDensity.compact,
                            color: cyan,
                          ),
                        ],
                      );
                      final requestGame = TextButton.icon(
                        key: const ValueKey('request-game-button'),
                        onPressed: () => AppLinks.requestGame(
                          context,
                          gameName: _gameSearchController.text.trim(),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: cyan,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        icon: const Icon(Icons.mail_outline_rounded, size: 16),
                        label: Text(context.tr('Oyun iste')),
                      );
                      if (constraints.maxWidth < 300 ||
                          MediaQuery.textScalerOf(context).scale(15) > 18) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            heading,
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: requestGame,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: heading),
                          requestGame,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr(
                      "Daha hızlı ve kaliteli bir çeviri deneyimi için oynadığın oyun listede varsa seç.",
                    ),
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  if (_loadingGames || _refreshingGames)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text(context.tr("Oyun listesi yükleniyor…")),
                      dense: true,
                    ),
                  if (_gamesRefreshFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'Güncel oyun listesi alınamadı. İnternet bağlantını kontrol edip tekrar dene.',
                            ),
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          TextButton.icon(
                            key: const ValueKey('retry-game-catalog'),
                            onPressed: canRefreshGames
                                ? () => _refreshGames(manual: true)
                                : null,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(context.tr('Tekrar dene')),
                          ),
                        ],
                      ),
                    ),
                  if (!_loadingGames && _gameLanguageWarning != null)
                    Container(
                      key: const ValueKey('game-language-warning'),
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFB74D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFFB74D),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _gameLanguageWarning!,
                              style: const TextStyle(
                                color: Color(0xFFFFD699),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_loadingGames &&
                      (_gamesError != null || _gameMemoryError != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        context.trMessage(_gamesError ?? _gameMemoryError!),
                        style: const TextStyle(
                          color: Color(0xFFFF9B8F),
                          fontSize: 12,
                        ),
                      ),
                    )
                  else if (!_loadingGames &&
                      !_refreshingGames &&
                      !_gamesRefreshFailed &&
                      _games.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        context.tr('Henüz oyun eklenmedi.'),
                        style: const TextStyle(color: muted, height: 1.5),
                      ),
                    ),
                  if (!_loadingGames && _games.isNotEmpty) ...[
                    if (allowLanguageSelection) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        key: ValueKey('game-library-language-$languageCode'),
                        initialValue: languageCode,
                        isExpanded: true,
                        dropdownColor: panel,
                        decoration: InputDecoration(
                          labelText: context.tr('Altyazı dili'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          for (final entry in languages.entries)
                            DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                entry.value.languageLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged:
                            _selectingGame || _translationRunning || _openingPs5
                            ? null
                            : (code) async {
                                if (code == null ||
                                    await _isTranslationActive() ||
                                    !mounted)
                                  return;
                                setState(() => _libraryTargetLanguage = code);
                                try {
                                  await _ps5Channel.invokeMethod<void>(
                                    'saveGameLibraryTargetLanguage',
                                    code,
                                  );
                                } on PlatformException {
                                  /* Retain the visible choice. */
                                } on MissingPluginException {
                                  /* Preview only. */
                                }
                              },
                      ),
                    ],
                    if (_translationRunning)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          context.tr(
                            'Dili veya oyunu değiştirmek için çeviriyi durdur.',
                          ),
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    if (allowLanguageSelection &&
                        selectedGame != null &&
                        selectedGame.targetLanguage != languageCode)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          context.tr('Seçili: {0} · {1}', [
                            selectedGame.name,
                            selectedGame.languageLabel,
                          ]),
                          style: const TextStyle(color: cyan, fontSize: 12),
                        ),
                      ),
                    if (selectedGame != null &&
                        selectedGame.targetLanguage == languageCode &&
                        _translationEngine == 'opus' &&
                        selectedGame.targetLanguage != _offlineTarget)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          context.tr(
                            'Seçili model bu dili desteklemiyor. Yalnızca oyun paketindeki metinler gösterilir.',
                          ),
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const ValueKey('game-library-search'),
                      controller: _gameSearchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        hintText: context.tr('Oyun adıyla ara'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _gameSearchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: context.tr('Aramayı temizle'),
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () =>
                                    setState(_gameSearchController.clear),
                              ),
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (games.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          context.tr(
                            !allowLanguageSelection &&
                                    !languages.containsKey(languageCode)
                                ? 'Bu dilde henüz oyun paketi yok.'
                                : 'Aramana uygun oyun bulunamadı.',
                          ),
                          style: const TextStyle(color: muted, height: 1.5),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (!_loadingGames && games.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final scaler = MediaQuery.textScalerOf(context);
                  final minimumWidth =
                      104 * (scaler.scale(12) / 12).clamp(1.0, 1.2);
                  final columns =
                      ((constraints.crossAxisExtent + 10) / (minimumWidth + 10))
                          .floor()
                          .clamp(1, 8);
                  final width =
                      (constraints.crossAxisExtent - 10 * (columns - 1)) /
                      columns;
                  return SliverGrid.builder(
                    itemCount: games.length,
                    findChildIndexCallback: (key) =>
                        key is ValueKey<String> ? gameIndices[key.value] : null,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      mainAxisExtent: GameCoverCard.heightFor(width, scaler),
                    ),
                    itemBuilder: (context, index) {
                      final game = games[index];
                      return SizedBox.expand(
                        key: ValueKey(game.id),
                        child: ListenableBuilder(
                          listenable: Listenable.merge([
                            _gameCatalog.downloadingPacks,
                            _gameCatalog.downloadedPacks,
                          ]),
                          builder: (context, _) => GameCoverCard(
                            game: game,
                            selected: _selectedGameId == game.id,
                            downloaded: _gameCatalog.downloadedPacks.value
                                .contains(game.contentKey),
                            downloading: _gameCatalog.downloadingPacks.value
                                .contains(game.contentKey),
                            preparing:
                                _selectedGameId == game.id &&
                                _gameMemoryLoading &&
                                !_gameCatalog.downloadingPacks.value.contains(
                                  game.contentKey,
                                ),
                            loadCover: _gameCatalog.loadCover,
                            onLongPress:
                                _selectingGame ||
                                    _gameMemoryLoading ||
                                    _openingPs5
                                ? null
                                : () => unawaited(_deleteGameDictionary(game)),
                            onTap:
                                _selectingGame ||
                                    _openingPs5 ||
                                    _translationRunning
                                ? null
                                : () => unawaited(
                                    _selectGame(
                                      _selectedGameId == game.id ? null : game,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _fixedLanguageChip(String label) => Container(
    height: 48,
    alignment: AlignmentDirectional.centerStart,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, color: Colors.white),
    ),
  );

  Widget _buildTranslationEngineCard() {
    final opusPairSupported =
        sourceLanguageCode == 'en' && targetLanguageCode == _offlineTarget;
    final hpltPairSupported =
        sourceLanguageCode == 'en' && targetLanguageCode == 'tr';
    final localEngine = _translationEngine == 'opus';
    final hpltEngine = _translationEngine == 'hplt';
    final deepLEngine = _translationEngine == 'deepl';
    final geminiEngine = _translationEngine == 'gemini';
    final cloudEngine = deepLEngine || geminiEngine;
    final selectedModelsReady = geminiEngine
        ? _geminiConfigured
        : deepLEngine
        ? _deepLConfigured
        : hpltEngine
        ? _hpltModelInstalled
        : localEngine
        ? _opusModelInstalled
        : _isLanguageDownloaded(sourceLanguageCode) &&
              _isLanguageDownloaded(targetLanguageCode);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A29),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF263247)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory_rounded, color: cyan, size: 20),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.tr("ÇEVİRİ MODELİ"),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(
              'En iyi çeviri için Oyun Kütüphanesi’ni öneriyoruz. Oyunun listede yoksa DeepL veya Gemini’yi, bunlara erişimin yoksa yerel modelleri kullanabilirsin.',
            ),
            style: const TextStyle(color: muted, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey(
              '$_translationEngine-$_translationEngineDropdownRevision',
            ),
            initialValue: _translationEngine,
            isExpanded: true,
            dropdownColor: panel,
            decoration: InputDecoration(
              filled: true,
              fillColor: bg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'opus',
                child: Text(
                  context.tr('Model A - Yerel Kaliteli'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'mlkit',
                child: Text(
                  context.tr('Model B - Yerel Hızlı'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'deepl',
                child: Text(
                  context.tr('DeepL (önerilen)'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'gemini',
                child: Text(
                  context.tr('Gemini (ücretsiz katman)'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            onChanged: !_translationPreferencesReady || _changingAppLanguage
                ? null
                : (engine) {
                    if (engine != null) _selectTranslationEngine(engine);
                  },
          ),
          const SizedBox(height: 8),
          if (deepLEngine) ...[
            DeepLSettingsPanel(
              hasKey: _deepLConfigured,
              onChanged: (hasKey) {
                setState(() => _deepLConfigured = hasKey);
                if (hasKey) unawaited(_loadDeepLLanguages());
              },
            ),
            if (_deepLLanguagesError != null)
              Text(
                context.trMessage(_deepLLanguagesError!),
                style: const TextStyle(color: Color(0xFFFFC56D), fontSize: 12),
              ),
          ],
          if (geminiEngine)
            GeminiSettingsPanel(
              hasKey: _geminiConfigured,
              onChanged: (hasKey) => setState(() => _geminiConfigured = hasKey),
            ),
          if (!cloudEngine && !selectedModelsReady)
            Text(
              hpltEngine
                  ? context.tr("Önce yaklaşık 80 MB HPLT model paketini indir.")
                  : localEngine
                  ? context.tr(
                      "İngilizceden seçtiğin hedef dile ait paketi indir.",
                    )
                  : context.tr(
                      "Seçtiğin kaynak ve hedef dillerin paketlerini indir.",
                    ),
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          const SizedBox(height: 8),
          if (!cloudEngine)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonalIcon(
                onPressed: _showTranslationLanguageManager,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(context.tr("Dilleri görüntüle ve indir")),
                style: FilledButton.styleFrom(
                  foregroundColor: const Color(0xFFB9F6ED),
                  backgroundColor: const Color(0xFF12312F),
                ),
              ),
            ),
          if (localEngine && !opusPairSupported)
            Text(
              context.tr(
                "Bu motor için kaynak dili İngilizce, hedef dili yukarıdaki seçim olmalı.",
              ),
              style: TextStyle(color: Color(0xFFFFC56D), fontSize: 11),
            ),
          if (hpltEngine && !hpltPairSupported)
            Text(
              context.tr(
                "Model C yalnızca İngilizce → Türkçe dil çiftiyle çalışır.",
              ),
              style: TextStyle(color: Color(0xFFFFC56D), fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _languageDropdown(bool source) {
    final value = source ? sourceLanguageCode : targetLanguageCode;
    final localEngine = _translationEngine == 'opus';
    final deepLEngine = _translationEngine == 'deepl';
    final geminiEngine = _translationEngine == 'gemini';
    final cloudEngine = deepLEngine || geminiEngine;
    final available = deepLEngine
        ? (source ? _deepLSourceLanguages : _deepLTargetLanguages)
        : geminiEngine
        ? (_translationModels.isNotEmpty
              ? _translationModels
              : const [
                  TranslationLanguageModel(
                    code: 'en',
                    name: 'English',
                    downloaded: true,
                  ),
                  TranslationLanguageModel(
                    code: 'tr',
                    name: 'Türkçe',
                    downloaded: true,
                  ),
                ])
        : localEngine
        ? _offlineModels
              .map(
                (model) => _LocalLanguageOption(
                  code: model['target'] as String,
                  name: context.tr(
                    model['label'] as String? ?? model['target'] as String,
                  ),
                  downloaded: model['installed'] == true,
                ),
              )
              .toList()
        : _translationModels;
    final selectable = available.where((model) {
      final code = model is _LocalLanguageOption
          ? model.code
          : (model as TranslationLanguageModel).code;
      final other = source ? targetLanguageCode : sourceLanguageCode;
      return cloudEngine
          ? code.split('-').first != other.split('-').first
          : code != other;
    }).toList();
    final selectedDownloaded = cloudEngine
        ? available.any(
            (row) => (row as TranslationLanguageModel).code == value,
          )
        : localEngine
        ? _offlineModels.any(
            (model) => model['target'] == value && model['installed'] == true,
          )
        : _isLanguageDownloaded(value);

    String optionCode(Object option) => option is _LocalLanguageOption
        ? option.code
        : (option as TranslationLanguageModel).code;
    // Model A'da kaynak her zaman İngilizce; listede gösterilmez.
    final selectedListed =
        !(source && localEngine) &&
        selectable.any((option) => optionCode(option) == value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedListed ? value : null,
          isExpanded: true,
          dropdownColor: panel,
          icon: const Icon(Icons.expand_more, size: 18),
          style: const TextStyle(fontSize: 12, color: Colors.white),
          hint: Text(
            (!cloudEngine && !localEngine && _loadingTranslationModels)
                ? context.tr("Diller yükleniyor…")
                : selectedDownloaded
                ? _languageName(value)
                : cloudEngine
                ? _languageName(value)
                : context.tr("{0} • indirilmedi", [_languageName(value)]),
            overflow: TextOverflow.ellipsis,
          ),
          selectedItemBuilder: (context) => selectable.map((language) {
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                selectedDownloaded
                    ? _languageName(optionCode(language))
                    : context.tr("{0} • indirilmedi", [
                        _languageName(optionCode(language)),
                      ]),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          items: selectable.map((language) {
            final code = optionCode(language);
            final name = language is _LocalLanguageOption
                ? language.name
                : _translationLanguageName(
                    language as TranslationLanguageModel,
                  );
            final downloaded = cloudEngine
                ? true
                : language is _LocalLanguageOption
                ? language.downloaded
                : (language as TranslationLanguageModel).downloaded;
            return DropdownMenuItem<String>(
              value: code,
              child: Text(
                downloaded ? name : context.tr("{0} • indirilmedi", [name]),
                overflow: TextOverflow.ellipsis,
                style: downloaded
                    ? null
                    : const TextStyle(color: muted, fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (source && localEngine) || selectable.isEmpty
              ? null
              : (code) {
                  if (code != null) {
                    _selectTranslationLanguage(source: source, code: code);
                  }
                },
        ),
      ),
    );
  }

  Widget _buildSelectedModelStatus({required bool source}) {
    if (const {'hplt', 'deepl', 'gemini'}.contains(_translationEngine)) {
      return const SizedBox.shrink();
    }
    final code = source ? sourceLanguageCode : targetLanguageCode;
    final localEngine = _translationEngine == 'opus';
    final downloaded = localEngine
        ? (source ||
              _offlineModels.any(
                (model) =>
                    model['target'] == code && model['installed'] == true,
              ))
        : _isLanguageDownloaded(code);
    final downloading = localEngine
        ? _opusDownloading
        : _downloadingLanguageCodes.contains(code);
    final status = _loadingTranslationModels && !localEngine
        ? context.tr("durum kontrol ediliyor")
        : downloaded
        ? context.tr("indirildi")
        : context.tr("indirilmedi");
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            _loadingTranslationModels
                ? Icons.hourglass_top
                : downloaded
                ? Icons.check_circle
                : Icons.download_for_offline_outlined,
            size: 15,
            color: _loadingTranslationModels
                ? muted
                : downloaded
                ? cyan
                : const Color(0xFFFFC56D),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${source ? context.tr("Kaynak") : context.tr("Hedef")}: ${_languageName(code)} • $status',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ),
          if ((localEngine || !_loadingTranslationModels) && !downloaded)
            downloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : InkWell(
                    onTap: () => localEngine
                        ? _downloadOpusModel()
                        : _downloadLanguage(code),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Text(
                        context.tr("İndir"),
                        style: TextStyle(
                          color: cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildTranslateButton() {
    return Container(
      key: const ValueKey('translation-start-stop'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0070D1), Color(0xFF0056A8)],
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap:
              _loadingPs5 ||
                  _openingPs5 ||
                  (!_translationRunning && _tvConnecting)
              ? null
              : _startOrStopTranslation,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 19),
            child: Row(
              children: [
                Icon(Icons.play_circle_fill_rounded, size: 35),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translationRunning
                            ? context.tr("ÇEVİRİYİ DURDUR")
                            : context.tr("ÇEVİRİYİ BAŞLAT"),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _loadingPs5
                            ? context.tr("PS5 kaydı kontrol ediliyor…")
                            : _openingPs5 && _waitingForGameMemory
                            ? context.tr('Oyun çevirileri hazırlanıyor…')
                            : _openingPs5
                            ? context.tr("Bağlantı hazırlanıyor…")
                            : _tvConnecting && !_translationRunning
                            ? context.tr("TV’ye bağlanılıyor…")
                            : _translationRunning
                            ? context.tr(
                                "Remote Play ve altyazı akışı durdurulur",
                              )
                            : _savedPs5 == null
                            ? context.tr("Önce PS5 kurulumunu tamamla")
                            : !_tvPairing
                            ? context.tr("Başlamak için TV’yi eşleştir")
                            : context.tr(
                                "PS5’e bağlanır ve altyazılar TV’de başlar",
                              ),
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (_openingPs5 && _waitingForGameMemory)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    _translationRunning
                        ? Icons.stop_circle_outlined
                        : Icons.arrow_forward_rounded,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelp() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _openSetupGuide,
        style: FilledButton.styleFrom(
          foregroundColor: const Color(0xFFEAF4FF),
          backgroundColor: const Color(0xFF12345A),
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: BorderSide(color: purple.withValues(alpha: 0.45)),
          ),
        ),
        icon: const Icon(Icons.checklist_rounded, color: Color(0xFF71BFFF)),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr("Kurulum rehberi"),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              context.tr("{0} / {1} adım tamamlandı", [
                _setupGuideCompletedCount,
                SetupGuideScreen.totalSteps,
              ]),
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
