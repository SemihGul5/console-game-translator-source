package com.abrebostudio.consolegametranslator

import kotlin.math.abs
import kotlin.math.min

/** One recognized word, mapped into the frame. */
internal data class CoverWord(val text: String, val box: CoverBox)

/** One OCR line for the cover mode with its words (empty when OCR gave no word boxes). */
internal data class CoverWordLine(val line: CoverLine, val words: List<CoverWord>)

/** Button-prompt labels covered one by one, and every other line for [groupCoverUnits]. */
internal class CoverPromptSplit(val prompts: List<CoverUnit>, val rest: List<CoverLine>)

/**
 * A row of controller prompts ("PHOTO STUDIO [□]   SELECT [X]   BACK [O]") is a
 * list of separate labels, each with its button drawn beside it. In the cover
 * mode each label gets its own translation over its own English, and the
 * game's buttons stay visible between them: no icon is cut out or redrawn.
 *
 * A row is split where a wide gap (a button) or a button misread as a token
 * ("O", "(R1", "%") separates its words. It counts as a prompt row only when it
 * has at least two labels, each of at most [MAX_PROMPT_WORDS] words, and no
 * label continues a sentence across a button ("Hold [L3] to view…" stays one
 * line, so its translation keeps Turkish word order).
 *
 * With [everyRowIsLabel] (a HUD area, not a subtitle strip) a short row is a
 * label on its own too ("CHEMICALS [X]" above "TAUNT [□]"): each row gets its
 * own cover the size of its English instead of one box over the whole stack.
 */
internal fun splitCoverPrompts(lines: List<CoverWordLine>, everyRowIsLabel: Boolean = false): CoverPromptSplit {
    val usable = lines.filter { it.line.text.isNotBlank() && it.line.box.height > 0f }
    val rows = ArrayList<MutableList<CoverWordLine>>()
    for (line in usable.sortedBy { it.line.box.centerY }) {
        val row = rows.lastOrNull()?.takeIf { row ->
            val first = row.first().line.box
            abs(first.centerY - line.line.box.centerY) <= min(first.height, line.line.box.height) * SAME_ROW_CENTER_LINES
        }
        if (row != null) row.add(line) else rows.add(mutableListOf(line))
    }
    val prompts = ArrayList<CoverUnit>()
    val rest = ArrayList<CoverLine>()
    for (row in rows) {
        val labels = promptLabels(row, everyRowIsLabel)
        if (labels == null) rest += row.map { it.line } else prompts += labels
    }
    return CoverPromptSplit(prompts, rest)
}

private fun promptLabels(row: List<CoverWordLine>, single: Boolean): List<CoverUnit>? {
    if (row.any { it.words.isEmpty() }) return null
    val words = row.flatMap { it.words }.filter { it.text.isNotBlank() && it.box.width > 0f && it.box.height > 0f }
        .map(::withoutGluedButton).sortedBy { it.box.left }
    if (words.isEmpty() || (words.size < 2 && !single)) return null
    if (PROMPT_SPEAKER_LABEL.containsMatchIn(words.joinToString(" ") { it.text })) return null
    val lineHeight = words.map { it.box.height }.sorted()[words.size / 2]
    val segments = ArrayList<List<CoverWord>>()
    var current = ArrayList<CoverWord>()
    var previous: CoverWord? = null
    for (word in words) {
        if (isIconMisread(word.text)) {
            if (current.isNotEmpty()) segments += current
            current = ArrayList()
        } else {
            val gap = previous?.let { word.box.left - it.box.right } ?: 0f
            if (current.isNotEmpty() && gap >= lineHeight * PROMPT_GAP_LINES) {
                segments += current
                current = ArrayList()
            }
            current += word
        }
        previous = word
    }
    if (current.isNotEmpty()) segments += current
    val labels = segments.map(::withoutEdgeButtons)
        .filter { segment -> segment.any { word -> word.text.count(Char::isLetter) >= 2 } }
    if (labels.isEmpty()) return null
    // One short row of a HUD area: the whole row (without button tokens) is one label.
    fun wholeRow(): List<CoverUnit>? {
        // Several pieces that read as one sentence across a button stay a line,
        // so no cover is drawn over the button between them.
        if (!single || labels.size != 1) return null
        val kept = labels.single()
        if (kept.size > MAX_PROMPT_WORDS) return null
        if (PROMPT_SENTENCE_PUNCTUATION.containsMatchIn(kept.joinToString(" ") { it.text })) return null
        return listOf(label(kept, lineHeight))
    }
    if (labels.size < 2 || labels.any { it.size > MAX_PROMPT_WORDS }) return wholeRow()
    // A sentence carried across a button: a later label starting in lower case or
    // with a joining word, or an earlier one ending with one or being a bare verb.
    if (labels.drop(1).any { label ->
            val first = label.first().text
            first.firstOrNull(Char::isLetter)?.isLowerCase() == true || first.lowercase() in PROMPT_JOINERS
        }) return wholeRow()
    if (labels.dropLast(1).any { label ->
            label.last().text.lowercase() in PROMPT_JOINERS ||
                (label.size == 1 && label[0].text.lowercase() in PROMPT_VERBS)
        }) return wholeRow()
    return labels.map { label(it, lineHeight) }
}

/**
 * A button OCR read as a lone character at a label's edge ("CHEMICALS? A" for
 * the triangle, "RECENTER 3" for R3, "PHOTO STUDIO O"): dropped, so neither the
 * translation nor the cover box includes the button. One-letter words inside a
 * label ("SEE A DOCTOR") stay.
 */
private fun withoutEdgeButtons(label: List<CoverWord>): List<CoverWord> {
    var kept = label
    fun lone(word: CoverWord) = word.text.count(Char::isLetterOrDigit) <= 1
    while (kept.size > 1 && lone(kept.last())) kept = kept.dropLast(1)
    while (kept.size > 1 && lone(kept.first())) kept = kept.drop(1)
    return kept
}

/**
 * A button glued to the end of a word by OCR ("MARKER\"O", "KYLE(O",
 * "KYLE()"): the word keeps its letters and its box is cut back in proportion.
 */
private fun withoutGluedButton(word: CoverWord): CoverWord {
    val text = word.text
    val cut = text.indexOfFirst { it in GLUED_BUTTON_START }.takeIf { it >= 2 } ?: return word
    if (text.substring(cut).count(Char::isLetterOrDigit) > 2 || text.substring(0, cut).count(Char::isLetter) < 2) return word
    val kept = cut.toFloat() / text.length
    return CoverWord(text.substring(0, cut), word.box.copy(right = word.box.left + word.box.width * kept))
}

private fun label(words: List<CoverWord>, lineHeight: Float) = CoverUnit(
    text = words.joinToString(" ") { it.text },
    box = words.map { it.box }.reduce(CoverBox::union),
    lineHeight = lineHeight,
    prompt = true,
)

/**
 * A controller button that OCR turned into a token: no letters or digits
 * ("%", "©"), a bracketed scrap ("(R1", "[O]"), a lone "O"/"X", or a button
 * code ("R1", "L2").
 */
internal fun isIconMisread(token: String): Boolean {
    val value = token.trim()
    if (value.none(Char::isLetterOrDigit)) return true
    val core = value.trim('(', ')', '[', ']', '{', '}', '<', '>', '|')
    if (core.none(Char::isLetterOrDigit)) return true
    if (value.first() in "([{<") return core.length <= 3
    if (core.length == 1 && core[0].uppercaseChar() in "OX0") return true
    return BUTTON_CODE.matches(core.uppercase())
}

private const val SAME_ROW_CENTER_LINES = 0.5f
private const val PROMPT_GAP_LINES = 0.9f
private const val MAX_PROMPT_WORDS = 4
private val BUTTON_CODE = Regex("[LRG][1-3]")
// A short HUD row ending with "?" or "!" is still a label (a dialogue choice).
private val PROMPT_SENTENCE_PUNCTUATION = Regex("""[.…;]""")
private const val GLUED_BUTTON_START = "\"“”([{<"
private val PROMPT_SPEAKER_LABEL = Regex("""^\s*[-–—]?\s*\p{Lu}[\p{L}\p{N} .’'-]{0,24}:\s*\S""")
private val PROMPT_JOINERS = setOf("to", "and", "or", "for", "the", "a", "of", "with", "then", "while", "into", "onto")
private val PROMPT_VERBS = setOf("press", "hold", "tap", "use", "push", "pull", "release", "click", "mash", "rotate", "swipe")
