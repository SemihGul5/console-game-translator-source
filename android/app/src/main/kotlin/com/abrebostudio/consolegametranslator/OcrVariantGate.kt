package com.abrebostudio.consolegametranslator

/** Only near-identical live OCR variants wait for a second read; JSON bypasses it. */
internal class OcrVariantGate(private val minimumReads: Int = 2) {
    data class Read(val key: String, val text: String, val confidence: Float)
    private var pending: Read? = null
    var consecutiveReads: Int = 0
        private set

    fun observe(key: String, text: String, confidence: Float): Read? {
        val previous = pending
        if (previous?.key != key) {
            pending = Read(key, text, confidence)
            consecutiveReads = 1
        } else {
            consecutiveReads++
            if (confidence > previous.confidence) pending = Read(key, text, confidence)
        }
        // A persistent new line must not remain blocked by an older, higher score.
        return pending.takeIf { consecutiveReads >= minimumReads }
    }

    fun clear() { pending = null; consecutiveReads = 0 }
}
