package com.abrebostudio.consolegametranslator

internal data class SubtitleOcrRead(
    val text: String,
    val confidence: Float,
    val memoryMatch: GameTranslationMatch? = null,
)

/** A JSON result remains authoritative across engine changes and delayed callbacks. */
internal fun canUseLiveSubtitle(currentKey: String?, memoryMatchKey: String?, requestedKey: String): Boolean =
    currentKey == requestedKey && memoryMatchKey != requestedKey

/** Look up the complete OCR before a dialogue heuristic can discard any lines. */
internal fun selectSubtitleSource(
    rawText: String,
    rawConfidence: Float,
    memory: GameTranslationMemory?,
    candidateTexts: List<String> = emptyList(),
    filteredRead: () -> SubtitleOcrRead,
): SubtitleOcrRead {
    memory?.findExact(rawText)?.let { return SubtitleOcrRead(rawText, rawConfidence, it) }
    // A HUD counter or a separate name block must not hide a clean JSON line.
    for (candidate in candidateTexts.distinct()) {
        if (candidate == rawText) continue
        memory?.findExact(candidate)?.let { return SubtitleOcrRead(candidate, rawConfidence, it) }
    }
    memory?.find(rawText)?.let { match ->
        return SubtitleOcrRead(rawText, rawConfidence, match)
    }
    val filtered = filteredRead()
    val match = if (filtered.text != rawText) memory?.find(filtered.text) else null
    return filtered.copy(memoryMatch = match)
}
