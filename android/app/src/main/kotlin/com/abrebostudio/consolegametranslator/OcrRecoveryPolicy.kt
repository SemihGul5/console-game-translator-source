package com.abrebostudio.consolegametranslator

/** Bounded on-device retries, never a bypass for game dictionaries or dialogue filtering. */
internal class OcrRecoveryPolicy(private val now: () -> Long) {
    data class Read(val rawText: String, val rawConfidence: Float, val text: String, val confidence: Float)
    private var lastAttempt: Long? = null
    private var cursor = 0

    @Synchronized fun reset() { lastAttempt = null; cursor = 0 }

    /** Retain an extra raw bitmap for at most one region per copied frame. */
    @Synchronized fun region(indices: List<Int>, gameSelected: Boolean, gameLookupReady: Boolean = false): Int? {
        if ((gameSelected && !gameLookupReady) || indices.isEmpty() || !ready()) return null
        val index = indices[cursor % indices.size]
        cursor = (cursor + 1) % 12
        return index
    }

    @Synchronized fun begin(read: Read, gameSelected: Boolean, visualReuse: Boolean, debugOnly: Boolean,
        gameLookupMiss: Boolean = false): Boolean {
        if ((gameSelected && !gameLookupMiss) || visualReuse || debugOnly || !ready()) return false
        val letters = read.rawText.count(Char::isLetter)
        val digits = read.rawText.count(Char::isDigit)
        if (letters < 2 || digits > letters || isControllerOcrHint(read.rawText) ||
            isConsoleSystemOcr(read.rawText) || isStandaloneOcrTimer(read.rawText)) return false
        // High-confidence text deliberately rejected by the dialogue filter is menu/HUD,
        // not an invitation to recover and translate it by a different route.
        if (read.text.isBlank() && read.rawConfidence >= .70f) return false
        if (read.text.isNotBlank() && read.confidence >= .75f && defects(read.text) == 0) return false
        lastAttempt = now()
        return true
    }

    fun modes(primary: Int): List<Int> = listOf(0, 1, 4).filter { it != primary }.take(2)
    fun withinBudget(startedAt: Long): Boolean = now() - startedAt in 0..180L

    /** Keep the original unless another read is substantially better and still a full sentence. */
    fun best(reads: List<Read>, source: String): Int {
        val original = reads.first()
        var best = 0
        var bestScore = score(original)
        for (index in 1 until reads.size) {
            val candidate = reads[index]
            if (candidate.text.isBlank() || candidate.confidence < .55f) continue
            val originalLetters = original.text.count(Char::isLetter)
            val letters = candidate.text.count(Char::isLetter)
            if (originalLetters >= 12 && (letters < originalLetters * .65f || letters > originalLetters * 1.6f)) continue
            val originalKey = deepLTextKey(original.text, source)
            val candidateKey = deepLTextKey(candidate.text, source)
            if (original.confidence >= .55f && facts(originalKey, source) != facts(candidateKey, source)) {
                // Numbers, direction and negation changes need two agreeing alternative filters.
                if (reads.drop(1).count { it.confidence >= .55f && deepLTextKey(it.text, source) == candidateKey } < 2) continue
            }
            val betterConfidence = candidate.confidence - original.confidence >= .08f
            val fewerDefects = defects(candidate.text) < defects(original.text) && candidate.confidence >= original.confidence - .03f
            if (!betterConfidence && !fewerDefects && original.text.isNotBlank()) continue
            val score = score(candidate)
            if (score > bestScore + .035f) { best = index; bestScore = score }
        }
        return best
    }

    private fun ready(): Boolean = lastAttempt?.let { now() - it >= 750L } ?: true
    private fun defects(text: String): Int = text.split(WORDS).count { token ->
        ('\uFFFD' in token || '|' in token ||
            (MIXED_DIGITS.containsMatchIn(token) && !token.matches(UPPERCASE_CODE)))
    }
    private fun score(read: Read): Float = if (read.text.isBlank()) -1f else read.confidence - defects(read.text) * .09f
    private fun facts(key: String, source: String): Set<String> {
        val values = NUMBERS.findAll(key).map { it.value }.toMutableSet()
        if (source.substringBefore('-') == "en") ENGLISH_FACTS
            .findAll(key).forEach { values.add(it.value) }
        return values
    }

    private companion object {
        val WORDS = Regex("\\s+")
        val MIXED_DIGITS = Regex("\\p{L}\\d+\\p{L}")
        val UPPERCASE_CODE = Regex("[A-Z0-9-]+")
        val NUMBERS = Regex("\\b\\d+(?:[.,]\\d+)*\\b")
        val ENGLISH_FACTS = Regex("\\b(?:not|no|never|cannot|can't|don't|doesn't|didn't|won't|isn't|aren't|left|right|north|south|east|west)\\b")
    }
}
