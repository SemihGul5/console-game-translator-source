package com.abrebostudio.consolegametranslator

import org.json.JSONObject
import java.util.Locale
import java.util.PriorityQueue
import java.text.Normalizer
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

internal data class GameTranslationMatch(
    val gameId: String,
    val entryId: String,
    val chapter: String?,
    val kind: String?,
    val speaker: String?,
    val source: String,
    val target: String,
    val score: Double,
    val matchType: String,
    val segmentIndex: Int? = null,
    val segmentCount: Int? = null,
)

/** Parsed once when a game is selected; OCR frames only query its in-memory indexes. */
internal class GameTranslationMemory private constructor(
    val gameId: String,
    val sourceLanguage: String,
    val targetLanguage: String,
    val entryCount: Int,
    val gameProfileJson: String?,
    private val entries: List<Entry>,
    private val alignedSpans: List<AlignedSpan>,
    private val speakerTranslations: Map<String, String>,
    private val exactIndex: Map<String, List<Entry>>,
    private val compactIndex: Map<String, List<Entry>>,
    private val trigramIndex: Map<String, PackedPostings>,
    private val spanLengthIndex: Map<Int, IntArray>,
    private val wordIndex: Map<String, PackedPostings>,
    private val lengthIndex: Map<Int, IntArray>,
) {
    private data class Entry(
        val type: String,
        val id: String,
        val chapter: String?,
        val kind: String?,
        val speaker: String?,
        val source: String,
        val target: String?,
        val normalizedSource: String,
        val words: List<String>,
        val segmentIndex: Int? = null,
        val segmentCount: Int? = null,
    ) {
        val meaning = meaningTokens(normalizedSource)
        val normalizedSpeaker = normalize(speaker.orEmpty())
    }

    // Keep ranges instead of duplicating every possible multi-sentence string.
    // Large JSON dictionaries include paragraphs as well as subtitle lines.
    private data class AlignedSpan(
        val parent: Entry,
        val sources: List<String>,
        val targets: List<String>,
        val start: Int,
        val end: Int,
        val normalizedLength: Int,
    ) {
        fun source() = sources.subList(start, end + 1).joinToString(" ")
        fun entry(): Entry {
            val source = source()
            val normalized = normalize(source)
            return parent.copy(source = source,
                target = targets.subList(start, end + 1).joinToString(" "),
                normalizedSource = normalized, words = normalized.split(' ').filter(String::isNotBlank),
                segmentIndex = start, segmentCount = sources.size)
        }
    }

    private data class RankedMatch(
        val entry: Entry,
        val score: Double,
        val similarity: Double,
        val tokenCoverage: Double,
        val sourceCoverage: Double,
        val partial: Boolean,
    )

    /** Index construction must not box millions of posting IDs as Integers. */
    private class IntPostings {
        private var values = IntArray(4)
        private var size = 0
        fun add(value: Int) {
            if (size == values.size) values = values.copyOf(size * 2)
            values[size++] = value
        }
        fun freeze(): IntArray = if (size == values.size) values else values.copyOf(size)
    }

    /** Posting IDs arrive sorted, so most deltas need one byte instead of four. */
    private class PackedPostings(private val bytes: ByteArray, val size: Int) {
        val byteSize get() = bytes.size
        operator fun iterator(): IntIterator = object : IntIterator() {
            private var offset = 0
            private var previous = 0
            override fun hasNext() = offset < bytes.size
            override fun nextInt(): Int {
                if (!hasNext()) throw NoSuchElementException()
                var delta = 0
                var shift = 0
                do {
                    val value = bytes[offset++].toInt() and 255
                    delta = delta or ((value and 127) shl shift)
                    shift += 7
                } while (value and 128 != 0)
                previous += delta
                return previous
            }
        }
    }

    private class PackedPostingsBuilder {
        private var bytes = ByteArray(8)
        private var length = 0
        private var previous = 0
        private var count = 0
        fun add(index: Int) {
            if (count > 0 && index == previous) return
            var delta = index - previous
            previous = index
            count++
            do {
                if (length == bytes.size) bytes = bytes.copyOf(length * 2)
                bytes[length++] = ((delta and 127) or if (delta >= 128) 128 else 0).toByte()
                delta = delta ushr 7
            } while (delta != 0)
        }
        fun freeze() = PackedPostings(bytes.copyOf(length), count)
    }

    private val availableMeanings = entries.mapTo(HashSet()) { it.meaning }
    private val gramVotes = IntArray(entries.size)
    private data class SearchKey(val query: String, val speaker: String?)
    private inner class SearchWork(val query: String, val speaker: String?) {
        val words by lazy { collectWordCandidateIndices(query) }
        val context by lazy { oneWordContext(query, speaker) }
        val wholeRowMatch by lazy {
            val wordCount = query.count { it == ' ' } + 1
            // Compare complete rows separately from their aligned fragments;
            // an observed ending can also prove joined/split OCR words complete.
            rankCandidates(query, speaker, words.filter { index ->
                val entry = entries[index]
                (entry.segmentIndex == null || entry.segmentCount == 1) &&
                    (entry.words.size == wordCount || hasWholeRowEnding(query, entry.normalizedSource))
            })
        }
        val wordMatch by lazy { rankCandidates(query, speaker, words) }
        val allMatch by lazy { rankCandidates(query, speaker, collectCandidateIndices(query, words)) }
    }
    private val searches = HashMap<SearchKey, SearchWork>()
    private fun search(query: String, speaker: String?) =
        searches.getOrPut(SearchKey(query, speaker)) { SearchWork(query, speaker) }

    private val lookupCache = object : LinkedHashMap<String, GameTranslationMatch?>(32, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, GameTranslationMatch?>?) = size > 64
    }

    // Conservative cache weight; includes duplicated sentence/span strings and postings.
    internal val estimatedRetainedBytes: Long =
        entries.sumOf { entry ->
            192L + 2L * (entry.source.length + entry.target.orEmpty().length + entry.normalizedSource.length +
                entry.normalizedSpeaker.length + entry.words.sumOf { it.length }) + 32L * entry.words.size
        } + 64L * alignedSpans.size + compactIndex.entries.sumOf { (key, values) -> 96L + 2L * key.length + 8L * values.size } +
            exactIndex.entries.sumOf { (_, values) -> 80L + 8L * values.size } +
            trigramIndex.entries.sumOf { (key, values) -> 112L + 2L * key.length + values.byteSize } +
            wordIndex.entries.sumOf { (key, values) -> 112L + 2L * key.length + values.byteSize } +
            spanLengthIndex.values.sumOf { 64L + 4L * it.size } + lengthIndex.values.sumOf { 64L + 4L * it.size }

    fun find(ocrText: String): GameTranslationMatch? = synchronized(lookupCache) {
        if (lookupCache.containsKey(ocrText)) return@synchronized lookupCache[ocrText]
        findUncached(ocrText).also { lookupCache[ocrText] = it }
    }

    /** Cheap exact probes let clean OCR blocks win before any fuzzy search. */
    fun findExact(ocrText: String): GameTranslationMatch? = synchronized(lookupCache) {
        lookupCache[ocrText]?.takeIf { it.matchType == "exact" || it.matchType == "spacing_exact" }
            ?.let { return@synchronized it }
        val query = prepareQuery(ocrText)
        val match = findExactNormalized(normalize(query.body), query.speaker)
            ?: query.speaker?.let { findExactNormalized(normalize("$it: ${query.body}"), null) }
        withDisplaySpeaker(match, query.speaker)?.also { lookupCache[ocrText] = it }
    }

    private data class QueryText(val body: String, val speaker: String?)

    fun rejectionReason(ocrText: String): String {
        val text = prepareQuery(ocrText)
        val query = normalize(text.body)
        val exact = exactIndex[query].orEmpty().filter { speakerMatches(it, text.speaker) }
        return when {
            query.isEmpty() -> "empty"
            exact.isNotEmpty() && equivalentOutput(exact) == null -> "ambiguous_exact"
            !isSafeExactQuery(query) -> "short_not_exact"
            else -> "not_found"
        }
    }

    private fun prepareQuery(ocrText: String): QueryText {
        val prefix = SPEAKER_PREFIX.find(ocrText) ?: return QueryText(ocrText, null)
        val label = normalize(prefix.groupValues[1])
        val speaker = if (speakerTranslations.containsKey(label)) label else {
            speakerTranslations.keys.filter { candidate ->
                label.length >= 3 && kotlin.math.abs(candidate.length - label.length) <= 1 &&
                    editDistance(candidate, label, 1) <= 1
            }.singleOrNull()
        }
        return if (speaker == null) QueryText(ocrText, null)
            else QueryText(ocrText.substring(prefix.range.last + 1).trimStart(' ', '/', '|', 92.toChar()), speaker)
    }

    private fun withDisplaySpeaker(match: GameTranslationMatch?, speaker: String?): GameTranslationMatch? =
        if (match == null || speaker == null) match else match.copy(speaker = speakerTranslations[speaker] ?: match.speaker)

    private fun speakerMatches(entry: Entry, expected: String?) =
        expected == null || entry.normalizedSpeaker.isEmpty() || entry.normalizedSpeaker == expected

    private fun findUncached(ocrText: String): GameTranslationMatch? {
        try {
            val query = prepareQuery(ocrText)
            val match = findBody(query.body, query.speaker)
                ?: query.speaker?.let { findBody("$it: ${query.body}", null) }
            return withDisplaySpeaker(match, query.speaker)
        } finally { searches.clear() }
    }

    private fun findBody(bodyText: String, expectedSpeaker: String?): GameTranslationMatch? {
        val query = normalize(bodyText)
        findExactNormalized(query, expectedSpeaker)?.let { return it }
        if (exactIndex[query].orEmpty().any { speakerMatches(it, expectedSpeaker) }) return null

        // A strongly matched whole row must win before sentence splitting:
        // a short damaged opening ("Yyan.") is not an unmatched new subtitle.
        // A joined word or a lost short token can change the word count. Require
        // the actual row ending and near-full character coverage in that case.
        if (isSafeExactQuery(query) && canContainMeaning(query)) {
            val work = search(query, expectedSpeaker)
            val context = work.context
            if (context.match != null || context.ambiguous) return context.match
            val fullRow = work.wholeRowMatch
            if (fullRow != null && fullRow.matchType == "fuzzy") {
                val normalizedSource = normalize(fullRow.source)
                val sameWordCount = normalizedSource.count { it == ' ' } == query.count { it == ' ' }
                val observedEnding = hasWholeRowEnding(query, normalizedSource)
                if ((fullRow.score >= 0.99 && sameWordCount) ||
                    (fullRow.score >= 0.985 && observedEnding && !isBetterVisiblePrefix(query, normalizedSource))) {
                    return fullRow.copy(matchType = "full_row_fuzzy")
                }
            }
        }

        val (completeSentences, trailingText) = splitCompleteSentences(bodyText)
        if (completeSentences.isNotEmpty()) {
            if (completeSentences.size > 1 || trailingText.isNotEmpty()) {
                findAlignedSentenceSequence(completeSentences, expectedSpeaker, trailingText)?.let { return it }
            }
            // A visible prefix cannot reveal the translation of a later sentence.
            if (trailingText.isNotEmpty()) return findAlignedSpan(query, expectedSpeaker)
        }
        // Common single lines use the indexed search before span reconstruction.
        return findNormalized(query, expectedSpeaker)
            ?: if (completeSentences.isNotEmpty()) findAlignedSpan(query, expectedSpeaker) else null
    }

    /** Spaces may join/split, but a later sentence must already be visible. */
    private fun hasWholeRowEnding(query: String, source: String): Boolean {
        if (query.length < 32 || query.count { it == ' ' } < 4) return false
        val compactQuery = query.replace(" ", "")
        val compactSource = source.replace(" ", "")
        if (kotlin.math.abs(compactQuery.length - compactSource.length) > max(2, compactSource.length * 6 / 100)) return false
        val ending = source.split(' ').takeLast(3).joinToString("")
        return ending.length >= 8 && compactQuery.endsWith(ending)
    }

    /** A repeated ending is not proof that the next identical sentence is visible. */
    private fun isBetterVisiblePrefix(query: String, source: String): Boolean {
        val compactQuery = query.replace(" ", "")
        val compactSource = source.replace(" ", "")
        if (compactQuery.length >= compactSource.length) return false
        val limit = max(compactQuery.length, compactSource.length) * 10
        val wholeCost = ocrTextDistance(compactQuery, compactSource, limit)
        val prefixCost = ocrTextDistance(compactQuery, compactSource.take(compactQuery.length), limit)
        return prefixCost <= wholeCost
    }

    /** Recover lost OCR sentence boundaries without revealing unseen sentences. */
    private fun findAlignedSpan(query: String, expectedSpeaker: String?): GameTranslationMatch? {
        if (query.length < MIN_PARTIAL_QUERY_LENGTH) return null
        val meaning = meaningTokens(query)
        val radius = max(3, query.length / 10)
        val nearbySpans = (query.length - radius..query.length + radius).asSequence()
            .flatMap { length -> spanLengthIndex[length]?.asSequence() ?: emptySequence() }
            .map { alignedSpans[it] }
        val ranked = nearbySpans.filter { span ->
            speakerMatches(span.parent, expectedSpeaker)
        }.mapNotNull { span ->
            val normalized = normalize(span.source())
            if (meaningTokens(normalized) != meaning) return@mapNotNull null
            val maxLength = max(query.length, normalized.length)
            val limit = maxLength * 8 / 100
            if (kotlin.math.abs(query.length - normalized.length) > limit) return@mapNotNull null
            val similarity = 1.0 - editDistance(query, normalized, limit).toDouble() / maxLength
            if (similarity < 0.92 || tokenCoverage(query.split(' '), normalized.split(' ')) < 0.85) null
            else span to similarity
        }.sortedByDescending { it.second }.take(2).toList()
        val best = ranked.firstOrNull() ?: return null
        if (ranked.size > 1 && best.second - ranked[1].second < 0.05) return null
        return best.first.entry().toMatch(best.second, "sentence_span_fuzzy")
    }

    private fun findExactNormalized(
        query: String,
        expectedSpeaker: String?,
    ): GameTranslationMatch? {
        if (query.length < 2 || query.none(Char::isLetterOrDigit)) return null
        val exact = exactIndex[query].orEmpty().filter { entry ->
            speakerMatches(entry, expectedSpeaker)
        }
        if (exact.isNotEmpty()) {
            // Localisation IDs and aligned sentences can share the same output.
            // A consensus is safe; conflicting translations are still rejected.
            val entry = equivalentOutput(exact) ?: return null
            return entry.toMatch(1.0, "exact")
        }
        // Resolve OCR word joins in O(1), but only for the complete character
        // sequence of one unique source/aligned sentence, never a parent prefix.
        val wordCount = query.count { it == ' ' } + 1
        if (query.length >= 12 && wordCount >= 2) {
            val compact = compactIndex[query.replace(" ", "")].orEmpty()
            if (compact.isNotEmpty()) {
                val meaning = meaningTokens(query)
                val compatible = compact.filter { entry ->
                    entry.meaning == meaning && entry.words.size >= wordCount &&
                        (speakerMatches(entry, expectedSpeaker))
                }
                equivalentOutput(compatible)?.let { return it.toMatch(1.0, "spacing_exact") }
            }
        }
        return null
    }

    private fun equivalentOutput(candidates: List<Entry>): Entry? {
        val first = candidates.firstOrNull() ?: return null
        if (candidates.any { it.target != first.target || it.normalizedSpeaker != first.normalizedSpeaker }) return null
        return candidates.firstOrNull { it.segmentCount == 1 || it.segmentCount == null } ?: first
    }

    private fun findNormalized(
        query: String,
        expectedSpeaker: String?,
    ): GameTranslationMatch? {
        if (!isSafeExactQuery(query)) return null
        findExactNormalized(query, expectedSpeaker)?.let { return it }

        if (exactIndex[query].orEmpty().any { speakerMatches(it, expectedSpeaker) }) return null
        if (!canContainMeaning(query)) return null
        val work = search(query, expectedSpeaker)
        val fast = work.wordMatch
        if (fast?.matchType == "fuzzy" && fast.score >= 0.985) return fast
        val context = work.context
        if (context.match != null || context.ambiguous) return context.match
        return work.allMatch
    }

    private data class ContextAttempt(val match: GameTranslationMatch?, val ambiguous: Boolean = false)

    /** One unreadable word may be recovered from unique, otherwise exact context. */
    private fun oneWordContext(query: String, speaker: String?): ContextAttempt {
        val words = query.split(' ')
        if (words.size < 4) return ContextAttempt(null)
        val unknown = words.indices.filter { words[it].length >= 3 && !wordIndex.containsKey(words[it]) }
        if (unknown.size > 1 || (unknown.isEmpty() && words.size < 5)) return ContextAttempt(null)
        val gap = unknown.singleOrNull()
        // Two rare anchors keep a real-but-wrong OCR word from hiding the row:
        // with one wrong word, at least one anchor must still be correct.
        val anchors = words.indices.filter { it != gap && wordIndex.containsKey(words[it]) }
            .sortedBy { wordIndex.getValue(words[it]).size }.take(if (gap == null) 2 else 1)
        if (anchors.isEmpty()) return ContextAttempt(null)
        val meaning = meaningTokens(query)
        val embeddedNumbers = embeddedOcrNumbersOnly(query)
        val candidates = ArrayList<Entry>()
        for ((anchorAt, anchor) in anchors.withIndex()) for (index in wordIndex.getValue(words[anchor])) {
            val entry = entries[index]
            if (anchorAt > 0 && words[anchors[0]] in entry.words) continue
            if (entry.words.size != words.size || !speakerMatches(entry, speaker)) continue
            var changed = -1
            var different = false
            for (i in words.indices) if (words[i] != entry.words[i]) {
                if (changed >= 0) { different = true; break }; changed = i
            }
            if (different || changed < 0) continue
            if ((gap != null && changed != gap) || words[changed].length < 3 || entry.words[changed].length < 3) continue
            // The unreadable slot itself could be a missing negation or number.
            if (entry.meaning != meaning && !(embeddedNumbers && entry.meaning.numbers.isEmpty() &&
                    entry.meaning.negated == meaning.negated)) return ContextAttempt(null, ambiguous = true)
            candidates.add(entry)
        }
        if (candidates.isEmpty()) return ContextAttempt(null)
        val selected = equivalentOutput(candidates) ?: return ContextAttempt(null, ambiguous = true)
        return ContextAttempt(selected.toMatch(1.0 - 1.0 / words.size, "one_word_context"))
    }

    private fun rankCandidates(query: String, expectedSpeaker: String?, candidates: List<Int>): GameTranslationMatch? {
        val queryWords = query.split(' ').filter(String::isNotBlank)
        val meaning = meaningTokens(query)
        val embeddedNumbers = embeddedOcrNumbersOnly(query)
        val ocrNegation = !meaning.negated && hasOcrNegation(query)

        val ranked = candidates.mapNotNull { index ->
            val entry = entries[index]
            if (!((meaning.numbers == entry.meaning.numbers || (entry.meaning.numbers.isEmpty() && embeddedNumbers)) &&
                    (meaning.negated == entry.meaning.negated || (!meaning.negated && entry.meaning.negated && ocrNegation))) ||
                !speakerMatches(entry, expectedSpeaker)) {
                return@mapNotNull null
            }
            val source = entry.normalizedSource
            if (source == query) return@mapNotNull null

            val partial = source.length > query.length * 1.10
            // A partial OCR may only reveal an aligned sentence, never its parent.
            if (partial && entry.segmentCount == null) return@mapNotNull null
            val sourceCoverage = (query.length.toDouble() / source.length).coerceIn(0.0, 1.0)
            if (partial && (query.length < MIN_PARTIAL_QUERY_LENGTH || queryWords.size < MIN_PARTIAL_WORDS ||
                    sourceCoverage < minimumPartialSourceCoverage(query.length, queryWords.size))) return@mapNotNull null
            val maxLength = max(query.length, source.length)
            val similarity = if (partial) {
                1.0 - substringEditDistance(query, source).toDouble() / query.length
            } else {
                val limit = (maxLength * (1.0 - MIN_FULL_SIMILARITY) * 100).toInt()
                val cost = ocrTextDistance(query, source, limit)
                if (cost > limit) return@mapNotNull null
                1.0 - cost.toDouble() / (maxLength * 100)
            }.coerceIn(0.0, 1.0)
            if (partial && similarity < MIN_PARTIAL_SIMILARITY) return@mapNotNull null
            val tokenCoverage = tokenCoverage(queryWords, entry.words)
            if (tokenCoverage < if (partial) MIN_PARTIAL_TOKEN_COVERAGE else MIN_FULL_TOKEN_COVERAGE) return@mapNotNull null
            val score = if (partial) {
                0.64 + 0.20 * similarity + 0.07 * tokenCoverage + 0.09 * sourceCoverage
            } else {
                0.82 + 0.18 * similarity
            }
            RankedMatch(entry, score, similarity, tokenCoverage, sourceCoverage, partial)
        }.sortedByDescending(RankedMatch::score)

        val best = ranked.firstOrNull() ?: return null
        val secondScore = ranked.drop(1).firstOrNull {
            it.entry.target != best.entry.target || it.entry.normalizedSpeaker != best.entry.normalizedSpeaker
        }?.score ?: 0.0
        // Full scores compress similarity into a 0.18 range. Compare the actual
        // similarity margin, rather than demanding an impossible 0.075 score gap.
        val scoreGap = (best.score - secondScore) / if (best.partial) 1.0 else 0.18
        val accepted = if (best.partial) {
            query.length >= MIN_PARTIAL_QUERY_LENGTH &&
                queryWords.size >= MIN_PARTIAL_WORDS &&
                best.similarity >= MIN_PARTIAL_SIMILARITY &&
                best.tokenCoverage >= MIN_PARTIAL_TOKEN_COVERAGE &&
                best.sourceCoverage >= minimumPartialSourceCoverage(query.length, queryWords.size) &&
                scoreGap >= MIN_PARTIAL_SCORE_GAP
        } else {
            query.length >= MIN_FUZZY_QUERY_LENGTH &&
                queryWords.size >= MIN_FUZZY_WORDS &&
                best.similarity >= MIN_FULL_SIMILARITY &&
                best.tokenCoverage >= MIN_FULL_TOKEN_COVERAGE &&
                scoreGap >= MIN_FULL_SCORE_GAP
        }
        if (!accepted) return null
        return best.entry.toMatch(best.score, if (best.partial) "partial" else "fuzzy")
    }

    private fun collectWordCandidateIndices(query: String): List<Int> {
        val words = query.split(' ')
        val partial = query.length >= MIN_PARTIAL_QUERY_LENGTH && words.size >= MIN_PARTIAL_WORDS
        val maxLength = if (partial) (query.length / minimumPartialSourceCoverage(query.length, words.size)).toInt()
            else (query.length / MIN_FULL_SIMILARITY).toInt()
        val minLength = ceil(query.length * MIN_FULL_SIMILARITY).toInt()
        val votes = gramVotes
        val touched = IntPostings()
        val rare = words.filter { it.length >= 3 && wordIndex.containsKey(it) }.distinct()
            .sortedBy { wordIndex.getValue(it).size }.take(6)
        for (word in rare) for (index in wordIndex.getValue(word)) {
            val entry = entries[index]
            if (entry.normalizedSource.length in minLength..maxLength &&
                (entry.normalizedSource.length <= query.length * 1.10 || entry.segmentCount != null)) {
                if (votes[index]++ == 0) touched.add(index)
            }
        }
        return topCandidates(touched.freeze(), votes, query.length)
    }

    private fun topCandidates(touched: IntArray, votes: IntArray, length: Int, minimum: Int = 1): List<Int> {
        val order = compareByDescending<Int> { votes[it] }
            .thenBy { kotlin.math.abs(entries[it].normalizedSource.length - length) }.thenBy { it }
        val top = PriorityQueue(96, order.reversed())
        for (index in touched) if (votes[index] >= minimum) {
            if (top.size < 96) top.add(index)
            else if (order.compare(index, top.peek()) < 0) { top.poll(); top.add(index) }
        }
        val result = top.sortedWith(order)
        for (index in touched) votes[index] = 0
        return result
    }

    private fun collectCandidateIndices(query: String, wordCandidates: List<Int>): List<Int> {
        val words = query.split(' ')
        val partialAllowed = query.length >= MIN_PARTIAL_QUERY_LENGTH && words.size >= MIN_PARTIAL_WORDS
        val minimumLength = ceil(query.length * MIN_FULL_SIMILARITY).toInt()
        val maximumLength = if (partialAllowed) {
            (query.length / minimumPartialSourceCoverage(query.length, words.size)).toInt()
        } else (query.length / MIN_FULL_SIMILARITY).toInt()
        fun eligible(index: Int): Boolean {
            val entry = entries[index]
            return entry.normalizedSource.length in minimumLength..maximumLength &&
                (entry.normalizedSource.length <= query.length * 1.10 || entry.segmentCount != null)
        }
        val grams = trigrams(query)
        val counts = gramVotes
        val touched = IntPostings()
        for (gram in grams) {
            val posting = trigramIndex[gram] ?: continue
            for (index in posting) {
                if (!eligible(index)) continue
                if (counts[index]++ == 0) touched.add(index)
            }
        }
        val minSharedGrams = max(2, ceil(grams.size * 0.22).toInt())
        // If source.contains(query), all query trigrams already occur in source.
        // A second O(dictionary size) substring scan cannot add another candidate.
        val gramCandidates = topCandidates(touched.freeze(), counts, query.length, minSharedGrams)
        val candidates = LinkedHashSet<Int>()
        candidates.addAll(wordCandidates)
        candidates.addAll(gramCandidates)
        if (words.size <= 1) for (length in minimumLength..maximumLength) {
            for (index in lengthIndex[length] ?: IntArray(0)) {
                if (candidates.size >= 192) break
                candidates.add(index)
            }
        }
        return candidates.toList()
    }

    private fun canContainMeaning(query: String): Boolean {
        val meaning = meaningTokens(query)
        if (meaning in availableMeanings) return true
        val numbers = if (embeddedOcrNumbersOnly(query)) emptyList() else meaning.numbers
        return meaning.copy(numbers = numbers) in availableMeanings ||
            (!meaning.negated && hasOcrNegation(query) && meaning.copy(numbers = numbers, negated = true) in availableMeanings)
    }

    private fun findAlignedSentenceSequence(
        sentences: List<String>,
        expectedSpeaker: String?,
        trailingText: String,
    ): GameTranslationMatch? {
        val matches = ArrayList<GameTranslationMatch>()
        for (sentence in sentences) {
            val match = findNormalized(normalize(sentence), expectedSpeaker) ?: return null
            if (match.segmentIndex == null || match.segmentCount == null) return null
            val previous = matches.lastOrNull()
            if (previous != null &&
                (match.gameId != previous.gameId ||
                    match.entryId != previous.entryId ||
                    match.speaker != previous.speaker ||
                    match.segmentCount != previous.segmentCount ||
                    match.segmentIndex != previous.segmentIndex?.plus(1))) {
                return null
            }
            matches.add(match)
        }

        var partialTailMatched = false
        val previous = matches.lastOrNull()
        if (trailingText.isNotEmpty() && previous?.segmentIndex != null) {
            val tailMatch = findNormalized(normalize(trailingText), expectedSpeaker)
            if (tailMatch != null &&
                tailMatch.gameId == previous.gameId &&
                tailMatch.entryId == previous.entryId &&
                tailMatch.speaker == previous.speaker &&
                tailMatch.segmentCount == previous.segmentCount &&
                tailMatch.segmentIndex == previous.segmentIndex + 1) {
                matches.add(tailMatch)
                partialTailMatched = tailMatch.matchType == "partial"
            }
        }
        val first = matches.firstOrNull() ?: return null
        return first.copy(
            source = matches.joinToString(" ") { it.source.trim() },
            target = matches.joinToString(" ") { it.target.trim() },
            score = matches.minOf(GameTranslationMatch::score),
            matchType = when {
                partialTailMatched -> "sentence_partial_tail"
                matches.any { it.matchType == "partial" } -> "sentence_partial"
                trailingText.isNotEmpty() -> "sentence_prefix"
                else -> "sentence_sequence"
            },
        )
    }

    private fun Entry.toMatch(score: Double, matchType: String) = GameTranslationMatch(
        gameId = gameId,
        entryId = id,
        chapter = chapter,
        kind = kind,
        speaker = speaker,
        source = source,
        target = target.orEmpty(),
        score = score.coerceIn(0.0, 1.0),
        matchType = matchType,
        segmentIndex = segmentIndex,
        segmentCount = segmentCount,
    )

    companion object {
        private data class MeaningTokens(val numbers: List<String>, val negated: Boolean)
        private val NUMBER = Regex("""\p{N}+""")
        private val NEGATIONS = setOf("no", "not", "never", "nothing", "nobody", "nowhere", "neither", "nor", "without", "aint",
            "dont", "doesnt", "didnt", "isnt", "arent", "wasnt", "werent", "wont", "wouldnt", "couldnt", "shouldnt",
            "cant", "cannot", "havent", "hasnt", "hadnt", "mustnt")
        private val NEGATION_STEMS = NEGATIONS.filter { it.endsWith("nt") }.map { it.dropLast(1) }.toSet()
        private val APOSTROPHIZED_NEGATION = Regex("""\b([\p{L}]{1,24})['‘’ʼ]t""")
        private fun meaningTokens(value: String): MeaningTokens {
            val words = value.split(' ')
            val negated = words.any { it in NEGATIONS } ||
                words.zipWithNext().any { (left, right) -> right == "t" && left + right in NEGATIONS }
            return MeaningTokens(NUMBER.findAll(value).map { it.value }.toList(), negated)
        }
        private fun embeddedOcrNumbersOnly(value: String): Boolean {
            val tokens = value.split(' ').filter { it.any(Char::isDigit) }
            return tokens.isNotEmpty() && tokens.all { it.count(Char::isLetter) >= 2 && it.all(Char::isLetterOrDigit) }
        }
        private fun hasOcrNegation(value: String): Boolean = value.split(' ').any { word ->
            word.length in 3..8 && word !in NEGATIONS &&
                (word.any(Char::isDigit) || "ri" in word || "rn" in word) &&
                NEGATIONS.any { negation -> ocrTextDistance(word, negation, 40) <= 40 }
        }
        private const val MIN_PARTIAL_QUERY_LENGTH = 24
        private const val MIN_PARTIAL_WORDS = 5
        private const val MIN_PARTIAL_SIMILARITY = 0.84
        private const val MIN_PARTIAL_TOKEN_COVERAGE = 0.75
        private const val MIN_PARTIAL_SCORE_GAP = 0.055
        private const val MIN_FUZZY_QUERY_LENGTH = 12
        private const val MIN_FUZZY_WORDS = 2
        private const val MIN_FULL_SIMILARITY = 0.86
        private const val MIN_FULL_TOKEN_COVERAGE = 0.70
        private const val MIN_FULL_SCORE_GAP = 0.075

        private fun minimumPartialSourceCoverage(queryLength: Int, wordCount: Int): Double = when {
            queryLength >= 56 && wordCount >= 9 -> 0.38
            queryLength >= 32 && wordCount >= 7 -> 0.48
            else -> 0.58
        }

        fun parse(
            gameId: String,
            sourceLanguage: String,
            targetLanguage: String,
            json: String,
        ): GameTranslationMemory {
            val (allEntries, speakerTranslations, gameProfileJson) = readEntries(json, sourceLanguage, targetLanguage)

            val matchableEntries = ArrayList<Entry>()
            val alignedSpans = ArrayList<AlignedSpan>()
            val indexedTranslations = HashSet<Triple<String, String?, String?>>()
            allEntries.forEach { entry ->
                if (entry.normalizedSource.isEmpty() || entry.target.isNullOrBlank()) {
                    return@forEach
                }
                // Localisation tables repeat identical text under different IDs.
                // Keep every file record, but index the same translation once.
                if (!indexedTranslations.add(Triple(entry.normalizedSource, entry.target, entry.speaker))) {
                    return@forEach
                }
                val sourceSentences = splitSentences(entry.source)
                if (sourceSentences.size == 1) {
                    matchableEntries.add(entry.copy(segmentIndex = 0, segmentCount = 1))
                    return@forEach
                } else {
                    matchableEntries.add(entry)
                }
                val targetSentences = splitSentences(entry.target)
                if (sourceSentences.size <= 1 || sourceSentences.size != targetSentences.size) {
                    return@forEach
                }
                val normalizedSentences = sourceSentences.map(::normalize)
                sourceSentences.indices.forEach { sentenceIndex ->
                    val sentenceSource = sourceSentences[sentenceIndex]
                    val sentenceTarget = targetSentences[sentenceIndex]
                    val normalizedSentence = normalizedSentences[sentenceIndex]
                    if (normalizedSentence.isNotEmpty() && sentenceTarget.isNotBlank()) {
                        matchableEntries.add(
                            entry.copy(
                                source = sentenceSource,
                                target = sentenceTarget,
                                normalizedSource = normalizedSentence,
                                words = normalizedSentence.split(' ').filter(String::isNotBlank),
                                segmentIndex = sentenceIndex,
                                segmentCount = sourceSentences.size,
                            ),
                        )
                    }
                }
                // Index only aligned, complete sentences. A visible prefix can
                // resolve without adding a later sentence such as "Ciao, Gaspare."
                sourceSentences.indices.forEach { start ->
                    val last = min(sourceSentences.lastIndex, start + 5)
                    var normalizedLength = normalizedSentences[start].length
                    for (end in start + 1..last) {
                        val added = normalizedSentences[end].length
                        if (added > 0) normalizedLength += added + if (normalizedLength > 0) 1 else 0
                        if (start == 0 && end == sourceSentences.lastIndex) continue
                        alignedSpans.add(AlignedSpan(entry, sourceSentences, targetSentences,
                            start, end, normalizedLength))
                    }
                }
            }
            val exact = HashMap<String, MutableList<Entry>>()
            val gramLists = HashMap<String, PackedPostingsBuilder>()
            val wordLists = HashMap<String, PackedPostingsBuilder>()
            matchableEntries.forEachIndexed { index, entry ->
                exact.getOrPut(entry.normalizedSource, ::mutableListOf).add(entry)
                for (at in 0..entry.normalizedSource.length - 3) {
                    val gram = entry.normalizedSource.substring(at, at + 3)
                    gramLists.getOrPut(gram, ::PackedPostingsBuilder).add(index)
                }
                for (word in entry.words) if (word.length >= 3) {
                    wordLists.getOrPut(word, ::PackedPostingsBuilder).add(index)
                }
            }
            val frozenGrams = freezePackedPostings(gramLists)
            val frozenWords = freezePackedPostings(wordLists)
            return GameTranslationMemory(
                gameId = gameId,
                sourceLanguage = sourceLanguage,
                targetLanguage = targetLanguage,
                entryCount = allEntries.size,
                gameProfileJson = gameProfileJson,
                entries = matchableEntries,
                alignedSpans = alignedSpans,
                speakerTranslations = speakerTranslations,
                exactIndex = exact,
                compactIndex = matchableEntries.groupBy { it.normalizedSource.replace(" ", "") },
                trigramIndex = frozenGrams,
                spanLengthIndex = lengthPostings(alignedSpans.size) { alignedSpans[it].normalizedLength },
                wordIndex = frozenWords,
                lengthIndex = lengthPostings(matchableEntries.size) { matchableEntries[it].normalizedSource.length },
            )
        }

        private fun freezePackedPostings(builders: MutableMap<String, PackedPostingsBuilder>): Map<String, PackedPostings> {
            val result = HashMap<String, PackedPostings>(builders.size)
            val iterator = builders.entries.iterator()
            while (iterator.hasNext()) {
                val item = iterator.next()
                result[item.key] = item.value.freeze()
                iterator.remove()
            }
            return result
        }

        private fun <K> freezePostings(builders: MutableMap<K, IntPostings>): Map<K, IntArray> {
            val result = HashMap<K, IntArray>(builders.size)
            val iterator = builders.entries.iterator()
            while (iterator.hasNext()) {
                val item = iterator.next()
                result[item.key] = item.value.freeze()
                iterator.remove()
            }
            return result
        }

        private fun lengthPostings(size: Int, length: (Int) -> Int): Map<Int, IntArray> {
            val builders = HashMap<Int, IntPostings>()
            for (index in 0 until size) builders.getOrPut(length(index), ::IntPostings).add(index)
            return freezePostings(builders)
        }

        private fun readEntries(json: String, sourceLanguage: String, targetLanguage: String): Triple<ArrayList<Entry>, Map<String, String>, String?> {
            val ids = HashSet<String>()
            val allEntries = ArrayList<Entry>()
            val pack = JSONObject(json.removePrefix("\uFEFF"))
            val version = pack.opt("schemaVersion") ?: 1
            require(version == 1 || version == 2) { "Oyun JSON schemaVersion geçersiz." }
            require(version == 2 || sourceLanguage == "en" && targetLanguage == "tr") { "english/turkish biçimi yalnızca İngilizce → Türkçe içindir." }
            require(!pack.requiredText("game").isBlank() &&
                pack.opt("source") == sourceLanguage && pack.opt("target") == targetLanguage) {
                "Oyun JSON dil bilgileri geçersiz."
            }
            val values = pack.getJSONArray("entries")
            require(!pack.has("gameProfile") || pack.isNull("gameProfile") || pack.opt("gameProfile") is JSONObject) {
                "Oyun JSON: gameProfile nesne olmalı."
            }
            require(values.length() > 0) { "Oyun JSON entries listesi boş." }
            for (index in 0 until values.length()) {
                val value = values.getJSONObject(index)
                val id = value.requiredText("id")
                if (!ids.add(id)) {
                    throw IllegalArgumentException("JSON entries[$index]: yinelenen ID $id.")
                }
                require(if (version == 2) !value.has("english") && !value.has("turkish") else !value.has("sourceText") && !value.has("targetText")) { "Oyun JSON biçimleri karıştırılamaz." }
                val source = value.requiredText(if (version == 2) "sourceText" else "english").replace(DELAY_DIRECTIVE, "")
                val target = value.requiredText(if (version == 2) "targetText" else "turkish").replace(DELAY_DIRECTIVE, "")
                require(!value.has("speaker") || value.isNull("speaker") || value.opt("speaker") is String) {
                    "JSON entries[$index]: speaker metin olmalı."
                }
                val normalized = normalize(source)
                allEntries.add(
                    Entry(
                        type = "entry",
                        id = id,
                        chapter = value.optionalString("chapter"),
                        kind = value.optionalString("kind"),
                        speaker = value.optionalString("speaker"),
                        source = source,
                        target = target,
                        normalizedSource = normalized,
                        words = normalized.split(' ').filter(String::isNotBlank),
                    ),
                )
            }
            val speakers = LinkedHashMap<String, String>()
            if (pack.has("speakers")) {
                val names = pack.getJSONObject("speakers")
                for (name in names.keys()) {
                    val translated = names.requiredText(name)
                    val key = normalize(name)
                    require(key.isNotEmpty()) { "Oyun JSON: konuşmacı adı boş olamaz." }
                    speakers[key] = translated
                }
            }
            for (entry in allEntries) {
                entry.speaker?.let { speakers.putIfAbsent(normalize(it), it) }
            }
            return Triple(allEntries, speakers, pack.optJSONObject("gameProfile")?.toString())
        }

        private fun JSONObject.requiredText(key: String): String =
            (opt(key) as? String)?.takeIf(String::isNotBlank)
                ?: throw IllegalArgumentException("Oyun JSON: $key dolu metin olmalı.")

        private fun JSONObject.optionalString(key: String): String? {
            if (!has(key) || isNull(key)) return null
            return optString(key).takeIf(String::isNotBlank)
        }

        private fun normalize(value: String): String {
            if (value.isEmpty()) return ""
            val lower = value.lowercase(Locale.ROOT)
            val raw = if (lower.any { it.code > 127 })
                Normalizer.normalize(lower, Normalizer.Form.NFD).filter { Character.getType(it) != Character.NON_SPACING_MARK.toInt() }
                else lower
            val lowered = APOSTROPHIZED_NEGATION.replace(raw) { match ->
                val stem = match.groupValues[1]
                val suffix = if (stem in NEGATION_STEMS) stem else NEGATION_STEMS
                    .filter { stem.endsWith(it) }.maxByOrNull { it.length }
                val corrected = suffix ?: NEGATION_STEMS
                    .filter { kotlin.math.abs(it.length - stem.length) <= 1 && editDistance(stem, it, 1) <= 1 }
                    .singleOrNull() ?: stem
                val prefix = if (suffix != null && suffix.length < stem.length) stem.dropLast(suffix.length) + " " else ""
                val end = match.range.last + 1
                // "don'thave" is an OCR join, while the apostrophe still proves negation.
                prefix + corrected + "t" + if (end < raw.length && raw[end].isLetter()) " " else ""
            }
            val result = StringBuilder(lowered.length)
            var pendingSpace = false
            for (character in lowered) {
                if (character in APOSTROPHES || character == '\u00ad') continue
                if (character.isLetterOrDigit()) {
                    if (pendingSpace && result.isNotEmpty()) result.append(' ')
                    result.append(character)
                    pendingSpace = false
                } else {
                    pendingSpace = true
                }
            }
            return result.toString().trim()
        }

        private fun splitSentences(value: String): List<String> {
            val sentences = ArrayList<String>()
            var start = 0
            for (boundary in SENTENCE_BOUNDARY.findAll(value)) {
                val end = boundary.range.last + 1
                value.substring(start, end).trim().takeIf(String::isNotBlank)?.let(sentences::add)
                start = end
            }
            value.substring(start).trim().takeIf(String::isNotBlank)?.let(sentences::add)
            return sentences
        }

        private fun substringEditDistance(query: String, source: String): Int {
            var previous = IntArray(source.length + 1)
            var current = IntArray(source.length + 1)
            for (i in query.indices) {
                current[0] = i + 1
                for (j in source.indices) {
                    current[j + 1] = min(
                        min(current[j] + 1, previous[j + 1] + 1),
                        previous[j] + if (query[i] == source[j]) 0 else 1,
                    )
                }
                val swap = previous
                previous = current
                current = swap
            }
            return previous.minOrNull() ?: query.length
        }

        private fun isSafeExactQuery(query: String): Boolean {
            if (query.isEmpty()) return false
            val words = query.split(' ').filter(String::isNotBlank)
            return (query.length >= 8 && words.size >= 2) ||
                (query.length >= 10 && words.size == 1)
        }

        private fun trigrams(value: String): Set<String> {
            if (value.length < 3) return emptySet()
            return (0..value.length - 3).mapTo(HashSet()) { value.substring(it, it + 3) }
        }

        private fun tokenCoverage(queryWords: List<String>, candidateWords: List<String>): Double {
            if (queryWords.isEmpty()) return 0.0
            val exactWords = candidateWords.toHashSet()
            val matched = queryWords.count { queryWord ->
                queryWord in exactWords || candidateWords.indices.any { start ->
                    var joined = ""
                    val last = min(candidateWords.lastIndex, start + 2)
                    (start..last).any { end ->
                        joined += candidateWords[end]
                        wordsAreSimilar(queryWord, joined)
                    }
                }
            }
            return matched.toDouble() / queryWords.size
        }

        private fun wordsAreSimilar(left: String, right: String): Boolean {
            if (left == right) return true
            if (left.length >= 3 && right.length >= 3 && kotlin.math.abs(left.length - right.length) <= 2 &&
                ocrTextDistance(left, right, if (max(left.length, right.length) <= 6) 100 else 200) <=
                    if (max(left.length, right.length) <= 6) 100 else 200) return true
            if (left.length == 2 && right.length == 2 && left[1] == right[1] &&
                ((left[0] == 'i' && right[0] == 'l') || (left[0] == 'l' && right[0] == 'i'))) {
                return true
            }
            if (left.length < 3 || right.length < 3) {
                val shorter = if (left.length <= right.length) left else right
                val longer = if (left.length > right.length) left else right
                return longer.length <= 3 && longer.length - shorter.length == 1 &&
                    longer.contains(shorter)
            }
            val maxDistance = if (max(left.length, right.length) <= 6) 1 else 2
            return kotlin.math.abs(left.length - right.length) <= maxDistance &&
                editDistance(left, right, maxDistance) <= maxDistance ||
                (left.length >= 4 && right.contains(left)) ||
                (right.length >= 4 && left.contains(right))
        }

        private val APOSTROPHES = setOf('\'', '\u2018', '\u2019', '\u02bc')
        private val DELAY_DIRECTIVE = Regex("""\[delay:\s*-?\d+(?:\.\d+)?\]""", RegexOption.IGNORE_CASE)
        private val SPEAKER_PREFIX = Regex("""^\s*([\p{L}\p{N}][\p{L}\p{N} .’'-]{0,23}):\s*""")
        private val SENTENCE_BOUNDARY = Regex("""[.!?…؟。！？]+["'’”)]*(?:\s+|$)""")

        private fun editDistance(left: String, right: String, limit: Int = max(left.length, right.length)): Int {
            if (left == right) return 0
            if (left.isEmpty()) return right.length
            if (right.isEmpty()) return left.length
            if (kotlin.math.abs(left.length - right.length) > limit) return limit + 1
            var start = 0
            val shortest = min(left.length, right.length)
            while (start < shortest && left[start] == right[start]) start++
            var leftEnd = left.length
            var rightEnd = right.length
            while (leftEnd > start && rightEnd > start && left[leftEnd - 1] == right[rightEnd - 1]) {
                leftEnd--; rightEnd--
            }
            val leftLength = leftEnd - start
            val rightLength = rightEnd - start
            if (leftLength == 0) return rightLength
            if (rightLength == 0) return leftLength
            var previous = IntArray(rightLength + 1) { it }
            var current = IntArray(rightLength + 1)
            for (i in 0 until leftLength) {
                current[0] = i + 1
                var rowMinimum = current[0]
                for (j in 0 until rightLength) {
                    current[j + 1] = min(
                        min(current[j] + 1, previous[j + 1] + 1),
                        previous[j] + if (left[start + i] == right[start + j]) 0 else 1,
                    )
                    rowMinimum = min(rowMinimum, current[j + 1])
                }
                if (rowMinimum > limit) return limit + 1
                val swap = previous
                previous = current
                current = swap
            }
            return previous[rightLength]
        }

        private fun splitCompleteSentences(value: String): Pair<List<String>, String> {
            val sentences = ArrayList<String>()
            var start = 0
            for (boundary in SENTENCE_BOUNDARY.findAll(value)) {
                val end = boundary.range.last + 1
                value.substring(start, end).trim().takeIf(String::isNotBlank)?.let(sentences::add)
                start = end
            }
            val trailing = value.substring(start).trim()
            return sentences to trailing
        }

    }
}
