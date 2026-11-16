package com.abrebostudio.consolegametranslator

import kotlin.math.abs
import kotlin.math.min

/** Edit cost in hundredths; only familiar OCR glyph substitutions get a discount. */
internal fun ocrTextDistance(left: String, right: String, limit: Int): Int {
    if (left == right) return 0
    if (abs(left.length - right.length) * 25 > limit) return limit + 1
    var before = IntArray(right.length + 1)
    for (j in right.indices) before[j + 1] = before[j] + if (right[j] == ' ') 35 else 100
    var previous = IntArray(right.length + 1)
    var current = IntArray(right.length + 1)
    var beforeMin = 0
    for (i in 1..left.length) {
        current[0] = before[0] + if (left[i - 1] == ' ') 35 else 100
        var rowMin = current[0]
        for (j in 1..right.length) {
            val a = left[i - 1]; val b = right[j - 1]
            var cost = min(min(current[j - 1] + if (b == ' ') 35 else 100,
                before[j] + if (a == ' ') 35 else 100), before[j - 1] + ocrGlyphCost(a, b))
            if (i >= 2 && ocrPairMatches(left[i - 2], a, b)) cost = min(cost, previous[j - 1] + 30)
            if (j >= 2 && ocrPairMatches(right[j - 2], b, a)) cost = min(cost, before[j - 2] + 30)
            current[j] = cost; rowMin = min(rowMin, cost)
        }
        // A two-character glyph can still lower the next row's minimum.
        if (i > 1 && rowMin > limit && beforeMin > limit) return limit + 1
        beforeMin = rowMin
        val spare = previous; previous = before; before = current; current = spare
    }
    return before[right.length]
}

private fun ocrGlyphCost(a: Char, b: Char): Int {
    if (a == b) return 0
    val group = when (a) {
        '0', 'o' -> "0o"
        '1', 'i', 'l' -> "1il"
        '5', 's' -> "5s"
        '8', 'b' -> "8b"
        '9', 'g', 'e' -> "9ge"
        '2', 'z' -> "2z"
        'u', 'v' -> "uv"
        'n', 'm' -> "nm"
        else -> ""
    }
    return if (b in group) 30 else 100
}

private fun ocrPairMatches(first: Char, second: Char, single: Char): Boolean =
    (first == 'r' && second == 'n' && single == 'm') ||
        (first == 'r' && second == 'i' && single == 'n') ||
        (first == 'r' && second == 'r' && single == 'n') ||
        (first == 'c' && second == 'l' && single == 'd') ||
        (first == 'v' && second == 'v' && single == 'w')
