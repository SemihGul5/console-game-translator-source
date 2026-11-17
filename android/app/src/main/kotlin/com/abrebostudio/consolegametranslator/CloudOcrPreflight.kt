package com.abrebostudio.consolegametranslator

import java.text.Normalizer

/** No language to translate: never buy a cloud translation of a standalone clock/number. */
internal fun isNonLinguisticCloudOcr(text: String): Boolean {
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
private const val CLOUD_CLOCK_SECONDS = "[0-9oOilILvV|aA]{1,2}"
private val CLOUD_CLOCK_TOKEN = Regex("$CLOUD_CLOCK_GLYPHS{1,3}:$CLOUD_CLOCK_SECONDS(?::$CLOUD_CLOCK_SECONDS)?")
private val CLOUD_COMPACT_CLOCK_FRAGMENT = Regex("[nN]?[0-9oOilIL|]{2,4}")
