package com.abrebostudio.consolegametranslator

import java.text.Normalizer
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

/** Only unambiguous English OCR mistakes are repaired; lexical changes remain distinct. */
internal fun deepLRequestText(text: String, source: String): String {
    var value = Normalizer.normalize(text, Normalizer.Form.NFKC)
        .replace('’', '\'').replace('‘', '\'').replace(Regex("\\s+"), " ").trim()
    if (source.substringBefore('-') != "en") return value
    value = value.replace(Regex("(?i)(?<![\\p{L}])[il]'[il|]{1,3}(?![\\p{L}|])"), "I'll")
        .replace(Regex("(?i)\\b[il]'(d|m|ve)\\b")) { "I'${it.groupValues[1].lowercase(Locale.ROOT)}" }
        .replace(Regex("(?i)\\bwwould(n't)?\\b")) { "would${it.groupValues[1]}" }
        .replace(Regex("(?i)\\b(don|isn|aren|wasn|weren|didn|doesn|haven|hasn|hadn|wouldn|couldn|shouldn|mustn|needn)t\\b")) {
            "${it.groupValues[1]}'t"
        }
        .replace(Regex("(?i)\\bim(?= [a-z]{3,}ing\\b)"), "I'm")
        // Repair missing apostrophes only in unambiguous verb contexts. Keep
        // real words such as "ill", "id" and the abbreviation "ID" intact.
        .replace(Regex("\\b(?:I|l)d(?= (?:be|have|come|go|like|rather|love|say|take|do|make)\\b)"), "I'd")
        .replace(Regex("\\b(?:I|l)[lI|]{2}(?= (?:call|go|be|have|take|get|come|see|tell|ask|do|make)\\b)"), "I'll")
        .replace(Regex("\\b([Ii]t|[Tt]hat)(ll|d)\\b")) { "${it.groupValues[1]}'${it.groupValues[2]}" }
    return value
}

internal fun deepLTextKey(text: String, source: String): String = deepLRequestText(text, source)
    .lowercase(Locale.ROOT).replace(Regex("[.!…,]+$"), "").trim()

/** Per visible subtitle, never a fuzzy lookup across unrelated past dialogue. */
internal class DeepLOcrPolicy(private val elapsedMillis: () -> Long = { System.nanoTime() / 1_000_000 }) {
    data class Read(val key: String, val text: String, val confidence: Float)
    private var anchor: Read? = null
    private var pending: Read? = null
    private var pendingReads = 0
    private var pendingSince = 0L
    private var newLine: Read? = null
    private var newLineReads = 0
    private val newLineCandidates = linkedMapOf<String, Pair<Read, Int>>()

    /** A different, unconfirmed line must not send a queued request for the old one. */
    val requestKey: String? get() = anchor?.key.takeIf { newLine == null }
    val hasPendingRead: Boolean get() = newLine != null || pending != null

    fun observe(text: String, confidence: Float, source: String, sampleIntervalMs: Long,
        corroborateInitialCandidate: Boolean = false): Read? {
        val now = elapsedMillis()
        val key = deepLTextKey(text, source)
        val next = Read(key, deepLRequestText(text, source), confidence)
        val previous = anchor
        if (previous == null) return confirmNewLine(next, sampleIntervalMs, corroborateInitialCandidate)
        if (equivalent(previous.key, key, source)) {
            pending = null
            pendingReads = 0
            clearNewLine()
            return previous
        }
        if (!nearVariant(previous.key, key)) return confirmNewLine(next, sampleIntervalMs, corroborateInitialCandidate)
        clearNewLine()
        if (pending?.key != key) {
            pending = next
            pendingReads = 1
            pendingSince = now
        } else {
            pendingReads++
            if (confidence > pending!!.confidence) pending = next
        }
        // Fast OCR needs three consistent reads; slow sampling must not add seconds.
        val required = if (sampleIntervalMs <= 100) 3 else if (sampleIntervalMs < 200) 2 else 1
        // Three reads can fit inside a 140 ms OCR glitch. Require a short real
        // stability interval before paying again for a near-identical spelling.
        val stableMillis = if (sampleIntervalMs < 200) 250L else 0L
        return if (pendingReads >= required && now - pendingSince >= stableMillis) accept(pending!!) else null
    }

    fun clear() { anchor = null; pending = null; pendingReads = 0; clearNewLine() }

    fun discardPending() { pending = null; pendingReads = 0; clearNewLine() }

    private fun confirmNewLine(next: Read, sampleIntervalMs: Long, corroborateInitialCandidate: Boolean): Read? {
        pending = null
        pendingReads = 0
        // Corroborating frames at high rates avoid buying the first noisy
        // fade-in spelling. Short dialogue and slow sampling remain immediate.
        if (next.key.length < 16 || sampleIntervalMs >= 200) return accept(next)
        val candidate = newLine
        if (candidate == null || (candidate.key != next.key && !nearVariant(candidate.key, next.key))) {
            newLine = next
            newLineReads = 1
            newLineCandidates.clear()
            newLineCandidates[next.key] = Pair(next, 1)
            return null
        }
        newLineReads++
        if (next.confidence >= candidate.confidence) newLine = next
        val seen = newLineCandidates[next.key]
        newLineCandidates[next.key] = Pair(if (seen == null || next.confidence >= seen.first.confidence) next else seen.first,
            (seen?.second ?: 0) + 1)
        if (newLineCandidates.size > 16) newLineCandidates.remove(newLineCandidates.keys.first())
        val required = if (sampleIntervalMs <= 100) 3 else 2
        // Preserve DeepL's measured OCR behavior. Gemini opts into the stricter
        // first-reading rule because its request/minute limit is much tighter.
        if (!corroborateInitialCandidate) return if (newLineReads >= required) accept(newLine!!) else null
        // A single high-confidence fade-in glitch must not win over a reading
        // actually seen twice. The reported "bed2!" frame previously did that.
        val corroborated = newLineCandidates.values.filter { it.second >= 2 }
            .maxWithOrNull(compareBy<Pair<Read, Int>> { it.second }.thenBy { it.first.confidence })?.first
        return if (newLineReads >= required && corroborated != null) accept(corroborated) else null
    }

    private fun clearNewLine() { newLine = null; newLineReads = 0; newLineCandidates.clear() }

    private fun accept(read: Read): Read {
        anchor = read
        pending = null
        pendingReads = 0
        clearNewLine()
        return read
    }

    private fun equivalent(left: String, right: String, source: String): Boolean {
        if (left == right) return true
        // Punctuation/word-spacing jitter is local to this visible subtitle.
        // Keep questions and apostrophes: "we'll" and "well" are different words.
        fun layoutKey(value: String) = value.replace(Regex("[.,…\\s]"), "")
            .replace(Regex("[\\p{Pd}]+$"), "")
        fun numbers(value: String) = Regex("\\d+(?:[.,]\\d+)*").findAll(value).map { it.value }.toList()
        if (min(left.length, right.length) >= 16 && numbers(left) == numbers(right) &&
            layoutKey(left) == layoutKey(right)) return true
        if (source.substringBefore('-') != "en" || min(left.length, right.length) < 60) return false
        // A disappearing isolated I in the reported long subtitle does not change its intent.
        // Compare to the original anchor every time so repeated OCR edits cannot drift.
        fun stable(value: String) = value.replace(Regex("\\band i know\\b"), "and know")
            .replace(Regex("\\bvith(?= (?:me|you|him|her|us|them|those|these)\\b)"), "with")
        return stable(left) == stable(right)
    }

    private fun nearVariant(left: String, right: String): Boolean {
        if (min(left.length, right.length) < 16) return false
        // An OCR glyph inside a word (gue9ssing) is not a changed quantity.
        fun numbers(value: String) = Regex("\\b\\d+\\b").findAll(value).map { it.value }.toList()
        if (numbers(left) != numbers(right)) return false
        // A stray colon in a damaged contraction (don': worry) is not a speaker.
        fun speaker(value: String) = value.substringBefore(":", "")
            .takeIf { it.matches(Regex("[\\p{L}][\\p{L}\\p{M} .-]{0,31}")) }.orEmpty()
        if (speaker(left) != speaker(right)) return false
        // A changed word/negation must still be translated once corroborated.
        // Do not treat a misspelled contraction as an entirely new sentence:
        // that previously let every Dont/Dort/Don't frame bypass confirmation.
        fun words(value: String) = Regex("[\\p{L}\\p{N}']+").findAll(value)
            .map { it.value }.filter { it.length > 2 }.toSet()
        val leftWords = words(left)
        val rightWords = words(right)
        if (leftWords.intersect(rightWords).size.toFloat() / leftWords.union(rightWords).size.coerceAtLeast(1) < .45f) return false
        // This is a confirmation gate, never a fuzzy cache hit. Larger OCR
        // damage must wait too; only exact, repeated candidates replace anchor.
        val limit = min(1_600, max(300, max(left.length, right.length) * 20))
        return ocrTextDistance(left, right, limit) <= limit
    }
}
