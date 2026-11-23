package com.abrebostudio.consolegametranslator

import kotlin.math.abs
import kotlin.math.max

/** A recognized word's box, relative to the OCR crop (0..1 on each axis). */
internal data class SceneTextWord(val left: Float, val top: Float, val right: Float, val bottom: Float) {
    val centerY get() = (top + bottom) / 2f
    val height get() = bottom - top
}

/**
 * One OCR line as the scene-text check sees it. Coordinates are relative to the
 * crop; [angle] is the recognizer's line angle in degrees; [confidence] is the
 * mean word confidence, or a negative value when the recognizer gave none.
 */
internal data class SceneTextLine(
    val text: String,
    val left: Float,
    val top: Float,
    val right: Float,
    val bottom: Float,
    val angle: Float,
    val confidence: Float,
    val words: List<SceneTextWord>,
)

/**
 * Where a block sits in the whole video frame (0..1, from the top-left), and the
 * height of one of its lines on the same scale.
 */
internal data class ScenePlacement(val centerX: Float, val centerY: Float, val lineHeight: Float)

/** Maps a block's crop-relative lines into the frame; [region] is the crop's [left, top, width, height]. */
internal fun scenePlacement(lines: List<SceneTextLine>, region: FloatArray): ScenePlacement? {
    if (lines.isEmpty() || region.size < 4 || region[2] <= 0f || region[3] <= 0f) return null
    val top = lines.minOf { it.top }
    val bottom = lines.maxOf { it.bottom }
    val left = lines.minOf { it.left }
    val right = lines.maxOf { it.right }
    val lineHeight = lines.map { it.bottom - it.top }.sorted()[lines.size / 2]
    return ScenePlacement(
        centerX = region[0] + (left + right) / 2f * region[2],
        centerY = region[1] + (top + bottom) / 2f * region[3],
        lineHeight = lineHeight * region[3],
    )
}

/**
 * A subtitle-shaped OCR area: horizontally centred in the frame and wide. A
 * phone screen at the side or a mission box in a corner is not; its short UI
 * lines ("Lucia", "Messages") and small, less certain text are real content.
 * [region] is the area's [left, top, width, height] in the frame.
 */
internal fun isSubtitleShapedRegion(region: FloatArray): Boolean =
    region.size >= 4 && region[2] >= MIN_SUBTITLE_REGION_WIDTH &&
        abs(region[0] + region[2] / 2f - 0.5f) <= MAX_SUBTITLE_REGION_OFFSET

/**
 * Text that belongs to the game world (licence plates, shop signs, shirts,
 * posters) is not a subtitle even when it passes through the subtitle area.
 * Returns why an OCR block is such scene text, or null when it may be a subtitle.
 *
 * Shape rules (tilt, plate code) apply in every OCR area. The low-confidence and
 * short-label rules apply only in a subtitle-shaped area ([subtitleRegion]); a
 * phone or mission area keeps its short UI lines. The short-label rule uses the
 * block's place in the whole frame ([placement]), never in the user's crop,
 * whose middle is usually exactly where subtitles are; heights where this
 * session already read certain subtitles ([band]) are exempt.
 * A block that starts with a speaker label is always kept.
 */
internal fun sceneTextReason(
    lines: List<SceneTextLine>,
    placement: ScenePlacement? = null,
    band: SubtitleBand? = null,
    subtitleRegion: Boolean = true,
): String? {
    val text = lines.joinToString(" ") { it.text.trim() }.trim()
    if (text.isEmpty() || SCENE_SPEAKER_LABEL.containsMatchIn(text)) return null
    if (lines.any(::isTiltedLine)) return "tilted"
    if (isPlateLike(lines)) return "plate"
    if (!subtitleRegion) return null
    if (isLowConfidenceFragment(lines, text)) return "low_confidence"
    if (placement != null && isShortSceneLabel(lines, text, placement, band)) return "short_scene_label"
    return null
}

/**
 * A sign, shirt or poster seen straight on: one short line (at most three words)
 * without sentence punctuation, away from the frame's top and bottom subtitle
 * strips and not at a height where this session read a certain subtitle.
 * Apostrophes do not count as punctuation ("Frank's Autocare").
 */
internal fun isShortSceneLabel(
    lines: List<SceneTextLine>,
    text: String,
    placement: ScenePlacement,
    band: SubtitleBand?,
): Boolean {
    if (lines.size != 1) return false
    if (SCENE_WORD.findAll(text).count() !in 1..MAX_LABEL_WORDS) return false
    if (SCENE_SENTENCE_PUNCTUATION.containsMatchIn(text) || ':' in text) return false
    if (placement.centerY <= SUBTITLE_EDGE_BAND || placement.centerY >= 1f - SUBTITLE_EDGE_BAND) return false
    return band?.contains(placement) != true
}

/**
 * A certain subtitle, whose height is remembered: a speaker-labelled block, or a
 * horizontally centred block of at least four words with dialogue punctuation.
 */
internal fun isCertainSubtitle(lines: List<SceneTextLine>, placement: ScenePlacement): Boolean {
    val text = lines.joinToString(" ") { it.text.trim() }.trim()
    if (SCENE_SPEAKER_LABEL.containsMatchIn(text)) return true
    return SCENE_WORD.findAll(text).count() >= MIN_CERTAIN_WORDS &&
        SCENE_SENTENCE_PUNCTUATION.containsMatchIn(text) &&
        abs(placement.centerX - 0.5f) <= CENTERED_DISTANCE
}

/**
 * Heights (frame-relative) where this session read certain subtitles. Each game
 * keeps its subtitles in one place; a short line there ("Let's go") is dialogue,
 * not a sign. Forgotten when the OCR areas change.
 */
internal class SubtitleBand(private val capacity: Int = BAND_CAPACITY) {
    private val heights = ArrayDeque<ScenePlacement>()

    @Synchronized fun contains(placement: ScenePlacement): Boolean = heights.any { near(it, placement) }

    @Synchronized fun remember(placement: ScenePlacement) {
        heights.removeAll { near(it, placement) }
        heights.addLast(placement)
        while (heights.size > capacity) heights.removeFirst()
    }

    @Synchronized fun clear() = heights.clear()

    private fun near(known: ScenePlacement, placement: ScenePlacement) =
        abs(known.centerY - placement.centerY) <= max(known.lineHeight, placement.lineHeight) * BAND_MARGIN_LINES
}

/**
 * Subtitles are drawn horizontally. Perspective text (a plate on a passing car,
 * a sign seen from the side) is rotated: the recognizer reports an angle, the
 * word centres drift one way along the line, or the line's box is much taller
 * than its words.
 */
internal fun isTiltedLine(line: SceneTextLine): Boolean {
    if (line.text.count(Char::isLetterOrDigit) >= MIN_TILT_CHARACTERS && abs(line.angle) >= TILT_ANGLE_DEGREES) return true
    val words = line.words.filter { it.height > 0f }
    if (words.size < 2) return false
    val wordHeight = words.map { it.height }.sorted()[words.size / 2]
    if (wordHeight <= 0f) return false
    if (line.bottom - line.top > wordHeight * TILT_BOX_HEIGHT_RATIO) return true
    if (words.size < 3) return false
    val ordered = words.sortedBy { it.left }
    val drift = ordered.last().centerY - ordered.first().centerY
    if (abs(drift) < wordHeight * TILT_DRIFT_WORD_HEIGHTS) return false
    // One direction only: recognizer jitter moves boxes a little both ways.
    val tolerance = wordHeight * TILT_JITTER_WORD_HEIGHTS
    return ordered.zipWithNext().all { (a, b) ->
        val step = b.centerY - a.centerY
        if (drift > 0) step >= -tolerance else step <= tolerance
    }
}

/**
 * A licence plate: short upper-case lines, no sentence punctuation, and one line
 * that is a letter/digit code ("8ZJK 264", "LEO-4821"). A state name above the
 * code ("LEONIDA") belongs to the same plate.
 */
internal fun isPlateLike(lines: List<SceneTextLine>): Boolean {
    if (lines.isEmpty() || lines.size > MAX_PLATE_LINES) return false
    val texts = lines.map { it.text.trim() }.filter { it.isNotEmpty() }
    if (texts.isEmpty()) return false
    if (texts.any { value -> value.any(Char::isLowerCase) || SCENE_SENTENCE_PUNCTUATION.containsMatchIn(value) }) return false
    if (texts.any { it.split(SCENE_WHITESPACE).size > MAX_PLATE_TOKENS }) return false
    return texts.any(::isPlateCode)
}

/**
 * [text] without a licence plate read after its last sentence ("… hang on.
 * HCO 11M" -> "… hang on."): a car behind the subtitle strip.
 */
internal fun withoutTrailingPlate(text: String): String {
    val match = TRAILING_PLATE.find(text) ?: return text
    return if (isPlateCode(match.groupValues[2])) match.groupValues[1].trimEnd() else text
}

private val TRAILING_PLATE = Regex("""^(.*[.!?…])\s+(\S+(?:\s+\S+)?)\s*$""")

/** "8ZJK 264", "6ABC123", "LEO-4821": 5–10 letters/digits with a digit, mixed or a digit run. */
internal fun isPlateCode(value: String): Boolean {
    val tokens = value.trim().split(SCENE_WHITESPACE).filter { it.isNotEmpty() }
    if (tokens.isEmpty() || tokens.size > MAX_PLATE_TOKENS) return false
    if (tokens.any { token -> token.any { !it.isLetterOrDigit() && it !in PLATE_SEPARATORS } }) return false
    if (value.any(Char::isLowerCase)) return false
    val characters = value.count(Char::isLetterOrDigit)
    if (characters !in MIN_PLATE_CHARACTERS..MAX_PLATE_CHARACTERS) return false
    val digits = value.count(Char::isDigit)
    if (digits == 0) return false
    val mixedToken = tokens.any { token -> token.any(Char::isLetter) && token.any(Char::isDigit) }
    return mixedToken || digits >= MIN_PLATE_DIGIT_RUN
}

/**
 * A one- or two-word read with no punctuation that the recognizer itself barely
 * trusts: usually a glimpse of a sign or a plate, not a line of dialogue.
 */
internal fun isLowConfidenceFragment(lines: List<SceneTextLine>, text: String): Boolean {
    val words = SCENE_WORD.findAll(text).count()
    if (words !in 1..MAX_LOW_CONFIDENCE_WORDS || SCENE_ANY_PUNCTUATION.containsMatchIn(text)) return false
    val known = lines.filter { it.confidence >= 0f }
    if (known.isEmpty()) return false
    return known.map { it.confidence }.average() < LOW_CONFIDENCE
}

private const val TILT_ANGLE_DEGREES = 5f
private const val MIN_TILT_CHARACTERS = 3
private const val TILT_BOX_HEIGHT_RATIO = 1.8f
private const val TILT_DRIFT_WORD_HEIGHTS = 0.6f
private const val TILT_JITTER_WORD_HEIGHTS = 0.15f
private const val MAX_PLATE_LINES = 3
private const val MAX_PLATE_TOKENS = 3
private const val MIN_PLATE_CHARACTERS = 5
private const val MAX_PLATE_CHARACTERS = 10
private const val MIN_PLATE_DIGIT_RUN = 3
private const val MAX_LOW_CONFIDENCE_WORDS = 2
private const val LOW_CONFIDENCE = 0.40
private const val PLATE_SEPARATORS = "-·•"
private const val MAX_LABEL_WORDS = 3
private const val SUBTITLE_EDGE_BAND = 0.22f
private const val MIN_CERTAIN_WORDS = 4
private const val CENTERED_DISTANCE = 0.20f
private const val BAND_CAPACITY = 4
private const val BAND_MARGIN_LINES = 1.0f
private const val MIN_SUBTITLE_REGION_WIDTH = 0.40f
private const val MAX_SUBTITLE_REGION_OFFSET = 0.15f

private val SCENE_SPEAKER_LABEL = Regex("""^\s*\p{Lu}[\p{L}\p{N} .’'-]{0,24}:\s*\S""")

/**
 * Scene text (a brand on a bottle, a sign) that OCR glued onto the start of a
 * subtitle line in front of its speaker label: "YHO Lucia: These are…".
 * Returns how many leading words to drop: one or two short words without
 * lowercase letters, followed by a capitalised speaker label and its line.
 */
internal fun sceneWordsBeforeSpeaker(words: List<String>): Int {
    for (count in 1..MAX_GLUED_SCENE_WORDS) {
        if (words.size < count + 2) return 0
        val glued = words.take(count)
        if (glued.any { word -> word.length > MAX_GLUED_SCENE_WORD_LENGTH || word.any(Char::isLowerCase) }) return 0
        val label = words[count]
        val twoWordLabel = words.size >= count + 3 && GLUED_LABEL_NAME.matches(label) && GLUED_LABEL.matches(words[count + 1])
        if (GLUED_LABEL.matches(label) || twoWordLabel) return count
    }
    return 0
}

/** [sceneWordsBeforeSpeaker] applied to a whole line of text. */
internal fun stripSceneWordsBeforeSpeaker(text: String): String {
    val words = text.trim().split(SCENE_WHITESPACE)
    val drop = sceneWordsBeforeSpeaker(words)
    return if (drop == 0) text else words.drop(drop).joinToString(" ")
}

private const val MAX_GLUED_SCENE_WORDS = 2
private const val MAX_GLUED_SCENE_WORD_LENGTH = 6
private val GLUED_LABEL = Regex("""\p{Lu}[\p{L}’'.-]{1,20}:""")
private val GLUED_LABEL_NAME = Regex("""\p{Lu}[\p{L}’'.-]{1,20}""")
private val SCENE_WHITESPACE = Regex("\\s+")
private val SCENE_WORD = Regex("""[\p{L}\p{N}]+(?:['’][\p{L}]+)*""")
private val SCENE_SENTENCE_PUNCTUATION = Regex("""[.!?…,;"“”]""")
private val SCENE_ANY_PUNCTUATION = Regex("""[.!?…,;:"“”'’]""")

/**
 * Upper-case words of [text] with at least [minLength] letters/digits. Digits
 * OCR puts in place of letters inside a word ("1SA", "5UIT") read as letters.
 */
internal fun sceneTokens(text: String, minLength: Int = 3): List<String> =
    SCENE_WORD.findAll(text).map { normalizeSceneToken(it.value) }.filter { it.length >= minLength }.toList()

private fun normalizeSceneToken(value: String): String {
    val upper = value.uppercase(java.util.Locale.ROOT).filter(Char::isLetterOrDigit)
    if (upper.none(Char::isLetter)) return upper
    return upper.map { when (it) { '1' -> 'I'; '5' -> 'S'; '0' -> 'O'; else -> it } }.joinToString("")
}

/** Two OCR readings of the same word: equal, one letter apart, or one inside the other ("TSUIT"/"SUIT"). */
internal fun similarSceneToken(a: String, b: String): Boolean {
    if (a == b) return true
    val shorter = minOf(a.length, b.length)
    val longer = maxOf(a.length, b.length)
    if (shorter < 3 || longer < 4) return false
    if (shorter >= 4 && (a.contains(b) || b.contains(a))) return true
    return longer - shorter <= 1 && editDistanceAtMostOne(a, b)
}

private fun editDistanceAtMostOne(a: String, b: String): Boolean {
    if (a.length == b.length) return a.indices.count { a[it] != b[it] } <= 1
    val (short, long) = if (a.length < b.length) a to b else b to a
    var i = 0
    var j = 0
    var skipped = false
    while (i < short.length && j < long.length) {
        if (short[i] == long[j]) { i++; j++ }
        else { if (skipped) return false; skipped = true; j++ }
    }
    return true
}

/**
 * A block starting with a speaker label, or a certain subtitle: never treated as
 * scene text by the motion and seen-words checks.
 */
internal fun isSceneExempt(lines: List<SceneTextLine>, placement: ScenePlacement?): Boolean {
    val text = lines.joinToString(" ") { it.text.trim() }.trim()
    if (SCENE_SPEAKER_LABEL.containsMatchIn(text)) return true
    return placement != null && isCertainSubtitle(lines, placement)
}

/**
 * Words of signs and other world text rejected as tilted a moment ago in one
 * OCR area. A sign seen at an angle is rejected as tilted, but OCR
 * often also reads one straight part of it ("SUIT" under "THE ONLY GOOD SUIT
 * IS A …"), which a pack then translates. A later block made only of those
 * words is the same sign, not a subtitle.
 */
internal class SceneWordMemory(
    private val holdMillis: Long = SCENE_WORD_HOLD_MS,
    private val capacity: Int = SCENE_WORD_CAPACITY,
) {
    private val words = LinkedHashMap<String, Long>()

    @Synchronized fun remember(text: String, now: Long) {
        sceneTokens(text).filterNot { it in SCENE_STOP_WORDS }.forEach { word ->
            words.remove(word)
            words[word] = now
        }
        while (words.size > capacity) words.remove(words.keys.first())
    }

    /** True when every (or, from four words, three in four) word of [text] was just seen on a rejected sign. */
    @Synchronized fun isSceneEcho(text: String, now: Long): Boolean {
        words.entries.removeAll { now - it.value > holdMillis }
        if (words.isEmpty()) return false
        val tokens = sceneTokens(text).filterNot { it in SCENE_STOP_WORDS }
        if (tokens.isEmpty()) {
            // A two-letter scrap of a remembered word ("SA" of "ISA").
            val short = sceneTokens(text, 2)
            return short.isNotEmpty() && short.all { piece -> words.keys.any { it.length > piece.length && piece in it } }
        }
        if (tokens.size > MAX_SCENE_ECHO_WORDS) return false
        val known = tokens.count { token -> words.keys.any { similarSceneToken(token, it) } }
        return if (tokens.size < 4) known == tokens.size else known * 4 >= tokens.size * 3
    }

    @Synchronized fun clear() = words.clear()
}

/** A block's box in crop pixels and its line height. */
internal data class SceneBox(val left: Float, val top: Float, val right: Float, val bottom: Float, val lineHeight: Float)

/** [lines] (crop-relative) as a pixel box of a [width]×[height] crop. */
internal fun sceneBox(lines: List<SceneTextLine>, width: Int, height: Int): SceneBox? {
    if (lines.isEmpty() || width <= 0 || height <= 0) return null
    val lineHeight = lines.map { it.bottom - it.top }.sorted()[lines.size / 2] * height
    if (lineHeight <= 0f) return null
    return SceneBox(lines.minOf { it.left } * width, lines.minOf { it.top } * height,
        lines.maxOf { it.right } * width, lines.maxOf { it.bottom } * height, lineHeight)
}

/**
 * HUD prompts and subtitles stay put on screen; signs, plates and posters move
 * whenever the camera does. Compares each block with the same text in the
 * previous OCR frame of one area: when it moved by more than a third of a line,
 * it is world text. Several evaluations of one frame (OCR recovery) share
 * [frameKey], so the check gives the same answer for all of them.
 */
internal class SceneMotionTracker(private val maxGapMillis: Long = SCENE_MOTION_MAX_GAP_MS) {
    private class Seen(val words: List<String>, val box: SceneBox)
    private var frame = Long.MIN_VALUE
    private var frameAt = 0L
    private var previous = emptyList<Seen>()
    private var previousAt = Long.MIN_VALUE
    private val current = mutableListOf<Seen>()

    @Synchronized fun moved(frameKey: Long, now: Long, text: String, box: SceneBox): Boolean {
        if (frameKey != frame) {
            if (current.isNotEmpty()) {
                previous = current.toList()
                previousAt = frameAt
            }
            current.clear()
            frame = frameKey
            frameAt = now
        }
        val words = sceneTokens(text, 2)
        if (words.isEmpty()) return false
        current.add(Seen(words, box))
        if (previousAt == Long.MIN_VALUE || now - previousAt > maxGapMillis) return false
        val before = previous.filter { sameSceneWords(it.words, words) }
            .minByOrNull { boxShift(it.box, box) } ?: return false
        return boxShift(before.box, box) > max(before.box.lineHeight, box.lineHeight) * SCENE_MOTION_LINES
    }

    @Synchronized fun clear() {
        previous = emptyList()
        previousAt = Long.MIN_VALUE
        current.clear()
        frame = Long.MIN_VALUE
    }

    /**
     * How far a block moved. A different reading of its first or last letter
     * moves one edge only, and a new line moves only its bottom, so each axis
     * takes the smaller of its two edge shifts.
     */
    private fun boxShift(a: SceneBox, b: SceneBox): Float = max(
        minOf(abs(a.left - b.left), abs(a.right - b.right)),
        minOf(abs(a.top - b.top), abs(a.bottom - b.bottom)),
    )
}

/** Most words of the two readings match ([similarSceneToken]). */
internal fun sameSceneWords(a: List<String>, b: List<String>): Boolean {
    if (a.isEmpty() || b.isEmpty()) return false
    val matched = a.count { word -> b.any { similarSceneToken(word, it) } }
    return matched * 10 >= max(a.size, b.size) * 6
}

private const val SCENE_WORD_HOLD_MS = 6000L
private const val SCENE_WORD_CAPACITY = 48
private const val MAX_SCENE_ECHO_WORDS = 6
private const val SCENE_MOTION_MAX_GAP_MS = 1500L
private const val SCENE_MOTION_LINES = 0.35f
private val SCENE_STOP_WORDS = setOf(
    "THE", "AND", "YOU", "FOR", "ARE", "BUT", "NOT", "THIS", "THAT", "WITH", "WAS", "HAVE",
    "YOUR", "ALL", "CAN", "HIS", "HER", "OUR", "ITS", "FROM", "THEY", "WHAT", "OUT", "GET",
)
