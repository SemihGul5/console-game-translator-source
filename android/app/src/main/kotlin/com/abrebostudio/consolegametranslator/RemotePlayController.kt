package com.abrebostudio.consolegametranslator

import android.app.AlertDialog
import android.content.Context
import android.content.ContextWrapper
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import java.lang.ref.WeakReference
import android.content.Intent
import android.content.pm.PackageManager
import android.Manifest
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import android.view.Surface
import android.net.wifi.WifiManager
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.URL
import java.net.SocketTimeoutException
import java.util.concurrent.Executors
import org.json.JSONArray
import org.json.JSONObject
import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.TranslateRemoteModel
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.TranslatorOptions
import java.util.Locale
import java.util.UUID
import java.io.File
import java.util.concurrent.atomic.AtomicInteger
import javax.net.ssl.SSLException
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformViewFactory
import com.metallic.chiaki.lib.ChiakiLog
import com.metallic.chiaki.lib.Codec
import com.metallic.chiaki.lib.ConnectInfo
import com.metallic.chiaki.lib.ConnectVideoProfile
import com.metallic.chiaki.lib.DiscoveryService
import com.metallic.chiaki.lib.DiscoveryServiceOptions
import com.metallic.chiaki.lib.Event
import com.metallic.chiaki.lib.ConnectedEvent
import com.metallic.chiaki.lib.LoginPinRequestEvent
import com.metallic.chiaki.lib.QuitEvent
import com.metallic.chiaki.lib.RumbleEvent
import com.metallic.chiaki.lib.CreateError
import com.metallic.chiaki.lib.Regist
import com.metallic.chiaki.lib.RegistEvent
import com.metallic.chiaki.lib.RegistEventCanceled
import com.metallic.chiaki.lib.RegistEventFailed
import com.metallic.chiaki.lib.RegistEventSuccess
import com.metallic.chiaki.lib.RegistInfo
import com.metallic.chiaki.lib.Target
import com.metallic.chiaki.lib.Session
import com.metallic.chiaki.lib.VideoFPSPreset
import com.metallic.chiaki.lib.VideoResolutionPreset

internal class RemotePlayController private constructor(context: Context) : ContextWrapper(context.applicationContext) {
    companion object {
        @Volatile private var instance: RemotePlayController? = null

        fun get(context: Context): RemotePlayController =
            instance ?: synchronized(this) {
                instance ?: RemotePlayController(context).also { instance = it }
            }

        fun onServiceStopped() { instance?.stopSession() }
        private const val CHANNEL = "com.abrebostudio.consolegametranslator/ps5_registration"
        private const val EVENTS = "com.abrebostudio.consolegametranslator/ps5_events"
        private const val VIDEO_VIEW = "com.abrebostudio.consolegametranslator/chiaki_video"
        private const val NOTIFICATION_PERMISSION_REQUEST = 812
        const val ACTION_STOP_TRANSLATION = "com.abrebostudio.consolegametranslator.NOTIFICATION_STOP_TRANSLATION"
        const val ACTION_OPEN_HOME_FROM_TRANSLATION_NOTIFICATION =
            "com.abrebostudio.consolegametranslator.OPEN_HOME_FROM_TRANSLATION_NOTIFICATION"
    }

    private val worker = Executors.newSingleThreadExecutor()
    private val gameMemoryWorker = Executors.newSingleThreadExecutor()
    private val gameMemoryIndexWriter = Executors.newSingleThreadExecutor()
    private val psnAuthWorker = Executors.newSingleThreadExecutor()
    private var psnTurnstileDialog: PsnTurnstileDialog? = null
    private var psnExchangeInFlight = false
    private val opusModelWorker = Executors.newSingleThreadExecutor()
    private val hpltStatusWorker = Executors.newSingleThreadExecutor()
    private val deepLWorker = Executors.newSingleThreadExecutor()
    private val deepLCredentials by lazy { DeepLCredentialStore(applicationContext) }
    private val geminiCredentials by lazy { GeminiCredentialStore(applicationContext) }
    private val subtitleSettingsPrefs by lazy {
        getSharedPreferences("subtitle_presentation_settings", MODE_PRIVATE)
    }
    private val personalizationPrefs by lazy {
        getSharedPreferences("personalization_settings", MODE_PRIVATE)
    }
    private lateinit var consoleStore: RegisteredConsoleStore
    private var activeRegistration: Regist? = null
    private var pendingRegistrationResult: MethodChannel.Result? = null
    private var pendingTranslationNotificationResult: MethodChannel.Result? = null
    @Volatile private var activeSession: Session? = null
    @Volatile private var sessionStartPending = false
    @Volatile private var sessionCancellationRequested = false
    @Volatile private var sessionStopPending = false
    @Volatile private var sessionConnected = false
    private var activeDiscovery: DiscoveryService? = null
    private var eventSink: EventChannel.EventSink? = null
    @Volatile private var selectedGameMemory: GameTranslationMemory? = null
    private var selectedGameMemoryKey: GameTranslationMemoryKey? = null
    private val gameMemoryCache = GameTranslationMemoryCache()
    private val gameMemoryIndexStore by lazy {
        // Every install/update gets fresh indexes, so parser changes never meet old files.
        val installed = runCatching {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0).lastUpdateTime
        }.getOrDefault(0L)
        GameTranslationMemoryIndexStore(File(cacheDir, "game_memory_index"), "${BuildConfig.VERSION_CODE}-$installed")
            .also { store -> gameMemoryIndexWriter.execute { store.deleteStale() } }
    }
    @Volatile private var gameMemoryLoadGeneration = 0
    @Volatile private var latestSurface: Surface? = null
    @Volatile private var latestSurfaceOwner: Int? = null
    @Volatile private var decoderSurface: Surface? = null
    private var activityVisible = false
    private val videoOutputLock = Any()
    @Volatile private var videoFrames: BackgroundVideoFrameReader? = null
    private val backgroundVideoFrames: BackgroundVideoFrameReader
        get() = synchronized(videoOutputLock) {
            videoFrames ?: BackgroundVideoFrameReader().also { videoFrames = it }
        }

    private fun releaseVideoOutput() {
        val output = synchronized(videoOutputLock) {
            videoFrames.also { videoFrames = null }
        }
        runCatching { output?.close() }
            .onFailure { Log.w("GameTranslateRemotePlay", "Could not release video output", it) }
    }
    private val surfaceLock = Any()
    private val subtitleOcrDelegate = lazy {
        SubtitleOcrController(applicationContext, { videoFrames?.captureLatestBitmap() }, ::emit,
            croppedFrameProvider = { regions -> videoFrames?.captureLatestCrop(regions) }).also {
            it.setGameTranslationMemory(selectedGameMemory)
        }
    }
    private val subtitleOcr by subtitleOcrDelegate
    private var normalizedOcrRegions = listOf(floatArrayOf(0.10f, 0.78f, 0.80f, 0.22f))
    private var multicastLock: WifiManager.MulticastLock? = null
    private var registrationHost: String = ""
    @Volatile private var videoPlatformView: ChiakiVideoPlatformView? = null

    private var activityReference = WeakReference<MainActivity>(null)
    private val cacheDocuments by lazy { TranslationCacheDocuments(applicationContext,
        { activityReference.get() }, { translationAccess.isTranslationRequested },
        { if (subtitleOcrDelegate.isInitialized()) subtitleOcr.awaitCloudWorkBeforeCacheChange() },
        { if (subtitleOcrDelegate.isInitialized()) subtitleOcr.onManagedCacheChanged() }) }

    fun onCacheDocumentResult(requestCode: Int, resultCode: Int, data: Intent?) {
        cacheDocuments.onActivityResult(requestCode, resultCode, data)
    }
    private var backgroundPowerDialog: AlertDialog? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val translationAccess by lazy { TranslationAccessController.get(applicationContext) }
    private var engineConfigured = false
    val flutterEngine by lazy { FlutterEngine(applicationContext) }

    fun attach(activity: MainActivity) {
        activityReference = WeakReference(activity)
    }

    private fun runOnUiThread(action: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) action() else mainHandler.post(action)
    }

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        if (engineConfigured) return
        engineConfigured = true
        translationAccess.configure(flutterEngine.dartExecutor.binaryMessenger)
        translationAccess.onChanged = {
            configureSubtitleOcr()
            TranslationForegroundService.refreshAccessNotification()
            if (!translationAccess.hasAccess()) emit(mapOf("type" to "subtitleCleared"))
            emit(mapOf("type" to "accessChanged"))
        }
        translationAccess.onDenied = {
            emit(mapOf("type" to "accessDenied"))
            stopSession()
        }
        translationAccess.onStatusChanged = { emit(mapOf("type" to "accessChanged")) }
        consoleStore = RegisteredConsoleStore(applicationContext)
        translationEngine() // Migrate a previously selected Model C or D to Model A.
        worker.execute(::removeRetiredExperimentalModels)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            VIDEO_VIEW,
            object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
                override fun create(context: android.content.Context, viewId: Int, args: Any?) : ChiakiVideoPlatformView {
                    lateinit var platformView: ChiakiVideoPlatformView
                    platformView = ChiakiVideoPlatformView(
                        context,
                        backgroundFrameProvider = {
                            videoFrames?.captureLatestBitmap()
                        },
                        onSurfaceChanged = { surface ->
                            val ownsSurface = synchronized(surfaceLock) {
                                if (surface != null) {
                                    if (latestSurfaceOwner == null || viewId >= latestSurfaceOwner!!) {
                                        latestSurface = surface
                                        latestSurfaceOwner = viewId
                                        true
                                    } else {
                                        false
                                    }
                                } else if (latestSurfaceOwner == viewId) {
                                    // A delayed destroy from an older PlatformView must not erase
                                    // the newer stream view's surface.
                                    latestSurface = null
                                    latestSurfaceOwner = null
                                    true
                                } else {
                                    false
                                }
                            }
                            if (ownsSurface) recoverVideoOutput()
                        },
                        onDisposed = {
                            if (videoPlatformView === platformView) {
                                videoPlatformView = null
                                synchronized(surfaceLock) {
                                    if (latestSurfaceOwner == viewId) {
                                        latestSurface = null
                                        latestSurfaceOwner = null
                                    }
                                }
                            }
                        },
                    )
                    videoPlatformView = platformView
                    applySavedOcrRegions()
                    configureSubtitleOcr()
                    return platformView
                }
            },
        )
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    if (events != null && sessionConnected && translationAccess.canProcessFrames() && subtitleOcrDelegate.isInitialized()) {
                        subtitleOcr.resendCurrentCachedSubtitles()
                    }
                }
                override fun onCancel(arguments: Any?) { eventSink = null }
            })
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (cacheDocuments.handle(call, result)) return@setMethodCallHandler
                when (call.method) {
                    "getGameCatalogAppCheckDebugToken" -> result.success(
                        if (BuildConfig.DEBUG) BuildConfig.APP_CHECK_DEBUG_TOKEN.takeIf { it.isNotBlank() } else null,
                    )
                    "getGameCatalogCacheDirectory" -> result.success(
                        java.io.File(cacheDir, "game_catalog").absolutePath,
                    )
                    "getAppInfo" -> result.success(mapOf(
                        "version" to BuildConfig.VERSION_NAME,
                        "build" to BuildConfig.VERSION_CODE,
                        "privacyUrl" to BuildConfig.PRIVACY_POLICY_URL,
                        "termsUrl" to BuildConfig.TERMS_OF_USE_URL,
                    ))
                    "registerPs5" -> startRegistration(call, result)
                    "getSavedConsole" -> getSavedConsole(result)
                    "getSubtitleSettings" -> getSubtitleSettings(result)
                    "saveSubtitleSettings" -> saveSubtitleSettings(call, result)
                    "getSelectedGameId" -> result.success(
                        subtitleSettingsPrefs.getString("selected_game_id", null),
                    )
                    "saveSelectedGameId" -> saveSelectedGameId(call, result)
                    "commitGameTranslationSelection" -> commitGameTranslationSelection(call, result)
                    "getGameLibraryTargetLanguage" -> result.success(subtitleSettingsPrefs.getString("game_library_target", "tr"))
                    "saveGameLibraryTargetLanguage" -> {
                        val target = call.arguments as? String
                        if (target == null || !target.matches(Regex("[a-z]{2,3}(?:-[a-z0-9]{2,8})*"))) {
                            result.error("INVALID_GAME_LANGUAGE", "Hedef dil kodu geçersiz.", null)
                        } else if (!subtitleSettingsPrefs.edit().putString("game_library_target", target).commit()) {
                            result.error("GAME_SELECTION_SAVE_FAILED", "Dil seçimi kaydedilemedi.", null)
                        } else result.success(null)
                    }
                    "setGameTranslationMemory" -> setGameTranslationMemory(call, result)
                    "reportSubtitlePresentation" -> {
                        if (BuildConfig.DEBUG) {
                            val details = call.arguments as? Map<*, *>
                            Log.i("GameTranslateOCR", "SUBTITLE_PRESENTED area=${details?.get("area")} " +
                                "result=${details?.get("result")} id=${details?.get("id")} chars=${details?.get("chars")}")
                        }
                        result.success(null)
                    }
                    "activateCachedGameTranslationMemory" -> activateCachedGameTranslationMemory(call, result)
                    "forgetGameTranslationMemory" -> forgetGameTranslationMemory(call, result)
                    "getIncompleteSetupWarningDismissed" -> result.success(
                        personalizationPrefs.getBoolean("incomplete_setup_warning_dismissed", false),
                    )
                    "setIncompleteSetupWarningDismissed" -> {
                        val dismissed = call.arguments as? Boolean
                        if (dismissed == null) {
                            result.error("INVALID_ARGUMENT", "Uyarı tercihi geçersiz.", null)
                        } else if (!personalizationPrefs.edit()
                                .putBoolean("incomplete_setup_warning_dismissed", dismissed)
                                .commit()) {
                            result.error("SETUP_WARNING_PREFERENCE_SAVE_FAILED", "Uyarı tercihi kaydedilemedi.", null)
                        } else result.success(true)
                    }
                    "getSubtitleSetupPromptDismissed" -> result.success(
                        subtitleSettingsPrefs.getBoolean("subtitle_setup_prompt_dismissed", false),
                    )
                    "setSubtitleSetupPromptDismissed" -> {
                        val dismissed = call.arguments as? Boolean
                        if (dismissed == null) {
                            result.error("INVALID_ARGUMENT", "Uyarı tercihi geçersiz.", null)
                        } else {
                            subtitleSettingsPrefs.edit()
                                .putBoolean("subtitle_setup_prompt_dismissed", dismissed)
                                .apply()
                            result.success(true)
                        }
                    }
                    "updateSubtitleSettingsRuntime" -> {
                        updateSubtitleSettingsRuntime(call.arguments as? Map<*, *>)
                        result.success(true)
                    }
                    "getTranslationLanguageModels" -> getTranslationLanguageModels(result)
                    "downloadTranslationLanguage" -> downloadTranslationLanguage(call, result)
                    "prepareTranslationModels" -> prepareTranslationModels(result)
                    "getTranslationEngine" -> result.success(translationEngine())
                    "getGeminiSettings" -> withGeminiResult(result) {
                        geminiCredentials.metadata()
                    }
                    "getGeminiRuntimeStatus" -> result.success(if (subtitleOcrDelegate.isInitialized())
                        subtitleOcr.geminiRuntimeStatus() else mapOf("state" to "idle", "remainingMs" to 0L))
                    "saveGeminiApiKey" -> withGeminiResult(result) {
                        val key = GeminiClient.validateKey(call.arguments as? String ?: "")
                        // Reject duplicate/full lists locally before spending a connection-test request.
                        GeminiKeyList.adding(geminiCredentials.readAll(), key)
                        GeminiClient(key).checkConnection()
                        geminiCredentials.save(key)
                        runOnUiThread { configureSubtitleOcr() }
                        true
                    }
                    "testGeminiConnection" -> withGeminiResult(result) {
                        GeminiClient(geminiCredentials.read().orEmpty()).checkConnection()
                        true
                    }
                    "clearGeminiApiKey" -> withGeminiResult(result) {
                        geminiCredentials.clear()
                        runOnUiThread { configureSubtitleOcr() }
                        true
                    }
                    "removeGeminiApiKey" -> withGeminiResult(result) {
                        geminiCredentials.remove(call.arguments as? String ?: "")
                        runOnUiThread { configureSubtitleOcr() }
                        geminiCredentials.metadata()
                    }
                    "getDeepLSettings" -> withDeepLResult(result) {
                        mapOf("hasKey" to !deepLCredentials.read().isNullOrBlank())
                    }
                    "saveDeepLApiKey" -> withDeepLResult(result) {
                        val key = DeepLClient.validateKey(call.arguments as? String ?: "")
                        DeepLClient(key).checkConnection()
                        deepLCredentials.save(key)
                        runOnUiThread { configureSubtitleOcr() }
                        true
                    }
                    "testDeepLConnection" -> withDeepLResult(result) {
                        deepLClient().checkConnection()
                        true
                    }
                    "getDeepLUsage" -> withDeepLResult(result) { deepLClient().usage() }
                    "clearDeepLApiKey" -> withDeepLResult(result) {
                        deepLCredentials.clear()
                        runOnUiThread { configureSubtitleOcr() }
                        true
                    }
                    "getDeepLTranslationLanguages" -> withDeepLResult(result) {
                        val client = deepLClient()
                        mapOf("source" to client.languages(true), "target" to client.languages(false))
                    }
                    "getSetupChecklist" -> {
                        val checklist = runCatching {
                            JSONArray(subtitleSettingsPrefs.getString("setup_checklist_json", "[]"))
                                .let { array -> (0 until array.length()).map { array.optBoolean(it, false) } }
                        }.getOrDefault(emptyList())
                        result.success(checklist)
                    }
                    "saveSetupChecklist" -> {
                        val checks = call.arguments as? List<*>
                        if (checks == null || checks.size > 16 || checks.any { it !is Boolean }) {
                            result.error("INVALID_SETUP_CHECKLIST", "Kurulum işaretleri geçersiz.", null)
                        } else {
                            val array = JSONArray()
                            checks.forEach { array.put(it as Boolean) }
                            subtitleSettingsPrefs.edit().putString("setup_checklist_json", array.toString()).apply()
                            result.success(true)
                        }
                    }
                    "getOfflineTranslationModels" -> result.success(offlineTranslationModels())
                    "selectOfflineTranslationTarget" -> selectOfflineTranslationTarget(call, result)
                    "getHpltModelStatus" -> hpltStatusWorker.execute {
                        val installed = hpltNativeSupported() && hpltModelInstalled()
                        runOnUiThread { result.success(installed) }
                    }
                    "downloadHpltModel" -> downloadHpltModel(result)
                    "setTranslationEngine" -> {
                        val engine = call.arguments as? String
                        if (engine !in setOf("mlkit", "opus", "deepl", "gemini")) {
                            result.error("INVALID_TRANSLATION_ENGINE", "Çeviri motoru seçimi geçersiz.", null)
                        } else {
                            val editor = subtitleSettingsPrefs.edit().putString("translation_engine", engine)
                            if (engine == "opus") {
                                val target = offlineTarget().takeIf { it in OfflineMarianCatalog.targetCodes } ?: "tr"
                                editor.putString("offline_translation_target", target)
                                    .putString("translation_source", "en")
                                    .putString("translation_target", target)
                            }
                            if (engine == "hplt") {
                                editor.putString("translation_source", "en")
                                    .putString("translation_target", "tr")
                            }
                            editor.apply()
                            configureSubtitleOcr()
                            result.success(true)
                        }
                    }
                    "getOpusModelStatus" -> result.success(offlineModelInstalled(offlineTarget()))
                    "downloadOpusModel" -> downloadOpusModel(call, result)
                    "getSmartTvPairing" -> result.success(subtitleSettingsPrefs.getString("smart_tv_pairing", null))
                    "saveSmartTvPairing" -> {
                        val record = call.arguments as? String
                        if (record != null && record.length > 4096) {
                            result.error("TV_PAIRING_SAVE_FAILED", "TV eşleştirme bilgileri geçersiz.", null)
                        } else if (!subtitleSettingsPrefs.edit().putString("smart_tv_pairing", record).commit()) {
                            result.error("TV_PAIRING_SAVE_FAILED", "TV eşleştirmesi kaydedilemedi.", null)
                        } else result.success(true)
                    }
                    "getTvPairing" -> result.success(
                        mapOf(
                            "address" to subtitleSettingsPrefs.getString("tv_pairing_address", null),
                            "sessionToken" to subtitleSettingsPrefs.getString("tv_pairing_session_token", null),
                            "certificateFingerprint" to subtitleSettingsPrefs.getString("tv_pairing_certificate", null),
                        ),
                    )
                    "saveTvPairing" -> {
                        val pairing = call.arguments as? Map<*, *>
                        val address = pairing?.get("address") as? String
                        val sessionToken = pairing?.get("sessionToken") as? String
                        val fingerprint = pairing?.get("certificateFingerprint") as? String
                        if (address.isNullOrBlank() || sessionToken == null ||
                            !Regex("^[A-Za-z0-9_-]{40,64}$").matches(sessionToken) ||
                            (address.startsWith("wss://") &&
                                (fingerprint == null || !Regex("^[a-f0-9]{64}$").matches(fingerprint))) ||
                            (!address.startsWith("wss://") && fingerprint != null)) {
                            result.error("TV_PAIRING_SAVE_FAILED", "TV eşleştirme bilgileri geçersiz.", null)
                        } else if (!subtitleSettingsPrefs.edit()
                                .putString("tv_pairing_address", address)
                                .putString("tv_pairing_session_token", sessionToken)
                                .putString("tv_pairing_certificate", fingerprint)
                                .commit()) {
                            result.error("TV_PAIRING_SAVE_FAILED", "TV eşleştirmesi kaydedilemedi.", null)
                        } else result.success(true)
                    }
                    "clearTvPairing" -> {
                        subtitleSettingsPrefs.edit()
                            .remove("tv_pairing_address")
                            .remove("tv_pairing_session_token")
                            .remove("tv_pairing_certificate")
                            .apply()
                        result.success(true)
                    }
                    "getTvPairingAddress" -> result.success(subtitleSettingsPrefs.getString("tv_pairing_address", null))
                    "saveTvPairingAddress" -> {
                        val address = call.arguments as? String
                        if (address.isNullOrBlank() || !subtitleSettingsPrefs.edit().putString("tv_pairing_address", address).commit()) {
                            result.error("TV_PAIRING_SAVE_FAILED", "TV adresi kaydedilemedi.", null)
                        } else result.success(true)
                    }
                    "clearTvPairingAddress" -> {
                        subtitleSettingsPrefs.edit().remove("tv_pairing_address").apply()
                        result.success(true)
                    }
                    "getSubtitleProfiles" -> getSubtitleProfiles(result)
                    "saveSubtitleProfiles" -> saveSubtitleProfiles(call, result)
                    "captureSubtitleSnapshot" -> captureSubtitleSnapshot(result)
                    "getSubtitleSnapshot" -> getSubtitleSnapshot(call, result)
                    "testOcrSelectedRegion" -> {
                        subtitleOcr.captureOnce((call.arguments as? Number)?.toInt() ?: 0) { text, timings ->
                            emit(mapOf("type" to "ocrDebug", "text" to text, "timings" to timings))
                            runOnUiThread { result.success(mapOf("text" to text, "timings" to timings)) }
                        }
                    }
                    "getPsnAccountIdState" -> getPsnAccountIdState(result)
                    "exchangePsnCode" -> exchangePsnCode(call, result)
                    "deleteSavedConsole" -> {
                        stopSession { stopError ->
                            if (stopError != null) {
                                result.error("SESSION_STOP_FAILED", stopError, null)
                                return@stopSession
                            }
                            try {
                                consoleStore.clear()
                                result.success(true)
                            } catch (_: Exception) {
                                result.error("SECURE_STORAGE_DELETE_FAILED", "Kayıtlı PSN ve PS5 bilgileri silinemedi.", null)
                            }
                        }
                    }
                    "startDiscovery" -> startDiscovery(result)
                    "stopDiscovery" -> { stopDiscovery(); result.success(true) }
                    "startSession" -> startSession(result)
                    "startTranslationForeground" -> {
                        requestTranslationForeground(result)
                    }
                    "stopTranslationForeground" -> {
                        stopTranslationForeground()
                        result.success(true)
                    }
                    "isTranslationForegroundRunning" -> result.success(
                        TranslationForegroundService.isRunning && translationAccess.isTranslationRequested,
                    )
                    "isVideoSurfaceReady" -> result.success(true)
                    "recoverVideoOutput" -> {
                        recoverVideoOutput()
                        result.success(true)
                    }
                    "getSessionState" -> result.success(mapOf(
                        "active" to ((activeSession != null && !sessionStopPending) || sessionStartPending),
                        "connected" to (sessionConnected && !sessionStopPending),
                        "starting" to sessionStartPending,
                        "videoReady" to isVideoOutputReady(),
                    ))
                    "stopSession" -> stopSession { stopError ->
                        if (stopError == null) result.success(true)
                        else result.error("SESSION_STOP_FAILED", stopError, null)
                    }
                    "cancelRegistration" -> {
                        activeRegistration?.stop()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    fun onResume() {
        activityVisible = true
        translationAccess.onResume()
        recoverVideoOutput()
        if (sessionConnected) showBackgroundPowerExplanation()
    }

    fun onStop() {
        activityVisible = false
        // Preview removal must never reconfigure MediaCodec or stop OCR.
        recoverVideoOutput()
    }

    private fun isVideoOutputReady(): Boolean =
        !sessionStopPending && activeSession != null && decoderSurface?.isValid == true

    private fun recoverVideoOutput() {
        if (activeSession == null) return
        val surface = synchronized(surfaceLock) {
            latestSurface?.takeIf { activityVisible && it.isValid }
        }
        try {
            videoFrames?.setPreviewSurface(surface)
        } catch (error: Exception) {
            Log.w("GameTranslateRemotePlay", "Could not attach video preview; translation continues", error)
        }
    }

    private fun requestTranslationForeground(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            if (pendingTranslationNotificationResult != null) {
                result.error("NOTIFICATION_PERMISSION_PENDING", "Bildirim izni isteği zaten açık.", null)
                return
            }
            pendingTranslationNotificationResult = result
            val activity = activityReference.get()
            if (activity == null) {
                pendingTranslationNotificationResult = null
                startTranslationForeground(result)
            } else activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_PERMISSION_REQUEST)
            return
        }
        startTranslationForeground(result)
    }

    private fun startTranslationForeground(result: MethodChannel.Result) {
        if (cacheDocuments.isChanging) {
            result.error("CACHE_BUSY", "Önbellek işleminin tamamlanmasını bekle.", null)
            return
        }
        try {
            translationAccess.arm()
            translationAccess.onRemotePlayConnectionChanged(sessionConnected && !sessionStopPending)
        } catch (error: IllegalStateException) {
            result.error("ACCESS_REQUIRED", error.message, null)
            return
        }
        val intent = Intent(this, TranslationForegroundService::class.java)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent)
            else startService(intent)
            result.success(true)
        } catch (_: Exception) {
            result.error("FOREGROUND_SERVICE_START_FAILED", "Çeviri bildirimi başlatılamadı.", null)
        }
    }

    fun onRequestPermissionsResult(requestCode: Int) {
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST) return
        val result = pendingTranslationNotificationResult ?: return
        pendingTranslationNotificationResult = null
        startTranslationForeground(result)
    }

    private fun showBackgroundPowerExplanation() {
        if (!activityVisible) return
        val activity = activityReference.get() ?: return
        if (activity.isFinishing || activity.isDestroyed || backgroundPowerDialog != null) return
        val power = getSystemService(PowerManager::class.java)
        if (power.isIgnoringBatteryOptimizations(packageName) ||
            personalizationPrefs.getBoolean("background_power_explanation_shown", false)) return
        runCatching {
            backgroundPowerDialog = AlertDialog.Builder(activity, android.R.style.Theme_DeviceDefault_Dialog_Alert)
                .setTitle(AppUiLanguage.text(activity, "Ekran kapalıyken çeviri"))
                .setMessage(AppUiLanguage.localizedContext(activity).getString(R.string.battery_optimization_message, activity.getString(R.string.app_name)))
                .setNegativeButton(AppUiLanguage.text(activity, "Şimdi değil"), null)
                .setPositiveButton(AppUiLanguage.text(activity, "Ayarları aç")) { _, _ ->
                    runCatching {
                        activity.startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")))
                    }.onFailure { Log.w("GameTranslateRemotePlay", "Battery settings unavailable", it) }
                }
                .setOnDismissListener { backgroundPowerDialog = null }
                .show()
            personalizationPrefs.edit().putBoolean("background_power_explanation_shown", true).apply()
        }.onFailure { Log.w("GameTranslateRemotePlay", "Battery explanation unavailable", it) }
    }

    private fun stopTranslationForeground() {
        TranslationForegroundService.stop(this)
        translationAccess.disarm()
    }

    fun handleNotificationStopIntent(intent: Intent?) {
        if (intent?.action == ACTION_OPEN_HOME_FROM_TRANSLATION_NOTIFICATION) {
            emit(mapOf("type" to "translationNotificationTapped"))
        } else if (intent?.action == ACTION_STOP_TRANSLATION) {
            stopTranslationForeground()
            stopSession()
        } else {
            return
        }
        intent.action = null
    }

    private fun startRegistration(call: MethodCall, result: MethodChannel.Result) {
        if (activeRegistration != null) {
            result.error("REGISTRATION_BUSY", "Bir PS5 kayıt işlemi zaten çalışıyor.", null)
            return
        }

        val host = call.argument<String>("host")?.trim().orEmpty()
        registrationHost = host
        val pinText = call.argument<String>("pin")?.trim().orEmpty()

        if (!isValidIpv4(host)) {
            result.error("INVALID_HOST", "PS5 IPv4 adresini kontrol et.", null)
            return
        }

        val accountId = try {
            consoleStore.loadAccountId()
        } catch (_: Exception) {
            recoverFromKeystoreFailure()
            result.error("PSN_REAUTH_REQUIRED", "Güvenli PSN kaydı açılamadı. PSN hesabını yeniden doğrula.", null)
            return
        }
        if (accountId == null || accountId.size != RegistInfo.ACCOUNT_ID_SIZE) {
            result.error("PSN_AUTH_REQUIRED", "Önce PSN hesabını doğrula.", null)
            return
        }

        if (!pinText.matches(Regex("^\\d{8}$"))) {
            result.error("INVALID_PIN", "PIN kodu 8 rakam olmalı.", null)
            return
        }

        val info = RegistInfo(
            target = Target.PS5_1,
            host = host,
            broadcast = false,
            psnOnlineId = null,
            psnAccountId = accountId,
            pin = pinText.toInt()
        )
        // Chiaki diagnostic messages may contain registration or session data.
        // Keep them out of logcat, where debug/crash tooling can collect them.
        val log = ChiakiLog(0) { _, _ -> }

        pendingRegistrationResult = result
        try {
            activeRegistration = Regist(info, log) { event ->
                runOnUiThread { handleRegistrationEvent(event) }
            }
        } catch (error: CreateError) {
            pendingRegistrationResult = null
            activeRegistration = null
            result.error("REGISTRATION_START_FAILED", "Chiaki kayıt işlemi başlatılamadı.", null)
        } catch (error: Exception) {
            pendingRegistrationResult = null
            activeRegistration = null
            result.error("REGISTRATION_START_FAILED", "Kayıt başlatılırken hata oluştu.", null)
        }
    }

    private fun handleRegistrationEvent(event: RegistEvent) {
        val result = pendingRegistrationResult ?: return
        when (event) {
            is RegistEventSuccess -> {
                val host = event.host
                try {
                    consoleStore.save(
                        RegisteredConsoleStore.Console(
                            host = registrationHost,
                            nickname = host.serverNickname,
                            registrationKey = host.rpRegistKey,
                            morning = host.rpKey,
                        ),
                    )
                    result.success(
                        mapOf(
                            "status" to "success",
                            "host" to registrationHost,
                            "nickname" to host.serverNickname,
                            "accessPointName" to host.apName,
                        ),
                    )
                    emit(mapOf("type" to "registered", "nickname" to host.serverNickname))
                } catch (error: Exception) {
                    result.error("SECURE_STORAGE_FAILED", "PS5 kaydı alındı ancak güvenli depoya yazılamadı.", null)
                } finally {
                    pendingRegistrationResult = null
                    releaseRegistration()
                }
            }
            is RegistEventFailed -> {
                result.error("REGISTRATION_FAILED", "Chiaki-ng PS5 kaydını tamamlayamadı. Host ve PIN bilgilerini kontrol edip yeniden dene.", null)
                pendingRegistrationResult = null
                releaseRegistration()
            }
            is RegistEventCanceled -> {
                result.error("REGISTRATION_CANCELED", "PS5 kayıt işlemi iptal edildi.", null)
                pendingRegistrationResult = null
                releaseRegistration()
            }
        }
    }

    private fun releaseRegistration() {
        val current = activeRegistration
        activeRegistration = null
        try {
            current?.dispose()
        } catch (_: Exception) {
            // Do not send native exception details to logcat.
        }
    }

    private fun getSavedConsole(result: MethodChannel.Result) {
        try {
            val console = consoleStore.load()
            result.success(console?.let {
                mapOf("host" to it.host, "nickname" to it.nickname)
            })
        } catch (_: Exception) {
            recoverFromKeystoreFailure()
            result.error("SAVED_CONSOLE_READ_FAILED", "Kayıtlı PS5 bilgileri çözülemedi. Yeniden eşleştirmen gerekebilir.", null)
        }
    }

    private fun storedSampleRateHz(): Double {
        val prefs = subtitleSettingsPrefs
        return runCatching { prefs.getFloat("sample_rate_hz", 10f).toDouble() }
            .getOrDefault(10.0)
            .coerceIn(0.25, 20.0)
    }

    private fun readRegionSettings(key: String): List<Map<String, Any?>> = try {
        val values = JSONArray(subtitleSettingsPrefs.getString(key, "[]"))
        (0 until values.length().coerceAtMost(12)).map { index ->
            val item = values.optJSONObject(index)
            item?.keys()?.asSequence()?.associateWith { item.opt(it) } ?: emptyMap()
        }
    } catch (_: Exception) { emptyList() }

    private fun getSubtitleSettings(result: MethodChannel.Result) {
        val prefs = subtitleSettingsPrefs
        val fallbackRegion = mapOf(
            "left" to prefs.getFloat("ocr_left", 0.10f).toDouble(),
            "top" to prefs.getFloat("ocr_top", 0.78f).toDouble(),
            "width" to prefs.getFloat("ocr_width", 0.80f).toDouble(),
            "height" to prefs.getFloat("ocr_height", 0.22f).toDouble(),
        )
        val regions = try {
            val parsed = JSONArray(prefs.getString("ocr_regions_json", "[]"))
            (0 until parsed.length()).map { index ->
                val rect = parsed.getJSONObject(index)
                mapOf("left" to rect.optDouble("left", 0.10), "top" to rect.optDouble("top", 0.78),
                    "width" to rect.optDouble("width", 0.80), "height" to rect.optDouble("height", 0.22))
            }.ifEmpty { listOf(fallbackRegion) }
        } catch (_: Exception) { listOf(fallbackRegion) }
        val subtitleRegions = try {
            val parsed = JSONArray(prefs.getString("subtitle_regions_json", "[]"))
            (0 until parsed.length()).map { index ->
                val rect = parsed.getJSONObject(index)
                mapOf(
                    "left" to rect.optDouble("left", 0.10),
                    "top" to rect.optDouble("top", 0.78),
                    "width" to rect.optDouble("width", 0.80),
                    "height" to rect.optDouble("height", 0.22),
                )
            }.take(12)
        } catch (_: Exception) { emptyList() }
        result.success(
            mapOf(
                "ocrRegion" to fallbackRegion,
                "ocrRegions" to regions,
                "subtitleBounds" to mapOf(
                    "left" to prefs.getFloat("subtitle_left", 0.10f).toDouble(),
                    "top" to prefs.getFloat("subtitle_top", 0.78f).toDouble(),
                    "width" to prefs.getFloat("subtitle_width", 0.80f).toDouble(),
                    "height" to prefs.getFloat("subtitle_height", 0.22f).toDouble(),
                ),
                "subtitleRegions" to subtitleRegions,
                "subtitleStyles" to readRegionSettings("subtitle_styles_json"),
                "ocrRegionSettings" to readRegionSettings("ocr_region_settings_json"),
                "enabled" to true,
                "sourceLanguageCode" to prefs.getString("translation_source", "en"),
                "targetLanguageCode" to prefs.getString("translation_target", "tr"),
                "sampleRateHz" to storedSampleRateHz(),
                "ocrPreprocessingMode" to prefs.getInt("ocr_preprocessing_mode", 0),
                "ocrPreprocessingModes" to readOcrPreprocessingModes(prefs, regions.size),
                "ocrDialogueFilter" to prefs.getBoolean("ocr_dialogue_filter", false),
                "ocrDialogueFilters" to readOcrDialogueFilters(prefs, regions.size),
                "ocrCaptureScale" to storedOcrCaptureScale(),
                "holdSeconds" to prefs.getFloat("hold_seconds", 2.5f).toDouble(),
                "autoHideEnabled" to true,
                "autoHideAfterSeconds" to prefs.getFloat("auto_hide_after_seconds", 2f).toDouble(),
                "backgroundColor" to prefs.getLong("background_color", 0xFF000000L),
                // New installs start fully opaque; older installs keep what they saved.
                "backgroundOpacity" to when {
                    prefs.contains("background_opacity") -> prefs.getFloat("background_opacity", 1f).toDouble()
                    prefs.contains("background_color") ->
                        ((prefs.getLong("background_color", 0xFF000000L) ushr 24) and 0xFF).toDouble() / 255.0
                    else -> 1.0
                },
                "textColor" to prefs.getLong("text_color", 0xFFFFFFFFL),
                "fontSize" to prefs.getFloat("font_size", 22f).toDouble(),
                "useGameFont" to prefs.getBoolean("use_game_font", true),
                "centered" to prefs.getBoolean("centered", true),
                "bold" to prefs.getBoolean("bold", false),
                "backgroundFitToText" to prefs.getBoolean("background_fit_text", true),
            ),
        )
    }

    private fun getSubtitleProfiles(result: MethodChannel.Result) {
        val raw = subtitleSettingsPrefs.getString("profiles_json", null)
        if (raw == null) {
            result.success("[]")
            return
        }
        try {
            val profiles = JSONArray(raw)
            result.success(profiles.toString())
        } catch (_: Exception) {
            result.success("[]")
        }
    }

    private fun saveSubtitleProfiles(call: MethodCall, result: MethodChannel.Result) {
        val profiles = call.arguments as? List<*> ?: run {
            result.error("INVALID_SUBTITLE_PROFILES", "Oyun profilleri okunamadı.", null)
            return
        }
        try {
            val json = JSONArray()
            profiles.take(50).forEach { profile ->
                val map = profile as? Map<*, *> ?: return@forEach
                val name = map["name"] as? String ?: return@forEach
                val settings = map["settings"] as? Map<*, *> ?: return@forEach
                val profile = JSONObject().put("name", name.take(48)).put("settings", JSONObject(settings))
                    .put("isDefault", map["isDefault"] == true)
                (map["snapshotId"] as? String)?.takeIf(::isValidSnapshotId)?.let {
                    profile.put("snapshotId", it)
                }
                json.put(profile)
            }
            if (!subtitleSettingsPrefs.edit().putString("profiles_json", json.toString()).commit()) {
                result.error("SUBTITLE_PROFILES_SAVE_FAILED", "Oyun profilleri kaydedilemedi.", null)
                return
            }
            result.success(true)
        } catch (_: Exception) {
            result.error("SUBTITLE_PROFILES_SAVE_FAILED", "Oyun profilleri kaydedilemedi.", null)
        }
    }

    private fun snapshotDirectory(): File = File(filesDir, "subtitle_snapshots").apply { mkdirs() }

    private fun isValidSnapshotId(value: String): Boolean = try {
        UUID.fromString(value).toString() == value
    } catch (_: Exception) { false }

    private fun captureSubtitleSnapshot(result: MethodChannel.Result) {
        val view = videoPlatformView
        if (view == null) {
            result.error("VIDEO_VIEW_UNAVAILABLE", "PS5 görüntü alanı hazır değil.", null)
            return
        }
        view.captureSnapshot { bytes ->
            if (bytes == null) {
                runOnUiThread {
                    result.error("SNAPSHOT_CAPTURE_FAILED", "PS5 karesini alamadım. Remote Play görüntüsü açıkken yeniden dene.", null)
                }
                return@captureSnapshot
            }
            try {
                val id = UUID.randomUUID().toString()
                File(snapshotDirectory(), "$id.jpg").writeBytes(bytes)
                runOnUiThread { result.success(mapOf("id" to id, "image" to bytes)) }
            } catch (_: Exception) {
                runOnUiThread {
                    result.error("SNAPSHOT_SAVE_FAILED", "PS5 ekran görüntüsü uygulama alanına kaydedilemedi.", null)
                }
            }
        }
    }

    private fun getSubtitleSnapshot(call: MethodCall, result: MethodChannel.Result) {
        val id = call.arguments as? String
        if (id == null || !isValidSnapshotId(id)) {
            result.error("INVALID_SNAPSHOT_ID", "Kayıtlı ekran görüntüsü bulunamadı.", null)
            return
        }
        val file = File(snapshotDirectory(), "$id.jpg")
        if (!file.isFile) {
            result.success(null)
            return
        }
        try {
            result.success(file.readBytes())
        } catch (_: Exception) {
            result.success(null)
        }
    }

    private fun saveSubtitleSettings(call: MethodCall, result: MethodChannel.Result) {
        val settings = call.arguments as? Map<*, *>
        if (settings == null) {
            result.error("INVALID_SUBTITLE_SETTINGS", "Altyazı ayarları okunamadı.", null)
            return
        }

        fun number(value: Any?, fallback: Float): Float =
            (value as? Number)?.toFloat()?.takeIf { it.isFinite() } ?: fallback

        fun saveRect(key: String, prefix: String, defaults: List<Float>, editor: android.content.SharedPreferences.Editor) {
            val value = settings[key] as? Map<*, *>
            val left = number(value?.get("left"), defaults[0]).coerceIn(0f, 0.98f)
            val top = number(value?.get("top"), defaults[1]).coerceIn(0f, 0.98f)
            val width = number(value?.get("width"), defaults[2]).coerceIn(0.02f, 1f - left)
            val height = number(value?.get("height"), defaults[3]).coerceIn(0.02f, 1f - top)
            editor.putFloat("${prefix}_left", left)
            editor.putFloat("${prefix}_top", top)
            editor.putFloat("${prefix}_width", width)
            editor.putFloat("${prefix}_height", height)
        }

        val editor = subtitleSettingsPrefs.edit()
        for ((field, key) in listOf("subtitleStyles" to "subtitle_styles_json", "ocrRegionSettings" to "ocr_region_settings_json")) {
            val values = JSONArray()
            (settings[field] as? List<*>)?.take(12)?.forEach { raw ->
                values.put(JSONObject(raw as? Map<*, *> ?: emptyMap<Any, Any>()))
            }
            editor.putString(key, values.toString())
        }
        val inputRegions = settings["ocrRegions"] as? List<*>
        val regionsJson = JSONArray()
        inputRegions?.take(12)?.forEach { raw ->
            val rect = raw as? Map<*, *> ?: return@forEach
            val normalized = JSONObject()
            normalized.put("left", number(rect["left"], 0.10f).coerceIn(0f, 0.98f).toDouble())
            normalized.put("top", number(rect["top"], 0.78f).coerceIn(0f, 0.98f).toDouble())
            normalized.put("width", number(rect["width"], 0.80f).coerceIn(0.02f, 1f - number(rect["left"], 0.10f).coerceIn(0f, 0.98f)).toDouble())
            normalized.put("height", number(rect["height"], 0.22f).coerceIn(0.02f, 1f - number(rect["top"], 0.78f).coerceIn(0f, 0.98f)).toDouble())
            regionsJson.put(normalized)
        }
        val firstRegion = (inputRegions?.firstOrNull() as? Map<*, *>)
        val firstMap = if (firstRegion != null) mapOf(
            "left" to firstRegion["left"], "top" to firstRegion["top"],
            "width" to firstRegion["width"], "height" to firstRegion["height"],
        ) else settings["ocrRegion"]
        saveRectValue(firstMap, "ocr", listOf(0.10f, 0.78f, 0.80f, 0.22f), editor)
        editor.putString("ocr_regions_json", if (regionsJson.length() == 0) "[]" else regionsJson.toString())
        saveRect("subtitleBounds", "subtitle", listOf(0.10f, 0.78f, 0.80f, 0.22f), editor)
        val subtitleRegions = JSONArray()
        (settings["subtitleRegions"] as? List<*>)?.take(12)?.forEach { raw ->
            val rect = raw as? Map<*, *> ?: return@forEach
            val left = number(rect["left"], 0.10f).coerceIn(0f, 0.98f)
            val top = number(rect["top"], 0.78f).coerceIn(0f, 0.98f)
            val width = number(rect["width"], 0.80f).coerceIn(0.02f, 1f - left)
            val height = number(rect["height"], 0.22f).coerceIn(0.02f, 1f - top)
            subtitleRegions.put(
                JSONObject()
                    .put("left", left.toDouble())
                    .put("top", top.toDouble())
                    .put("width", width.toDouble())
                    .put("height", height.toDouble()),
            )
        }
        editor.putString("subtitle_regions_json", subtitleRegions.toString())
        editor.remove("enabled")
        val supportedLanguages = TranslateLanguage.getAllLanguages()
        fun supportedLanguage(code: String) = if (translationEngine() in setOf("deepl", "gemini"))
            code.matches(Regex("[a-z]{2,3}(?:-[a-z0-9]{2,8})*")) else code in supportedLanguages
        (settings["sourceLanguageCode"] as? String)?.takeIf(::supportedLanguage)?.let {
            editor.putString("translation_source", it)
        }
        (settings["targetLanguageCode"] as? String)?.takeIf(::supportedLanguage)?.let {
            editor.putString("translation_target", it)
        }
        (settings["sampleRateHz"] as? Number)?.let {
            editor.putFloat("sample_rate_hz", it.toDouble().coerceIn(0.25, 20.0).toFloat())
        }
        (settings["ocrPreprocessingMode"] as? Number)?.let {
            editor.putInt("ocr_preprocessing_mode", it.toInt().coerceIn(0, 9))
        }
        val preprocessingModesJson = JSONArray()
        (settings["ocrPreprocessingModes"] as? List<*>)?.take(12)?.forEach { mode ->
            preprocessingModesJson.put(((mode as? Number)?.toInt() ?: 0).coerceIn(0, 9))
        }
        editor.putString("ocr_preprocessing_modes_json", preprocessingModesJson.toString())
        (settings["ocrDialogueFilter"] as? Boolean)?.let {
            editor.putBoolean("ocr_dialogue_filter", it)
        }
        val dialogueFiltersJson = JSONArray()
        (settings["ocrDialogueFilters"] as? List<*>)?.take(12)?.forEach { filter ->
            dialogueFiltersJson.put(filter as? Boolean ?: false)
        }
        editor.putString("ocr_dialogue_filters_json", dialogueFiltersJson.toString())
        (settings["ocrCaptureScale"] as? Number)?.let {
            editor.putInt("ocr_capture_scale_tenths", ocrCaptureScaleTenths(it))
            editor.putBoolean("ocr_capture_scale_tenths_migrated", true)
        }
        (settings["holdSeconds"] as? Number)?.let {
            editor.putFloat("hold_seconds", it.toFloat().coerceIn(0f, 10f))
        }
        editor.putBoolean("auto_hide_enabled", true)
        (settings["autoHideAfterSeconds"] as? Number)?.let {
            editor.putFloat("auto_hide_after_seconds", it.toFloat().coerceIn(0.5f, 30f))
        }
        (settings["backgroundColor"] as? Number)?.let {
            editor.putLong("background_color", it.toLong() and 0xFFFFFFFFL)
        }
        (settings["backgroundOpacity"] as? Number)?.let {
            editor.putFloat("background_opacity", it.toFloat().coerceIn(0f, 1f))
        }
        (settings["textColor"] as? Number)?.let {
            editor.putLong("text_color", it.toLong() and 0xFFFFFFFFL)
        }
        (settings["fontSize"] as? Number)?.let {
            editor.putFloat("font_size", it.toFloat().coerceIn(4f, 64f))
        }
        (settings["useGameFont"] as? Boolean)?.let { editor.putBoolean("use_game_font", it) }
        (settings["centered"] as? Boolean)?.let { editor.putBoolean("centered", it) }
        (settings["bold"] as? Boolean)?.let { editor.putBoolean("bold", it) }
        (settings["backgroundFitToText"] as? Boolean)?.let {
            editor.putBoolean("background_fit_text", it)
        }

        if (!editor.commit()) {
            result.error("SUBTITLE_SETTINGS_SAVE_FAILED", "Altyazı ayarları kaydedilemedi.", null)
            return
        }
        applySavedOcrRegions()
        configureSubtitleOcr()
        result.success(true)
    }

    private fun saveSelectedGameId(call: MethodCall, result: MethodChannel.Result) {
        val gameId = call.arguments as? String
        val editor = subtitleSettingsPrefs.edit()
        if (gameId.isNullOrBlank()) editor.remove("selected_game_id")
        else editor.putString("selected_game_id", gameId)
        if (editor.commit()) {
            if (subtitleOcrDelegate.isInitialized()) subtitleOcr.setGameSelected(!gameId.isNullOrBlank() || selectedGameMemory != null)
            result.success(true)
        }
        else result.error("GAME_SELECTION_SAVE_FAILED", "Oyun seçimi kaydedilemedi.", null)
    }

    private fun gameMemoryKey(arguments: Map<*, *>?): GameTranslationMemoryKey? {
        fun text(key: String) = (arguments?.get(key) as? String)?.takeIf { it.isNotBlank() }
        return GameTranslationMemoryKey(
            text("gameId") ?: return null,
            text("sourceLanguage") ?: return null,
            text("targetLanguage") ?: return null,
            text("contentKey") ?: return null,
        )
    }

    private fun commitGameTranslationSelection(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        val key = gameMemoryKey(arguments)
        val packId = arguments?.get("packId") as? String
        if (key == null || key != selectedGameMemoryKey || selectedGameMemory == null ||
            packId == null || !packId.matches(Regex("[a-z0-9][a-z0-9_-]{0,111}"))) {
            result.error("GAME_SELECTION_NOT_READY", "Dil paketi henüz hazır değil.", null)
            return
        }
        if (!subtitleSettingsPrefs.edit().putString("selected_game_id", packId)
                .putString("game_library_target", key.targetLanguage)
                .putString("translation_source", key.sourceLanguage)
                .putString("translation_target", key.targetLanguage).commit()) {
            result.error("GAME_SELECTION_SAVE_FAILED", "Oyun ve dil seçimi kaydedilemedi.", null)
            return
        }
        configureSubtitleOcr()
        result.success(null)
    }

    private fun applyGameMemory(memory: GameTranslationMemory?, key: GameTranslationMemoryKey?) {
        selectedGameMemory = memory
        selectedGameMemoryKey = key
        if (subtitleOcrDelegate.isInitialized()) {
            subtitleOcr.setGameSelected(!subtitleSettingsPrefs.getString("selected_game_id", null).isNullOrBlank() || memory != null)
            subtitleOcr.setGameTranslationMemory(memory)
        }
    }

    private fun activateCachedGameTranslationMemory(call: MethodCall, result: MethodChannel.Result) {
        val started = System.nanoTime()
        val generation = ++gameMemoryLoadGeneration
        val key = gameMemoryKey(call.arguments as? Map<*, *>)
        val memory = if (key == null) null else
            selectedGameMemory?.takeIf { selectedGameMemoryKey == key } ?: gameMemoryCache.get(key)
        if (memory == null && key != null && gameMemoryIndexStore.exists(key)) {
            activateStoredGameTranslationMemory(key, generation, started, result)
            return
        }
        if (memory != null && (memory !== selectedGameMemory || key != selectedGameMemoryKey)) {
            applyGameMemory(memory, key.takeIf { memory != null })
        }
        if (BuildConfig.DEBUG) Log.i("GameMemory", "ACTIVATE game=${key?.gameId} cacheHit=${memory != null} elapsedMs=${(System.nanoTime() - started) / 1_000_000.0}")
        result.success(mapOf("loaded" to (memory != null), "entryCount" to (memory?.entryCount ?: 0), "cacheHit" to (memory != null),
            "gameProfile" to memory?.gameProfileJson))
    }

    /** A game prepared in an earlier app run opens from its disk index instead of its JSON. */
    private fun activateStoredGameTranslationMemory(
        key: GameTranslationMemoryKey,
        generation: Int,
        started: Long,
        result: MethodChannel.Result,
    ) {
        gameMemoryWorker.execute {
            val memory = if (generation == gameMemoryLoadGeneration) gameMemoryIndexStore.read(key) else null
            runOnUiThread {
                val loaded = memory != null && generation == gameMemoryLoadGeneration
                if (loaded) {
                    gameMemoryCache.put(key, memory!!)
                    applyGameMemory(memory, key)
                }
                if (BuildConfig.DEBUG) Log.i("GameMemory", "ACTIVATE game=${key.gameId} diskHit=$loaded " +
                    "elapsedMs=${(System.nanoTime() - started) / 1_000_000.0}")
                result.success(mapOf("loaded" to loaded, "entryCount" to (if (loaded) memory!!.entryCount else 0),
                    "cacheHit" to loaded, "gameProfile" to (if (loaded) memory!!.gameProfileJson else null)))
            }
        }
    }

    private fun forgetGameTranslationMemory(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        val gameId = (arguments?.get("gameId") as? String) ?: call.arguments as? String
        val source = arguments?.get("sourceLanguage") as? String
        val target = arguments?.get("targetLanguage") as? String
        if (!gameId.isNullOrBlank()) {
            gameMemoryLoadGeneration++
            gameMemoryCache.removeGame(gameId, source, target)
            gameMemoryIndexStore.removeGame(gameId, source, target)
            if (selectedGameMemory?.let { it.gameId == gameId && (source == null || source == it.sourceLanguage) && (target == null || target == it.targetLanguage) } == true) applyGameMemory(null, null)
        }
        result.success(true)
    }

    private fun setGameTranslationMemory(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        val gameId = arguments?.get("gameId") as? String
        val sourceLanguage = arguments?.get("sourceLanguage") as? String
        val targetLanguage = arguments?.get("targetLanguage") as? String
        val json = arguments?.get("json") as? String
        val filePath = arguments?.get("filePath") as? String
        if (gameId.isNullOrBlank() || sourceLanguage.isNullOrBlank() ||
            targetLanguage.isNullOrBlank() || (json == null && filePath == null)) {
            gameMemoryLoadGeneration++
            applyGameMemory(null, null)
            result.success(mapOf("loaded" to false, "entryCount" to 0))
            return
        }
        val key = gameMemoryKey(arguments)
        val cached = if (key == null) null else selectedGameMemory?.takeIf { selectedGameMemoryKey == key } ?: gameMemoryCache.get(key)
        cached?.let { existing ->
            gameMemoryLoadGeneration++
            if (existing !== selectedGameMemory || selectedGameMemoryKey != key) applyGameMemory(existing, key)
            result.success(mapOf("loaded" to true, "entryCount" to existing.entryCount,
                "gameProfile" to existing.gameProfileJson))
            return
        }

        val generation = ++gameMemoryLoadGeneration
        val indexEpoch = gameMemoryIndexStore.epoch(gameId)
        gameMemoryWorker.execute {
            // A newer selection made this request obsolete while it waited in the queue.
            if (generation != gameMemoryLoadGeneration) {
                runOnUiThread { result.success(mapOf("loaded" to false, "entryCount" to 0)) }
                return@execute
            }
            try {
                val started = System.nanoTime()
                val stored = key?.let(gameMemoryIndexStore::read)
                val memory = stored ?: run {
                    // Files (plain or .json.gz) are hashed, expanded and parsed in one
                    // streaming pass; the JSON never exists as one String.
                    val prepared = if (json != null) {
                        GameTranslationMemory.parse(gameId, sourceLanguage, targetLanguage, json)
                    } else {
                        GameTranslationPackFile.read(
                            java.io.File(cacheDir, "game_catalog"), filePath!!,
                            arguments?.get("sha256") as? String ?: "", (arguments?.get("bytes") as? Number)?.toLong() ?: 0L,
                        ) { reader -> GameTranslationMemory.parse(gameId, sourceLanguage, targetLanguage, reader) }
                    }
                    if (BuildConfig.DEBUG) Log.i("GameMemory", "PREPARE game=$gameId source=${if (json == null) "file" else "channel"} " +
                        "gzip=${filePath?.endsWith(".gz") == true} parseMs=${(System.nanoTime() - started) / 1_000_000.0} " +
                        "estimatedBytes=${prepared.estimatedRetainedBytes}")
                    prepared
                }
                if (BuildConfig.DEBUG) Log.i("GameMemory", "READY game=$gameId diskHit=${stored != null} " +
                    "elapsedMs=${(System.nanoTime() - started) / 1_000_000.0}")
                if (stored == null && key != null) {
                    // Save after the game is usable; the next app start skips the JSON.
                    gameMemoryIndexWriter.execute {
                        val writeStarted = System.nanoTime()
                        gameMemoryIndexStore.write(key, memory, indexEpoch)
                        if (BuildConfig.DEBUG) Log.i("GameMemory", "INDEX_SAVED game=$gameId " +
                            "elapsedMs=${(System.nanoTime() - writeStarted) / 1_000_000.0}")
                    }
                }
                runOnUiThread {
                    if (generation != gameMemoryLoadGeneration) {
                        result.success(mapOf("loaded" to false, "entryCount" to 0))
                    } else {
                        if (key != null) gameMemoryCache.put(key, memory)
                        applyGameMemory(memory, key)
                        result.success(mapOf("loaded" to true, "entryCount" to memory.entryCount,
                            "gameProfile" to memory.gameProfileJson))
                    }
                }
            } catch (error: Exception) {
                runOnUiThread {
                    if (generation != gameMemoryLoadGeneration) {
                        result.success(mapOf("loaded" to false, "entryCount" to 0))
                    } else {
                        result.error(
                            "GAME_TRANSLATION_MEMORY_INVALID",
                            error.message ?: "Oyun çeviri dosyası okunamadı.",
                            null,
                        )
                    }
                }
            } catch (error: OutOfMemoryError) {
                // A very large pack must not crash the app; its partial index is unreachable now.
                runOnUiThread {
                    if (generation != gameMemoryLoadGeneration) {
                        result.success(mapOf("loaded" to false, "entryCount" to 0))
                    } else {
                        result.error(
                            "GAME_TRANSLATION_MEMORY_TOO_LARGE",
                            "Bu oyunun çeviri paketi telefonun belleğine sığmadı. Diğer uygulamaları kapatıp tekrar dene.",
                            null,
                        )
                    }
                }
            }
        }
    }

    private fun saveRectValue(value: Any?, prefix: String, defaults: List<Float>, editor: android.content.SharedPreferences.Editor) {
        val rect = value as? Map<*, *>
        fun number(key: String, fallback: Float): Float = (rect?.get(key) as? Number)?.toFloat()?.takeIf { it.isFinite() } ?: fallback
        val left = number("left", defaults[0]).coerceIn(0f, 0.98f)
        val top = number("top", defaults[1]).coerceIn(0f, 0.98f)
        editor.putFloat("${prefix}_left", left)
        editor.putFloat("${prefix}_top", top)
        editor.putFloat("${prefix}_width", number("width", defaults[2]).coerceIn(0.02f, 1f - left))
        editor.putFloat("${prefix}_height", number("height", defaults[3]).coerceIn(0.02f, 1f - top))
    }

    private fun applySavedOcrRegions() {
        val prefs = subtitleSettingsPrefs
        val regions = try {
            val parsed = JSONArray(prefs.getString("ocr_regions_json", "[]"))
            (0 until parsed.length()).map { index ->
                val rect = parsed.getJSONObject(index)
                floatArrayOf(rect.optDouble("left", 0.10).toFloat(), rect.optDouble("top", 0.78).toFloat(),
                    rect.optDouble("width", 0.80).toFloat(), rect.optDouble("height", 0.22).toFloat())
            }
        } catch (_: Exception) { emptyList() }
        normalizedOcrRegions = regions.ifEmpty {
            listOf(floatArrayOf(prefs.getFloat("ocr_left", 0.10f), prefs.getFloat("ocr_top", 0.78f),
                prefs.getFloat("ocr_width", 0.80f), prefs.getFloat("ocr_height", 0.22f)))
        }
    }

    private fun readOcrPreprocessingModes(
        prefs: android.content.SharedPreferences,
        regionCount: Int,
    ): List<Int> {
        val fallback = prefs.getInt("ocr_preprocessing_mode", 0).coerceIn(0, 9)
        val saved = try {
            val parsed = JSONArray(prefs.getString("ocr_preprocessing_modes_json", "[]"))
            (0 until parsed.length()).map { parsed.optInt(it, fallback).coerceIn(0, 9) }
        } catch (_: Exception) {
            emptyList()
        }
        return List(regionCount.coerceIn(1, 12)) { index -> saved.getOrNull(index) ?: fallback }
    }

    private fun readOcrDialogueFilters(
        prefs: android.content.SharedPreferences,
        regionCount: Int,
    ): List<Boolean> {
        val fallback = prefs.getBoolean("ocr_dialogue_filter", false)
        val saved = try {
            val parsed = JSONArray(prefs.getString("ocr_dialogue_filters_json", "[]"))
            (0 until parsed.length()).map { index -> parsed.optBoolean(index, fallback) }
        } catch (_: Exception) {
            emptyList()
        }
        return List(regionCount.coerceIn(1, 12)) { index -> saved.getOrNull(index) ?: fallback }
    }

    private fun storedOcrCaptureScale(): Double {
        val prefs = subtitleSettingsPrefs
        if (!prefs.getBoolean("ocr_capture_scale_tenths_migrated", false)) {
            val legacyScale = if (prefs.contains("ocr_capture_scale")) {
                prefs.getInt("ocr_capture_scale", 2)
            } else {
                1
            }
            val migrated = when (legacyScale) {
                1 -> 10
                15 -> 15
                else -> 20
            }
            prefs.edit()
                .putInt("ocr_capture_scale_tenths", migrated)
                .putBoolean("ocr_capture_scale_tenths_migrated", true)
                .apply()
        }
        val tenths = prefs.getInt("ocr_capture_scale_tenths", 10)
        return when (tenths) {
            15 -> 1.5
            20 -> 2.0
            else -> 1.0
        }
    }

    private fun ocrCaptureScaleTenths(value: Number): Int {
        val scale = value.toDouble()
        return when {
            kotlin.math.abs(scale - 1.0) < 0.01 -> 10
            kotlin.math.abs(scale - 1.5) < 0.01 -> 15
            else -> 20
        }
    }

    private fun configureSubtitleOcr() {
        val prefs = subtitleSettingsPrefs
        if (!sessionConnected && !subtitleOcrDelegate.isInitialized()) return
        subtitleOcr.configure(
            normalizedOcrRegions,
            sessionConnected && translationAccess.canProcessFrames(),
            storedSampleRateHz(),
            prefs.getFloat("hold_seconds", 2.5f),
            true,
            prefs.getFloat("auto_hide_after_seconds", 2f),
            prefs.getString("translation_source", "en") ?: "en",
            prefs.getString("translation_target", "tr") ?: "tr",
            readOcrPreprocessingModes(prefs, run {
                val regions = try {
                    JSONArray(prefs.getString("ocr_regions_json", "[]")).length()
                } catch (_: Exception) { 0 }
                regions.coerceAtLeast(1)
            }),
            readOcrDialogueFilters(prefs, run {
                val regions = try {
                    JSONArray(prefs.getString("ocr_regions_json", "[]")).length()
                } catch (_: Exception) { 0 }
                regions.coerceAtLeast(1)
            }),
            storedOcrCaptureScale().toFloat(),
            translationEngine(),
            readRegionSettings("ocr_region_settings_json").map { OcrRegionSettings.fromMap(it) },
            runCatching { deepLCredentials.read() }.getOrNull().orEmpty(),
            selectedGeminiApiKeys = runCatching { geminiCredentials.readAll() }.getOrDefault(emptyList()),
            hasSelectedGame = !prefs.getString("selected_game_id", null).isNullOrBlank() || selectedGameMemory != null,
        )
    }

    private fun updateSubtitleSettingsRuntime(settings: Map<*, *>?) {
        if (settings == null) return
        val regions = (settings["ocrRegions"] as? List<*>)?.mapNotNull { raw ->
            val rect = raw as? Map<*, *> ?: return@mapNotNull null
            fun number(key: String, fallback: Float) = (rect[key] as? Number)?.toFloat()?.takeIf { it.isFinite() } ?: fallback
            floatArrayOf(number("left", 0.10f), number("top", 0.78f), number("width", 0.80f), number("height", 0.22f))
        }.orEmpty()
        val fallbackPreprocessingMode =
            ((settings["ocrPreprocessingMode"] as? Number)?.toInt() ?: 0).coerceIn(0, 9)
        val rawPreprocessingModes = settings["ocrPreprocessingModes"] as? List<*>
        val preprocessingModes = List(regions.size.coerceIn(1, 12)) { index ->
            ((rawPreprocessingModes?.getOrNull(index) as? Number)?.toInt()
                ?: fallbackPreprocessingMode).coerceIn(0, 9)
        }
        val fallbackDialogueFilter = settings["ocrDialogueFilter"] as? Boolean ?: false
        val rawDialogueFilters = settings["ocrDialogueFilters"] as? List<*>
        val dialogueFilters = List(regions.size.coerceIn(1, 12)) { index ->
            rawDialogueFilters?.getOrNull(index) as? Boolean ?: fallbackDialogueFilter
        }
        normalizedOcrRegions = regions.ifEmpty { listOf(floatArrayOf(0.10f, 0.78f, 0.80f, 0.22f)) }
        subtitleOcr.configure(
            normalizedOcrRegions,
            sessionConnected && translationAccess.canProcessFrames(),
            ((settings["sampleRateHz"] as? Number)?.toDouble() ?: 10.0).coerceIn(0.25, 20.0),
            ((settings["holdSeconds"] as? Number)?.toFloat() ?: 2.5f).coerceIn(0f, 10f),
            true,
            ((settings["autoHideAfterSeconds"] as? Number)?.toFloat() ?: 2f).coerceIn(0.5f, 30f),
            (settings["sourceLanguageCode"] as? String) ?: "en",
            (settings["targetLanguageCode"] as? String) ?: "tr",
            preprocessingModes,
            dialogueFilters,
            (((settings["ocrCaptureScale"] as? Number)?.toDouble() ?: storedOcrCaptureScale())
                .coerceIn(1.0, 2.0).toFloat()),
            translationEngine(),
            (settings["ocrRegionSettings"] as? List<*>)?.take(12)
                ?.map { OcrRegionSettings.fromMap(it as? Map<*, *>) }.orEmpty(),
            runCatching { deepLCredentials.read() }.getOrNull().orEmpty(),
            selectedGeminiApiKeys = runCatching { geminiCredentials.readAll() }.getOrDefault(emptyList()),
            hasSelectedGame = !subtitleSettingsPrefs.getString("selected_game_id", null).isNullOrBlank() || selectedGameMemory != null,
        )
    }

    private fun translationEngine(): String {
        val saved = subtitleSettingsPrefs.getString("translation_engine", "opus") ?: "opus"
        if (saved in setOf("mlkit", "opus", "deepl", "gemini")) return saved
        subtitleSettingsPrefs.edit().putString("translation_engine", "opus").apply()
        return "opus"
    }

    private fun removeRetiredExperimentalModels() {
        listOf(
            "models/opus-mt-tc-big-en-tr-ct2-4729dd2c",
            "models/nllb-200-distilled-600m-ct2-int8-46858753",
        ).forEach { relativePath ->
            val retiredModel = File(applicationContext.filesDir, relativePath)
            if (retiredModel.exists() && !retiredModel.deleteRecursively()) {
                Log.w("GameTranslate", "Retired model files could not be fully removed: $relativePath")
            }
        }
    }

    private fun hpltModelDirectory(): File = File(
        applicationContext.filesDir,
        "models/${HpltModelCatalog.directoryName}",
    )

    private fun hpltNativeSupported(): Boolean = Build.SUPPORTED_ABIS.any { it == "arm64-v8a" }

    private fun hpltModelInstalled(): Boolean = runCatching {
        val dir = hpltModelDirectory()
        val model = File(dir, "model.bin")
        val sourceTokenizer = File(dir, "source.spm")
        val targetTokenizer = File(dir, "target.spm")
        if (!model.isFile || model.length() != HpltModelCatalog.modelBytes ||
            !sha256Matches(model, HpltModelCatalog.modelSha256)) return@runCatching false
        if (!sourceTokenizer.isFile || sourceTokenizer.length() != HpltModelCatalog.sourceTokenizerBytes ||
            !sha256Matches(sourceTokenizer, HpltModelCatalog.sourceTokenizerSha256)) return@runCatching false
        if (!targetTokenizer.isFile || targetTokenizer.length() != HpltModelCatalog.sourceTokenizerBytes ||
            !sha256Matches(targetTokenizer, HpltModelCatalog.sourceTokenizerSha256)) return@runCatching false
        if (File(dir, "config.json").length() != HpltModelCatalog.configBytes ||
            File(dir, "shared_vocabulary.json").length() != HpltModelCatalog.vocabularyBytes) return@runCatching false
        File(dir, ".complete").readText() == HpltModelCatalog.revision
    }.getOrDefault(false)

    private fun downloadHpltModel(result: MethodChannel.Result) {
        if (!hpltNativeSupported()) {
            result.error("HPLT_UNSUPPORTED_ABI", "Model C için 64-bit ARM Android gerekiyor.", null)
            return
        }
        opusModelWorker.execute {
            try {
                val dir = hpltModelDirectory()
                if (!dir.exists() && !dir.mkdirs()) error("Model klasörü oluşturulamadı.")
                val base = "https://huggingface.co/${HpltModelCatalog.repository}/resolve/${HpltModelCatalog.revision}/"
                val expectedSizes = mapOf(
                    "model.bin" to HpltModelCatalog.modelBytes,
                    "source.spm" to HpltModelCatalog.sourceTokenizerBytes,
                    "target.spm" to HpltModelCatalog.sourceTokenizerBytes,
                    "config.json" to HpltModelCatalog.configBytes,
                    "shared_vocabulary.json" to HpltModelCatalog.vocabularyBytes,
                )
                expectedSizes.forEach { (name, expectedSize) ->
                    val destination = File(dir, name)
                    val temporary = File(dir, "$name.part")
                    val expectedHash = when (name) {
                        "model.bin" -> HpltModelCatalog.modelSha256
                        "source.spm", "target.spm" -> HpltModelCatalog.sourceTokenizerSha256
                        else -> null
                    }
                    val currentFileIsValid = destination.isFile &&
                        destination.length() == expectedSize &&
                        (expectedHash == null || sha256Matches(destination, expectedHash))
                    if (currentFileIsValid) return@forEach

                    temporary.delete()
                    val connection = (URL(base + name).openConnection() as javax.net.ssl.HttpsURLConnection).apply {
                        connectTimeout = 20_000
                        readTimeout = 120_000
                        instanceFollowRedirects = true
                        setRequestProperty("User-Agent", "GameTranslate/1.0")
                    }
                    try {
                        connection.inputStream.use { input -> temporary.outputStream().use { output -> input.copyTo(output) } }
                        if (!temporary.isFile || temporary.length() != expectedSize) {
                            error("$name dosyası eksik veya boyutu doğrulanamadı.")
                        }
                        if (expectedHash != null && !sha256Matches(temporary, expectedHash)) {
                            error("$name dosyasının SHA-256 doğrulaması başarısız.")
                        }
                        if (destination.exists() && !destination.delete()) error("Eski $name dosyası değiştirilemedi.")
                        if (!temporary.renameTo(destination)) error("$name dosyası kaydedilemedi.")
                    } finally {
                        connection.disconnect()
                    }
                }
                File(dir, ".complete").writeText(HpltModelCatalog.revision)
                if (!hpltModelInstalled()) error("HPLT model paketi doğrulanamadı.")
                runOnUiThread {
                    if (subtitleSettingsPrefs.getString("translation_engine", "mlkit") == "hplt") {
                        configureSubtitleOcr()
                    }
                    result.success(true)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "HPLT_MODEL_DOWNLOAD_FAILED",
                        error.message ?: "HPLT model paketi indirilemedi.",
                        null,
                    )
                }
            }
        }
    }

    private fun offlinePack(target: String) = OfflineMarianCatalog.pack(target)
        ?: error("Bu çevrimdışı dil modeli henüz desteklenmiyor.")
    private fun offlineTarget() = subtitleSettingsPrefs.getString("offline_translation_target", "tr") ?: "tr"
    private fun offlineModelDirectory(target: String): File {
        val pack = offlinePack(target)
        return File(applicationContext.filesDir, "models/${pack.directoryName}")
    }
    private fun offlineModelInstalled(target: String): Boolean = runCatching {
        val pack = offlinePack(target)
        val dir = offlineModelDirectory(target)
        val model = File(dir, "model.tflite")
        if (!model.isFile || model.length() != pack.bytes || !sha256Matches(model, pack.sha256)) return@runCatching false
        if (!listOf("source.spm", "vocab.json", "config.json").all { File(dir, it).isFile }) return@runCatching false
        File(dir, ".complete").readText() == pack.revision
    }.getOrDefault(false)

    private fun sha256Matches(file: File, expected: String): Boolean {
        val digest = java.security.MessageDigest.getInstance("SHA-256")
        file.inputStream().buffered().use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) } == expected
    }

    private fun offlineTranslationModels(): List<Map<String, Any>> = OfflineMarianCatalog.packs.map { pack ->
        mapOf("target" to pack.target, "label" to Locale.forLanguageTag(pack.target).getDisplayName(Locale.forLanguageTag(pack.target)), "selected" to (pack.target == offlineTarget()), "installed" to offlineModelInstalled(pack.target))
    }

    private fun selectOfflineTranslationTarget(call: MethodCall, result: MethodChannel.Result) {
        val target = call.arguments as? String
        if (target == null) {
            result.error("OFFLINE_LANGUAGE_UNSUPPORTED", "Dil seçimi okunamadı.", null)
            return
        }
        if (OfflineMarianCatalog.pack(target) == null) {
            result.error("OFFLINE_LANGUAGE_UNSUPPORTED", "Bu çevrimdışı dil henüz sunulmuyor.", null)
            return
        }
        val prefs = subtitleSettingsPrefs
        val editor = prefs.edit().putString("offline_translation_target", target).putString("translation_source", "en").putString("translation_target", target)
        editor.apply()
        configureSubtitleOcr()
        result.success(offlineTranslationModels())
    }

    private fun downloadOpusModel(call: MethodCall, result: MethodChannel.Result) {
        val target = (call.arguments as? String) ?: offlineTarget()
        val pack = runCatching { offlinePack(target) }.getOrElse {
            result.error("OFFLINE_LANGUAGE_UNSUPPORTED", it.message, null)
            return
        }
        opusModelWorker.execute {
            try {
                val dir = offlineModelDirectory(target)
                if (!dir.exists() && !dir.mkdirs()) error("Model klasörü oluşturulamadı.")
                val revision = pack.revision
                val base = "https://huggingface.co/${pack.repository}/resolve/$revision/"
                val files = listOf("model.tflite", "source.spm", "vocab.json", "config.json")
                files.forEach { name ->
                    val dest = File(dir, name)
                    val temp = File(dir, "$name.part")
                    val modelIsTrusted = name != "model.tflite" ||
                        (dest.isFile && dest.length() == pack.bytes && sha256Matches(dest, pack.sha256))
                    if (!dest.isFile || !modelIsTrusted) {
                        temp.delete()
                        val connection = (URL(base + name).openConnection() as javax.net.ssl.HttpsURLConnection).apply {
                            connectTimeout = 20_000
                            readTimeout = 45_000
                            instanceFollowRedirects = true
                            setRequestProperty("User-Agent", "GameTranslate/1.0")
                        }
                        try {
                            connection.inputStream.use { input -> temp.outputStream().use { output -> input.copyTo(output) } }
                            if (!temp.isFile || temp.length() < 100) error("$name indirilemedi.")
                            if (name == "model.tflite") {
                                if (temp.length() != pack.bytes || !sha256Matches(temp, pack.sha256)) {
                                    error("İndirilen model doğrulanamadı.")
                                }
                            }
                            if (!temp.renameTo(dest)) error("$name dosyası kaydedilemedi.")
                        } finally { connection.disconnect() }
                    }
                }
                val configFile = File(dir, "config.json")
                val config = com.google.gson.Gson().fromJson(configFile.readText(), MarianConfig::class.java)
                if (config.dModel != 256 || config.maxPositionEmbeddings != 256 ||
                    config.decoderStartTokenId != 32000 || config.eosTokenId != 0 ||
                    config.vocabSize != 32001 || config.decoderVocabSize != 32001) {
                    error("Çevrimdışı model dosyaları beklenen dil modeliyle uyuşmuyor.")
                }
                File(dir, ".complete").writeText(revision)
                if (!offlineModelInstalled(target)) error("Çevrimdışı model dosyaları eksik veya sürümleri uyuşmuyor.")
                runOnUiThread { configureSubtitleOcr() }
                runOnUiThread { result.success(true) }
            } catch (error: Exception) {
                runOnUiThread { result.error("OFFLINE_MODEL_DOWNLOAD_FAILED", error.message ?: "Çevrimdışı dil modeli indirilemedi.", null) }
            }
        }
    }

    private fun getTranslationLanguageModels(result: MethodChannel.Result) {
        val languages = TranslateLanguage.getAllLanguages().sorted()
        if (languages.isEmpty()) {
            result.success(emptyList<Map<String, Any>>())
            return
        }
        val manager = RemoteModelManager.getInstance()
        val rows = java.util.Collections.synchronizedList(mutableListOf<Map<String, Any>>())
        val remaining = AtomicInteger(languages.size)
        fun finish() {
            if (remaining.decrementAndGet() == 0) {
                val ordered = synchronized(rows) { rows.sortedBy { it["code"].toString() } }
                runOnUiThread { result.success(ordered) }
            }
        }
        languages.forEach { code ->
            val model = TranslateRemoteModel.Builder(code).build()
            manager.isModelDownloaded(model)
                .addOnSuccessListener { downloaded ->
                    rows.add(mapOf(
                        "code" to code,
                        "name" to Locale.forLanguageTag(code).getDisplayName(Locale.forLanguageTag("tr")),
                        "englishName" to Locale.forLanguageTag(code).getDisplayName(Locale.ENGLISH),
                        "nativeName" to Locale.forLanguageTag(code).getDisplayName(Locale.forLanguageTag(code)),
                        "downloaded" to downloaded,
                    ))
                    finish()
                }
                .addOnFailureListener {
                    rows.add(mapOf(
                        "code" to code,
                        "name" to Locale.forLanguageTag(code).getDisplayName(Locale.forLanguageTag("tr")),
                        "englishName" to Locale.forLanguageTag(code).getDisplayName(Locale.ENGLISH),
                        "nativeName" to Locale.forLanguageTag(code).getDisplayName(Locale.forLanguageTag(code)),
                        "downloaded" to false,
                    ))
                    finish()
                }
        }
    }

    private fun prepareTranslationModels(result: MethodChannel.Result) {
        // A verified game dictionary works offline without a fallback model/key.
        val prepared = selectedGameMemory
        if (prepared != null && prepared.sourceLanguage == subtitleSettingsPrefs.getString("translation_source", "en") &&
            prepared.targetLanguage == subtitleSettingsPrefs.getString("translation_target", "tr")) {
            result.success(true)
            return
        }
        if (translationEngine() == "deepl") {
            withDeepLResult(result) { deepLClient(); true }
            return
        }
        if (translationEngine() == "gemini") {
            // Validate locally. Opening/starting translation does not spend a test request.
            withGeminiResult(result) { GeminiClient.validateKey(geminiCredentials.read().orEmpty()); true }
            return
        }
        val source = subtitleSettingsPrefs.getString("translation_source", "en") ?: "en"
        val target = subtitleSettingsPrefs.getString("translation_target", "tr") ?: "tr"
        if (source == target || source !in TranslateLanguage.getAllLanguages() || target !in TranslateLanguage.getAllLanguages()) {
            result.error("INVALID_LANGUAGE_PAIR", "Kaynak ve hedef dil seçimini kontrol et.", null)
            return
        }
        val translator = Translation.getClient(TranslatorOptions.Builder()
            .setSourceLanguage(source).setTargetLanguage(target).build())
        translator.downloadModelIfNeeded(DownloadConditions.Builder().build())
            .addOnSuccessListener {
                translator.close()
                runOnUiThread { result.success(true) }
            }
            .addOnFailureListener {
                translator.close()
                runOnUiThread { result.error("MODEL_PREPARATION_FAILED", "Çeviri dil paketleri indirilemedi. İnternet bağlantını kontrol et.", null) }
            }
    }

    private fun deepLClient() = DeepLClient(deepLCredentials.read().orEmpty())

    private fun withGeminiResult(result: MethodChannel.Result, action: () -> Any?) {
        deepLWorker.execute {
            try {
                val value = action()
                runOnUiThread { result.success(value) }
            } catch (error: GeminiException) {
                runOnUiThread { result.error(error.code, error.message, null) }
            } catch (_: Exception) {
                runOnUiThread { result.error("GEMINI_FAILED", "Gemini işlemi tamamlanamadı. Tekrar dene.", null) }
            }
        }
    }

    private fun withDeepLResult(result: MethodChannel.Result, action: () -> Any?) {
        deepLWorker.execute {
            try {
                val value = action()
                runOnUiThread { result.success(value) }
            } catch (error: DeepLException) {
                runOnUiThread { result.error(error.code, error.message, null) }
            } catch (_: Exception) {
                runOnUiThread { result.error("DEEPL_FAILED", "DeepL işlemi tamamlanamadı. Tekrar dene.", null) }
            }
        }
    }

    private fun downloadTranslationLanguage(call: MethodCall, result: MethodChannel.Result) {
        val code = call.arguments as? String
        if (code == null || code !in TranslateLanguage.getAllLanguages()) {
            result.error("UNSUPPORTED_TRANSLATION_LANGUAGE", "Bu çeviri dili desteklenmiyor.", null)
            return
        }
        val model = TranslateRemoteModel.Builder(code).build()
        RemoteModelManager.getInstance()
            .download(model, DownloadConditions.Builder().build())
            .addOnSuccessListener { runOnUiThread { result.success(true) } }
            .addOnFailureListener { error ->
                runOnUiThread {
                    result.error(
                        "TRANSLATION_MODEL_DOWNLOAD_FAILED",
                        "Dil paketi indirilemedi. İnternet bağlantını kontrol edip yeniden dene.",
                        error.javaClass.simpleName,
                    )
                }
            }
    }

    private fun getPsnAccountIdState(result: MethodChannel.Result) {
        try {
            result.success(consoleStore.loadAccountId() != null)
        } catch (_: Exception) {
            recoverFromKeystoreFailure()
            result.success(false)
        }
    }

    private fun recoverFromKeystoreFailure() {
        try {
            consoleStore.resetAfterDecryptionFailure()
        } catch (_: Exception) {
            // Keep failing closed if Android Keystore is unavailable.
        }
        emit(mapOf("type" to "psnReauthenticationRequired"))
    }

    private fun exchangePsnCode(call: MethodCall, result: MethodChannel.Result) {
        val code = call.argument<String>("code")?.trim()
        if (code.isNullOrEmpty() || code.length > 4096 || code.any { it.code <= 0x20 || it.code == 0x7f }) {
            result.error("INVALID_AUTH_CODE", "PSN yönlendirme kodu geçersiz.", null)
            return
        }
        if (psnExchangeInFlight) {
            result.error("PSN_AUTH_BUSY", "PSN hesabı zaten doğrulanıyor.", null)
            return
        }
        val client = try {
            PsnBrokerClient(BuildConfig.PSN_BROKER_URL)
        } catch (_: Exception) {
            result.error("PSN_BROKER_NOT_CONFIGURED", "PSN hesap doğrulama sunucusu yapılandırılmamış.", null)
            return
        }
        val activity = activityReference.get()
        if (activity == null || activity.isFinishing || activity.isDestroyed) {
            result.error("ACTIVITY_UNAVAILABLE", "Doğrulama için uygulamayı yeniden aç.", null)
            return
        }
        psnExchangeInFlight = true
        emit(mapOf("type" to "psnProgress", "stage" to "securityCheck"))
        try {
            val challenge = PsnTurnstileDialog(activity, client.origin, PsnBrokerClient.codeDigest(code)) { proof ->
                psnTurnstileDialog = null
                val token = proof.getOrNull()
                if (token == null) {
                    psnExchangeInFlight = false
                    result.error("PSN_SECURITY_CHECK_FAILED", proof.exceptionOrNull()?.message, null)
                } else {
                    emit(mapOf("type" to "psnProgress", "stage" to "broker"))
                    psnAuthWorker.execute {
                        try {
                            val accountId = Base64.decode(client.exchange(code, token), Base64.NO_WRAP)
                            check(accountId.size == 8) { "PSN hesap yanıtı geçersiz." }
                            // Preserve the existing Keystore storage and Remote Play registration format.
                            consoleStore.saveAccountId(accountId)
                            runOnUiThread {
                                psnExchangeInFlight = false
                                emit(mapOf("type" to "psnAuthenticated"))
                                result.success(true)
                            }
                        } catch (error: Exception) {
                            runOnUiThread {
                                psnExchangeInFlight = false
                                val message = when (error) {
                                    is IllegalStateException -> error.message ?: "PSN hesabı doğrulanamadı."
                                    is SocketTimeoutException -> "Hesap doğrulama sunucusundan yanıt alınamadı. Tekrar dene."
                                    is SSLException -> "Hesap doğrulama sunucusunun TLS sertifikası doğrulanamadı."
                                    else -> "PSN hesabı doğrulanamadı. Giriş akışını yeniden başlatıp tekrar dene."
                                }
                                result.error("PSN_AUTH_FAILED", message, null)
                            }
                        }
                    }
                }
            }
            psnTurnstileDialog = challenge
            challenge.show()
        } catch (_: Exception) {
            // WebView may be unavailable on a device. Fail without crashing the app.
            val pending = psnTurnstileDialog
            psnTurnstileDialog = null
            if (pending != null) pending.cancel()
            else {
                psnExchangeInFlight = false
                result.error("PSN_SECURITY_CHECK_FAILED", "Güvenlik doğrulaması açılamadı. Android System WebView'i kontrol edip tekrar dene.", null)
            }
        }
    }

    private fun startSession(result: MethodChannel.Result) {
        if (activeSession != null || sessionStartPending || sessionStopPending) {
            result.error("SESSION_BUSY", "Bir Remote Play oturumu zaten açık.", null)
            return
        }
        val console = try {
            consoleStore.load()
        } catch (_: Exception) {
            recoverFromKeystoreFailure()
            result.error("SAVED_CONSOLE_READ_FAILED", "Kayıtlı PS5 bilgileri okunamadı. Yeniden PS5 eşleştirmen gerekebilir.", null)
            return
        }
        if (console == null) {
            result.error("NO_REGISTERED_CONSOLE", "Önce bir PS5'i kaydet.", null)
            return
        }
        try {
            val serviceIntent = Intent(this, TranslationForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(serviceIntent)
            else startService(serviceIntent)
        } catch (error: Exception) {
            result.error("FOREGROUND_SERVICE_START_FAILED", "Arka plan çeviri servisi başlatılamadı.", null)
            return
        }
        sessionCancellationRequested = false
        sessionStartPending = true
        emit(mapOf("type" to "connecting", "host" to console.host))
        worker.execute {
            var session: Session? = null
            try {
                if (sessionCancellationRequested) {
                    runOnUiThread { result.error("SESSION_CANCELLED", "PS5 bağlantısı iptal edildi.", null) }
                    return@execute
                }
                val profile = ConnectVideoProfile.preset(
                    VideoResolutionPreset.RES_720P,
                    VideoFPSPreset.FPS_30,
                    Codec.CODEC_H264,
                )
                Log.i(
                    "GameTranslateRemotePlay",
                    "SESSION_VIDEO_PROFILE profile=${profile.width}x${profile.height}@${profile.maxFPS}fps bitrate=${profile.bitrate} codec=${profile.codec}",
                )
                val createdSession = Session(
                    ConnectInfo(true, console.host, console.registrationKey, console.morning, profile),
                    null,
                    false,
                )
                session = createdSession
                createdSession.eventCallback = { event -> handleSessionEvent(createdSession, event) }
                if (sessionCancellationRequested) {
                    createdSession.dispose()
                    runOnUiThread { result.error("SESSION_CANCELLED", "PS5 bağlantısı iptal edildi.", null) }
                    return@execute
                }
                activeSession = createdSession
                sessionConnected = false
                val surface = backgroundVideoFrames.surface
                createdSession.setSurface(surface)
                decoderSurface = surface
                runOnUiThread { recoverVideoOutput() }
                if (sessionCancellationRequested) {
                    activeSession = null
                    decoderSurface = null
                    createdSession.dispose()
                    runOnUiThread { result.error("SESSION_CANCELLED", "PS5 bağlantısı iptal edildi.", null) }
                    return@execute
                }
                val startResult = createdSession.start()
                if (!startResult.isSuccess) {
                    activeSession = null
                    decoderSurface = null
                    createdSession.dispose()
                    throw IllegalStateException("Chiaki oturumu başlatılamadı: $startResult")
                }
                sessionStartPending = false
                if (sessionCancellationRequested) {
                    activeSession = null
                    decoderSurface = null
                    createdSession.stop()
                    createdSession.dispose()
                    emit(mapOf("type" to "stopped"))
                    runOnUiThread { result.error("SESSION_CANCELLED", "PS5 bağlantısı iptal edildi.", null) }
                    return@execute
                }
                runOnUiThread { result.success(true) }
            } catch (error: Exception) {
                sessionStartPending = false
                if (sessionCancellationRequested) {
                    emit(mapOf("type" to "stopped"))
                    return@execute
                }
                activeSession = null
                decoderSurface = null
                try { session?.dispose() } catch (_: Exception) { }
                emit(mapOf("type" to "error", "message" to "Remote Play oturumu başlatılamadı."))
                runOnUiThread { result.error("SESSION_START_FAILED", "Remote Play oturumu başlatılamadı.", null) }
            } finally {
                sessionStartPending = false
                if (activeSession == null) releaseVideoOutput()
            }
        }
    }

    private fun handleSessionEvent(session: Session, event: Event) {
        if (activeSession !== session) return
        when (event) {
            is ConnectedEvent -> {
                sessionConnected = true
                runOnUiThread {
                    translationAccess.onRemotePlayConnectionChanged(
                        activeSession === session && sessionConnected && !sessionStopPending,
                    )
                }
                configureSubtitleOcr()
                runOnUiThread(::showBackgroundPowerExplanation)
                val session = activeSession
                if (session != null) {
                    worker.execute {
                        if (activeSession === session && sessionConnected) {
                            val result = session.requestIdr()
                            if (!result.isSuccess) {
                                emit(mapOf("type" to "videoRecoveryUnavailable"))
                            }
                        }
                    }
                }
                emit(mapOf("type" to "connected"))
            }
            is LoginPinRequestEvent -> emit(mapOf("type" to "loginPinRequired", "incorrect" to event.pinIncorrect))
            is RumbleEvent -> emit(mapOf("type" to "rumble"))
            is QuitEvent -> {
                activeSession = null
                sessionConnected = false
                runOnUiThread { translationAccess.onRemotePlayConnectionChanged(sessionConnected && activeSession != null) }
                decoderSurface = null
                configureSubtitleOcr()
                emit(mapOf("type" to "subtitleCleared"))
                Log.w(
                    "GameTranslateRemotePlay",
                    "Remote Play session ended: reason=${event.reason}, message=${event.reasonString}",
                )
                emit(mapOf(
                    "type" to "disconnected",
                    "reason" to event.reason.toString(),
                    "message" to (event.reasonString ?: event.reason.toString()),
                ))
                worker.execute {
                    try { session.dispose() } finally {
                        if (activeSession == null) releaseVideoOutput()
                    }
                }
            }
        }
    }

    private fun stopSession(
        message: String? = null,
        onStopped: ((String?) -> Unit)? = null,
    ) {
        if (sessionStopPending) {
            onStopped?.invoke(null)
            return
        }
        sessionCancellationRequested = true
        if (activeSession == null && !sessionStartPending && !sessionStopPending) {
            stopTranslationForeground()
            onStopped?.invoke(null)
            return
        }
        sessionStopPending = true
        worker.execute {
            val current = activeSession
            val wasConnected = sessionConnected
            val previousSurface = decoderSurface
            activeSession = null
            sessionConnected = false
            runOnUiThread { translationAccess.onRemotePlayConnectionChanged(sessionConnected && activeSession != null) }
            decoderSurface = null
            configureSubtitleOcr()
            emit(mapOf("type" to "subtitleCleared"))
            var stopError: String? = null
            try {
                if (current != null) {
                    val result = current.stopAndDispose()
                    if (!result.isSuccess) {
                        activeSession = current
                        stopError = "Chiaki oturumu kapatılamadı: $result"
                    }
                }
            } catch (error: Exception) {
                activeSession = current
                stopError = "Remote Play oturumu kapatılırken hata oluştu."
            }
            sessionStartPending = false
            sessionStopPending = false
            if (stopError == null) {
                releaseVideoOutput()
                stopTranslationForeground()
                val stoppedEvent = mutableMapOf<String, Any?>("type" to "stopped", "userInitiated" to true)
                if (message != null) stoppedEvent["message"] = message
                emit(stoppedEvent)
            }
            else {
                sessionConnected = wasConnected
                runOnUiThread { translationAccess.onRemotePlayConnectionChanged(sessionConnected && activeSession != null) }
                decoderSurface = previousSurface
                configureSubtitleOcr()
                emit(mapOf("type" to "error", "message" to stopError))
            }
            runOnUiThread { onStopped?.invoke(stopError) }
        }
    }

    private fun startDiscovery(result: MethodChannel.Result) {
        if (activeDiscovery != null) {
            result.success(true)
            return
        }
        try {
            // Devices without Wi-Fi (Ethernet) can still discover without a multicast lock.
            val wifi = applicationContext.getSystemService(WIFI_SERVICE) as? WifiManager
            multicastLock = wifi?.createMulticastLock("gametranslate-chiaki-discovery")?.apply {
                setReferenceCounted(false)
                acquire()
            }
            val options = DiscoveryServiceOptions(
                hostsMax = 32UL,
                hostDropPings = 4UL,
                pingMs = 1500UL,
                sendAddr = InetSocketAddress(InetAddress.getByName("255.255.255.255"), 0),
            )
            activeDiscovery = DiscoveryService(options) { hosts ->
                val items = hosts.filter { it.isPS5 }.map { host ->
                    mapOf(
                        "host" to host.hostAddr,
                        "nickname" to host.hostName,
                        "state" to host.state.name,
                    )
                }
                emit(mapOf("type" to "discovery", "hosts" to items))
            }
            result.success(true)
            emit(mapOf("type" to "discovering"))
        } catch (error: Exception) {
            stopDiscovery()
            result.error("DISCOVERY_FAILED", "Yerel ağ keşfi başlatılamadı: ${error.message}", null)
        }
    }

    private fun stopDiscovery() {
        val service = activeDiscovery
        activeDiscovery = null
        try { service?.dispose() } catch (error: Exception) {
                // Avoid forwarding native exception details to logcat.
        }
        try { multicastLock?.release() } catch (_: Exception) { }
        multicastLock = null
    }

    private fun emit(event: Map<String, Any?>) {
        runOnUiThread {
            // Covers carry the same paid translations as subtitle text.
            val subtitle = event["type"] == "subtitleText" || event["type"] == "subtitleCovers"
            val diagnostics = subtitle && BuildConfig.DEBUG
            val access = !subtitle || translationAccess.hasAccess()
            val sink = eventSink
            if (diagnostics) Log.i("GameTranslateOCR", "SUBTITLE_DELIVERY area=${(event["regionIndex"] as? Int ?: 0) + 1} " +
                "result=${if (!access) "access_denied" else if (sink == null) "no_listener" else "sent"} " +
                "id=${(event["translationMemory"] as? Map<*, *>)?.get("id") ?: "-"}")
            if (access) sink?.success(if (diagnostics) event + ("diagnostics" to true) else event)
        }
    }

    private fun isValidIpv4(value: String): Boolean {
        val parts = value.split('.')
        if (parts.size != 4) return false
        return parts.all { part ->
            if (part.isEmpty() || part.length > 3 || !part.all(Char::isDigit)) return@all false
            val number = part.toIntOrNull() ?: return@all false
            number in 0..255
        }
    }

    fun detach(activity: MainActivity) {
        if (activityReference.get() !== activity) return
        onStop()
        if (activity.isFinishing) cacheDocuments.cancelPicker()
        psnTurnstileDialog?.cancel()
        psnTurnstileDialog = null
        backgroundPowerDialog?.dismiss()
        backgroundPowerDialog = null
        pendingTranslationNotificationResult?.error("ACTIVITY_DESTROYED", "Bildirim izni isteği tamamlanamadı.", null)
        pendingTranslationNotificationResult = null
        activityReference.clear()
        videoPlatformView = null
        synchronized(surfaceLock) {
            latestSurface = null
            latestSurfaceOwner = null
        }
        stopDiscovery()
        // Session, OCR, Flutter engine and TV delivery belong to this application
        // controller and the foreground service, never to a disposable Activity.
    }
}
