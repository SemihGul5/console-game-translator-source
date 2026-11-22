package com.abrebostudio.consolegametranslator

import kotlin.math.abs

/**
 * Controller button icons inside a subtitle or hint ("Hold [L3] to view…").
 * OCR reads only the words around an icon and leaves a wide gap where it is,
 * so the icon is found from that gap, cut out of the frame, and drawn back
 * into the translation in place of [ICON_PLACEHOLDER].
 */
internal const val ICON_PLACEHOLDER = '￼'

/** An icon cut from the frame: [png] is base64 PNG, [box] its place in the frame. */
internal data class ButtonIcon(val png: String, val box: CoverBox)

/** A recognised word's box, in crop pixels. */
internal data class IconWord(val left: Int, val top: Int, val right: Int, val bottom: Int, val text: String = "") {
    val height get() = bottom - top
    val centerY get() = (top + bottom) / 2f
}

/** Where an icon may be, in crop pixels. */
internal data class IconArea(val left: Int, val top: Int, val right: Int, val bottom: Int) {
    val width get() = right - left
    val height get() = bottom - top
}

/**
 * Gaps between neighbouring words of one row that are wide enough to hold a
 * button icon, in reading order. Normal word spaces are well under one line
 * height; a gap of several line heights is another column, not an icon.
 *
 * Icons belong to control hints ("Hold [L3] to view…"), never to dialogue or
 * menus: the text must name a button action, and a row that starts with a
 * speaker label ("Cal: …") is dialogue and is never searched.
 */
internal fun buttonIconGaps(words: List<IconWord>, width: Int, height: Int): List<IconArea> {
    if (!CONTROL_HINT.containsMatchIn(words.joinToString(" ") { it.text })) return emptyList()
    val rows = ArrayList<MutableList<IconWord>>()
    for (word in words.filter { it.right > it.left && it.height > 0 }.sortedBy { it.centerY }) {
        val row = rows.firstOrNull { row ->
            val rowHeight = row.map { it.height }.sorted()[row.size / 2]
            abs(row.map { it.centerY }.average().toFloat() - word.centerY) <= rowHeight * ROW_TOLERANCE
        }
        if (row != null) row.add(word) else rows.add(mutableListOf(word))
    }
    return rows.sortedBy { row -> row.minOf { it.top } }.flatMap { row ->
        val sorted = row.sortedBy { it.left }
        if (ICON_GAP_SPEAKER.matches(sorted.first().text)) return@flatMap emptyList()
        val lineHeight = sorted.map { it.height }.sorted()[sorted.size / 2].toFloat()
        val centerY = sorted.map { it.centerY }.average().toFloat()
        sorted.zipWithNext().mapNotNull { (before, after) ->
            val gap = after.left - before.right
            if (gap < lineHeight * MIN_ICON_GAP_LINES || gap > lineHeight * MAX_ICON_GAP_LINES) return@mapNotNull null
            // A speaker label starts a subtitle; what stands before it is scene
            // text glued on by OCR ("AYHO Lucia: …"), never a button.
            if (ICON_GAP_SPEAKER.matches(after.text)) return@mapNotNull null
            val pad = (lineHeight * ICON_GAP_PADDING).toInt()
            val half = lineHeight * ICON_HALF_HEIGHT_LINES
            IconArea(
                (before.right + pad).coerceIn(0, width),
                (centerY - half).toInt().coerceIn(0, height),
                (after.left - pad).coerceIn(0, width),
                (centerY + half).toInt().coerceIn(0, height),
            ).takeIf { it.width > 2 && it.height > 2 }
        }
    }.take(MAX_ICONS)
}

/**
 * The drawn shape inside [area], or null when the gap holds only background.
 * [pixels] are the area's ARGB pixels, row by row. The returned box is
 * relative to [area] and fits the icon tightly. An icon is a compact,
 * clearly contrasting shape about as tall as the text beside it.
 */
internal fun iconInk(pixels: IntArray, area: IconArea, lineHeight: Int): IconArea? {
    val width = area.width
    val height = area.height
    if (width <= 0 || height <= 0 || pixels.size < width * height) return null
    val luma = IntArray(width * height) { index ->
        val color = pixels[index]
        (((color shr 16) and 0xFF) * 299 + ((color shr 8) and 0xFF) * 587 + (color and 0xFF) * 114) / 1000
    }
    val sorted = luma.sortedArray()
    val background = sorted[sorted.size / 2]
    if (sorted.last() - sorted.first() < MIN_ICON_CONTRAST) return null
    var left = width; var top = height; var right = -1; var bottom = -1; var ink = 0
    for (y in 0 until height) for (x in 0 until width) {
        if (abs(luma[y * width + x] - background) <= INK_DIFFERENCE) continue
        ink++
        if (x < left) left = x
        if (x > right) right = x
        if (y < top) top = y
        if (y > bottom) bottom = y
    }
    if (right < 0) return null
    val ratio = ink.toFloat() / (width * height)
    if (ratio < MIN_INK_RATIO || ratio > MAX_INK_RATIO) return null
    val box = IconArea(left, top, right + 1, bottom + 1)
    val aspect = box.width.toFloat() / box.height
    if (box.height < lineHeight * MIN_ICON_HEIGHT_LINES || aspect < MIN_ICON_ASPECT || aspect > MAX_ICON_ASPECT) return null
    return box
}

/**
 * Puts [count] icons back into a translation. In Turkish the icon goes where
 * the button is meant: a pack's "bu tuşa" becomes "[icon] tuşuna", otherwise
 * it goes before the button verb ("… için [icon] basılı tut"). Elsewhere, and
 * when no such word is found, it goes at the start, after any speaker label.
 */
internal fun insertButtonIcons(text: String, count: Int, turkish: Boolean): String {
    if (count <= 0 || text.isBlank()) return text
    val icons = List(count.coerceAtMost(MAX_ICONS)) { ICON_PLACEHOLDER }.joinToString(" ")
    val speaker = ICON_SPEAKER_LABEL.find(text)
    val bodyStart = speaker?.range?.last?.plus(1) ?: 0
    if (turkish) {
        BUTTON_REFERENCE.find(text, bodyStart)?.let { match ->
            val noun = match.groupValues[1]
            val suffix = match.groupValues[2].lowercase(TURKISH)
            val replaced = if (noun.lowercase(TURKISH) == "tuş") when (suffix) {
                "a" -> "tuşuna"; "u" -> "tuşunu"; "la" -> "tuşuyla"; "un" -> "tuşunun"; else -> "tuşu"
            } else when (suffix) {
                "ye" -> "düğmesine"; "yi" -> "düğmesini"; "yle" -> "düğmesiyle"; "nin" -> "düğmesinin"; else -> "düğmesi"
            }
            return text.replaceRange(match.range, "$icons $replaced")
        }
        BUTTON_VERB.findAll(text, bodyStart).lastOrNull()?.let { verb ->
            return text.substring(0, verb.range.first) + "$icons " + text.substring(verb.range.first)
        }
    }
    return text.substring(0, bodyStart) + (if (bodyStart > 0 && !text[bodyStart - 1].isWhitespace()) " " else "") +
        "$icons " + text.substring(bodyStart).trimStart()
}

private val TURKISH = java.util.Locale.forLanguageTag("tr")
private const val MAX_ICONS = 4
private const val ROW_TOLERANCE = 0.5f
private const val MIN_ICON_GAP_LINES = 1.0f
private const val MAX_ICON_GAP_LINES = 3.5f
private const val ICON_GAP_PADDING = 0.12f
private const val ICON_HALF_HEIGHT_LINES = 0.8f
private const val MIN_ICON_CONTRAST = 70
private const val INK_DIFFERENCE = 48
private const val MIN_INK_RATIO = 0.06f
private const val MAX_INK_RATIO = 0.75f
private const val MIN_ICON_HEIGHT_LINES = 0.6f
private const val MIN_ICON_ASPECT = 0.5f
private const val MAX_ICON_ASPECT = 2.2f
// The words a game uses to tell which button to use.
private val CONTROL_HINT = Regex(
    """(?<![\p{L}])(?:press|hold|tap|release|use|toggle|select|switch|click|push|pull|mash|rotate|swipe)(?![\p{L}])""",
    RegexOption.IGNORE_CASE,
)
private val ICON_GAP_SPEAKER = Regex("""\p{Lu}[\p{L}’'.-]{1,20}:""")
private val ICON_SPEAKER_LABEL = Regex("""^\s*\p{Lu}[\p{L}\p{N} .’'-]{0,24}:\s*""")
private val BUTTON_REFERENCE = Regex("""(?<![\p{L}])[Bb]u (tuş|düğme)(a|u|la|un|ye|yi|yle|nin)?(?![\p{L}])""")
private val BUTTON_VERB = Regex(
    """(?<![\p{L}])(?:basılı tut|bas|tut|dokun|tıkla|kaydır|çevir|kullan|sürükle|it|çek)\p{L}*""",
    RegexOption.IGNORE_CASE,
)
