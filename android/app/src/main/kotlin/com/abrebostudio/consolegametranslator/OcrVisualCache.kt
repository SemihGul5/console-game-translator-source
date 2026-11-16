package com.abrebostudio.consolegametranslator

/** Reuse OCR only for an identical pixel fingerprint, never a similar subtitle. */
internal class OcrVisualCache<T>(private val maxAgeMillis: Long = 150L) {
    private var fingerprint: Long? = null
    private var readAt = 0L
    private var result: T? = null

    @Synchronized fun reuse(key: Long, now: Long): T? =
        result.takeIf { fingerprint == key && now >= readAt && now - readAt < maxAgeMillis }

    @Synchronized fun remember(key: Long, now: Long, value: T) {
        fingerprint = key; readAt = now; result = value
    }

    @Synchronized fun clear() { fingerprint = null; result = null }
}

internal fun ocrPixelFingerprint(width: Int, height: Int, pixels: IntArray): Long {
    require(width > 0 && height > 0 && pixels.size >= width * height)
    var hash = -3750763034362895579L xor (width.toLong() shl 32) xor height.toLong()
    for (index in 0 until width * height) hash = (hash xor pixels[index].toLong()) * 1099511628211L
    return hash
}
