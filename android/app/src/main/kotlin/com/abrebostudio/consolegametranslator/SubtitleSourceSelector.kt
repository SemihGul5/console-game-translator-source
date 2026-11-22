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
        if (candidate == rawText || !coversMostOf(candidate, rawText)) continue
        memory?.findExact(candidate)?.let { return SubtitleOcrRead(candidate, rawConfidence, it) }
    }
    memory?.find(rawText)?.let { match ->
        return SubtitleOcrRead(rawText, rawConfidence, match)
    }
    val filtered = filteredRead()
    val match = if (filtered.text != rawText) memory?.find(filtered.text) else null
    return filtered.copy(memoryMatch = match)
}

/**
 * A block may stand for the whole read only when what it leaves out is small: a
 * counter, a name, a button or a scrap ("00:14", "Lucia"), at most two words or
 * no more words than the block itself. The last line of a tip ("criminal
 * profile.") must not replace the whole tip ("Tip: Indiscriminate violence will
 * contribute toward a violent criminal profile.") just because the pack knows
 * those two words as a menu title.
 */
internal fun coversMostOf(candidate: String, rawText: String): Boolean {
    val kept = selectorWords(candidate)
    val rest = selectorWords(rawText).toMutableList()
    kept.forEach { word -> rest.remove(word) }
    return rest.size <= maxOf(MAX_LEFT_OUT_WORDS, kept.size)
}

private fun selectorWords(text: String): List<String> =
    SELECTOR_WORD.findAll(text.lowercase()).map { it.value }.filter { word -> word.count(Char::isLetter) >= 2 }.toList()

private const val MAX_LEFT_OUT_WORDS = 2
private val SELECTOR_WORD = Regex("""[\p{L}\p{N}]+(?:['’][\p{L}]+)*""")
