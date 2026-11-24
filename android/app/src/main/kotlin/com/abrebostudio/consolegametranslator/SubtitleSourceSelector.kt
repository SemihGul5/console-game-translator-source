package com.abrebostudio.consolegametranslator

internal data class SubtitleOcrRead(
    val text: String,
    val confidence: Float,
    val memoryMatch: GameTranslationMatch? = null,
)

/** A JSON result remains authoritative across engine changes and delayed callbacks. */
internal fun canUseLiveSubtitle(currentKey: String?, memoryMatchKey: String?, requestedKey: String): Boolean =
    currentKey == requestedKey && memoryMatchKey != requestedKey

/**
 * Look up the complete OCR before a dialogue heuristic can discard any lines.
 * Every cheap way (hash lookups only: the read, each speaker's turn, each OCR
 * block, see [GameTranslationMemory.findQuick]) is tried before the first slow
 * fuzzy search, so one clean read never waits behind a search that will miss.
 */
internal fun selectSubtitleSource(
    rawText: String,
    rawConfidence: Float,
    memory: GameTranslationMemory?,
    candidateTexts: List<String> = emptyList(),
    filteredRead: () -> SubtitleOcrRead,
): SubtitleOcrRead {
    if (memory != null) {
        memory.findExact(rawText)?.let { return SubtitleOcrRead(rawText, rawConfidence, it) }
        // Two speakers on screen together ("Cal: … Jason: …") are two pack lines:
        // both are shown, one under the other, instead of only the longer one.
        val turns = speakerTurns(rawText)
        fun bothSpeakers(lookup: (String) -> GameTranslationMatch?): SubtitleOcrRead? {
            if (turns.size < 2) return null
            val matches = turns.map(lookup)
            return if (matches.all { it != null })
                SubtitleOcrRead(rawText, rawConfidence, combineSpeakerTurns(turns, matches.filterNotNull())) else null
        }
        bothSpeakers(memory::findQuick)?.let { return it }
        // A HUD counter or a separate name block must not hide a clean JSON line.
        for (candidate in candidateTexts.distinct()) {
            if (candidate == rawText || !coversMostOf(candidate, rawText)) continue
            memory.findQuick(candidate)?.let { return SubtitleOcrRead(candidate, rawConfidence, it) }
        }
        // Only then the whole read sentence by sentence: an objective line below
        // a subtitle ("Inspect the chemicals") is its own block, not part of it.
        memory.findQuick(rawText)?.let { return SubtitleOcrRead(rawText, rawConfidence, it) }
        bothSpeakers(memory::find)?.let { return it }
        memory.find(rawText)?.let { match -> return SubtitleOcrRead(rawText, rawConfidence, match) }
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

/**
 * Splits a read where a new speaker label follows a finished sentence
 * ("… into my head. Jason: I keep telling him.") into one text per speaker.
 * A read without such a label is one turn.
 */
internal fun speakerTurns(text: String): List<String> {
    val starts = SPEAKER_TURN.findAll(text).map { it.range.first }.filter { it > 0 }.toList()
    if (starts.isEmpty()) return listOf(text.trim())
    return (listOf(0) + starts + text.length).zipWithNext { start, end -> text.substring(start, end).trim() }
        .filter(String::isNotEmpty)
}

/** One subtitle event for several speakers: each line keeps its own speaker label. */
internal fun combineSpeakerTurns(turns: List<String>, matches: List<GameTranslationMatch>): GameTranslationMatch {
    val lines = turns.zip(matches) { turn, match ->
        val label = match.speaker?.trim()?.takeIf(String::isNotEmpty)
            ?: TURN_LABEL.find(turn)?.groupValues?.get(1)?.trim()
        if (label == null || match.target.trimStart().startsWith("$label:", ignoreCase = true)) match.target
        else "$label: ${match.target}"
    }
    return matches.first().copy(
        entryId = matches.joinToString("+") { it.entryId },
        speaker = null,
        source = turns.joinToString(" "),
        target = lines.joinToString("\n"),
        score = matches.minOf { it.score },
        matchType = matches.firstOrNull { it.matchType != "exact" }?.matchType ?: "exact",
        segmentIndex = null,
        segmentCount = null,
    )
}

private val SPEAKER_TURN = Regex("""(?<=[.!?…]["'’”)]?)\s+(?=\p{Lu}[\p{L}\p{N}'’.-]{0,20}(?: \p{Lu}[\p{L}\p{N}'’.-]{0,20})?:\s)""")
private val TURN_LABEL = Regex("""^\s*(\p{Lu}[\p{L}\p{N}'’. -]{0,24}):\s""")

/**
 * [reread] is [previous] spoiled by OCR, not a new line: its words (two letters
 * or more) are nearly all in [previous] and cover most of it, with the same
 * negations ("No, no, -| want you here." for "No, no, I- I want you here.").
 */
internal fun isNoisyRereadOf(previous: String, reread: String): Boolean {
    val old = selectorWords(previous)
    val new = selectorWords(reread)
    if (new.size < MIN_REREAD_WORDS || old.isEmpty()) return false
    if (new.filter { it in NEGATIONS }.toSet() != old.filter { it in NEGATIONS }.toSet()) return false
    val oldSet = old.toSet()
    val newSet = new.toSet()
    return new.count { it in oldSet } >= new.size * REREAD_INSIDE && old.count { it in newSet } >= old.size * REREAD_COVERS
}

private const val MIN_REREAD_WORDS = 3
private const val REREAD_INSIDE = 0.8
private const val REREAD_COVERS = 0.7
private val NEGATIONS = setOf("not", "no", "never", "cannot", "can't", "cant", "don't", "dont", "won't", "wont", "isn't", "isnt", "aren't", "arent", "didn't", "didnt")
