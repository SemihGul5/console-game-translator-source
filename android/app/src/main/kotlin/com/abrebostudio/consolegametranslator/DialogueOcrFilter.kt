package com.abrebostudio.consolegametranslator

import java.util.Locale
import java.text.Normalizer

internal data class OcrLineCandidate(
    val rawText: String,
    val text: String,
    val blockIndex: Int,
    val confidenceValues: List<Float>,
    val left: Float,
    val top: Float,
    val right: Float,
    val bottom: Float,
)

/** Accept or reject complete dialogue blocks; never truncate an accepted block. */
internal fun filterDialogueOcrLines(candidates: List<OcrLineCandidate>, rejectTimerGlyphs: Boolean = false): List<OcrLineCandidate> {
    // Console home/share controls in the reported crop are not dialogue.
    // This filter is called only when the user enables dialogue filtering;
    // authoritative JSON matches and unfiltered OCR keep their existing path.
    if (isConsoleSystemOcr(candidates.joinToString(" ") { it.rawText })) return emptyList()
    val meaningful = candidates.filter { line ->
        line.text.length >= 2 && line.text.any { it.isLetterOrDigit() }
    }
    return meaningful.groupBy { it.blockIndex }.values.mapNotNull { block ->
        val lines = block.sortedWith(compareBy<OcrLineCandidate> { it.top }.thenBy { it.left })
        if (lines.isEmpty()) return@mapNotNull null
        val text = lines.joinToString(" ") { it.text }.trim()
        if (isControllerOcrHint(text)) return@mapNotNull null
        if (rejectTimerGlyphs && isStandaloneOcrTimer(text)) return@mapNotNull null
        val letters = text.count { it.isLetter() }
        val digits = text.count { it.isDigit() }
        if (letters < 2 || digits > letters * 2) return@mapNotNull null

        val wordCount = DIALOGUE_WORD_PATTERN.findAll(text).count()
        val lowerCaseLetters = text.count { it.isLowerCase() }
        val speakerLabel = SPEAKER_LABEL_PATTERN.containsMatchIn(text)
        val terminalPunctuation = TERMINAL_PUNCTUATION_PATTERN.containsMatchIn(text)
        val commonReply = wordCount in 1..2 &&
            text.lowercase(Locale.ROOT).trimEnd('.', '!', '?', '…', ',', ':', ';') in COMMON_DIALOGUE_REPLIES
        val sentenceLike = wordCount >= 3 && (lowerCaseLetters >= 2 || terminalPunctuation)
        val shortSentence = wordCount == 2 && terminalPunctuation
        val allCapsDisplayText = lowerCaseLetters == 0 && !speakerLabel && !commonReply &&
            !(wordCount >= 3 && terminalPunctuation)

        val centerX = (lines.minOf { it.left } + lines.maxOf { it.right }) / 2f
        val centerY = (lines.minOf { it.top } + lines.maxOf { it.bottom }) / 2f
        // Coordinates are relative to the user's crop. A long speaker-labelled
        // subtitle can extend into its upper half and is still dialogue.
        val minimumY = if (speakerLabel) 0f else 0.35f
        val inSubtitlePosition = centerX in 0.04f..0.96f && centerY in minimumY..0.98f
        val hasDialogueShape = speakerLabel || sentenceLike || shortSentence || commonReply
        if (!inSubtitlePosition || allCapsDisplayText || !hasDialogueShape) null else lines
    }.flatten().sortedWith(compareBy<OcrLineCandidate> { it.top }.thenBy { it.left })
}

/** Short menu actions followed by two controller buttons are HUD, not dialogue. */
internal fun isControllerOcrHint(text: String): Boolean = CONTROLLER_HINT_PATTERN.matches(text.trim())

/** A timer such as VI:00 must not become a fictitious speaker called VI. */
internal fun isStandaloneOcrTimer(text: String): Boolean = OCR_TIMER_PATTERN.matches(text.trim())

private const val OCR_TIMER_GLYPHS = "[0-9oOilILvV|]"
private const val OCR_TIMER_TOKEN = "$OCR_TIMER_GLYPHS{1,3}\\s*[:：]\\s*$OCR_TIMER_GLYPHS{2}(?:\\s*[:：]\\s*$OCR_TIMER_GLYPHS{2})?"
private val OCR_TIMER_PATTERN = Regex("$OCR_TIMER_TOKEN(?:\\s+$OCR_TIMER_TOKEN)*")

private val CONTROLLER_HINT_PATTERN = Regex(
    """(?:[\p{L}]+\s+){1,3}(?:L[123TBIU]|R[123TB])\s+(?:L[123TBIU]|R[123TB])""",
    RegexOption.IGNORE_CASE,
)

internal fun isConsoleSystemOcr(text: String): Boolean {
    val value = Normalizer.normalize(text.lowercase(Locale.ROOT).replace('ı', 'i'), Normalizer.Form.NFD)
        .replace(Regex("\\p{M}+"), "").replace(Regex("[^a-z0-9 ]"), " ")
        .replace(Regex("\\s+"), " ").trim()
    val shellMarkers = listOf("arkadas etkinligi", "konsol depolama", "bos alan",
        "friends activity", "console storage", "free space")
    if (shellMarkers.count { value.contains(it) } >= 2) return true
    // Match whole commands, never phrases mentioned inside ordinary dialogue.
    return value.matches(Regex("(?:[a-z]{1,2} )?ekran goruntusu a[li]?")) ||
        value in setOf("yakin zamandaki oyun deneyimini kaydet", "take screenshot",
            "take a screenshot", "save recent gameplay")
}

private val DIALOGUE_WORD_PATTERN = Regex("""[\p{L}]+(?:['’][\p{L}]+)*""")
private val COMMON_DIALOGUE_REPLIES = setOf(
    "yes", "no", "yeah", "yep", "nope", "okay", "ok", "thanks", "please",
    "wait", "stop", "run", "help", "what", "why", "who", "where", "hello",
    "hi", "sorry", "right",
)
private val SPEAKER_LABEL_PATTERN = Regex("""^\s*\p{Lu}[\p{L}\p{N} .’'-]{0,24}:\s*\S""")
private val TERMINAL_PUNCTUATION_PATTERN = Regex("""[.!?…][\p{Pe}"'’]*$""")
