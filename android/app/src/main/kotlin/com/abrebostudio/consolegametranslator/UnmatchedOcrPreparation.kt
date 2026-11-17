package com.abrebostudio.consolegametranslator

/** A selected pack must have completed its normal lookup before live OCR is improved. */
internal fun canPrepareUnmatchedOcr(
    gameSelected: Boolean,
    gameLookupReady: Boolean,
    jsonMatched: Boolean,
): Boolean = !jsonMatched && (!gameSelected || gameLookupReady)

internal data class PreparedOcrRead(val read: SubtitleOcrRead, val corrections: Int = 0)

/** Only processes a miss. The supplied lookup is the existing, unchanged game matcher. */
internal fun prepareUnmatchedOcr(
    read: SubtitleOcrRead,
    gameSelected: Boolean,
    gameLookupReady: Boolean,
    correct: (String) -> OcrCorrectionTable.Result,
    findGameTranslation: (String) -> GameTranslationMatch?,
): PreparedOcrRead {
    if (!canPrepareUnmatchedOcr(gameSelected, gameLookupReady, read.memoryMatch != null) || read.text.isBlank())
        return PreparedOcrRead(read)
    val corrected = correct(read.text)
    if (corrected.text == read.text) return PreparedOcrRead(read, corrected.replacements)
    val match = if (gameLookupReady) findGameTranslation(corrected.text) else null
    return PreparedOcrRead(read.copy(text = corrected.text, memoryMatch = match), corrected.replacements)
}
