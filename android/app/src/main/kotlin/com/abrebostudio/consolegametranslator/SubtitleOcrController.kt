package com.abrebostudio.consolegametranslator

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Rect
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import android.util.Log
import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.nl.translate.TranslateRemoteModel
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.TextRecognizer
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.util.LinkedHashMap
import java.util.Locale
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit
import kotlin.math.max
import kotlin.math.roundToInt

/** Recognizes subtitle crops from the persistent Remote Play decoder output. */
internal class SubtitleOcrController(
    private val applicationContext: Context,
    private val backgroundFrameProvider: () -> Bitmap?,
    private val emit: (Map<String, Any?>) -> Unit,
    private val croppedFrameProvider: ((List<FloatArray>) -> CroppedVideoFrame?)? = null,
) {
    private val thread = HandlerThread("subtitle-pixel-copy").apply { start() }
    private val handler = Handler(thread.looper)
    private val recognitionExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val marianExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val localTranslationQueue = LatestLocalTranslationQueue(marianExecutor)
    private val deepLExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val deepLDraining = AtomicBoolean(false)
    private val deepLRevision = AtomicInteger()
    @Volatile private var deepLApiKey = ""
    private var deepLConfigSource = ""
    private var deepLConfigTarget = ""
    private val cloudRetry = CloudTranslationRetryPolicy { SystemClock.elapsedRealtime() }
    private val geminiKeyPool = GeminiKeyPool { SystemClock.elapsedRealtime() }
    private var geminiConfiguredKeys = emptyList<String>()
    @Volatile private var geminiPoolRevision = -1
    private var cloudRetryTick: Runnable? = null
    private data class DeepLRequest(val engine: String, val index: Int, val state: RegionState, val key: String,
        val text: String, val source: String, val target: String, val apiKey: String, val revision: Int)
    private val pendingDeepL = java.util.Collections.synchronizedMap(LinkedHashMap<Int, DeepLRequest>())
    // Accessed on the network thread; survives session, engine and API-key changes.
    private val deepLCache by lazy {
        TranslationCacheManager.get(applicationContext).repository.deepL
    }
    private val deepLTranslationEngine by lazy {
        DeepLTranslationEngine(deepLCache, diagnostic = { message ->
            if (diagnosticsEnabled()) Log.i(OCR_LOG_TAG, message)
        })
    }
    // Separate provider/model namespace prevents DeepL and Gemini cache mixing.
    private val geminiCache by lazy {
        TranslationCacheManager.get(applicationContext).repository.gemini
    }
    private val geminiTranslationEngine by lazy {
        GeminiTranslationEngine(geminiCache, diagnostic = { message ->
            if (diagnosticsEnabled()) Log.i(OCR_LOG_TAG, message)
        })
    }
    private fun isCloudEngine() = translationEngine in setOf("deepl", "gemini")
    private fun cloudCache() = if (translationEngine == "gemini") geminiCache else deepLCache
    @Volatile private var geminiFallbackStatus = "idle"
    fun geminiRuntimeStatus(): Map<String, Any?> = if (translationEngine == "gemini")
        cloudRetry.snapshot() + geminiKeyPool.snapshot() +
            ("fallback" to if (cloudRetry.allowsGeminiFallback) geminiFallbackStatus else "idle")
        else mapOf("state" to "idle", "remainingMs" to 0L)
    // Separate local instances/cache: a temporary result must never become a Gemini cache hit.
    private var fallbackMarian: MarianOnDeviceTranslator? = null
    private var fallbackMarianTarget = ""
    private var fallbackMlkit: Translator? = null
    private var fallbackMlkitPair: Pair<String, String>? = null
    private var geminiLocalFallback = createGeminiLocalFallback()
    private val latestMarianKeyByRegion = ConcurrentHashMap<Int, String>()
    private val recognizer: TextRecognizer =
        TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    private val ocrRecovery = OcrRecoveryPolicy { SystemClock.elapsedRealtime() }
    private val ocrCorrections by lazy {
        try {
            applicationContext.assets.open(OcrCorrectionTable.ASSET_PATH).bufferedReader(Charsets.UTF_8).use {
                OcrCorrectionTable.parse(it.readText())
            }
        } catch (error: Exception) {
            if (BuildConfig.DEBUG) Log.w(OCR_LOG_TAG, "OCR_CORRECTIONS_DISABLED error=${error.javaClass.simpleName}")
            OcrCorrectionTable.EMPTY
        }
    }
    private val recoveryRevision = AtomicInteger()
    @Volatile private var selectedGame = false
    @Volatile private var sourceLanguageCode = TranslateLanguage.ENGLISH
    @Volatile private var targetLanguageCode = TranslateLanguage.TURKISH
    @Volatile private var translator: Translator = createTranslator(sourceLanguageCode, targetLanguageCode)
    private var mlkitSourceLanguage = sourceLanguageCode
    private var mlkitTargetLanguage = targetLanguageCode
    @Volatile private var translationModelReady = false
    @Volatile private var translationEngine = "opus"
    @Volatile private var gameTranslationMemory: GameTranslationMemory? = null
    @Volatile private var marianTranslator: MarianOnDeviceTranslator? = null
    @Volatile private var hpltTranslator: HpltCTranslate2? = null
    @Volatile private var marianTargetLanguageCode = "tr"
    @Volatile private var translationModelDownloadInFlight = false
    private var translationModelRetryAfter = 0L
    private val translationCache = object : LinkedHashMap<String, String>(16, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, String>?) =
            size > if (isCloudEngine()) 1024 else 128
    }
    private val compareResults = LinkedHashMap<String, MutableMap<String, String>>(64, 0.75f, true)
    private val compareInFlight = mutableSetOf<Pair<String, String>>()

    @Volatile private var regions = listOf(floatArrayOf(0.10f, 0.78f, 0.80f, 0.22f))
    @Volatile private var enabled = false
    @Volatile private var sampleIntervalMillis = 100L
    @Volatile private var regionSettings = listOf(OcrRegionSettings())
    private val regionSchedule = OcrRegionSchedule()
    @Volatile private var captureInFlight = false
    private var sampling = false
    private var lastSampleStartedAt = 0L
    private data class RegionState(
        var sourceText: String? = null,
        var sourceKey: String? = null,
        var sourceConfidence: Float = 0f,
        var lastConfirmedLiveAt: Long = 0L,
        val variantGate: OcrVariantGate = OcrVariantGate(),
        val deepLOcrPolicy: DeepLOcrPolicy = DeepLOcrPolicy(),
        val localOcrPolicy: DeepLOcrPolicy = DeepLOcrPolicy(),
        var translatingKey: String? = null,
        // Retain an unavailable/failed attempt for this reading so OCR frames do not retry it.
        var fallbackPendingKey: String? = null,
        var fallbackVisibleKey: String? = null,
        var memoryMatchedKey: String? = null,
        var visibleSince: Long? = null,
        var emptySince: Long? = null,
        var clearSent: Boolean = false,
    )
    private var regionStates = mutableListOf<RegionState>()
    // Detailed OCR/translation diagnostics are debug-only. A device log property
    // must never enable subtitle text logging in a release build.
    private val lastLoggedOcrByRegion = mutableListOf<String>()
    private val lastLoggedLookupByRegion = mutableMapOf<Int, String>()
    private data class PerformanceWindow(var start: Long, var reads: Int = 0, var hits: Int = 0,
        var copyMs: Long = 0, var ocrMs: Long = 0, var lookupMs: Long = 0, var reused: Int = 0, var intervals: Int = 0, var elapsedMs: Long = 0)
    private val performanceWindows = mutableMapOf<Int, PerformanceWindow>()
    private val lastPerformanceReadAt = mutableMapOf<Int, Long>()
    private val visualOcrCaches = ConcurrentHashMap<Int, OcrVisualCache<com.google.mlkit.vision.text.Text>>()
    private var visualPixels = IntArray(0)
    @Volatile private var closed = false

    fun setGameTranslationMemory(memory: GameTranslationMemory?) {
        gameTranslationMemory = memory
        recoveryRevision.incrementAndGet()
        visualOcrCaches.clear()
        if (closed) return
        recognitionExecutor.execute {
            translationCache.clear()
            regionStates.forEachIndexed { index, state ->
                val currentText = state.sourceText ?: return@forEachIndexed
                val currentConfidence = state.sourceConfidence
                state.sourceKey = null
                state.translatingKey = null
                state.fallbackPendingKey = null
                state.fallbackVisibleKey = null
                state.memoryMatchedKey = null
                onRecognized(index, currentText, currentConfidence, matchingGameMemory()?.find(currentText))
            }
        }
    }

    fun setGameSelected(value: Boolean) {
        if (selectedGame == value) return
        selectedGame = value
        recoveryRevision.incrementAndGet()
        visualOcrCaches.clear()
        ocrRecovery.reset()
    }

    /** Called only by the cache worker after translation has stopped. */
    fun awaitCloudWorkBeforeCacheChange() {
        if (!closed) deepLExecutor.submit {}.get(30, TimeUnit.SECONDS)
    }

    fun onManagedCacheChanged() {
        if (closed) return
        recognitionExecutor.execute {
            translationCache.clear()
            regionStates.forEach { resetState(it) }
            latestMarianKeyByRegion.clear()
        }
    }

    /** Replay a cached result for a reattached listener, without translating it again. */
    fun resendCurrentCachedSubtitles() {
        if (closed) return
        recognitionExecutor.execute {
            if (closed || !enabled) return@execute
            regionStates.forEachIndexed { index, state ->
                val text = state.sourceText ?: return@forEachIndexed
                val key = state.sourceKey ?: return@forEachIndexed
                val match = matchingGameMemory()?.find(text)
                if (match != null) {
                    state.memoryMatchedKey = null
                    onRecognized(index, text, state.sourceConfidence, match)
                    return@forEachIndexed
                }
                val cached = translationCache[key] ?: if (isCloudEngine())
                    cloudCache().getIfLoaded(sourceLanguageCode, targetLanguageCode, key) else null
                if (cached != null && canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key)) {
                    state.visibleSince = SystemClock.elapsedRealtime()
                    state.fallbackVisibleKey = null
                    emitSubtitleText(index, text, cached, "live_cache", translationEngine)
                } else if (translationEngine == "gemini" && state.fallbackVisibleKey == key) {
                    geminiLocalFallback.cached(sourceLanguageCode, targetLanguageCode, key)?.let { local ->
                        if (canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key)) {
                            emitSubtitleText(index, text, local.text.orEmpty(), "live_cache", local.engine)
                        }
                    }
                }
            }
        }
    }

    fun configure(
        normalizedRegions: List<FloatArray>,
        isEnabled: Boolean,
        rateHz: Double,
        holdSeconds: Float,
        shouldAutoHide: Boolean,
        autoHideAfterSeconds: Float,
        sourceLanguage: String,
        targetLanguage: String,
        imagePreprocessingModes: List<Int>,
        imageDialogueFilters: List<Boolean>,
        imageCaptureScale: Float,
        selectedTranslationEngine: String = "opus",
        independentRegionSettings: List<OcrRegionSettings> = emptyList(),
        selectedDeepLApiKey: String = "",
        selectedGeminiApiKey: String = "",
        selectedGeminiApiKeys: List<String> = emptyList(),
        hasSelectedGame: Boolean = false,
    ) {
        setGameSelected(hasSelectedGame)
        val geminiKeys = (selectedGeminiApiKeys.ifEmpty { listOf(selectedGeminiApiKey) })
            .filter { it.isNotBlank() }.distinct().take(GeminiKeyList.MAX_KEYS)
        val selectedCloudKey = if (selectedTranslationEngine == "gemini") geminiKeys.firstOrNull().orEmpty() else selectedDeepLApiKey
        val deepLChanged = deepLApiKey != selectedCloudKey ||
            (selectedTranslationEngine == "gemini" && geminiConfiguredKeys != geminiKeys) ||
            deepLConfigSource != sourceLanguage || deepLConfigTarget != targetLanguage ||
            translationEngine != selectedTranslationEngine || enabled != isEnabled
        if (deepLChanged) {
            deepLRevision.incrementAndGet()
            pendingDeepL.clear()
            localTranslationQueue.clear()
        }
        val configurationRevision = deepLRevision.get()
        deepLApiKey = selectedCloudKey
        geminiConfiguredKeys = geminiKeys
        deepLConfigSource = sourceLanguage
        deepLConfigTarget = targetLanguage
        regions = normalizedRegions.filter { it.size >= 4 }.take(12).map { it.copyOfRange(0, 4) }
            .ifEmpty { listOf(floatArrayOf(0.10f, 0.78f, 0.80f, 0.22f)) }
        while (regionStates.size < regions.size) regionStates.add(RegionState())
        while (regionStates.size > regions.size) regionStates.removeAt(regionStates.lastIndex)
        val shouldResetRecognizedText = isEnabled && !enabled
        enabled = isEnabled

        val preprocessingModes = List(regions.size) { index ->
            imagePreprocessingModes.getOrNull(index)?.coerceIn(0, 9)
                ?: imagePreprocessingModes.firstOrNull()?.coerceIn(0, 9)
                ?: 0
        }
        val dialogueFilters = List(regions.size) { index ->
            imageDialogueFilters.getOrNull(index) ?: imageDialogueFilters.firstOrNull() ?: false
        }
        regionSettings = List(regions.size) { index ->
            independentRegionSettings.getOrNull(index) ?: OcrRegionSettings(
                sampleRateHz = rateHz.coerceIn(0.25, 20.0),
                preprocessingMode = preprocessingModes[index],
                dialogueFilter = dialogueFilters[index],
                captureScale = normalizeCaptureScale(imageCaptureScale),
                holdMillis = (holdSeconds.coerceIn(0f, 10f) * 1000).toLong(),
                autoHideMillis = (autoHideAfterSeconds.coerceIn(0.5f, 30f) * 1000).toLong(),
            )
        }
        sampleIntervalMillis = regionSettings.minOf { it.sampleIntervalMillis }
        val safeEngine = selectedTranslationEngine.takeIf { it in setOf("mlkit", "opus", "deepl", "gemini") } ?: "opus"
        val safeMarianTarget = if (safeEngine == "hplt") "tr" else
            targetLanguage.takeIf { it in OfflineMarianCatalog.targetCodes } ?: "tr"
        if (marianTargetLanguageCode != safeMarianTarget) {
            marianTargetLanguageCode = safeMarianTarget
            marianExecutor.execute {
                synchronized(this) {
                    marianTranslator?.close()
                    marianTranslator = null
                }
            }
        }
        if (translationEngine != safeEngine) {
            translationEngine = safeEngine
            translationCache.clear()
            regionStates.forEach { resetState(it) }
            latestMarianKeyByRegion.clear()
            marianExecutor.execute {
                synchronized(this) {
                    if (safeEngine != "opus") {
                        marianTranslator?.close()
                        marianTranslator = null
                    }
                    if (safeEngine != "hplt") {
                        hpltTranslator?.close()
                        hpltTranslator = null
                    }
                }
            }
        }
        if (!closed) {
            recognitionExecutor.execute {
                if (closed || configurationRevision != deepLRevision.get()) return@execute
                if (deepLChanged) {
                    cloudRetry.clear()
                    // A cancelled local job must not leave the same reading
                    // permanently marked as translating after a revision change.
                    regionStates.forEach { it.translatingKey = null; it.fallbackPendingKey = null }
                    geminiKeyPool.configure(geminiKeys)
                    geminiPoolRevision = configurationRevision
                    geminiFallbackStatus = "idle"
                    geminiLocalFallback = createGeminiLocalFallback()
                    marianExecutor.execute { closeGeminiFallbackModels() }
                    cloudRetryTick?.let { handler.removeCallbacks(it) }
                    if (safeEngine in setOf("deepl", "gemini")) {
                        translationCache.clear()
                        regionStates.forEach { resetState(it) }
                    }
                }
                if (translationEngine == "hplt") {
                    setTranslationLanguages(TranslateLanguage.ENGLISH, TranslateLanguage.TURKISH)
                } else {
                    setTranslationLanguages(sourceLanguage, targetLanguage)
                }
                if (enabled && translationEngine == "mlkit") ensureTranslationModel()
                if (enabled && translationEngine == "opus" && liveTranslationSupported()) warmMarianModel()
                if (enabled && translationEngine == "hplt") warmHpltModel()
            }
        }
        if (shouldResetRecognizedText && !closed) {
            recognitionExecutor.execute {
                regionStates.forEach { resetState(it) }
            }
        }
        if (enabled) startSampling() else stopSampling()
    }

    private fun setTranslationLanguages(source: String, target: String) {
        if (isCloudEngine()) {
            sourceLanguageCode = source
            targetLanguageCode = target
            return
        }
        if (source !in TranslateLanguage.getAllLanguages() || target !in TranslateLanguage.getAllLanguages()) {
            // Prepared dictionaries can support targets beyond the live engine.
            sourceLanguageCode = source
            targetLanguageCode = target
            translationCache.clear()
            regionStates.forEach { resetState(it) }
            return
        }
        val safeSource = TranslateLanguage.getAllLanguages().firstOrNull { it == source } ?: TranslateLanguage.ENGLISH
        var safeTarget = TranslateLanguage.getAllLanguages().firstOrNull { it == target } ?: TranslateLanguage.TURKISH
        if (safeSource == safeTarget) {
            safeTarget = if (safeSource == TranslateLanguage.TURKISH) TranslateLanguage.ENGLISH else TranslateLanguage.TURKISH
        }
        if (safeSource == sourceLanguageCode && safeTarget == targetLanguageCode &&
            safeSource == mlkitSourceLanguage && safeTarget == mlkitTargetLanguage) return
        val oldTranslator = translator
        sourceLanguageCode = safeSource
        targetLanguageCode = safeTarget
        mlkitSourceLanguage = safeSource
        mlkitTargetLanguage = safeTarget
        translator = createTranslator(safeSource, safeTarget)
        translationCache.clear()
        translationModelReady = false
        translationModelDownloadInFlight = false
        translationModelRetryAfter = 0L
        regionStates.forEach { resetState(it) }
        try { oldTranslator.close() } catch (_: Exception) { }
    }

    /** Download/check the model once up front instead of adding this task to every subtitle. */
    private fun ensureTranslationModel() {
        if (closed || translationModelReady || translationModelDownloadInFlight) return
        if (SystemClock.elapsedRealtime() < translationModelRetryAfter) return
        translationModelDownloadInFlight = true
        val selectedTranslator = translator
        selectedTranslator.downloadModelIfNeeded(DownloadConditions.Builder().build())
            .addOnSuccessListener(recognitionExecutor) {
                if (selectedTranslator !== translator) return@addOnSuccessListener
                translationModelDownloadInFlight = false
                translationModelReady = true
                regionStates.forEachIndexed { index, state ->
                    val text = state.sourceText
                    val key = state.sourceKey
                    if (text != null && key != null && enabled) translate(index, state, key, text)
                }
            }
            .addOnFailureListener(recognitionExecutor) {
                if (selectedTranslator !== translator) return@addOnFailureListener
                translationModelDownloadInFlight = false
                translationModelRetryAfter = SystemClock.elapsedRealtime() + MODEL_RETRY_DELAY_MS
                emit(mapOf("type" to "subtitleOcrStatus", "status" to "Çeviri modeli hazır değil"))
            }
    }

    private fun createTranslator(source: String, target: String): Translator = Translation.getClient(
        TranslatorOptions.Builder().setSourceLanguage(source).setTargetLanguage(target).build(),
    )

    fun captureOnce(regionIndex: Int = 0, completion: (String, Map<String, Any?>?) -> Unit) {
        handler.post { capture(debugOnly = true, completion = completion, compareVariants = true, debugRegionIndex = regionIndex) }
    }

    fun close() {
        closed = true
        deepLRevision.incrementAndGet()
        pendingDeepL.clear()
        localTranslationQueue.clear()
        deepLExecutor.shutdownNow()
        visualOcrCaches.clear()
        sampling = false
        handler.removeCallbacksAndMessages(null)
        recognitionExecutor.shutdownNow()
        try {
            marianExecutor.execute {
                closeGeminiFallbackModels()
                try { marianTranslator?.close() } catch (_: Exception) { }
                try { hpltTranslator?.close() } catch (_: Exception) { }
            }
            marianExecutor.shutdown()
        } catch (_: Exception) { marianTranslator?.close() }
        try { recognizer.close() } catch (_: Exception) { }
        try { translator.close() } catch (_: Exception) { }
        thread.quitSafely()
    }

    private fun startSampling() {
        if (closed || sampling) return
        sampling = true
        scheduleNext(0)
    }

    private fun stopSampling() {
        sampling = false
        handler.removeCallbacks(sampleRunnable)
    }

    private val sampleRunnable = Runnable {
        if (!sampling || closed) return@Runnable
        if (captureInFlight) return@Runnable
        lastSampleStartedAt = SystemClock.elapsedRealtime()
        capture(debugOnly = false, completion = null)
        if (!captureInFlight) scheduleNext(nextOcrSampleDelay(lastSampleStartedAt, SystemClock.elapsedRealtime(), sampleIntervalMillis))
    }

    private fun scheduleNext(delayMillis: Long) {
        if (sampling && !closed) handler.postDelayed(sampleRunnable, delayMillis)
    }

    private fun finishCapture() {
        handler.post {
            captureInFlight = false
            handler.removeCallbacks(sampleRunnable)
            scheduleNext(regionSchedule.nextDelay(SystemClock.elapsedRealtime(), regionSettings))
        }
    }

    private fun capture(
        debugOnly: Boolean,
        completion: ((String, Map<String, Any?>?) -> Unit)?,
        compareVariants: Boolean = false,
        debugRegionIndex: Int = 0,
    ) {
        if (closed || (!debugOnly && (!enabled || !TranslationAccessController.get(applicationContext).hasAccess()))) {
            completion?.invoke("OCR kapalı", null)
            return
        }
        if (captureInFlight) {
            completion?.invoke("Önceki OCR karesi hâlâ işleniyor", null)
            return
        }
        val copyStartedAt = SystemClock.elapsedRealtime()
        val allRegions = regions
        val settingsSnapshot = regionSettings
        val indices = if (debugOnly) listOf(debugRegionIndex.coerceIn(0, allRegions.lastIndex))
            else regionSchedule.dueIndices(copyStartedAt, settingsSnapshot).filter { it < allRegions.size }
        if (indices.isEmpty()) return
        val regionSnapshot = indices.map { allRegions[it] }
        var captured: CroppedVideoFrame? = null
        val backgroundFrame = try {
            if (croppedFrameProvider != null) {
                captured = croppedFrameProvider.invoke(regionSnapshot)
                captured?.bitmap
            } else backgroundFrameProvider()
        } catch (_: Exception) {
            null
        }
        if (backgroundFrame == null) {
            completion?.invoke("Video karesi henüz hazır değil", null)
            return
        }
        val sourceWidth = captured?.sourceWidth ?: backgroundFrame.width
        val sourceHeight = captured?.sourceHeight ?: backgroundFrame.height
        val selectedBounds = regionSnapshot.map { normalizedCrop(sourceWidth, sourceHeight, it) }
        val bounds = captured?.bounds ?: Rect(
            selectedBounds.minOf { it.left }, selectedBounds.minOf { it.top },
            selectedBounds.maxOf { it.right }, selectedBounds.maxOf { it.bottom },
        )
        if (bounds.width() <= 0 || bounds.height() <= 0) {
            backgroundFrame.recycle()
            completion?.invoke("OCR alanı boş", null)
            return
        }
        captureInFlight = true
        try {
            if (!debugOnly) regionSchedule.sampled(indices, copyStartedAt)
            val bitmap = backgroundFrame
            val copyMillis = SystemClock.elapsedRealtime() - copyStartedAt
            val cropStartedAt = SystemClock.elapsedRealtime()
            val unionBitmap = if (captured != null) bitmap else cropFallback(bitmap, bounds, sourceWidth, sourceHeight)
            val croppedBitmaps = cropSelectedRegions(unionBitmap, bounds, selectedBounds).mapIndexed { offset, crop ->
                val captureScale = settingsSnapshot.getOrNull(indices[offset])?.captureScale ?: 1f
                val scale = (sourceWidth * captureScale).roundToInt().coerceIn(1, MAX_COPY_WIDTH).toFloat() / sourceWidth
                val scaled = Bitmap.createScaledBitmap(crop,
                    (crop.width * scale).roundToInt().coerceAtLeast(1),
                    (crop.height * scale).roundToInt().coerceAtLeast(1), true)
                if (scaled !== crop) crop.recycle()
                scaled
            }
            val cropMillis = SystemClock.elapsedRealtime() - cropStartedAt
            // Each selected crop is an independent bitmap. Release both source
            // buffers after cropping.
            if (unionBitmap !== bitmap) unionBitmap.recycle()
            bitmap.recycle()
            if (debugOnly && compareVariants) {
                val raw = croppedBitmaps.first()
                croppedBitmaps.drop(1).forEach { it.recycle() }
                compareOcrVariants(raw, copyMillis, cropMillis, completion)
            } else {
                if (debugOnly) {
                    val preprocessingStartedAt = SystemClock.elapsedRealtime()
                    val preprocessingMode = settingsSnapshot.getOrNull(indices.first())?.preprocessingMode ?: 0
                    val processed = preprocessCrop(croppedBitmaps.first(), preprocessingMode)
                    if (processed !== croppedBitmaps.first()) croppedBitmaps.first().recycle()
                    val preprocessMillis = SystemClock.elapsedRealtime() - preprocessingStartedAt
                    recognize(
                        processed, indices.first(), copyMillis, cropMillis, preprocessMillis, true, completion,
                        preprocessingMode = preprocessingMode,
                    )
                    croppedBitmaps.drop(1).forEach { it.recycle() }
                } else recognizeRegions(croppedBitmaps, indices, settingsSnapshot, copyMillis, cropMillis)
            }
        } catch (error: Exception) {
            if (!backgroundFrame.isRecycled) backgroundFrame.recycle()
            captureInFlight = false
            completion?.invoke("Video karesi işlenemedi", null)
            if (diagnosticsEnabled()) {
                Log.w("GameTranslateOcr", "Could not process video frame", error)
            } else {
                Log.w("GameTranslateOcr", "Could not process video frame ${error.javaClass.simpleName}")
            }
        }
    }

    private fun normalizedCrop(width: Int, height: Int, value: FloatArray): Rect {
        val bounds = ocrFrameBounds(width, height, value)
        return Rect(bounds.left, bounds.top, bounds.right, bounds.bottom)
    }

    /** Combines only user-selected crops; pixels between selected regions never reach OCR. */
    private fun cropSelectedRegions(union: Bitmap, unionBounds: Rect, selected: List<Rect>): List<Bitmap> {
        val scaleX = union.width.toFloat() / unionBounds.width()
        val scaleY = union.height.toFloat() / unionBounds.height()
        val sources = selected.map { rect ->
            Rect(
                ((rect.left - unionBounds.left) * scaleX).toInt().coerceIn(0, union.width - 1),
                ((rect.top - unionBounds.top) * scaleY).toInt().coerceIn(0, union.height - 1),
                ((rect.right - unionBounds.left) * scaleX).toInt().coerceIn(1, union.width),
                ((rect.bottom - unionBounds.top) * scaleY).toInt().coerceIn(1, union.height),
            )
        }.map { it.apply { right = right.coerceAtLeast(left + 1); bottom = bottom.coerceAtLeast(top + 1) } }
        return sources.map { source ->
            val crop = Bitmap.createBitmap(union, source.left, source.top, source.width(), source.height())
            if (crop === union) crop.copy(Bitmap.Config.ARGB_8888, false) else crop
        }
    }

    private fun cropFallback(bitmap: Bitmap, sourceBounds: Rect, sourceWidth: Int, sourceHeight: Int): Bitmap {
        val sx = bitmap.width.toFloat() / sourceWidth
        val sy = bitmap.height.toFloat() / sourceHeight
        val left = (sourceBounds.left * sx).toInt().coerceIn(0, bitmap.width - 1)
        val top = (sourceBounds.top * sy).toInt().coerceIn(0, bitmap.height - 1)
        val right = max(left + 1, (sourceBounds.right * sx).toInt()).coerceAtMost(bitmap.width)
        val bottom = max(top + 1, (sourceBounds.bottom * sy).toInt()).coerceAtMost(bitmap.height)
        return Bitmap.createBitmap(bitmap, left, top, right - left, bottom - top)
    }

    /** Applies optional enhancement only after the exact user-selected crop. */
    private fun preprocessCrop(source: Bitmap, mode: Int): Bitmap {
        if (mode == 0) return source
        val width = source.width
        val height = source.height
        val size = width * height
        val input = IntArray(size)
        source.getPixels(input, 0, width, 0, 0, width, height)
        if (mode == 8) return isolateYellowText(input, width, height)
        if (mode == 9) return adaptiveColorChannel(input, width, height)
        // Mode 2 only needs the source pixels for this grayscale conversion;
        // reuse the pixel array to avoid a second full-size allocation.
        val gray = if (mode == 2) input else IntArray(size)
        var sum = 0L
        for (i in input.indices) {
            val pixel = input[i]
            val value = (Color.red(pixel) * 299 + Color.green(pixel) * 587 + Color.blue(pixel) * 114) / 1000
            gray[i] = value
            sum += value
        }
        if (mode in 5..7) {
            val brightTextOnDark = when (mode) {
                5 -> true
                6 -> false
                else -> sum / size < 128
            }
            return adaptiveThreshold(gray, width, height, brightTextOnDark, 2)
        }
        // Modes 1, 2 and 4 read only the current gray pixel after their
        // neighborhood/integral data is ready, so the output can reuse gray.
        val output = if (mode == 1 || mode == 2 || mode == 4) gray else IntArray(size)
        if (mode == 1) {
            for (i in gray.indices) {
                val value = (((gray[i] - 128) * 1.65f) + 128f).toInt().coerceIn(0, 255)
                output[i] = Color.rgb(value, value, value)
            }
        } else if (mode == 3) {
            // Mild unsharp mask to restore subtitle edges softened by stream
            // compression. This runs on the already cropped OCR bitmap only.
            for (y in 0 until height) {
                for (x in 0 until width) {
                    var neighborhood = 0
                    var samples = 0
                    for (dy in -1..1) for (dx in -1..1) {
                        val nx = (x + dx).coerceIn(0, width - 1)
                        val ny = (y + dy).coerceIn(0, height - 1)
                        neighborhood += gray[ny * width + nx]
                        samples++
                    }
                    val index = y * width + x
                    val blur = neighborhood / samples
                    val value = (gray[index] + (gray[index] - blur) * 1.5f)
                        .toInt().coerceIn(0, 255)
                    output[index] = Color.rgb(value, value, value)
                }
            }
        } else if (mode == 4) {
            // Local contrast normalization compensates for gradients and glow
            // using one integer integral image and a fixed local gain.
            val integral = buildIntegralImage(gray, width, height)
            val stride = width + 1
            val radius = 12
            for (y in 0 until height) {
                val top = (y - radius).coerceAtLeast(0)
                val bottom = (y + radius + 1).coerceAtMost(height)
                for (x in 0 until width) {
                    val left = (x - radius).coerceAtLeast(0)
                    val right = (x + radius + 1).coerceAtMost(width)
                    val area = (right - left) * (bottom - top)
                    val sumLocal = integral[bottom * stride + right] - integral[top * stride + right] -
                        integral[bottom * stride + left] + integral[top * stride + left]
                    val localMean = sumLocal / area
                    val index = y * width + x
                    val value = (128 + (gray[index] - localMean) * 2)
                        .coerceIn(0, 255)
                    output[index] = Color.rgb(value, value, value)
                }
            }
        } else {
            // Integral image makes adaptive thresholding O(width * height),
            // keeping the optional filter cheap even for 3x crops.
            val stride = width + 1
            val integral = IntArray((width + 1) * (height + 1))
            for (y in 0 until height) {
                var rowSum = 0
                for (x in 0 until width) {
                    rowSum += gray[y * width + x]
                    integral[(y + 1) * stride + x + 1] = integral[y * stride + x + 1] + rowSum
                }
            }
            val radius = 12
            val brightTextOnDark = sum / size < 128
            for (y in 0 until height) {
                val top = (y - radius).coerceAtLeast(0)
                val bottom = (y + radius + 1).coerceAtMost(height)
                for (x in 0 until width) {
                    val left = (x - radius).coerceAtLeast(0)
                    val right = (x + radius + 1).coerceAtMost(width)
                    val area = (right - left) * (bottom - top)
                    val localSum = integral[bottom * stride + right] - integral[top * stride + right] -
                        integral[bottom * stride + left] + integral[top * stride + left]
                    val localMean = localSum / area
                    val glyph = if (brightTextOnDark) gray[y * width + x] > localMean + 8
                        else gray[y * width + x] < localMean - 8
                    val value = if (glyph) 0 else 255
                    output[y * width + x] = Color.rgb(value, value, value)
                }
            }
        }
        return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also {
            it.setPixels(output, 0, width, 0, 0, width, height)
        }
    }

    /** Fast color-difference mask for yellow game text over blue/cool backgrounds. */
    private fun isolateYellowText(pixels: IntArray, width: Int, height: Int): Bitmap {
        val output = IntArray(pixels.size)
        for (index in pixels.indices) {
            val pixel = pixels[index]
            val red = Color.red(pixel)
            val green = Color.green(pixel)
            val blue = Color.blue(pixel)
            // Blue/cyan backgrounds have a large blue channel. Yellow glyphs
            // have both red and green above blue; this simple chroma contrast
            // preserves that distinction instead of flattening it to grayscale.
            val yellowContrast = minOf(red, green) - blue
            val isYellowGlyph = red >= 90 && green >= 75 && yellowContrast >= 18
            output[index] = if (isYellowGlyph) Color.BLACK else Color.WHITE
        }
        return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also {
            it.setPixels(output, 0, width, 0, 0, width, height)
        }
    }

    /** Picks the RGB channel with the strongest per-crop contrast, then thresholds it. */
    private fun adaptiveColorChannel(pixels: IntArray, width: Int, height: Int): Bitmap {
        val sums = LongArray(3)
        val squaredSums = LongArray(3)
        var sampleCount = 0
        // Estimate channel contrast on a sparse grid to keep this adaptive
        // choice cheap; the selected channel is still applied to every pixel.
        for (y in 0 until height step 8) {
            for (x in 0 until width step 8) {
                val pixel = pixels[y * width + x]
                val red = Color.red(pixel).toLong()
                val green = Color.green(pixel).toLong()
                val blue = Color.blue(pixel).toLong()
                sums[0] += red
                sums[1] += green
                sums[2] += blue
                squaredSums[0] += red * red
                squaredSums[1] += green * green
                squaredSums[2] += blue * blue
                sampleCount++
            }
        }
        val count = sampleCount.toDouble()
        var selectedChannel = 0
        var highestVariance = -1.0
        for (channel in 0..2) {
            val mean = sums[channel] / count
            val variance = squaredSums[channel] / count - mean * mean
            if (variance > highestVariance) {
                highestVariance = variance
                selectedChannel = channel
            }
        }
        val channelPixels = IntArray(pixels.size)
        for (index in pixels.indices) {
            val pixel = pixels[index]
            channelPixels[index] = when (selectedChannel) {
                0 -> Color.red(pixel)
                1 -> Color.green(pixel)
                else -> Color.blue(pixel)
            }
        }
        val brightTextOnDark = sums[selectedChannel] / count < 128.0
        return adaptiveThreshold(
            channelPixels,
            width,
            height,
            brightTextOnDark,
            thresholdOffset = 4,
        )
    }

    /** Local adaptive thresholding with selectable light/dark text polarity. */
    private fun adaptiveThreshold(
        gray: IntArray,
        width: Int,
        height: Int,
        brightTextOnDark: Boolean,
        thresholdOffset: Int,
    ): Bitmap {
        val stride = width + 1
        val integral = buildIntegralImage(gray, width, height)
        // The integral image already contains all neighborhood data, so gray
        // can be overwritten in place as each output pixel is produced.
        val output = gray
        val radius = 12
        for (y in 0 until height) {
            val top = (y - radius).coerceAtLeast(0)
            val bottom = (y + radius + 1).coerceAtMost(height)
            for (x in 0 until width) {
                val left = (x - radius).coerceAtLeast(0)
                val right = (x + radius + 1).coerceAtMost(width)
                val area = (right - left) * (bottom - top)
                val sumLocal = integral[bottom * stride + right] - integral[top * stride + right] -
                    integral[bottom * stride + left] + integral[top * stride + left]
                val localMean = sumLocal / area
                val pixel = gray[y * width + x]
                // A small offset keeps faint strokes while the local mean adapts
                // to gradients. Users can force either text polarity.
                val isGlyph = if (brightTextOnDark) {
                    pixel >= localMean + thresholdOffset
                } else {
                    pixel <= localMean - thresholdOffset
                }
                output[y * width + x] = if (isGlyph) Color.BLACK else Color.WHITE
            }
        }
        return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also {
            it.setPixels(output, 0, width, 0, 0, width, height)
        }
    }

    private fun buildIntegralImage(gray: IntArray, width: Int, height: Int): IntArray {
        val stride = width + 1
        val integral = IntArray((width + 1) * (height + 1))
        for (y in 0 until height) {
            var rowSum = 0
            for (x in 0 until width) {
                rowSum += gray[y * width + x]
                integral[(y + 1) * stride + x + 1] = integral[y * stride + x + 1] + rowSum
            }
        }
        return integral
    }

    /** Compare all preprocessing variants on one copied game frame and one selected crop. */
    private fun compareOcrVariants(
        raw: Bitmap,
        copyMs: Long,
        cropMs: Long,
        completion: ((String, Map<String, Any?>?) -> Unit)?,
    ) {
        val grayStartedAt = SystemClock.elapsedRealtime()
        val gray = preprocessCrop(raw, 1)
        val grayMs = SystemClock.elapsedRealtime() - grayStartedAt
        val thresholdStartedAt = SystemClock.elapsedRealtime()
        val threshold = preprocessCrop(raw, 2)
        val thresholdMs = SystemClock.elapsedRealtime() - thresholdStartedAt
        val results = linkedMapOf<String, String>()
        val measurements = linkedMapOf<String, Map<String, Any?>>()
        fun finishIfReady() {
            if (results.size < 3) return
            fun row(name: String, label: String) = "$label (${measurements[name]?.get("ocrMs") ?: "?"} ms, güven ${measurements[name]?.get("ocrConfidence") ?: "?"}): ${results[name]}"
            val combined = "${row("ham", "Ham")}\n${row("kontrast", "Kontrast")}\n${row("adaptif", "Adaptif")}"
            completion?.invoke(
                combined,
                mapOf("copyMs" to copyMs, "cropMs" to cropMs, "preprocessMs" to (grayMs + thresholdMs),
                    "cropWidth" to raw.width, "cropHeight" to raw.height, "variants" to measurements),
            )
        }
        fun recognizeVariant(
            bitmap: Bitmap,
            name: String,
            mode: Int,
            preprocessMs: Long,
            release: Boolean,
            next: (() -> Unit)? = null,
        ) {
            recognize(bitmap, 0, copyMs, cropMs, preprocessMs, true, { text, timings ->
                results[name] = text
                if (timings != null) measurements[name] = timings
                next?.invoke() ?: finishIfReady()
            }, releaseCaptureWhenDebugDone = release, preprocessingMode = mode)
        }
        recognizeVariant(raw, "ham", 0, 0, false) {
            recognizeVariant(gray, "kontrast", 1, grayMs, false) {
                recognizeVariant(threshold, "adaptif", 2, thresholdMs, true)
            }
        }
    }

    private fun recognize(
        bitmap: Bitmap,
        regionIndex: Int,
        copyMillis: Long,
        cropMillis: Long,
        preprocessMillis: Long,
        debugOnly: Boolean,
        completion: ((String, Map<String, Any?>?) -> Unit)?,
        releaseCaptureWhenDebugDone: Boolean = true,
        preprocessingMode: Int = 0,
        dialogueFilter: Boolean = false,
        recoveryRaw: Bitmap? = null,
    ) {
        val ocrStartedAt = SystemClock.elapsedRealtime()
        val frameRevision = deepLRevision.get()
        val recoveryEpoch = recoveryRevision.get()
        val owned = linkedSetOf(bitmap).apply { recoveryRaw?.let { add(it) } }
        var totalPreprocessMillis = preprocessMillis
        var attempts = 0
        val visualKey = if (!debugOnly) {
            val count = bitmap.width * bitmap.height
            if (visualPixels.size < count) visualPixels = IntArray(count)
            bitmap.getPixels(visualPixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
            ocrPixelFingerprint(bitmap.width, bitmap.height, visualPixels)
        } else null
        val visualCache = if (!debugOnly) visualOcrCaches.getOrPut(regionIndex) { OcrVisualCache() } else null
        data class Evaluated(
            val result: com.google.mlkit.vision.text.Text,
            val rawText: String,
            val rawConfidence: Float,
            val selected: SubtitleOcrRead,
            val memory: GameTranslationMemory?,
            val lookupMillis: Long,
        ) {
            fun recoveryRead() = OcrRecoveryPolicy.Read(rawText, rawConfidence, selected.text, selected.confidence)
        }
        fun evaluate(result: com.google.mlkit.vision.text.Text): Evaluated {
            val lines = result.textBlocks.flatMap { it.lines }.sortedWith(
                compareBy<com.google.mlkit.vision.text.Text.Line> { it.boundingBox?.top ?: 0 }
                    .thenBy { it.boundingBox?.left ?: 0 })
            val rawText = lines.joinToString(" ") { it.text }
            val rawConfidenceValues = lines.flatMap { line ->
                line.elements.map { it.confidence }.filter { it > 0f }
            }.ifEmpty { lines.map { it.confidence }.filter { it > 0f } }
            val rawConfidence = if (rawConfidenceValues.isEmpty()) 0f
                else rawConfidenceValues.average().toFloat().coerceIn(0f, 1f)
            val lookupStartedAt = SystemClock.elapsedRealtime()
            val memory = if (debugOnly) null else matchingGameMemory()
            val blocks = result.textBlocks.sortedBy { it.boundingBox?.top ?: 0 }
                .map { block -> block.lines.joinToString(" ") { it.text } }
            val candidates = (blocks + blocks.zipWithNext { left, right -> "$left $right" })
                .filter { it.length >= 2 && it.any(Char::isLetterOrDigit) }.sortedByDescending(String::length).take(8)
            val selected = selectSubtitleSource(
                rawText, rawConfidence, memory, candidates,
            ) {
                val acceptedLines = if (!debugOnly && dialogueFilter) {
                    val candidates = result.textBlocks.flatMapIndexed { blockIndex, block ->
                        block.lines.map { line ->
                            val box = line.boundingBox ?: Rect(0, 0, bitmap.width, bitmap.height)
                            val confidenceValues = line.elements.map { it.confidence }.filter { it > 0f }
                                .ifEmpty { listOfNotNull(line.confidence.takeIf { it > 0f }) }
                            OcrLineCandidate(
                                rawText = line.text,
                                text = normalizeOcrText(line.text),
                                blockIndex = blockIndex,
                                confidenceValues = confidenceValues,
                                left = box.left.toFloat() / bitmap.width.coerceAtLeast(1),
                                top = box.top.toFloat() / bitmap.height.coerceAtLeast(1),
                                right = box.right.toFloat() / bitmap.width.coerceAtLeast(1),
                                bottom = box.bottom.toFloat() / bitmap.height.coerceAtLeast(1),
                            )
                        }
                    }
                        .sortedWith(compareBy<OcrLineCandidate> { it.top }.thenBy { it.left })
                    // This callback is reached only after the normal full/block JSON lookup misses.
                    filterDialogueOcrLines(candidates, rejectTimerGlyphs = canPrepareUnmatchedOcr(
                        selectedGame || gameTranslationMemory != null, memory != null, jsonMatched = false))
                } else null
                val text = acceptedLines?.let { accepted ->
                    normalizeOcrText(accepted.joinToString(" ") { it.rawText })
                } ?: normalizeOcrText(rawText)
                val confidenceValues = acceptedLines?.flatMap { it.confidenceValues } ?: rawConfidenceValues
                val confidence = if (confidenceValues.isEmpty()) 0f
                    else confidenceValues.average().toFloat().coerceIn(0f, 1f)
                SubtitleOcrRead(text, confidence)
            }
            return Evaluated(result, rawText, rawConfidence, selected, memory,
                SystemClock.elapsedRealtime() - lookupStartedAt)
        }
        fun release() { owned.forEach { if (!it.isRecycled) it.recycle() } }
        fun currentFrameContext() = !closed && enabled &&
            recoveryRevision.get() == recoveryEpoch && deepLRevision.get() == frameRevision
        fun currentRecoveryAllowed(value: Evaluated) = currentFrameContext() && canPrepareUnmatchedOcr(
            selectedGame || gameTranslationMemory != null,
            value.memory != null && value.memory === matchingGameMemory(),
            value.selected.memoryMatch != null,
        )
        fun finish(value: Evaluated, chosenMode: Int, visualReuse: Boolean) {
            // A game selected while an alternative was running keeps JSON priority.
            val current = if (!debugOnly && value.memory !== matchingGameMemory()) evaluate(value.result) else value
            val hasGame = selectedGame || gameTranslationMemory != null
            var extraLookupMillis = 0L
            val prepared = if (debugOnly || !currentFrameContext()) PreparedOcrRead(current.selected)
            else prepareUnmatchedOcr(current.selected, hasGame, current.memory != null,
                correct = { text -> ocrCorrections.correct(text, sourceLanguageCode,
                    gameSelected = hasGame, gameLookupMiss = current.memory != null) },
                findGameTranslation = { text ->
                    val startedAt = SystemClock.elapsedRealtime()
                    try { current.memory?.find(text) }
                    finally { extraLookupMillis += SystemClock.elapsedRealtime() - startedAt }
                })
            val selected = prepared.read
            val text = selected.text
            val confidence = selected.confidence
            val ocrMillis = SystemClock.elapsedRealtime() - ocrStartedAt
            val lookupMillis = current.lookupMillis + extraLookupMillis
            // Also retain a recovery result which found JSON, without adding work to primary JSON hits.
            if (visualKey != null && !visualReuse && currentFrameContext() &&
                (currentRecoveryAllowed(current) || (attempts > 0 && selected.memoryMatch != null)))
                visualCache?.remember(visualKey, SystemClock.elapsedRealtime(), current.result)
            if (!debugOnly) logLookup(regionIndex, text, current.memory, selected.memoryMatch,
                copyMillis, ocrMillis, lookupMillis, visualReuse)
            if (!debugOnly) logOcrResult(regionIndex, current.rawText, text, confidence, bitmap.width, bitmap.height,
                copyMillis, cropMillis, totalPreprocessMillis, chosenMode, dialogueFilter, ocrMillis)
            val details = mapOf(
                "copyMs" to copyMillis, "cropMs" to cropMillis, "preprocessMs" to totalPreprocessMillis,
                "preprocessingMode" to chosenMode, "preprocessingModeName" to preprocessingModeName(chosenMode),
                "dialogueFilter" to dialogueFilter, "ocrMs" to ocrMillis, "jsonLookupMs" to lookupMillis,
                "visualReuse" to visualReuse, "cropWidth" to bitmap.width, "cropHeight" to bitmap.height,
                "ocrConfidence" to confidence, "recoveryAttempts" to attempts,
                "ocrCorrections" to prepared.corrections,
            )
            if (attempts > 0 && diagnosticsEnabled()) Log.i(OCR_LOG_TAG,
                "OCR_RECOVERY area=${regionIndex + 1} attempts=$attempts primaryMode=$preprocessingMode chosenMode=$chosenMode latencyMs=$ocrMillis")
            if (prepared.corrections > 0 && diagnosticsEnabled()) Log.i(OCR_LOG_TAG,
                "OCR_CORRECTION area=${regionIndex + 1} replacements=${prepared.corrections} tableVersion=1")
            release()
            if (debugOnly) {
                if (releaseCaptureWhenDebugDone) finishCapture()
                completion?.invoke(text.ifEmpty { "Seçili alanda metin bulunamadı" }, details)
                return
            }
            if (!closed && enabled && deepLRevision.get() == frameRevision)
                onRecognized(regionIndex, text, confidence, selected.memoryMatch)
            completion?.invoke(text, details)
        }
        fun recognized(result: com.google.mlkit.vision.text.Text, visualReuse: Boolean) {
            if (visualKey != null && !visualReuse) visualCache?.remember(visualKey, SystemClock.elapsedRealtime(), result)
            val primary = evaluate(result)
            val raw = recoveryRaw
            if (raw == null || !currentRecoveryAllowed(primary) || !ocrRecovery.begin(primary.recoveryRead(),
                    gameSelected = selectedGame || gameTranslationMemory != null, visualReuse = visualReuse,
                    debugOnly = debugOnly, gameLookupMiss = primary.memory != null)) {
                finish(primary, preprocessingMode, visualReuse)
                return
            }
            val values = mutableListOf(primary)
            val modes = mutableListOf(preprocessingMode)
            val recoveryStartedAt = SystemClock.elapsedRealtime()
            val alternatives = ocrRecovery.modes(preprocessingMode)
            fun next(index: Int) {
                if (index >= alternatives.size || !currentRecoveryAllowed(primary) || !ocrRecovery.withinBudget(recoveryStartedAt)) {
                    val chosen = if (currentRecoveryAllowed(primary))
                        ocrRecovery.best(values.map { it.recoveryRead() }, sourceLanguageCode) else 0
                    finish(values[chosen], modes[chosen], visualReuse)
                    return
                }
                val mode = alternatives[index]
                val started = SystemClock.elapsedRealtime()
                val alternative = try { preprocessCrop(raw, mode).also { owned.add(it) } }
                catch (_: Exception) { next(index + 1); return }
                totalPreprocessMillis += SystemClock.elapsedRealtime() - started
                attempts++
                val task = try { recognizer.process(InputImage.fromBitmap(alternative, 0)) }
                    catch (_: Exception) { next(index + 1); return }
                task
                    .addOnSuccessListener(recognitionExecutor) {
                        val evaluated = evaluate(it)
                        if (evaluated.selected.memoryMatch != null) {
                            finish(evaluated, mode, visualReuse)
                        } else {
                            values.add(evaluated); modes.add(mode); next(index + 1)
                        }
                    }
                    .addOnFailureListener(recognitionExecutor) { next(index + 1) }
            }
            next(0)
        }
        val cached = if (visualKey == null) null else visualCache?.reuse(visualKey, SystemClock.elapsedRealtime())
        if (cached != null) {
            recognitionExecutor.execute { recognized(cached, true) }
            return
        }
        recognizer.process(InputImage.fromBitmap(bitmap, 0))
            .addOnSuccessListener(recognitionExecutor) { recognized(it, false) }
            .addOnFailureListener(recognitionExecutor) { error ->
                release()
                if (debugOnly) {
                    if (releaseCaptureWhenDebugDone) finishCapture()
                    completion?.invoke("OCR işlenemedi: ${error.javaClass.simpleName}", null)
                } else {
                    emit(mapOf("type" to "subtitleOcrStatus", "status" to "OCR hatası"))
                    completion?.invoke("", null)
                }
            }
    }

    private fun normalizeCaptureScale(value: Float): Float = when {
        value < 1.25f -> 1f
        value < 1.75f -> 1.5f
        else -> 2f
    }

    private fun recognizeRegions(bitmaps: List<Bitmap>, indices: List<Int>, settings: List<OcrRegionSettings>, copyMs: Long, cropMs: Long) {
        if (bitmaps.isEmpty() || closed) { finishCapture(); return }
        val remaining = AtomicInteger(bitmaps.size)
        val recoveryRegion = ocrRecovery.region(indices, selectedGame || gameTranslationMemory != null,
            gameLookupReady = matchingGameMemory() != null)
        bitmaps.forEachIndexed { offset, crop ->
            val index = indices[offset]
            // Process and submit each crop immediately. A slow enhancement on a
            // later region must not hold back OCR for an earlier raw region.
            val preprocessingMode = settings.getOrNull(index)?.preprocessingMode ?: 0
            val dialogueFilter = settings.getOrNull(index)?.dialogueFilter ?: false
            val preprocessStartedAt = SystemClock.elapsedRealtime()
            val bitmap = preprocessCrop(crop, preprocessingMode)
            val recoveryRaw = crop.takeIf { index == recoveryRegion && crop.width.toLong() * crop.height <= 1_500_000 }
            if (bitmap !== crop && recoveryRaw == null) crop.recycle()
            val preprocessMs = SystemClock.elapsedRealtime() - preprocessStartedAt
            recognize(
                bitmap, index, copyMs, cropMs, preprocessMs, false,
                completion = { _, _ ->
                    if (remaining.decrementAndGet() == 0) finishCapture()
                },
                preprocessingMode = preprocessingMode,
                dialogueFilter = dialogueFilter,
                recoveryRaw = recoveryRaw,
            )
        }
    }

    private fun onRecognized(
        index: Int,
        text: String,
        confidence: Float,
        memoryMatch: GameTranslationMatch? = null,
    ) {
        while (regionStates.size <= index) regionStates.add(RegionState())
        val state = regionStates[index]
        val now = SystemClock.elapsedRealtime()
        // A known JSON line is authoritative even if the dialogue filter would
        // reject its position/line count or report zero accepted confidence.
        if (memoryMatch != null) {
            state.deepLOcrPolicy.clear()
            state.localOcrPolicy.clear()
            val matchKey = "${memoryMatch.gameId}:${memoryMatch.entryId}:" +
                canonicalTranslationKey(memoryMatch.source) + ":" + memoryMatch.speaker.orEmpty()
            val sameMatch = state.memoryMatchedKey == matchKey
            latestMarianKeyByRegion.remove(index)
            clearPendingVariant(state)
            state.sourceText = text
            state.sourceKey = matchKey
            state.sourceConfidence = confidence
            state.translatingKey = null
            state.memoryMatchedKey = matchKey
            state.fallbackPendingKey = null
            state.fallbackVisibleKey = null
            state.visibleSince = now
            state.emptySince = null
            state.clearSent = false
            if (!sameMatch) {
                emit(mapOf("type" to "ocrDebug", "text" to text, "regionIndex" to index, "confidence" to confidence))
                emitSubtitleText(index, text, memoryMatch.target, "game_memory", "none", memoryMatch)
            }
            return
        }
        // Punctuation-only detections (for example a subtitle separator ':')
        // behave like an empty OCR result and never reach translation. Cloud
        // clocks/numbers also take this path even with dialogue filtering off,
        // before either cache lookup or API scheduling. JSON already returned above.
        if (text.isEmpty() || text.none { it.isLetterOrDigit() } ||
            (isCloudEngine() && isNonLinguisticCloudOcr(text))) {
            state.deepLOcrPolicy.discardPending()
            state.localOcrPolicy.discardPending()
            expireVisibleSubtitleIfNeeded(state, index, now)
            clearPendingVariant(state)
            if (state.sourceText != null) {
                val emptyStart = state.emptySince ?: now.also { state.emptySince = it }
                if (!state.clearSent && now - emptyStart >= (regionSettings.getOrNull(index)?.holdMillis ?: 2500L)) {
                    // A single empty OCR frame is often a transient recognition
                    // miss. Keep the in-flight translation valid for the whole
                    // subtitle hold interval; cancel it only once we actually
                    // clear the held subtitle.
                    latestMarianKeyByRegion.remove(index)
                    state.clearSent = true
                    state.sourceText = null
                    state.sourceKey = null
                    state.fallbackPendingKey = null
                    state.fallbackVisibleKey = null
                    state.deepLOcrPolicy.clear()
                    state.localOcrPolicy.clear()
                    state.sourceConfidence = 0f
                    clearPendingVariant(state)
                    state.translatingKey = null
                    state.memoryMatchedKey = null
                    state.visibleSince = null
                    emit(mapOf("type" to "subtitleCleared", "regionIndex" to index))
                }
            } else if (state.sourceKey != null) {
                latestMarianKeyByRegion.remove(index)
                // The expired text has now left the OCR area, so it may be
                // displayed again if it appears later.
                state.sourceKey = null
                state.fallbackPendingKey = null
                state.fallbackVisibleKey = null
                state.deepLOcrPolicy.clear()
                state.localOcrPolicy.clear()
                state.sourceConfidence = 0f
                clearPendingVariant(state)
                state.translatingKey = null
                state.memoryMatchedKey = null
            }
            return
        }

        state.emptySince = null
        state.clearSent = false
        if (confidence < MIN_CONFIDENT_OCR_THRESHOLD) {
            state.deepLOcrPolicy.discardPending()
            state.localOcrPolicy.discardPending()
            expireVisibleSubtitleIfNeeded(state, index, now)
            clearPendingVariant(state)
            return
        }
        if (!liveTranslationSupported()) {
            expireVisibleSubtitleIfNeeded(state, index, now)
            return
        }
        val deepLRead = if (isCloudEngine()) {
            state.deepLOcrPolicy.observeCloud(text, confidence, sourceLanguageCode,
                regionSettings.getOrNull(index)?.sampleIntervalMillis ?: sampleIntervalMillis,
                engine = translationEngine)
                ?: run {
                    if (state.deepLOcrPolicy.requestKey != state.sourceKey) {
                        // OCR has already moved to a different, unconfirmed line.
                        // Do not spend on its predecessor while the API is busy.
                        pendingDeepL.remove(index)
                        latestMarianKeyByRegion.remove(index)
                        state.translatingKey = null
                        state.fallbackPendingKey = null
                    }
                    if (state.deepLOcrPolicy.requestKey == state.sourceKey && state.visibleSince != null) {
                        state.visibleSince = now
                    } else {
                        expireVisibleSubtitleIfNeeded(state, index, now)
                    }
                    if (diagnosticsEnabled()) Log.d(OCR_LOG_TAG, "${translationEngine.uppercase(Locale.ROOT)}_OCR_PENDING area=${index + 1}")
                    return
                }
        } else null
        // Use the same corroboration/meaning safeguards for local OCR. A model
        // taking 500 ms cannot finish a separate spelling from every 70 ms frame.
        val localRead = if (translationEngine in setOf("opus", "mlkit") && sourceLanguageCode == "en") {
            val interval = regionSettings.getOrNull(index)?.sampleIntervalMillis ?: sampleIntervalMillis
            state.localOcrPolicy.observe(text, confidence, sourceLanguageCode,
                interval) ?: run {
                if (state.localOcrPolicy.requestKey == state.sourceKey && state.visibleSince != null)
                    state.visibleSince = now
                else expireVisibleSubtitleIfNeeded(state, index, now)
                return
            }
        } else null
        val confirmedRead = deepLRead ?: localRead
        val acceptedText = confirmedRead?.text ?: text
        if (deepLRead != null) state.lastConfirmedLiveAt = now
        val acceptedConfidence = confirmedRead?.confidence ?: confidence
        val key = confirmedRead?.key ?: canonicalTranslationKey(acceptedText)
        if (key.isEmpty()) {
            expireVisibleSubtitleIfNeeded(state, index, now)
            return
        }
        // Active cloud/local engines corroborate above; retired comparison engines
        // keep the older variant gate below.
        if (key == state.sourceKey) {
            state.sourceConfidence = maxOf(state.sourceConfidence, acceptedConfidence)
            if (state.visibleSince != null) state.visibleSince = now
            // Returning to the current reading breaks a candidate sequence.
            clearPendingVariant(state)
            if (isCloudEngine() && (state.visibleSince == null ||
                    (state.fallbackVisibleKey == key && !cloudRetry.waiting)) && state.translatingKey == null) {
                translateWithDeepL(index, state, key, acceptedText)
            }
            if (localRead != null && state.visibleSince == null && state.translatingKey == null) {
                val cached = translationCache[key]
                if (cached != null) {
                    state.visibleSince = now
                    emitSubtitleText(index, acceptedText, cached, "live_cache", translationEngine)
                } else if (translationEngine == "opus") translateWithMarian(index, state, key, acceptedText)
                else if (translationModelReady) translate(index, state, key, acceptedText)
                else ensureTranslationModel()
            }
            return
        }
        val previousVisibleText = state.sourceText
        val isVisibleOcrVariant = previousVisibleText != null &&
            isOcrNoiseVariant(previousVisibleText, acceptedText)
        if (isVisibleOcrVariant) {
            if (state.visibleSince != null) state.visibleSince = now
        } else {
            // The old displayed line may expire after a fade-out, but keep the
            // policy's freshly confirmed replacement eligible for delivery.
            expireVisibleSubtitleIfNeeded(state, index, now, resetOcrPolicies = confirmedRead == null)
        }
        val previousText = state.sourceText
        var effectiveText = acceptedText
        var effectiveConfidence = acceptedConfidence
        if (confirmedRead == null && previousText != null && isOcrNoiseVariant(previousText, acceptedText)) {
            val confirmed = state.variantGate.observe(key, acceptedText, acceptedConfidence)
            if (confirmed == null) {
                if (diagnosticsEnabled()) Log.d(OCR_LOG_TAG,
                    "OCR_VARIANT_PENDING area=${index + 1} confidence=$acceptedConfidence")
                return
            }
            effectiveText = confirmed.text
            effectiveConfidence = confirmed.confidence
        }
        clearPendingVariant(state)
        // A genuinely different line stays immediate. Similar OCR spellings
        // are accepted after the new candidate is repeated, regardless of the old score.
        val effectiveKey = confirmedRead?.key ?: canonicalTranslationKey(effectiveText)
        state.sourceText = effectiveText
        state.sourceKey = effectiveKey
        state.fallbackPendingKey = null
        state.sourceConfidence = effectiveConfidence
        state.memoryMatchedKey = null
        state.visibleSince = null
        state.fallbackVisibleKey = null
        emit(mapOf("type" to "ocrDebug", "text" to effectiveText, "regionIndex" to index, "confidence" to effectiveConfidence))
        latestMarianKeyByRegion.remove(index)
        val cachedTranslation = translationCache[effectiveKey] ?: if (isCloudEngine())
            cloudCache().getIfLoaded(sourceLanguageCode, targetLanguageCode, effectiveKey) else null
        cachedTranslation?.let { cached ->
            translationCache[effectiveKey] = cached
            state.fallbackVisibleKey = null
            state.visibleSince = SystemClock.elapsedRealtime()
            emitSubtitleText(index, effectiveText, cached, "live_cache", translationEngine)
            return
        }
        if (translationEngine == "opus") {
            translateWithMarian(index, state, effectiveKey, effectiveText)
            return
        }
        if (isCloudEngine()) {
            translateWithDeepL(index, state, effectiveKey, effectiveText)
            return
        }
        if (translationEngine == "hplt") {
            translateWithHplt(index, state, effectiveKey, effectiveText)
            return
        }
        if (translationEngine == "compare") {
            translateWithMarian(index, state, effectiveKey, effectiveText)
        }
        if (!translationModelReady) {
            ensureTranslationModel()
            return
        }
        translate(index, state, effectiveKey, effectiveText)
    }

    private fun translateWithDeepL(index: Int, state: RegionState, key: String, text: String) {
        if (closed || !enabled || !canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key) ||
            state.translatingKey == key) return
        if (translationEngine == "gemini" && geminiPoolRevision != deepLRevision.get()) return
        // A provider cooldown forbids new HTTP requests, never local cache hits.
        val cached = translationCache[key] ?: cloudCache().getIfLoaded(sourceLanguageCode, targetLanguageCode, key)
        if (cached != null) {
            translationCache[key] = cached
            state.fallbackVisibleKey = null
            state.visibleSince = SystemClock.elapsedRealtime()
            emitSubtitleText(index, text, cached, "live_cache", translationEngine)
            return
        }
        if (cloudRetry.waiting) {
            if (translationEngine == "gemini" && cloudRetry.allowsGeminiFallback)
                translateWithGeminiFallback(index, state, key, text)
            return
        }
        if (deepLApiKey.isBlank()) {
            cloudRetry.fail("KEY_REQUIRED", "", Long.MAX_VALUE)
            emit(mapOf("type" to "subtitleOcrStatus", "status" to if (translationEngine == "gemini") "Geçerli bir Gemini API anahtarı gir." else "Geçerli bir DeepL API anahtarı gir."))
            return
        }
        val requestKey = if (translationEngine == "gemini") geminiKeyPool.acquire() else deepLApiKey
        if (requestKey == null) {
            applyGeminiPoolWait()
            if (cloudRetry.allowsGeminiFallback) translateWithGeminiFallback(index, state, key, text)
            return
        }
        state.translatingKey = key
        latestMarianKeyByRegion[index] = key
        pendingDeepL[index] = DeepLRequest(translationEngine, index, state, key, text, sourceLanguageCode,
            targetLanguageCode, requestKey, deepLRevision.get())
        emit(mapOf("type" to "subtitleOcrStatus", "status" to "Çeviri hazırlanıyor"))
        drainDeepLRequests()
    }

    /** Keep only the newest queued subtitle per region while a network request is running. */
    private fun drainDeepLRequests() {
        if (closed || !deepLDraining.compareAndSet(false, true)) return
        deepLExecutor.execute {
            try {
                while (!closed) {
                    val request = synchronized(pendingDeepL) {
                        pendingDeepL.keys.firstOrNull()?.let { pendingDeepL.remove(it) }
                    } ?: break
                    val index = request.index
                    if (!enabled || translationEngine != request.engine || request.revision != deepLRevision.get() ||
                        latestMarianKeyByRegion[index] != request.key) continue
                    var cacheHit = false
                    val result = runCatching {
                        if (request.engine == "gemini") {
                            val translated = geminiTranslationEngine.translate(request.source, request.target,
                                request.key, request.text, request.apiKey)
                            cacheHit = translated.fromCache
                            translated.text
                        } else {
                            val translated = deepLTranslationEngine.translate(request.source, request.target,
                                request.key, request.text, request.apiKey, index)
                            cacheHit = translated.fromCache
                            translated.text
                        }
                    }
                    if (closed) break
                    recognitionExecutor.execute response@{
                        if (request.revision != deepLRevision.get() || translationEngine != request.engine) return@response
                        if (request.state.translatingKey == request.key) request.state.translatingKey = null
                        result.fold(onSuccess = { translated ->
                            if (!cacheHit) {
                                cloudRetry.clear()
                                if (request.engine == "gemini") geminiKeyPool.succeeded(request.apiKey)
                            }
                            translationCache[request.key] = translated
                            if (enabled && regionStates.getOrNull(index) === request.state &&
                                request.state.deepLOcrPolicy.requestKey == request.key &&
                                canUseLiveSubtitle(request.state.sourceKey, request.state.memoryMatchedKey, request.key)) {
                                request.state.visibleSince = SystemClock.elapsedRealtime()
                                request.state.fallbackVisibleKey = null
                                emitSubtitleText(index, request.text, translated, if (cacheHit) "live_cache" else "live_translation", request.engine)
                                emit(mapOf("type" to "subtitleOcrStatus", "status" to "Çevrildi"))
                            }
                        }, onFailure = { error ->
                            val failure = when (error) {
                                is GeminiException -> DeepLException(error.code, error.message.orEmpty(), error.retryDelayMs)
                                is DeepLException -> error
                                else -> if (request.engine == "gemini") DeepLException("GEMINI_UNAVAILABLE", "Gemini şu anda yanıt veremiyor. Biraz sonra tekrar dene.", 5_000)
                                    else DeepLClient.errorForStatus(503)
                            }
                            val keyFailure = request.engine == "gemini" && GeminiKeyPool.canFailOver(failure.code)
                            val retryDelay = if (keyFailure) {
                                geminiKeyPool.failed(request.apiKey, GeminiException(failure.code, failure.message.orEmpty(), failure.retryDelayMs))
                                if (geminiKeyPool.acquire() != null) { cloudRetry.clear(); 0L }
                                else { applyGeminiPoolWait(); cloudRetry.remainingMs }
                            } else cloudRetry.fail(failure.code, failure.message.orEmpty(), failure.retryDelayMs)
                            if (diagnosticsEnabled()) Log.w(OCR_LOG_TAG, "${request.engine.uppercase(Locale.ROOT)}_FAILURE code=${failure.code} retryDelayMs=$retryDelay")
                            pendingDeepL.clear()
                            regionStates.forEach { it.translatingKey = null }
                            emit(mapOf("type" to "subtitleOcrStatus", "status" to failure.message))
                            if (request.engine == "gemini" && (!cloudRetry.waiting || cloudRetry.allowsGeminiFallback)) {
                                regionStates.forEachIndexed { area, state ->
                                    val key = state.sourceKey ?: return@forEachIndexed
                                    val text = state.sourceText ?: return@forEachIndexed
                                    if (state.deepLOcrPolicy.requestKey == key && !state.deepLOcrPolicy.hasPendingRead &&
                                        cloudRetry.isLatestFresh(state.lastConfirmedLiveAt, sampleIntervalMillis)) {
                                        translateWithDeepL(area, state, key, text)
                                    }
                                }
                            }
                            if (cloudRetry.waiting) scheduleCloudRetry(request.engine, request.revision)
                        })
                    }
                    // Apply the response/backoff before taking the next queued request.
                    val applied = java.util.concurrent.CountDownLatch(1)
                    recognitionExecutor.execute { applied.countDown() }
                    applied.await()
                    if (cloudRetry.waiting) break
                }
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
            } finally {
                deepLDraining.set(false)
                if (!closed && pendingDeepL.isNotEmpty()) drainDeepLRequests()
            }
        }
    }

    private fun applyGeminiPoolWait() {
        val blocked = geminiKeyPool.blockedStatus() ?: return
        cloudRetry.defer(blocked["code"] as? String ?: "GEMINI_RATE_LIMIT",
            blocked["message"] as? String ?: "", blocked["delayMs"] as? Long ?: Long.MAX_VALUE)
    }

    /** Count down locally and resume only current, corroborated text; never replay the backlog. */
    private fun scheduleCloudRetry(engine: String, revision: Int) {
        cloudRetryTick?.let { handler.removeCallbacks(it) }
        if (cloudRetry.remainingMs == Long.MAX_VALUE) return
        val tick = object : Runnable {
            override fun run() {
                if (closed || !enabled || translationEngine != engine || deepLRevision.get() != revision) return
                val remaining = cloudRetry.remainingMs
                if (remaining == Long.MAX_VALUE) return
                if (remaining > 0L) {
                    if (engine == "gemini") emitGeminiFallbackStatus()
                    handler.postDelayed(this, minOf(1000L, remaining))
                    return
                }
                recognitionExecutor.execute {
                    if (closed || !enabled || translationEngine != engine || deepLRevision.get() != revision || cloudRetry.waiting) return@execute
                    if (diagnosticsEnabled()) Log.i(OCR_LOG_TAG, "${engine.uppercase(Locale.ROOT)}_RETRY_READY")
                    if (engine == "gemini") emit(mapOf("type" to "subtitleOcrStatus",
                        "status" to "Gemini hazır. Güncel altyazı bekleniyor."))
                    regionStates.forEachIndexed { index, state ->
                        val key = state.sourceKey ?: return@forEachIndexed
                        val text = state.sourceText ?: return@forEachIndexed
                        val sampleInterval = regionSettings.getOrNull(index)?.sampleIntervalMillis ?: sampleIntervalMillis
                        if (state.deepLOcrPolicy.requestKey == key && !state.deepLOcrPolicy.hasPendingRead &&
                            (state.visibleSince == null || state.fallbackVisibleKey == key) &&
                            cloudRetry.canRetryLatest(state.lastConfirmedLiveAt, sampleInterval)) {
                            translateWithDeepL(index, state, key, text)
                        }
                    }
                }
            }
        }
        cloudRetryTick = tick
        handler.postDelayed(tick, minOf(1000L, cloudRetry.remainingMs))
    }

    /** Only inspects installed files/ML Kit metadata. Never downloads a pack. */
    private fun createGeminiLocalFallback() = GeminiLocalFallback(installed = { source, target ->
        val models = mutableSetOf<String>()
        val pack = OfflineMarianCatalog.pack(target)
        if (source == "en" && pack != null && runCatching {
                val directory = java.io.File(applicationContext.filesDir, "models/${pack.directoryName}")
                val model = java.io.File(directory, "model.tflite")
                val complete = java.io.File(directory, ".complete")
                if (!complete.isFile || complete.readText() != pack.revision ||
                    !model.isFile || model.length() != pack.bytes ||
                    !listOf("source.spm", "vocab.json", "config.json").all { java.io.File(directory, it).isFile }) false
                else {
                    val digest = java.security.MessageDigest.getInstance("SHA-256")
                    model.inputStream().buffered().use { input ->
                        val buffer = ByteArray(64 * 1024)
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            digest.update(buffer, 0, count)
                        }
                    }
                    digest.digest().joinToString("") { "%02x".format(it) } == pack.sha256
                }
            }.getOrDefault(false)) models.add("opus")
        if (source != target && source in TranslateLanguage.getAllLanguages() && target in TranslateLanguage.getAllLanguages()) {
            val downloaded = runCatching {
                Tasks.await(RemoteModelManager.getInstance().getDownloadedModels(TranslateRemoteModel::class.java),
                    5, TimeUnit.SECONDS).map { it.language }.toSet()
            }.getOrDefault(emptySet())
            // English is built in; every other side of the pair needs its own installed pack.
            if (listOf(source, target).all { it == "en" || it in downloaded }) models.add("mlkit")
        }
        models
    }, translateInstalled = { engine, source, target, text ->
        if (engine == "opus") {
            if (fallbackMarianTarget != target) {
                fallbackMarian?.close()
                fallbackMarian = null
                fallbackMarianTarget = target
            }
            val model = fallbackMarian ?: MarianOnDeviceTranslator.load(java.io.File(applicationContext.filesDir,
                "models/${OfflineMarianCatalog.pack(target)!!.directoryName}")).also { fallbackMarian = it }
            model.translate(text)
        } else {
            if (fallbackMlkitPair != (source to target)) {
                fallbackMlkit?.close()
                fallbackMlkit = createTranslator(source, target)
                fallbackMlkitPair = source to target
            }
            // Deliberately no downloadModelIfNeeded: an absent pack must not cause a network request.
            Tasks.await(fallbackMlkit!!.translate(text), 15, TimeUnit.SECONDS)
        }
    })

    private fun closeGeminiFallbackModels() {
        runCatching { fallbackMarian?.close() }
        fallbackMarian = null
        fallbackMarianTarget = ""
        runCatching { fallbackMlkit?.close() }
        fallbackMlkit = null
        fallbackMlkitPair = null
    }

    private fun emitGeminiFallbackStatus() {
        val status = when (if (cloudRetry.allowsGeminiFallback) geminiFallbackStatus else "idle") {
            "opus" -> "Gemini bekliyor. Model A ile yerel çeviri kullanılıyor."
            "mlkit" -> "Gemini bekliyor. Model B ile yerel çeviri kullanılıyor."
            "unavailable" -> "Gemini bekliyor. Bu dil çifti için yerel paket yüklü değil. Model A veya B dil paketini indir. Önbellekteki çeviriler kullanılabilir."
            "failed" -> "Gemini bekliyor. Yerel paket açılamadı. Model A veya B dil paketini yeniden indir. Önbellekteki çeviriler kullanılabilir."
            else -> if (cloudRetry.remainingMs == Long.MAX_VALUE) "Gemini günlük kotası doldu. Yerel paketler kontrol ediliyor."
                else "Gemini bekliyor. ${(cloudRetry.remainingMs + 999) / 1000} sn sonra güncel altyazıyla yeniden denenecek."
        }
        emit(mapOf("type" to "subtitleOcrStatus", "status" to status))
    }

    private fun translateWithGeminiFallback(index: Int, state: RegionState, key: String, text: String) {
        if (state.fallbackPendingKey == key || !canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key)) return
        state.fallbackPendingKey = key
        latestMarianKeyByRegion[index] = key
        val revision = deepLRevision.get()
        val source = sourceLanguageCode
        val target = targetLanguageCode
        val local = geminiLocalFallback
        fun deliver(result: GeminiLocalFallback.Result) {
            if (closed || !enabled || translationEngine != "gemini" || revision != deepLRevision.get() ||
                !cloudRetry.allowsGeminiFallback || regionStates.getOrNull(index) !== state) return
            if (latestMarianKeyByRegion[index] != key || state.deepLOcrPolicy.hasPendingRead ||
                state.deepLOcrPolicy.requestKey != key ||
                !cloudRetry.isLatestFresh(state.lastConfirmedLiveAt,
                    regionSettings.getOrNull(index)?.sampleIntervalMillis ?: sampleIntervalMillis) ||
                !canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key)) {
                if (state.fallbackPendingKey == key) state.fallbackPendingKey = null
                return
            }
            geminiFallbackStatus = result.engine
            if (!result.text.isNullOrBlank()) {
                state.visibleSince = SystemClock.elapsedRealtime()
                state.fallbackVisibleKey = key
                emitSubtitleText(index, text, result.text, if (result.fromCache) "live_cache" else "live_translation", result.engine)
            }
            emitGeminiFallbackStatus()
        }
        local.cached(source, target, key)?.let { deliver(it); return }
        geminiFallbackStatus = "checking"
        marianExecutor.execute {
            if (closed || !enabled || revision != deepLRevision.get() || translationEngine != "gemini" ||
                !cloudRetry.allowsGeminiFallback || latestMarianKeyByRegion[index] != key) return@execute
            val result = local.translate(source, target, key, text)
            if (!closed) recognitionExecutor.execute { deliver(result) }
        }
    }

    private fun translate(index: Int, state: RegionState, key: String, sourceText: String) {
        if (!canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key)) return
        if (translationEngine == "compare") {
            val cached = cachedComparison(sourceText, "MLKit")
            if (cached != null) {
                if (enabled && canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key)) {
                    state.visibleSince = SystemClock.elapsedRealtime()
                    emitSubtitleText(index, sourceText, cached, "live_cache", "mlkit")
                }
                return
            }
            if (!reserveComparison(sourceText, "MLKit")) return
        } else if ((state.translatingKey == key) || translationCache.containsKey(key)) return
        state.translatingKey = key
        emit(mapOf("type" to "subtitleOcrStatus", "status" to "Çeviri hazırlanıyor"))
        val selectedTranslator = translator
        val selectedSource = sourceLanguageCode
        val selectedTarget = targetLanguageCode
        val startedAt = SystemClock.elapsedRealtime()
        selectedTranslator.translate(sourceText)
            .addOnSuccessListener(recognitionExecutor) { translated ->
                if (selectedTranslator !== translator) {
                    if (translationEngine == "compare") releaseComparison(sourceText, "MLKit")
                    return@addOnSuccessListener
                }
                if (state.translatingKey == key) state.translatingKey = null
                if (translated.isNotBlank()) {
                    if (translationEngine == "mlkit") translationCache[key] = translated
                    if (diagnosticsEnabled()) {
                        Log.i(
                            OCR_LOG_TAG,
                            "MLKIT_RESULT area=${index + 1} ${selectedSource}->${selectedTarget} " +
                                "latencyMs=${SystemClock.elapsedRealtime() - startedAt} " +
                                "source=${logText(sourceText)} translated=${logText(translated)}",
                        )
                        Log.i(
                            OCR_LOG_TAG,
                            "TRANSLATION_RESULT model=MLKit area=${index + 1} ${selectedSource}->${selectedTarget} " +
                                "latencyMs=${SystemClock.elapsedRealtime() - startedAt} " +
                                "source=${logText(sourceText)} translated=${logText(translated)}",
                        )
                    }
                    if (translationEngine == "compare") recordComparison(sourceText, "MLKit", translated)
                    if (translationEngine in setOf("mlkit", "compare") && enabled &&
                        canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key) &&
                        sourceLanguageCode == selectedSource && targetLanguageCode == selectedTarget) {
                        state.visibleSince = SystemClock.elapsedRealtime()
                        emitSubtitleText(index, sourceText, translated, "live_translation", "mlkit")
                        emit(mapOf("type" to "subtitleOcrStatus", "status" to "Çevrildi"))
                    }
                }
                if (translated.isBlank() && translationEngine == "compare") releaseComparison(sourceText, "MLKit")
            }
            .addOnFailureListener(recognitionExecutor) {
                if (selectedTranslator !== translator) {
                    if (translationEngine == "compare") releaseComparison(sourceText, "MLKit")
                    return@addOnFailureListener
                }
                if (translationEngine == "compare") releaseComparison(sourceText, "MLKit")
                if (state.translatingKey == key) state.translatingKey = null
                if (state.sourceKey == key) {
                    emit(mapOf("type" to "subtitleOcrStatus", "status" to "Çeviri başarısız"))
                }
            }
    }

    private fun translateWithMarian(index: Int, state: RegionState, key: String, sourceText: String) {
        if (closed || !enabled || !canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key)) return
        if (translationEngine == "compare") {
            val cached = cachedComparison(sourceText, "OPUS-MT")
            if (cached != null) {
                if (!cached.startsWith("[OPUS-MT") && enabled && canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key)) {
                    state.visibleSince = SystemClock.elapsedRealtime()
                    emitSubtitleText(index, sourceText, cached, "live_cache", "opus")
                }
                return
            }
            if (!reserveComparison(sourceText, "OPUS-MT")) return
        } else if (state.translatingKey == key && translationEngine == "opus") return
        state.translatingKey = key
        latestMarianKeyByRegion[index] = key
        val queuedAt = SystemClock.elapsedRealtime()
        val revision = deepLRevision.get()
        val engine = translationEngine
        val target = marianTargetLanguageCode
        localTranslationQueue.submit(index, "$revision:$target:$key") marianWork@{
            if (closed || !enabled || revision != deepLRevision.get() || translationEngine != engine ||
                latestMarianKeyByRegion[index] != key) return@marianWork
            try {
                val inferenceStartedAt = SystemClock.elapsedRealtime()
                val queueWaitMs = inferenceStartedAt - queuedAt
                val model = marianTranslator ?: synchronized(this) {
                    marianTranslator ?: MarianOnDeviceTranslator.load(
                        java.io.File(
                            applicationContext.filesDir,
                            "models/${OfflineMarianCatalog.pack(target)?.directoryName
                                ?: OfflineMarianCatalog.pack("tr")!!.directoryName}",
                        ),
                    ).also { marianTranslator = it }
                }
                val translated = model.translate(sourceText)
                val inferenceMs = SystemClock.elapsedRealtime() - inferenceStartedAt
                if (closed) return@marianWork
                recognitionExecutor.execute {
                    if (closed || revision != deepLRevision.get() || translationEngine != engine ||
                        marianTargetLanguageCode != target || regionStates.getOrNull(index) !== state) return@execute
                    // A completed translation is still useful if this line reappears.
                    // It must not be displayed over a genuinely different current line.
                    if (translated.isNotBlank() && engine == "opus") translationCache[key] = translated
                    if (latestMarianKeyByRegion[index] != key || state.sourceKey != key ||
                        (engine == "opus" && state.localOcrPolicy.requestKey != key)) {
                        if (translationEngine == "compare") releaseComparison(sourceText, "OPUS-MT")
                        if (state.translatingKey == key) state.translatingKey = null
                        if (diagnosticsEnabled()) Log.i(OCR_LOG_TAG, "OPUS_STALE_RESULT_DROPPED area=${index + 1}")
                        return@execute
                    }
                    val safeTranslation = translated.takeIf { it.isNotBlank() }
                        ?: "[OPUS-MT decoder output rejected]"
                    if (translated.isBlank()) {
                        Log.w(OCR_LOG_TAG, "OPUS_INVALID_OUTPUT area=${index + 1} reason=repeated-token-loop")
                    }
                    if (diagnosticsEnabled()) {
                        Log.i(OCR_LOG_TAG,
                            "OPUS_RESULT area=${index + 1} en->$marianTargetLanguageCode " +
                                "latencyMs=${SystemClock.elapsedRealtime() - queuedAt} queueWaitMs=$queueWaitMs inferenceMs=$inferenceMs " +
                                "source=${logText(sourceText)} translated=${logText(safeTranslation)}")
                        Log.i(
                            OCR_LOG_TAG,
                            "TRANSLATION_RESULT model=OPUS-MT area=${index + 1} en->$marianTargetLanguageCode " +
                                "latencyMs=${SystemClock.elapsedRealtime() - queuedAt} queueWaitMs=$queueWaitMs inferenceMs=$inferenceMs " +
                                "source=${logText(sourceText)} translated=${logText(safeTranslation)}",
                        )
                    }
                    if (translationEngine == "compare") {
                        if (translated.isNotBlank()) recordComparison(sourceText, "OPUS-MT", safeTranslation)
                        else releaseComparison(sourceText, "OPUS-MT")
                    }
                    if (state.translatingKey == key) state.translatingKey = null
                    if (translated.isNotBlank()) {
                        if (enabled && canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key) &&
                            translationEngine in setOf("opus", "compare")) {
                            state.visibleSince = SystemClock.elapsedRealtime()
                            emitSubtitleText(index, sourceText, translated, "live_translation", "opus")
                            val statusContext = AppUiLanguage.localizedContext(applicationContext)
                            emit(mapOf("type" to "subtitleOcrStatus", "status" to statusContext.getString(
                                R.string.local_translation_status, statusContext.getString(R.string.app_name),
                            )))
                        }
                    }
                }
            } catch (error: Exception) {
                if (closed) return@marianWork
                recognitionExecutor.execute {
                    if (closed || revision != deepLRevision.get() || translationEngine != engine) return@execute
                    if (translationEngine == "compare") releaseComparison(sourceText, "OPUS-MT")
                    if (latestMarianKeyByRegion[index] != key || state.sourceKey != key) return@execute
                    Log.e(OCR_LOG_TAG, "OPUS_TRANSLATION_FAILED ${error.javaClass.simpleName}")
                    if (state.translatingKey == key) state.translatingKey = null
                    emit(mapOf("type" to "subtitleOcrStatus", "status" to "Yerel çeviri paketi açılamadı"))
                }
            }
        }
    }

    private fun hpltModelDirectory() = java.io.File(
        applicationContext.filesDir,
        "models/${HpltModelCatalog.directoryName}",
    )

    /** Load an installed OPUS pack before the first subtitle needs translation. */
    private fun warmMarianModel() {
        if (closed || translationEngine != "opus" || marianTranslator != null) return
        marianExecutor.execute {
            try {
                synchronized(this) {
                    if (closed || translationEngine != "opus" || marianTranslator != null) {
                        return@synchronized
                    }
                    val pack = OfflineMarianCatalog.pack(marianTargetLanguageCode) ?: return@synchronized
                    val modelDirectory = java.io.File(
                        applicationContext.filesDir,
                        "models/${pack.directoryName}",
                    )
                    val marker = java.io.File(modelDirectory, ".complete")
                    if (!marker.isFile || marker.readText() != pack.revision) return@synchronized
                    val loadStartedAt = SystemClock.elapsedRealtime()
                    marianTranslator = MarianOnDeviceTranslator.load(modelDirectory)
                    Log.i(
                        OCR_LOG_TAG,
                        "OPUS_MODEL_READY target=${pack.target} " +
                            "loadMs=${SystemClock.elapsedRealtime() - loadStartedAt}",
                    )
                }
            } catch (error: Exception) {
                Log.e(OCR_LOG_TAG, "OPUS_MODEL_WARMUP_FAILED ${error.javaClass.simpleName}" +
                    if (diagnosticsEnabled()) ": ${error.message}" else "")
                recognitionExecutor.execute {
                    if (translationEngine == "opus" && enabled) {
                        emit(mapOf("type" to "subtitleOcrStatus", "status" to "Yerel çeviri paketi açılamadı"))
                    }
                }
            }
        }
    }

    private fun warmHpltModel() {
        if (closed || translationEngine != "hplt" || hpltTranslator != null) return
        marianExecutor.execute {
            try {
                synchronized(this) {
                    if (closed || translationEngine != "hplt" || hpltTranslator != null) return@synchronized
                    val marker = java.io.File(hpltModelDirectory(), ".complete")
                    if (!marker.isFile || marker.readText() != HpltModelCatalog.revision) return@synchronized
                    hpltTranslator = HpltCTranslate2.load(hpltModelDirectory())
                    Log.i(OCR_LOG_TAG, "HPLT_MODEL_READY model=HPLT-v2-INT8")
                }
            } catch (error: Exception) {
                Log.e(OCR_LOG_TAG, "HPLT_MODEL_LOAD_FAILED ${error.javaClass.simpleName}" +
                    if (diagnosticsEnabled()) ": ${error.message}" else "")
                recognitionExecutor.execute {
                    if (translationEngine == "hplt" && enabled) {
                        emit(mapOf("type" to "subtitleOcrStatus", "status" to "HPLT modeli açılamadı"))
                    }
                }
            }
        }
    }

    private fun translateWithHplt(index: Int, state: RegionState, key: String, sourceText: String) {
        if (!canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key)) return
        if (state.translatingKey == key) return
        state.translatingKey = key
        latestMarianKeyByRegion[index] = key
        val queuedAt = SystemClock.elapsedRealtime()
        emit(mapOf("type" to "subtitleOcrStatus", "status" to "HPLT çevirisi hazırlanıyor"))
        marianExecutor.execute {
            if (latestMarianKeyByRegion[index] != key || translationEngine != "hplt") return@execute
            try {
                val inferenceStartedAt = SystemClock.elapsedRealtime()
                val model = hpltTranslator ?: synchronized(this) {
                    hpltTranslator ?: HpltCTranslate2.load(hpltModelDirectory()).also { hpltTranslator = it }
                }
                val translated = model.translate(sourceText)
                val inferenceMs = SystemClock.elapsedRealtime() - inferenceStartedAt
                recognitionExecutor.execute {
                    if (latestMarianKeyByRegion[index] != key || state.sourceKey != key || translationEngine != "hplt") {
                        if (state.translatingKey == key) state.translatingKey = null
                        Log.i(OCR_LOG_TAG, "HPLT_STALE_RESULT_DROPPED area=${index + 1}")
                        return@execute
                    }
                    if (state.translatingKey == key) state.translatingKey = null
                    if (diagnosticsEnabled()) {
                        Log.i(
                            OCR_LOG_TAG,
                            "TRANSLATION_RESULT model=HPLT-v2-INT8 area=${index + 1} en->tr " +
                                "latencyMs=${SystemClock.elapsedRealtime() - queuedAt} " +
                                "queueWaitMs=${inferenceStartedAt - queuedAt} inferenceMs=$inferenceMs " +
                                "source=${logText(sourceText)} translated=${logText(translated)}",
                        )
                    }
                    if (translated.isNotBlank()) {
                        translationCache[key] = translated
                        if (enabled && canUseLiveSubtitle(state.sourceKey, state.memoryMatchedKey, key)) {
                            state.visibleSince = SystemClock.elapsedRealtime()
                            emitSubtitleText(index, sourceText, translated, "live_translation", "hplt")
                            emit(mapOf("type" to "subtitleOcrStatus", "status" to "Çevrildi · HPLT"))
                        }
                    }
                }
            } catch (error: Exception) {
                recognitionExecutor.execute {
                    if (latestMarianKeyByRegion[index] != key || state.sourceKey != key) return@execute
                    if (state.translatingKey == key) state.translatingKey = null
                    Log.e(OCR_LOG_TAG, "HPLT_TRANSLATION_FAILED ${error.javaClass.simpleName}" +
                        if (diagnosticsEnabled()) ": ${error.message}" else "")
                    emit(mapOf("type" to "subtitleOcrStatus", "status" to "HPLT çevirisi başarısız"))
                }
            }
        }
    }

    private fun recordComparison(source: String, engine: String, translated: String) {
        val pair = synchronized(compareResults) {
            val cacheKey = comparisonSourceKey(source)
            compareInFlight.remove(cacheKey to engine)
            val results = compareResults.getOrPut(cacheKey) { linkedMapOf() }
            results[engine] = translated
            while (compareResults.size > 64) compareResults.remove(compareResults.keys.first())
            results["MLKit"] to results["OPUS-MT"]
        }
        val mlkit = pair.first
        val opus = pair.second
        if (BuildConfig.DEBUG && mlkit != null && opus != null) {
            Log.i(OCR_LOG_TAG, "TRANSLATION_COMPARE source=${logText(source)} MLKit=${logText(mlkit)} OPUS-MT=${logText(opus)}")
        }
    }

    private fun cachedComparison(source: String, engine: String): String? = synchronized(compareResults) {
        compareResults[comparisonSourceKey(source)]?.get(engine)
    }

    private fun reserveComparison(source: String, engine: String): Boolean = synchronized(compareResults) {
        val cacheKey = comparisonSourceKey(source)
        if (compareResults[cacheKey]?.containsKey(engine) == true || !compareInFlight.add(cacheKey to engine)) false else true
    }

    private fun releaseComparison(source: String, engine: String) {
        synchronized(compareResults) { compareInFlight.remove(comparisonSourceKey(source) to engine) }
    }

    // Ignore unstable trailing OCR punctuation (e.g. "minute.." vs
    // "minute...") while keeping lexical differences such as "Il"/"I'll".
    private fun comparisonSourceKey(source: String): String = source
        .lowercase(Locale.ROOT)
        .replace(Regex("\\s+"), " ")
        .trim()
        .replace(Regex("[.!?…,:;]+$"), "")

    private fun canonicalTranslationKey(text: String): String = text
        .lowercase(Locale.ROOT)
        .replace(Regex("[\\p{Punct}\\s]+"), " ")
        .trim()
        .replace(Regex("\\s+"), " ")

    private fun matchingGameMemory(): GameTranslationMemory? = gameTranslationMemory?.takeIf {
        it.sourceLanguage == sourceLanguageCode && it.targetLanguage == targetLanguageCode
    }

    private fun liveTranslationSupported(): Boolean = when (translationEngine) {
        "opus" -> sourceLanguageCode == "en" && targetLanguageCode == marianTargetLanguageCode && targetLanguageCode in OfflineMarianCatalog.targetCodes
        "hplt" -> sourceLanguageCode == "en" && targetLanguageCode == "tr"
        "deepl", "gemini" -> deepLApiKey.isNotBlank()
        else -> sourceLanguageCode in TranslateLanguage.getAllLanguages() && targetLanguageCode in TranslateLanguage.getAllLanguages()
    }

    /**
     * Treat near-identical, long subtitle reads as OCR jitter without waiting
     * for another frame. Short lines remain exact-match only so a real one-word
     * dialogue change is not hidden. Negation changes always trigger translation.
     */
    private fun isOcrNoiseVariant(previous: String, candidate: String): Boolean {
        val left = canonicalTranslationKey(previous)
        val right = canonicalTranslationKey(candidate)
        if (left == right) return true

        val negations = setOf("not", "no", "never", "cannot", "can't", "cant", "don't", "dont", "won't", "wont", "isn't", "isnt", "aren't", "arent")
        fun negationSet(value: String): Set<String> = Regex("(?i)\\b(?:not|no|never|cannot|can’t|can't|cant|don’t|don't|dont|won’t|won't|wont|isn’t|isn't|isnt|aren’t|aren't|arent)\\b")
            .findAll(value)
            .map { it.value.lowercase(Locale.ROOT).replace('’', '\'') }
            .filter { it in negations }
            .toSet()
        val leftNegations = negationSet(previous)
        val rightNegations = negationSet(candidate)
        if (leftNegations != rightNegations) return false

        val leftWords = left.split(' ').filter { it.length > 2 }.toSet()
        val rightWords = right.split(' ').filter { it.length > 2 }.toSet()
        val sharedWords = leftWords.intersect(rightWords).size
        val wordUnion = leftWords.union(rightWords).size.coerceAtLeast(1)

        // Long subtitle lines: retain the existing low-cost sentence similarity
        // check, including its protection against swallowing negation changes.
        if (left.length >= 36 && right.length >= 36) {
            val maxLength = max(left.length, right.length)
            if (kotlin.math.abs(left.length - right.length) > max(8, maxLength / 12)) return false
            val distanceLimit = maxLength / 10
            if (boundedLevenshteinDistance(left, right, distanceLimit) > distanceLimit) return false
            return sharedWords.toFloat() / wordUnion >= 0.70f
        }

        // Short/medium reads such as "... Company" -> "... mpanV" do not meet
        // the old 36-character gate. Suppress one badly read word only when at
        // least two other words anchor both readings to the same subtitle.
        val oldTokens = left.split(' ')
        val newTokens = right.split(' ')
        if (oldTokens.size != newTokens.size || oldTokens.size < 3) return false
        var changedIndex = -1
        for (tokenIndex in oldTokens.indices) {
            if (oldTokens[tokenIndex] == newTokens[tokenIndex]) continue
            if (changedIndex >= 0) return false
            changedIndex = tokenIndex
        }
        if (changedIndex < 0) return true
        val oldWord = oldTokens[changedIndex]
        val newWord = newTokens[changedIndex]
        if (oldWord.length < 4 || newWord.length < 4) return false
        val wordLength = max(oldWord.length, newWord.length)
        val wordDistanceLimit = max(2, (wordLength + 2) / 3)
        if (boundedLevenshteinDistance(oldWord, newWord, wordDistanceLimit) > wordDistanceLimit) return false
        val unchangedContextWords = oldTokens.indices.count {
            it != changedIndex && oldTokens[it] == newTokens[it]
        }
        return unchangedContextWords >= 2
    }

    /** Bounded, allocation-light Levenshtein distance; returns limit+1 on cutoff. */
    private fun boundedLevenshteinDistance(left: String, right: String, limit: Int): Int {
        if (kotlin.math.abs(left.length - right.length) > limit) return limit + 1
        var previous = IntArray(right.length + 1) { it }
        var current = IntArray(right.length + 1)
        for (i in left.indices) {
            current[0] = i + 1
            var rowMinimum = current[0]
            val from = max(1, i + 1 - limit)
            val to = minOf(right.length, i + 1 + limit)
            for (j in 1 until from) current[j] = limit + 1
            for (j in from..to) {
                val substitution = previous[j - 1] + if (left[i] == right[j - 1]) 0 else 1
                current[j] = minOf(previous[j] + 1, current[j - 1] + 1, substitution)
                rowMinimum = minOf(rowMinimum, current[j])
            }
            for (j in to + 1..right.length) current[j] = limit + 1
            if (rowMinimum > limit) return limit + 1
            val swap = previous
            previous = current
            current = swap
        }
        return previous[right.length]
    }

    // Retained for debug builds: OCR quality plus copy/crop/preprocess/OCR timing.
    // The diagnostics guard runs before snapshots or messages are created.
    private fun logOcrResult(
        index: Int,
        rawText: String,
        normalizedText: String,
        confidence: Float,
        width: Int,
        height: Int,
        copyMillis: Long,
        cropMillis: Long,
        preprocessMillis: Long,
        preprocessingMode: Int,
        dialogueFilter: Boolean,
        ocrMillis: Long,
    ) {
        if (!diagnosticsEnabled()) return
        while (lastLoggedOcrByRegion.size <= index) lastLoggedOcrByRegion.add("")
        val snapshot = "$preprocessingMode\u001f$dialogueFilter\u001f$rawText\u001f$normalizedText"
        if (lastLoggedOcrByRegion[index] == snapshot) return
        lastLoggedOcrByRegion[index] = snapshot
        Log.i(
            OCR_LOG_TAG,
            "OCR area=${index + 1} confidence=${"%.2f".format(Locale.ROOT, confidence)} " +
                "crop=${width}x$height copyMs=$copyMillis cropMs=$cropMillis " +
                "preMode=$preprocessingMode(${preprocessingModeName(preprocessingMode)}) " +
                "dialogueFilter=$dialogueFilter " +
                "preprocessMs=$preprocessMillis ocrMs=$ocrMillis " +
                "raw=${logText(rawText)} normalized=${logText(normalizedText)}",
        )
    }

    private fun diagnosticsEnabled() = BuildConfig.DEBUG

    private fun logLookup(index: Int, text: String, memory: GameTranslationMemory?, match: GameTranslationMatch?,
        copyMs: Long, ocrMs: Long, lookupMs: Long, visualReuse: Boolean) {
        if (!diagnosticsEnabled()) return
        val reason = when {
            gameTranslationMemory == null -> "no_game_selected"
            memory == null -> "language_mismatch"
            match != null -> "hit"
            else -> memory.rejectionReason(text)
        }
        val key = "${memory?.gameId}:$reason:$text"
        if (lastLoggedLookupByRegion[index] != key) {
            lastLoggedLookupByRegion[index] = key
            Log.i(OCR_LOG_TAG, "JSON_LOOKUP area=${index + 1} game=${gameTranslationMemory?.gameId ?: "-"} " +
                "entries=${memory?.entryCount ?: 0} result=$reason lookupMs=$lookupMs " +
                "id=${match?.entryId ?: "-"} matchType=${match?.matchType ?: "-"} ocr=${logText(text)}")
        }
        val now = SystemClock.elapsedRealtime()
        val window = performanceWindows.getOrPut(index) { PerformanceWindow(now) }
        lastPerformanceReadAt.put(index, now)?.let { previous ->
            window.intervals++
            window.elapsedMs += now - previous
        }
        window.reads++
        if (match != null) window.hits++
        if (visualReuse) window.reused++
        window.copyMs += copyMs; window.ocrMs += ocrMs; window.lookupMs += lookupMs
        if (now - window.start >= 1000) {
            val count = window.reads.toDouble()
            Log.i(OCR_LOG_TAG, "PIPELINE_PERF area=${index + 1} requestedHz=${1000.0 / sampleIntervalMillis} " +
                "actualHz=${window.intervals * 1000.0 / window.elapsedMs.coerceAtLeast(1L)} reads=${window.reads} jsonHits=${window.hits} visualReuse=${window.reused} " +
                "copyMsAvg=${window.copyMs / count} ocrMsAvg=${window.ocrMs / count} lookupMsAvg=${window.lookupMs / count}")
            performanceWindows[index] = PerformanceWindow(now)
        }
    }

    private fun logText(value: String): String =
        "\"${value.replace("\\", "\\\\").replace("\r", "\\r").replace("\n", "\\n").take(1000)}\""

    private fun emitSubtitleText(
        index: Int,
        sourceText: String,
        translatedText: String,
        origin: String,
        engine: String,
        match: GameTranslationMatch? = null,
    ) {
        val event = subtitleTextEvent(index, translatedText, engine, match)
        val speaker = event["speaker"] as? String
        val displayText = event["text"] as String
        if (diagnosticsEnabled()) {
            val engineName = when (engine) {
                "none" -> "JSON"
                "opus" -> "OPUS-MT"
                "mlkit" -> "MLKit"
                "hplt" -> "HPLT"
                else -> engine
            }
            val score = match?.score?.let { "%.3f".format(Locale.ROOT, it) } ?: "-"
            Log.i(
                OCR_LOG_TAG,
                "SUBTITLE_SOURCE area=${index + 1} source=$origin engine=$engineName " +
                    "game=${match?.gameId ?: "-"} id=${match?.entryId ?: "-"} " +
                    "score=$score matchType=${match?.matchType ?: "-"} " +
                    "speaker=${speaker?.let(::logText) ?: "-"} " +
                    "ocr=${logText(sourceText)} matched=${match?.let { logText(it.source) } ?: "-"} " +
                    "output=${logText(displayText)}",
            )
        }
        emit(event)
    }

    private fun preprocessingModeName(mode: Int): String = when (mode) {
        0 -> "raw"
        1 -> "grayscale_contrast"
        2 -> "adaptive_threshold"
        3 -> "sharpen"
        4 -> "local_contrast"
        5 -> "threshold_light_text"
        6 -> "threshold_dark_text"
        7 -> "threshold_auto_polarity"
        8 -> "yellow_text"
        9 -> "auto_color_channel"
        else -> "unknown"
    }

    private fun normalizeOcrText(value: String): String {
        val cleaned = value
            // ML Kit sometimes recognizes subtitle separator strokes after a
            // speaker label as slash/pipe glyphs: "ISABELLA: / What...".
            .replace(
                Regex("""([\p{L}][\p{L}\p{N}_'’ -]{0,24}:)\s*[/\\|]+\s*"""),
                "$1 ",
            )
            // A standalone slash or vertical stroke is OCR noise, not dialogue.
            .replace(Regex("""(^|\s)[/\\|](?=\s|$)"""), " ")
            .replace(Regex("\\s+"), " ")
            .trim()
            .trim('/', '|', '\\')
            .trim()
        if (sourceLanguageCode != TranslateLanguage.ENGLISH || cleaned.isEmpty()) {
            return cleaned
        }
        // In English dialogue, isolated OCR specks such as "t" and "e" are
        // not useful words. Keep the valid standalone words I and A.
        return cleaned.split(Regex("\\s+"))
            .filter { token ->
                val word = token.trim { !it.isLetterOrDigit() }.lowercase(Locale.ROOT)
                word.length != 1 || word == "i" || word == "a"
            }
            .joinToString(" ")
    }

    private fun clearPendingVariant(state: RegionState) = state.variantGate.clear()

    private fun resetState(state: RegionState) {
        state.deepLOcrPolicy.clear()
        state.localOcrPolicy.clear()
        state.sourceText = null
        state.sourceKey = null
        state.sourceConfidence = 0f
        clearPendingVariant(state)
        state.translatingKey = null
        state.fallbackPendingKey = null
        state.fallbackVisibleKey = null
        state.memoryMatchedKey = null
        state.visibleSince = null
        state.emptySince = null
        state.clearSent = false
    }

    private fun expireVisibleSubtitleIfNeeded(state: RegionState, index: Int, now: Long, resetOcrPolicies: Boolean = true) {
        val shownAt = state.visibleSince ?: return
        if (now - shownAt < (regionSettings.getOrNull(index)?.autoHideMillis ?: 2000L)) return
        latestMarianKeyByRegion.remove(index)
        if (resetOcrPolicies) {
            state.deepLOcrPolicy.clear()
            state.localOcrPolicy.clear()
        }
        state.visibleSince = null
        state.sourceText = null
        state.sourceKey = null
        state.sourceConfidence = 0f
        clearPendingVariant(state)
        state.translatingKey = null
        state.fallbackPendingKey = null
        state.fallbackVisibleKey = null
        state.memoryMatchedKey = null
        state.clearSent = true
        emit(mapOf("type" to "subtitleCleared", "regionIndex" to index))
    }

    companion object {
        private const val OCR_LOG_TAG = "GameTranslateOCR"
        private const val MAX_COPY_WIDTH = 1600
        private const val MIN_CONFIDENT_OCR_THRESHOLD = 0.35f
        private const val MODEL_RETRY_DELAY_MS = 10000L
    }
}
