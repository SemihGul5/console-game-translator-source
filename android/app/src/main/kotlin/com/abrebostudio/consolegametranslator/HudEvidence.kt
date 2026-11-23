package com.abrebostudio.consolegametranslator

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/*
 * A HUD area (a phone, a notification corner) also sees the game world behind
 * it: shop signs, billboards, posters. Its short UI lines are real content, so
 * the subtitle strip's short-label rules do not apply there. Instead, text the
 * game pack does not know is translated only with some evidence that it is the
 * game's interface: it reads as words ([isGarbledRead]), it is not a stack of
 * sign lines ([isSignLine]), and it has stayed in place ([HudSettleTracker]).
 * Whether it sits on the flat panel of a HUD box ([measurePanel]) is only
 * measured and logged for now, to tune its limits on real play.
 */

/**
 * A read that is mostly not words: a word counts as broken when letters and
 * digits interleave ("1SA" style codes aside: "PS5", "R2", "2nd", "$500" are
 * fine), when a lower-case letter is followed by a capital ("wIaT"), when it
 * has three or more letters and no vowel (interjections and short acronyms
 * aside), or, given the pack's word list ([knowsWord]), when a word of three or
 * more letters is in no pack line ("SIUWLLAVING", "PRCSLEUTEO"). The read is
 * garbled when broken words hold at least half of its letters.
 */
internal fun isGarbledRead(text: String, knowsWord: ((String) -> Boolean)? = null): Boolean {
    var letters = 0
    var broken = 0
    for (raw in text.split(' ', '\n')) {
        val word = raw.trim(*EDGE_MARKS)
        val count = word.count(Char::isLetter)
        if (count < 2) continue
        letters += count
        if (isBrokenWord(word, knowsWord)) broken += count
    }
    return letters > 0 && broken * 2 >= letters
}

private fun isBrokenWord(word: String, knowsWord: ((String) -> Boolean)?): Boolean {
    val hasDigit = word.any(Char::isDigit)
    if (hasDigit && word.any(Char::isLetter) && !USUAL_CODE.matches(word)) return true
    if (ODD_CASE.containsMatchIn(word) && !MC_NAME.matches(word)) return true
    val letters = word.filter(Char::isLetter)
    val lower = letters.lowercase()
    if (letters.length >= 3 && lower.none { it in VOWELS } && lower !in INTERJECTIONS &&
        !(letters.all(Char::isUpperCase) && letters.length <= 4)) return true
    if (knowsWord != null && !hasDigit && letters.length >= 3 && lower !in INTERJECTIONS &&
        letters.length == word.count { it.isLetter() || it == '\'' || it == '’' || it == '-' }) {
        val plain = lower.filter { it.isLetter() }
        if (!knowsWord(plain)) return true
    }
    return false
}

/**
 * A line of a sign or billboard: no lower-case letter, at least one capital,
 * at most [SIGN_WORDS] words and [SIGN_LENGTH] characters, and no sentence or
 * label punctuation ("FARM EQUIPMENT", "HAULAGE REPAIRS"). Text without letter
 * case (Japanese) never is.
 */
internal fun isSignLine(text: String): Boolean {
    val value = text.trim()
    if (value.isEmpty() || value.length > SIGN_LENGTH) return false
    if (value.any(Char::isLowerCase) || value.none(Char::isUpperCase)) return false
    if (value.any { it in ".?!:…" }) return false
    return value.split(' ').count { it.any(Char::isLetterOrDigit) } in 1..SIGN_WORDS
}

/**
 * Reads as a sentence, not a sign: at least [SENTENCE_WORDS] words and mostly
 * lower-case letters ("Hey, I'm back. Sahara put up a good fight…").
 */
internal fun isSentenceLike(text: String): Boolean {
    val words = text.split(' ', '\n').count { word -> word.count(Char::isLetter) >= 2 }
    val letters = text.count(Char::isLetter)
    return words >= SENTENCE_WORDS && letters > 0 && text.count(Char::isLowerCase) * 2 >= letters
}

/**
 * Remembers where HUD text was seen. A block is settled once text with mostly
 * the same words has stayed within about half a line of the same place for
 * [settleMillis]; a box that slides in, a passing sign or a one-frame glimpse
 * is not. Call [settled] for every block of a read, then [endFrame].
 */
internal class HudSettleTracker(
    private val settleMillis: Long = DEFAULT_SETTLE_MILLIS,
    private val forgetMillis: Long = DEFAULT_FORGET_MILLIS,
) {
    private class Seen(var words: Set<String>, var centerX: Float, var centerY: Float, var height: Float,
        val since: Long, var last: Long)

    private val seen = ArrayList<Seen>()

    /** [lines]: the block's lines, relative to the area (0..1). */
    fun settled(text: String, lines: List<SceneTextLine>, now: Long): Boolean {
        if (lines.isEmpty()) return false
        val words = settleWords(text)
        val left = lines.minOf { it.left }
        val right = lines.maxOf { it.right }
        val top = lines.minOf { it.top }
        val bottom = lines.maxOf { it.bottom }
        val height = lines.map { it.bottom - it.top }.sorted()[lines.size / 2].coerceAtLeast(0.001f)
        val centerX = (left + right) / 2f
        val centerY = (top + bottom) / 2f
        val match = seen.firstOrNull { item ->
            now - item.last <= forgetMillis && sameWords(item.words, words) &&
                abs(item.centerY - centerY) <= max(item.height, height) * PLACE_LINES &&
                abs(item.centerX - centerX) <= max(item.height, height) * PLACE_LINES * 2
        }
        if (match == null) {
            seen += Seen(words, centerX, centerY, height, now, now)
            return false
        }
        match.words = words
        match.centerX = centerX
        match.centerY = centerY
        match.height = height
        match.last = now
        return now - match.since >= settleMillis
    }

    fun endFrame(now: Long) {
        seen.removeAll { now - it.last > forgetMillis }
        while (seen.size > MAX_SEEN) seen.removeAt(0)
    }

    private fun sameWords(a: Set<String>, b: Set<String>): Boolean {
        if (a.isEmpty() || b.isEmpty()) return a.isEmpty() && b.isEmpty()
        val shared = a.count { it in b }
        return shared * 10 >= max(a.size, b.size) * 6
    }

    private fun settleWords(text: String): Set<String> =
        SETTLE_WORD.findAll(text.lowercase()).map { it.value }.filter { it.length >= 2 }.toHashSet()

    companion object {
        const val DEFAULT_SETTLE_MILLIS = 200L
        const val DEFAULT_FORGET_MILLIS = 700L
        private const val PLACE_LINES = 0.5f
        private const val MAX_SEEN = 32
    }
}

/**
 * What the pixels around a HUD block look like (measured only, not yet used to
 * reject): [ground] is the median brightness of a thin strip just outside its
 * line boxes, [spread] the spread (upper minus lower quartile) of that strip,
 * [ink] how much brighter (positive) or darker (negative) the text is than the
 * ground. A HUD box is a flat, dark or semi-transparent panel with light text;
 * the game world behind a sign is textured, a billboard often dark on light.
 */
internal data class PanelStats(val ground: Int, val spread: Int, val ink: Int) {
    /**
     * The verdict the rule would give with today's limits (logged, not applied).
     * Either polarity: a GTA phone app is a white panel with dark text.
     */
    val flatPanel: Boolean get() = spread <= PANEL_SPREAD && abs(ink) >= PANEL_INK
}

/**
 * [boxes]: the block's line boxes in pixels (left, top, right, bottom) of an
 * image [width] x [height]; [luma] gives a pixel's brightness, 0-255. Null when
 * too few points could be sampled.
 */
internal fun measurePanel(width: Int, height: Int, boxes: List<IntArray>, luma: (Int, Int) -> Int): PanelStats? {
    if (boxes.isEmpty() || width <= 0 || height <= 0) return null
    val ground = ArrayList<Int>()
    val inside = ArrayList<Int>()
    fun sample(x: Int, y: Int, into: MutableList<Int>) {
        if (x in 0 until width && y in 0 until height && boxes.none { x in it[0]..it[2] && y in it[1]..it[3] }) into += luma(x, y)
    }
    for (box in boxes) {
        val boxHeight = (box[3] - box[1]).coerceAtLeast(1)
        val gap = max(2, boxHeight / 4)
        for (step in 0..PANEL_SAMPLES) {
            val x = box[0] + (box[2] - box[0]) * step / PANEL_SAMPLES
            sample(x, box[1] - gap, ground)
            sample(x, box[3] + gap, ground)
        }
        for (step in 0..PANEL_SAMPLES / 4) {
            val y = box[1] + boxHeight * step / (PANEL_SAMPLES / 4)
            sample(box[0] - gap, y, ground)
            sample(box[2] + gap, y, ground)
        }
        for (row in 1 until 6) for (step in 1 until PANEL_SAMPLES) {
            val x = box[0] + (box[2] - box[0]) * step / PANEL_SAMPLES
            val y = box[1] + boxHeight * row / 6
            if (x in 0 until width && y in 0 until height) inside += luma(x, y)
        }
    }
    if (ground.size < MIN_PANEL_POINTS || inside.size < MIN_PANEL_POINTS) return null
    ground.sort()
    inside.sort()
    val median = ground[ground.size / 2]
    val spread = ground[ground.size * 3 / 4] - ground[ground.size / 4]
    // The text is the part of the box least like the ground: its brightest or darkest tenth.
    val bright = inside[min(inside.size - 1, inside.size * 9 / 10)] - median
    val dark = inside[inside.size / 10] - median
    return PanelStats(median, spread, if (bright >= -dark) bright else dark)
}

private const val SIGN_WORDS = 4
private const val SIGN_LENGTH = 36
private const val PANEL_SAMPLES = 24
private const val MIN_PANEL_POINTS = 12
/**
 * From two measured plays (23 Nov). Interface: clocks ink 145-228, phone white
 * panel ink about -120, the semi-transparent tip box spread 37-49 and ink
 * 152-175, the PS5 overlay ink 154-198. Signs: FARMFIX ink -51 (spread 19), its
 * other lines ink -42..29 (spread 36-47), "The Keys" ink 23-30 (spread 30-36),
 * "NOW LEAVING" spread up to 90. The ink (text against ground) separates them;
 * the spread only removes a very busy background.
 */
private const val PANEL_SPREAD = 60
private const val PANEL_INK = 90
private const val SENTENCE_WORDS = 4
private val EDGE_MARKS = ".,!?;:\"'()[]{}<>|…“”‘’-".toCharArray()
private const val VOWELS = "aeiouy"
private val INTERJECTIONS = setOf("hmm", "shh", "brr", "grr", "psst", "pfft", "mmm", "zzz", "tsk", "hm", "mm", "sh", "pst", "nth")
private val USUAL_CODE = Regex("""^(\$?\d[\d,.]*[a-zA-Z]{0,3}|[a-zA-Z]{1,3}\d{1,4}|\d{1,4}(st|nd|rd|th|s|k|m|x|p|fps|km|kg)|x\d{1,3})$""")
private val ODD_CASE = Regex("""\p{Ll}\p{Lu}""")
private val MC_NAME = Regex("""^(Mc|Mac|O')\p{Lu}\p{Ll}+$""")
private val SETTLE_WORD = Regex("""[\p{L}\p{N}]+""")
