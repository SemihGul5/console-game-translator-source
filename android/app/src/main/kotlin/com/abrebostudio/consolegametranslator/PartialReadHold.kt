package com.abrebostudio.consolegametranslator

/**
 * A HUD prompt area ("DIVE [R1]  SURFACE [O]") is read whole in one frame and
 * only in part in the next ("SURFACE"). Each part can hit its own pack line, so
 * the shown translation flipped several times a second. While the shown text
 * is on screen, a read that only drops words from it keeps the shown
 * translation; it replaces it only after it has lasted [holdMillis] without the
 * whole text being read again (the prompt really changed). Used for areas that
 * are not subtitle-shaped; subtitles change line by line.
 */
internal class PartialReadHold(private val holdMillis: Long = PARTIAL_READ_HOLD_MS) {
    private var shown: List<String>? = null
    private var partialSince: Long? = null

    /** The source text now on screen for this area, or null after it was cleared. */
    @Synchronized fun shown(source: String?) {
        shown = source?.let { sceneTokens(it) }?.takeIf { it.isNotEmpty() }
        partialSince = null
    }

    /** True when [read] should not replace the shown text yet. */
    @Synchronized fun holds(read: String, now: Long): Boolean {
        val current = shown ?: return false
        if (!isPartialRead(sceneTokens(read), current)) {
            partialSince = null
            return false
        }
        val since = partialSince ?: now.also { partialSince = it }
        return now - since < holdMillis
    }
}

/** Every word of [read] is in [shown], and [read] has fewer words. */
internal fun isPartialRead(read: List<String>, shown: List<String>): Boolean {
    if (read.isEmpty() || read.size >= shown.size) return false
    val left = shown.toMutableList()
    return read.all { word ->
        val at = left.indexOfFirst { similarSceneToken(word, it) }
        if (at < 0) false else { left.removeAt(at); true }
    }
}

private const val PARTIAL_READ_HOLD_MS = 1500L
