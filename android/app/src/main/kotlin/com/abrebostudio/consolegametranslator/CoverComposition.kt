package com.abrebostudio.consolegametranslator

/** A subtitle split into its speaker label ("Final Chapter") and what is said. */
internal data class SpokenLine(val speaker: String?, val body: String) {
    /** [translated] with this line's speaker label in front, as the game shows it. */
    fun withSpeaker(translated: String) = if (speaker == null) translated else "$speaker: $translated"
}

internal fun spokenLine(text: String): SpokenLine {
    val match = COVER_SPEAKER.matchEntire(text.trim()) ?: return SpokenLine(null, text.trim())
    return SpokenLine(match.groupValues[1].trim(), match.groupValues[2].trim())
}

/** Several pack lines shown together in one subtitle. */
internal data class ComposedCover(val text: String, val key: String)

/**
 * A subtitle box often holds several pack lines at once ("Final Chapter: You're
 * who Kyle sent? You don't look like a fucking farmer to me."), so the whole
 * box is in no single entry. The sentences are matched from left to right,
 * each time with the longest run of sentences that [lookup] finds; the box is
 * translated only when every sentence is covered. [lookup] gives a
 * translation and a stable key for a piece of text, or null.
 */
internal fun composeFromSentences(text: String, lookup: (String) -> Pair<String, String>?): ComposedCover? {
    val line = spokenLine(text)
    val sentences = line.body.split(SENTENCE_BREAK).map { it.trim() }.filter { it.isNotEmpty() }
    if (sentences.size < 2 || sentences.size > MAX_COMPOSED_SENTENCES) return null
    val targets = ArrayList<String>()
    val keys = ArrayList<String>()
    var start = 0
    while (start < sentences.size) {
        var found: Pair<String, String>? = null
        // A run that is the whole body was already looked up by the caller.
        var end = if (start == 0) sentences.size - 1 else sentences.size
        while (end > start) {
            found = lookup(sentences.subList(start, end).joinToString(" "))
            if (found != null) break
            end--
        }
        if (found == null) return null
        targets += found.first
        keys += found.second
        start = end
    }
    return ComposedCover(line.withSpeaker(targets.joinToString(" ")), keys.joinToString("+"))
}

private const val MAX_COMPOSED_SENTENCES = 8
private val SENTENCE_BREAK = Regex("""(?<=[.!?…])\s+""")
private val COVER_SPEAKER = Regex("""^[-–—]?\s*(\p{Lu}[\p{L}\p{N} .’'-]{0,24}):\s*(\S.*)$""", RegexOption.DOT_MATCHES_ALL)
