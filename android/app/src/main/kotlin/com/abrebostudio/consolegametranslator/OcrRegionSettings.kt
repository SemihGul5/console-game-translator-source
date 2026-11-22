package com.abrebostudio.consolegametranslator

import kotlin.math.roundToLong

/** Independent scan and expiry settings for one normalized OCR region. */
internal data class OcrRegionSettings(
    val sampleRateHz: Double = 10.0,
    val preprocessingMode: Int = 0,
    val dialogueFilter: Boolean = false,
    val captureScale: Float = 1f,
    val holdMillis: Long = 2500L,
    val autoHideMillis: Long = 2000L,
    /** Draw the translation over the English text this area read (each area's own switch). On by default. */
    val coverEnglish: Boolean = true,
) {
    val sampleIntervalMillis: Long get() = (1000.0 / sampleRateHz).roundToLong().coerceIn(50L, 4000L)

    companion object {
        fun fromMap(value: Map<*, *>?, fallback: OcrRegionSettings = OcrRegionSettings()): OcrRegionSettings {
            fun number(key: String, default: Double): Double =
                (value?.get(key) as? Number)?.toDouble()?.takeIf { it.isFinite() } ?: default
            val scale = number("ocrCaptureScale", fallback.captureScale.toDouble())
            return OcrRegionSettings(
                sampleRateHz = number("sampleRateHz", fallback.sampleRateHz).coerceIn(0.25, 20.0),
                preprocessingMode = number("ocrPreprocessingMode", fallback.preprocessingMode.toDouble()).toInt().coerceIn(0, 9),
                dialogueFilter = value?.get("ocrDialogueFilter") as? Boolean ?: fallback.dialogueFilter,
                captureScale = when { scale < 1.25 -> 1f; scale < 1.75 -> 1.5f; else -> 2f },
                holdMillis = (number("holdSeconds", fallback.holdMillis / 1000.0).coerceIn(0.0, 10.0) * 1000).toLong(),
                autoHideMillis = (number("autoHideAfterSeconds", fallback.autoHideMillis / 1000.0).coerceIn(0.5, 30.0) * 1000).toLong(),
                coverEnglish = value?.get("ocrCoverEnglish") as? Boolean ?: fallback.coverEnglish,
            )
        }
    }
}

/** Called only on the capture handler, so slower regions skip the faster regions' ticks. */
internal class OcrRegionSchedule {
    private val lastSamples = mutableMapOf<Int, Long>()

    fun dueIndices(now: Long, settings: List<OcrRegionSettings>): List<Int> = settings.indices.filter { index ->
        val last = lastSamples[index]
        last == null || now - last >= settings[index].sampleIntervalMillis
    }

    fun sampled(indices: List<Int>, now: Long) {
        indices.forEach { lastSamples[it] = now }
    }

    fun nextDelay(now: Long, settings: List<OcrRegionSettings>): Long = settings.indices.minOfOrNull { index ->
        val last = lastSamples[index]
        if (last == null) 0L else (last + settings[index].sampleIntervalMillis - now).coerceAtLeast(0L)
    } ?: 100L
}
