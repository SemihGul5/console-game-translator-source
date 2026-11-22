package com.abrebostudio.consolegametranslator

import java.text.Normalizer

/**
 * No language to translate: a standalone clock/number (for example a video
 * player's "02:59 04:59") never reaches any translation engine, cloud or local.
 */
internal fun isNonLinguisticOcr(text: String): Boolean {
    if (text.none(Char::isLetter)) return true
    val value = Normalizer.normalize(text, Normalizer.Form.NFKC).trim()
        .replace(CLOCK_COLON_SPACING, ":")
    if (isStandaloneOcrTimer(value)) return true
    if (value.none(Char::isDigit)) return false
    val tokens = value.split(CLOCK_WHITESPACE)
    // Permit one missing seconds digit or a clock glyph damaged into 'a', and
    // compact fragments such as n014 only alongside an actual clock. Every
    // token must be numeric-shaped; never strip times out of a real sentence.
    return tokens.any(CLOUD_CLOCK_TOKEN::matches) && tokens.all {
        CLOUD_CLOCK_TOKEN.matches(it) || CLOUD_COMPACT_CLOCK_FRAGMENT.matches(it)
    }
}

private val CLOCK_COLON_SPACING = Regex("\\s*[:：]\\s*")
private val CLOCK_WHITESPACE = Regex("\\s+")
private const val CLOUD_CLOCK_GLYPHS = "[0-9oOilILvV|]"
// Seconds digits are often misread as letters ("02:5e", "02:5S", "02:5g").
private const val CLOUD_CLOCK_SECONDS = "[0-9oOilILvV|aAsSgGeBzZq]{1,2}"
private val CLOUD_CLOCK_TOKEN = Regex("$CLOUD_CLOCK_GLYPHS{1,3}:$CLOUD_CLOCK_SECONDS(?::$CLOUD_CLOCK_SECONDS)?")
private val CLOUD_COMPACT_CLOCK_FRAGMENT = Regex("[nN]?[0-9oOilIL|]{2,4}")

/**
 * Marian/HPLT decoders write "<unk>" for pieces their vocabulary cannot express
 * (for example "02:59 <unk>4:59"). Such output is never cached or displayed.
 */
internal fun containsUnknownToken(translation: String): Boolean = translation.contains(UNKNOWN_TOKEN)

private const val UNKNOWN_TOKEN = "<unk>"

/**
 * True when a live model gave the text back unchanged: a brand or name on a
 * bottle or sign ("AYHO"), a code, a clock, or text the game already shows in
 * the target language. Showing it adds nothing, so it is never displayed.
 * Letters and digits are compared only, so "02:5e" -> "02: 5e" also counts.
 */
internal fun isUntranslatedEcho(source: String, translation: String): Boolean {
    val sourceKey = echoKey(source)
    return sourceKey.isNotEmpty() && sourceKey == echoKey(translation)
}

// OCR writes clock digits as look-alike letters ("O0:07" -> "00:07"), which the
// model then corrects: both sides map those letters to digits before comparing.
private fun echoKey(text: String): String =
    text.filter(Char::isLetterOrDigit).lowercase(java.util.Locale.ROOT)
        .map { when (it) { 'o' -> '0'; 'i', 'l' -> '1'; else -> it } }.joinToString("")

/**
 * A running call or mission timer beside a short label ("Kenton O0:05"): the
 * clock changes every second, so the text would go to a translation engine every
 * second. Drops the clock at the start or end when the rest is a short label of
 * at most three words without sentence punctuation; dialogue keeps its times.
 */
internal fun stripLabelClock(text: String): String {
    val tokens = text.trim().split(CLOCK_WHITESPACE).filter { it.isNotEmpty() }
    if (tokens.size < 2) return text
    val rest = when {
        isClockToken(tokens.last()) -> tokens.dropLast(1)
        isClockToken(tokens.first()) -> tokens.drop(1)
        else -> return text
    }
    if (rest.size > MAX_CLOCK_LABEL_WORDS || rest.none { token -> token.any(Char::isLetter) }) return text
    val label = rest.joinToString(" ")
    if (CLOCK_LABEL_PUNCTUATION.containsMatchIn(label)) return text
    return label
}

private fun isClockToken(token: String): Boolean =
    token.any(Char::isDigit) && CLOUD_CLOCK_TOKEN.matches(Normalizer.normalize(token, Normalizer.Form.NFKC))

private const val MAX_CLOCK_LABEL_WORDS = 3
private val CLOCK_LABEL_PUNCTUATION = Regex("""[.!?…,;:"“”]""")
