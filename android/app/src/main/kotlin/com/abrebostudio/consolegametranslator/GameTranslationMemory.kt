package com.abrebostudio.consolegametranslator

import com.google.gson.JsonParser
import com.google.gson.stream.JsonReader
import com.google.gson.stream.JsonToken
import com.google.gson.stream.MalformedJsonException
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

/**
 * Parsed once when a game is selected; OCR frames only query its in-memory indexes.
 *
 * Large packs (hundreds of thousands of rows) must fit in a phone's Java heap, so
 * nothing is kept as one object per row: texts live in UTF-8 blocks addressed by
 * offset arrays ([TextTable]), row fields in primitive arrays ([Store]) and
 * indexes in sorted primitive arrays. A row is materialised as an [Entry] view
 * only when a query actually looks at it.
 */
internal class GameTranslationMemory private constructor(
    val gameId: String,
    val sourceLanguage: String,
    val targetLanguage: String,
    val entryCount: Int,
    val gameProfileJson: String?,
    private val store: Store,
    private val speakerTranslations: Map<String, String>,
    prebuiltExact: HashIndex? = null,
    prebuiltCompact: HashIndex? = null,
    prebuiltMeanings: Set<MeaningTokens>? = null,
) {
    /**
     * Records are the kept pack rows (unique translations); entries are what the
     * matcher searches: whole rows plus their aligned sentences. A record whose
     * sentences align with its translation keeps their character ranges once;
     * sentence entries and multi-sentence spans refer to those ranges.
     */
    private class Store(
        val ids: TextTable,
        val sources: TextTable,
        val targets: TextTable,
        val chapters: TextTable,
        val kinds: TextTable,
        val speakers: TextTable,
        val normalized: TextTable,
        val recordChapter: IntArray,
        val recordKind: IntArray,
        val recordSpeaker: IntArray,
        /** First aligned sentence of the record, or -1. */
        val recordSentenceFirst: IntArray,
        val recordSentenceCount: IntArray,
        val sentenceSourceStart: IntArray,
        val sentenceSourceEnd: IntArray,
        val sentenceTargetStart: IntArray,
        val sentenceTargetEnd: IntArray,
        val entryRecord: IntArray,
        val entryLength: IntArray,
        val entryWordCount: IntArray,
        /** [WHOLE_SINGLE], [WHOLE_PARENT] or the global index of an aligned sentence. */
        val entrySentence: IntArray,
        val spanRecord: IntArray,
        val spanStart: IntArray,
        val spanEnd: IntArray,
        val spanLength: IntArray,
        val grams: PostingTable,
        val words: PostingTable,
    ) {
        val recordCount get() = ids.size
        val entryCount get() = entryRecord.size
        val spanCount get() = spanRecord.size

        fun segmentIndex(entry: Int): Int = when (val sentence = entrySentence[entry]) {
            WHOLE_SINGLE -> 0
            WHOLE_PARENT -> -1
            else -> sentence - recordSentenceFirst[entryRecord[entry]]
        }

        fun segmentCount(entry: Int): Int = when (val sentence = entrySentence[entry]) {
            WHOLE_SINGLE -> 1
            WHOLE_PARENT -> -1
            else -> recordSentenceCount[entryRecord[entry]]
        }

        fun intArrays() = arrayOf(recordChapter, recordKind, recordSpeaker, recordSentenceFirst, recordSentenceCount,
            sentenceSourceStart, sentenceSourceEnd, sentenceTargetStart, sentenceTargetEnd,
            entryRecord, entryLength, entryWordCount, entrySentence, spanRecord, spanStart, spanEnd, spanLength)

        fun textTables() = arrayOf(ids, sources, targets, chapters, kinds, speakers, normalized)

        /** Cheap structural checks; a damaged snapshot must fail here, not during a lookup. */
        fun validate() {
            val records = recordCount
            val entries = entryCount
            val spans = spanCount
            val sentences = sentenceSourceStart.size
            require(sources.size == records && targets.size == records && recordChapter.size == records &&
                recordKind.size == records && recordSpeaker.size == records && recordSentenceFirst.size == records &&
                recordSentenceCount.size == records) { "Oyun indeksi bozuk." }
            require(sentenceSourceEnd.size == sentences && sentenceTargetStart.size == sentences &&
                sentenceTargetEnd.size == sentences) { "Oyun indeksi bozuk." }
            require(normalized.size == entries && entryLength.size == entries && entryWordCount.size == entries &&
                entrySentence.size == entries) { "Oyun indeksi bozuk." }
            require(spanStart.size == spans && spanEnd.size == spans && spanLength.size == spans) { "Oyun indeksi bozuk." }
            for (record in 0 until records) {
                val first = recordSentenceFirst[record]
                val count = recordSentenceCount[record]
                require(recordChapter[record] in -1 until chapters.size && recordKind[record] in -1 until kinds.size &&
                    recordSpeaker[record] in -1 until speakers.size &&
                    (first == -1 && count == 0 || first >= 0 && count >= 2 && first.toLong() + count <= sentences)) {
                    "Oyun indeksi bozuk."
                }
            }
            for (entry in 0 until entries) {
                val record = entryRecord[entry]
                require(record in 0 until records && entryLength[entry] >= 0 && entryWordCount[entry] >= 0) {
                    "Oyun indeksi bozuk."
                }
                val sentence = entrySentence[entry]
                require(sentence == WHOLE_SINGLE || sentence == WHOLE_PARENT ||
                    recordSentenceFirst[record] >= 0 && sentence - recordSentenceFirst[record] in 0 until recordSentenceCount[record]) {
                    "Oyun indeksi bozuk."
                }
            }
            for (span in 0 until spans) {
                val record = spanRecord[span]
                require(record in 0 until records && recordSentenceFirst[record] >= 0 &&
                    spanStart[span] in 0..spanEnd[span] && spanEnd[span] < recordSentenceCount[record]) { "Oyun indeksi bozuk." }
            }
            grams.validate(entries)
            words.validate(entries)
        }

        fun retainedBytes(): Long = 256L + intArrays().sumOf { 16L + 4L * it.size } +
            textTables().sumOf { it.retainedBytes() } + grams.retainedBytes() + words.retainedBytes()
    }

    /** A row of the matcher, decoded only when a query inspects it. */
    private inner class Entry(val index: Int) {
        private val record get() = store.entryRecord[index]
        val id: String get() = store.ids[record]
        val chapter: String? get() = store.chapters.optional(store.recordChapter[record])
        val kind: String? get() = store.kinds.optional(store.recordKind[record])
        val speaker: String? get() = store.speakers.optional(store.recordSpeaker[record])
        val source: String by lazy(LazyThreadSafetyMode.NONE) {
            entryText(store.sources, index, store.sentenceSourceStart, store.sentenceSourceEnd)
        }
        val target: String by lazy(LazyThreadSafetyMode.NONE) {
            entryText(store.targets, index, store.sentenceTargetStart, store.sentenceTargetEnd)
        }
        val normalizedSource: String by lazy(LazyThreadSafetyMode.NONE) { store.normalized[index] }
        val words: List<String> by lazy(LazyThreadSafetyMode.NONE) { normalizedSource.split(' ').filter(String::isNotBlank) }
        val segmentIndex: Int? get() = store.segmentIndex(index).takeIf { it >= 0 }
        val segmentCount: Int? get() = store.segmentCount(index).takeIf { it >= 0 }
        val meaning: MeaningTokens by lazy(LazyThreadSafetyMode.NONE) { meaningTokens(normalizedSource) }
        val normalizedSpeaker: String get() = speakerKey(store.recordSpeaker[record])
    }

    private fun entryText(table: TextTable, entry: Int, starts: IntArray, ends: IntArray): String {
        val text = table[store.entryRecord[entry]]
        val sentence = store.entrySentence[entry]
        return if (sentence < 0) text else text.substring(starts[sentence], ends[sentence])
    }

    private val normalizedSpeakers = Array(store.speakers.size) { normalize(store.speakers[it]) }
    private fun speakerKey(speaker: Int) = if (speaker < 0) "" else normalizedSpeakers[speaker]

    private fun entry(index: Int) = Entry(index)

    // A spaceless key resolves OCR word joins in O(log n); both are verified byte for byte.
    private val exactIndex = prebuiltExact ?: HashIndex.build(store.normalized, skipSpaces = false)
    private val compactIndex = prebuiltCompact ?: HashIndex.build(store.normalized, skipSpaces = true)
    private val spanLengthIndex = lengthPostings(store.spanCount) { store.spanLength[it] }
    private val lengthIndex = lengthPostings(store.entryCount) { store.entryLength[it] }

    private data class RankedMatch(
        val entry: Entry,
        val score: Double,
        val similarity: Double,
        val tokenCoverage: Double,
        val sourceCoverage: Double,
        val partial: Boolean,
    )

    private val availableMeanings: Set<MeaningTokens> = prebuiltMeanings ?: HashSet<MeaningTokens>().also { meanings ->
        for (index in 0 until store.entryCount) meanings.add(meaningTokens(store.normalized[index]))
    }
    private val gramVotes = IntArray(store.entryCount)

    /** Row fingerprints and each row's first entry, for the fuzzy prefilter ([FuzzySignatures]). */
    private class Prefilter(val signatures: FuzzySignatures, val firstEntry: IntArray)

    /**
     * Built after loading, off the reading thread for a large pack: until it is
     * ready the fuzzy search works as before, so loading never waits for it.
     */
    @Volatile private var prefilter: Prefilter? = null

    private fun buildPrefilter(): Prefilter {
        val firstEntry = IntArray(store.recordCount) { -1 }
        for (entry in 0 until store.entryCount) {
            val record = store.entryRecord[entry]
            if (firstEntry[record] < 0) firstEntry[record] = entry
        }
        val signatures = FuzzySignatures.build(store.recordCount) { record ->
            firstEntry[record].let { if (it < 0) "" else store.normalized[it] }
        }
        return Prefilter(signatures, firstEntry)
    }

    init {
        if (store.recordCount <= SYNC_PREFILTER_RECORDS) prefilter = buildPrefilter()
        else Thread({ prefilter = buildPrefilter() }, "pack-fingerprints").apply {
            isDaemon = true
            priority = Thread.MIN_PRIORITY
        }.start()
    }

    /** The entries of the rows whose fingerprints are nearest to [query] (see [FuzzySignatures.nearest]). */
    private fun prefilteredEntries(query: String, limit: Int, minLength: Int, eligible: (Int) -> Boolean): List<Int>? {
        val index = prefilter ?: return null
        val entries = ArrayList<Int>()
        for (record in index.signatures.nearest(query, limit, minLength, Int.MAX_VALUE)) {
            var entry = index.firstEntry[record]
            if (entry < 0) continue
            while (entry < store.entryCount && store.entryRecord[entry] == record) {
                if (eligible(entry)) entries.add(entry)
                entry++
            }
        }
        return entries
    }
    private data class SearchKey(val query: String, val speaker: String?)
    private inner class SearchWork(val query: String, val speaker: String?) {
        val words by lazy { collectWordCandidateIndices(query) }
        val context by lazy { oneWordContext(query, speaker) }
        val wholeRowMatch by lazy {
            val wordCount = query.count { it == ' ' } + 1
            // Compare complete rows separately from their aligned fragments;
            // an observed ending can also prove joined/split OCR words complete.
            rankCandidates(query, speaker, words.filter { index ->
                // Whole rows: single-sentence rows and multi-sentence parents, not their sentences.
                store.entrySentence[index] < 0 &&
                    (store.entryWordCount[index] == wordCount || hasWholeRowEnding(query, store.normalized[index]))
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

    /** Actual array and block sizes, identical for a parsed pack and its snapshot. */
    internal val estimatedRetainedBytes: Long =
        store.retainedBytes() + exactIndex.retainedBytes() + compactIndex.retainedBytes() +
            8L * store.entryCount + // gramVotes (4 B) and per-query scratch
            28L * store.recordCount + // fuzzy prefilter fingerprints (~16 B words, offsets, lengths, scores)
            spanLengthIndex.values.sumOf { 64L + 4L * it.size } + lengthIndex.values.sumOf { 64L + 4L * it.size } +
            speakerTranslations.entries.sumOf { (key, value) -> 96L + 2L * (key.length + value.length) } +
            normalizedSpeakers.sumOf { 48L + 2L * it.length } + 64L * availableMeanings.size

    fun find(ocrText: String): GameTranslationMatch? = synchronized(lookupCache) {
        if (lookupCache.containsKey(ocrText)) return@synchronized lookupCache[ocrText]
        // A row picked by the conversation around it is not cached, and neither is
        // a line left open for want of one: the same words may be another scene's.
        // It is kept only while the conversation stays where it was.
        unsettledHit("f\u0000$ocrText")?.let { return@synchronized it.match }
        val unresolved = unresolvedLines
        foundRecord = -1
        readText = ocrText
        val match = findUncached(ocrText)?.takeUnless { isCaseMismatchedScrap(prepareQuery(ocrText).body, it) }
        remembered(match).also {
            if (cacheable(it, unresolved)) lookupCache[ocrText] = it else keepUnsettled("f\u0000$ocrText", it)
        }
    }

    private class Unsettled(val record: Int, val match: GameTranslationMatch?)
    private val unsettledCache = object : LinkedHashMap<String, Unsettled>(16, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Unsettled>?) = size > 96
    }
    private fun unsettledHit(key: String) = unsettledCache[key]?.takeIf { it.record == contextVersion }
    private fun keepUnsettled(key: String, match: GameTranslationMatch?) { unsettledCache[key] = Unsettled(contextVersion, match) }

    /** Notes where in the script an exactly found line of some length sits. */
    private fun remembered(match: GameTranslationMatch?): GameTranslationMatch? {
        val record = foundRecord
        if (match != null && match.matchType == "exact" && record >= 0 && store.ids[record] == match.entryId &&
            normalize(match.source).length >= MIN_CONTEXT_QUERY) rememberRecord(record)
        return match
    }

    /** Cheap exact probes let clean OCR blocks win before any fuzzy search. */
    fun findExact(ocrText: String): GameTranslationMatch? = synchronized(lookupCache) {
        lookupCache[ocrText]?.takeIf { it.matchType == "exact" || it.matchType == "spacing_exact" }
            ?.let { return@synchronized it }
        unsettledHit("e\u0000$ocrText")?.let { return@synchronized it.match }
        val unresolved = unresolvedLines
        val query = prepareQuery(ocrText)
        foundRecord = -1
        readText = ocrText
        val match = if (query.label != null) {
            findExactNormalized(normalize(ocrText), null)
                ?: findExactNormalized(normalize(query.body), null)?.let { withLabel(it, query.label) }
        } else findExactNormalized(normalize(query.body), query.speaker)
            ?: query.speaker?.let { findExactNormalized(normalize("$it: ${query.body}"), null) }
        remembered(withDisplaySpeaker(match?.takeUnless { isCaseMismatchedScrap(query.body, it) }, query.speaker)).also {
            if (it != null && it.matchType !in UNSETTLED_EXACT) lookupCache[ocrText] = it
            else if (it != null || unresolvedLines != unresolved) keepUnsettled("e\u0000$ocrText", it)
        }
    }

    /**
     * A read of at most [MAX_SCRAP_LETTERS] letters is a pack row only with the
     * row's own capitals: "sg" glimpsed in a scene is not the label "SG".
     */
    private fun isCaseMismatchedScrap(read: String, match: GameTranslationMatch): Boolean {
        val letters = read.filter(Char::isLetter)
        return letters.length <= MAX_SCRAP_LETTERS && letters != match.source.filter(Char::isLetter)
    }

    /** Whether [word] occurs in any pack line (as the matcher normalizes it). */
    fun knowsWord(word: String): Boolean {
        val normalized = normalize(word)
        return normalized.isNotEmpty() && ' ' !in normalized && store.words.find(normalized) >= 0
    }

    private class QuickResult(val match: GameTranslationMatch?)
    private val quickCache = object : LinkedHashMap<String, QuickResult>(32, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, QuickResult>?) = size > 64
    }

    /**
     * The pack line(s) of [ocrText] found with hash lookups only, no fuzzy search:
     * the whole line (with or without its speaker label), the line as runs of whole
     * sentences each found exactly (two subtitles read together are two pack
     * lines), then one likely OCR misreading fixed ("rn" read for "m", a stray or
     * a lost letter). Every way is tried before any slow search, so a clean read
     * never waits for one.
     */
    fun findQuick(ocrText: String): GameTranslationMatch? = synchronized(lookupCache) {
        quickCache[ocrText]?.let { return@synchronized it.match }
        unsettledHit("q\u0000$ocrText")?.let { return@synchronized it.match }
        val unresolved = unresolvedLines
        findQuickUncached(ocrText).also {
            if (cacheable(it, unresolved)) quickCache[ocrText] = QuickResult(it) else keepUnsettled("q\u0000$ocrText", it)
        }
    }

    private fun findQuickUncached(ocrText: String): GameTranslationMatch? {
        findExact(ocrText)?.let { return it }
        val query = prepareQuery(ocrText)
        fun shown(match: GameTranslationMatch) =
            if (query.label != null) withLabel(match, query.label) else withDisplaySpeaker(match, query.speaker)!!
        fun piece(text: String): GameTranslationMatch? {
            val normalized = normalize(text)
            readText = text
            // A misreading is undone in one sentence at a time, not in every run tried.
            return findExactNormalized(normalized, query.speaker)
                ?: if (quickSentences(text).size == 1) correctedQuery(normalized, query.speaker) else null
        }
        correctedQuery(normalize(query.body), query.speaker)?.let { return shown(it) }
        val sentences = quickSentences(query.body)
        if (sentences.size < 2 || sentences.size > MAX_QUICK_SENTENCES) return null
        // Longest runs first: a pack line of several sentences stays one line.
        val matches = ArrayList<GameTranslationMatch>()
        val sources = ArrayList<String>()
        var start = 0
        while (start < sentences.size) {
            var end = if (start == 0) sentences.size - 1 else sentences.size
            var found: GameTranslationMatch? = null
            while (end > start && found == null) {
                found = piece(sentences.subList(start, end).joinToString(" "))
                if (found == null) end--
            }
            matches += found ?: return null
            sources += sentences.subList(start, end).joinToString(" ")
            start = end
        }
        val first = matches.first()
        val oneEntry = matches.all { it.entryId == first.entryId }
        return shown(first.copy(
            entryId = matches.map { it.entryId }.distinct().joinToString("+"),
            source = matches.joinToString(" ") { it.source.trim() },
            target = matches.joinToString(" ") { it.target.trim() },
            score = matches.minOf { it.score },
            matchType = "sentence_exact",
            segmentIndex = if (oneEntry) first.segmentIndex else null,
            segmentCount = if (oneEntry) first.segmentCount else null,
        ))
    }

    /**
     * A short line ([MIN_VARIANT_LETTERS]..[MAX_VARIANT_LETTERS] letters) as it
     * reads after one usual OCR misreading is undone, looked up exactly. Every
     * fix that finds a line must agree on its translation, and a fix may not
     * change a number or a negation.
     */
    private fun correctedQuery(query: String, speaker: String?): GameTranslationMatch? {
        val letters = query.count { it != ' ' }
        if (letters < MIN_VARIANT_LETTERS || letters > MAX_VARIANT_LETTERS) return null
        // A read that is itself a pack line ("Really?" with several translations)
        // or made only of words the pack knows is no misreading: "Really?" must
        // not become "Rally" by dropping a letter.
        if (exactEntries(query).isNotEmpty()) return null
        // One word alone is too little context to change ("SLAVING" -> "Saving").
        if (query.split(' ').count { it.isNotEmpty() } < 2) return null
        // Only the words the pack does not know are misreadings to undo.
        val unknown = ArrayList<IntRange>()
        var start = 0
        for (word in query.split(' ')) {
            if (word.isNotEmpty() && store.words.find(word) < 0) unknown += start until start + word.length
            start += word.length + 1
        }
        if (unknown.isEmpty()) return null
        val meaning = meaningTokens(query)
        var found: Entry? = null
        for (variant in ocrVariants(query, unknown, insertLetters = letters >= MIN_INSERT_LETTERS)) {
            val entries = exactEntries(variant).filter { speakerMatches(it, speaker) }
            if (entries.isEmpty() || meaningTokens(variant) != meaning) continue
            val entry = equivalentOutput(entries) ?: return null
            if (found != null && (found.target != entry.target || found.normalizedSpeaker != entry.normalizedSpeaker)) return null
            if (found == null) found = entry
        }
        return found?.toMatch(OCR_VARIANT_SCORE, "ocr_variant")
    }

    /**
     * [label] is a name-like "Name:" prefix the pack does not list as a speaker
     * ("Final Chapter: Got someone coming in…"): the line is looked up without
     * it, and the label is shown as the game shows it.
     */
    private data class QueryText(val body: String, val speaker: String?, val label: String? = null)

    /** A pack row that already starts with the label shows it in its own text. */
    private fun withLabel(match: GameTranslationMatch, label: String) =
        if (normalize(match.source).startsWith(normalize(label) + " ")) match else match.copy(speaker = label)

    fun rejectionReason(ocrText: String): String {
        val text = prepareQuery(ocrText)
        val query = normalize(text.body)
        val exact = exactEntries(query).filter { speakerMatches(it, text.speaker) }
        return when {
            query.isEmpty() -> "empty"
            exact.isNotEmpty() && equivalentOutput(exact) == null -> "ambiguous_exact"
            !isSafeExactQuery(query) -> "short_not_exact"
            else -> "not_found"
        }
    }

    private fun exactEntries(query: String): List<Entry> =
        exactIndex.find(store.normalized, query, skipSpaces = false).map(::entry)

    private fun compactEntries(query: String): List<Entry> =
        compactIndex.find(store.normalized, query, skipSpaces = true).map(::entry)

    private fun prepareQuery(ocrText: String): QueryText {
        val prefix = SPEAKER_PREFIX.find(ocrText) ?: return QueryText(ocrText, null)
        val read = prefix.groupValues[1].trim()
        // Scene text read just before the label ("AYHO Lucia:", "M Mattia:") is no part of the name.
        val cleaned = withoutLabelScraps(read)
        fun knownSpeaker(label: String) = if (speakerTranslations.containsKey(label)) label else {
            speakerTranslations.keys.filter { candidate ->
                label.length >= 3 && kotlin.math.abs(candidate.length - label.length) <= 1 &&
                    editDistance(candidate, label, 1) <= 1
            }.singleOrNull()
        }
        val speaker = knownSpeaker(normalize(read)) ?: cleaned.takeIf { it != read }?.let { knownSpeaker(normalize(it)) }
        val body = ocrText.substring(prefix.range.last + 1).trimStart(' ', '/', '|', 92.toChar())
        if (speaker != null) return QueryText(body, speaker)
        val shown = if (normalize(read) in inlineLabels) read else cleaned
        // Rows that carry this label in their own text are still searched with it.
        if (normalize(shown) in inlineLabels) return QueryText(ocrText, null)
        // A name the pack does not list is shown as read around the pack line, long
        // or short ("STRANGER: What?"): a pack may list no speakers at all, and a
        // line with several translations is settled like any other (conversation,
        // most rows), not by the name.
        return if (isNameLabel(shown) && body.count(Char::isLetter) >= 2) QueryText(body, null, shown)
            else QueryText(ocrText, null)
    }

    /**
     * Names written into the pack's own rows ("Cal: Look, I'm sorry. …"), found
     * once by scanning only the first bytes of each source for a colon.
     */
    private val inlineLabels: Set<String> by lazy {
        val labels = HashSet<String>()
        for (record in 0 until store.sources.size) {
            val label = store.sources.prefixBefore(record, ':', INLINE_LABEL_BYTES) ?: continue
            if (SPEAKER_PREFIX.matches("$label: ")) labels.add(normalize(label))
        }
        labels
    }

    /**
     * [label] without leading scraps: one-letter tokens and capitals-only tokens
     * before a name written in lower case ("AYHO A Lucia" -> "Lucia").
     */
    private fun withoutLabelScraps(label: String): String {
        val words = label.split(' ').filter(String::isNotBlank).toMutableList()
        while (words.size > 1) {
            val first = words.first()
            val scrap = first.count(Char::isLetterOrDigit) <= 1 ||
                (first.filter(Char::isLetter).let { it.isNotEmpty() && it.all(Char::isUpperCase) } &&
                    words.drop(1).any { word -> word.any(Char::isLowerCase) })
            if (!scrap) break
            words.removeAt(0)
        }
        return words.joinToString(" ")
    }

    /** One to three words, each starting with a capital letter ("Final Chapter", "Cal"). */
    private fun isNameLabel(label: String): Boolean {
        val words = label.split(' ').filter(String::isNotBlank)
        return words.size in 1..3 && label.count(Char::isLetter) >= 2 &&
            words.all { word -> word.first().isUpperCase() }
    }

    private fun withDisplaySpeaker(match: GameTranslationMatch?, speaker: String?): GameTranslationMatch? =
        if (match == null || speaker == null) match else match.copy(speaker = speakerTranslations[speaker] ?: match.speaker)

    private fun speakerMatches(entry: Entry, expected: String?) = speakerMatchesRecord(store.entryRecord[entry.index], expected)

    private fun speakerMatchesRecord(record: Int, expected: String?): Boolean {
        if (expected == null) return true
        val speaker = speakerKey(store.recordSpeaker[record])
        return speaker.isEmpty() || speaker == expected
    }

    private fun findUncached(ocrText: String): GameTranslationMatch? {
        findQuick(ocrText)?.let { return it }
        try {
            val query = prepareQuery(ocrText)
            // An unknown label: only the whole text's exact row keeps it, then the line without it.
            if (query.label != null) return findExactNormalized(normalize(ocrText), null)
                ?: findBody(query.body, null)?.let { withLabel(it, query.label) }
            val match = findBody(query.body, query.speaker)
                ?: query.speaker?.let { findBody("$it: ${query.body}", null) }
            return withDisplaySpeaker(match, query.speaker)
        } finally { searches.clear() }
    }

    private fun findBody(bodyText: String, expectedSpeaker: String?): GameTranslationMatch? {
        val query = normalize(bodyText)
        findExactNormalized(query, expectedSpeaker)?.let { return it }
        if (exactEntries(query).any { speakerMatches(it, expectedSpeaker) }) return null

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

    private fun spanSentences(span: Int, table: TextTable, starts: IntArray, ends: IntArray): String {
        val record = store.spanRecord[span]
        val text = table[record]
        val first = store.recordSentenceFirst[record]
        val builder = StringBuilder()
        for (sentence in store.spanStart[span]..store.spanEnd[span]) {
            if (sentence > store.spanStart[span]) builder.append(' ')
            builder.append(text, starts[first + sentence], ends[first + sentence])
        }
        return builder.toString()
    }

    private fun spanSource(span: Int) =
        spanSentences(span, store.sources, store.sentenceSourceStart, store.sentenceSourceEnd)

    private fun spanMatch(span: Int, score: Double, matchType: String): GameTranslationMatch {
        val record = store.spanRecord[span]
        return GameTranslationMatch(
            gameId = gameId,
            entryId = store.ids[record],
            chapter = store.chapters.optional(store.recordChapter[record]),
            kind = store.kinds.optional(store.recordKind[record]),
            speaker = store.speakers.optional(store.recordSpeaker[record]),
            source = spanSource(span),
            target = spanSentences(span, store.targets, store.sentenceTargetStart, store.sentenceTargetEnd),
            score = score.coerceIn(0.0, 1.0),
            matchType = matchType,
            segmentIndex = store.spanStart[span],
            segmentCount = store.recordSentenceCount[record],
        )
    }

    /** Recover lost OCR sentence boundaries without revealing unseen sentences. */
    private fun findAlignedSpan(query: String, expectedSpeaker: String?): GameTranslationMatch? {
        if (query.length < MIN_PARTIAL_QUERY_LENGTH) return null
        val meaning = meaningTokens(query)
        val radius = max(3, query.length / 10)
        // Only spans of rows whose fingerprints hold the read are spelled out and compared.
        val rows = if (query.length < MIN_PREFILTER_QUERY) null
            else prefilter?.signatures?.nearest(query, PREFILTER_ROWS, query.length - radius, Int.MAX_VALUE)?.toHashSet()
        val nearbySpans = (query.length - radius..query.length + radius).asSequence()
            .flatMap { length -> spanLengthIndex[length]?.asSequence() ?: emptySequence() }
        val ranked = nearbySpans.filter { span ->
            (rows == null || store.spanRecord[span] in rows) && speakerMatchesRecord(store.spanRecord[span], expectedSpeaker)
        }.mapNotNull { span ->
            val normalized = normalize(spanSource(span))
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
        return spanMatch(best.first, best.second, "sentence_span_fuzzy")
    }

    private fun findExactNormalized(
        query: String,
        expectedSpeaker: String?,
    ): GameTranslationMatch? {
        if (query.length < 2 || query.none(Char::isLetterOrDigit)) return null
        val exact = exactEntries(query).filter { entry ->
            speakerMatches(entry, expectedSpeaker)
        }
        if (exact.isNotEmpty()) {
            // Localisation IDs and aligned sentences can share the same output, and
            // rows that differ only in punctuation ("Oh, shit!" / "Oh shit...") are
            // one line: the row punctuated as read is shown. Truly different
            // translations go by the conversation being read (the row next to the
            // last line found), else by the translation most rows give.
            val entry = equivalentOutput(exact)
                ?: return inConversation(exact, query)?.toMatch(1.0, CONTEXT_EXACT)
                    ?: mostCommon(exact).also { if (it == null) unresolvedLines++ }
            foundRecord = store.entryRecord[entry.index]
            return entry.toMatch(1.0, "exact")
        }
        // Resolve OCR word joins in O(1), but only for the complete character
        // sequence of one unique source/aligned sentence, never a parent prefix.
        val wordCount = query.count { it == ' ' } + 1
        if (query.length >= 12 && wordCount >= 2) {
            val compact = compactEntries(query)
            if (compact.isNotEmpty()) {
                val meaning = meaningTokens(query)
                val compatible = compact.filter { entry ->
                    // OCR may also split a word the pack writes joined ("left a" for "lefta").
                    entry.meaning == meaning && store.entryWordCount[entry.index] >= wordCount - MAX_OCR_SPLIT_WORDS &&
                        (speakerMatches(entry, expectedSpeaker))
                }
                equivalentOutput(compatible)?.let { return it.toMatch(1.0, "spacing_exact") }
            }
        }
        return null
    }

    /**
     * Records of the last lines of some length found exactly, newest first:
     * where the game's script is being read. Several, because the OCR areas
     * share this memory: a tip read top left must not wipe out the phone
     * message that places the tip's own line (24 Nov log).
     */
    private val recentRecords = IntArray(RECENT_RECORDS) { -1 }

    /** Changes whenever [recentRecords] gains a record it did not hold. */
    private var contextVersion = 0

    private fun rememberRecord(record: Int) {
        val at = recentRecords.indexOf(record)
        if (at == 0) return
        // Already held: only its place changes, the set of places stays.
        val end = if (at > 0) at else recentRecords.size - 1
        for (index in end downTo 1) recentRecords[index] = recentRecords[index - 1]
        recentRecords[0] = record
        if (at < 0) contextVersion++
    }

    /** The record of the last unique exact row found inside one lookup. */
    private var foundRecord = -1

    /** Counts lines with several translations that no nearby line settled. */
    private var unresolvedLines = 0

    private fun cacheable(match: GameTranslationMatch?, unresolvedBefore: Int) =
        if (match == null) unresolvedLines == unresolvedBefore else match.matchType !in UNSETTLED_EXACT

    /** The OCR read being looked up (or the sentence of it): its punctuation picks among equal rows. */
    private var readText = ""

    /**
     * The translation most of [candidates] give (punctuation aside), when one
     * clearly leads: "Oh shit" is "Hassiktir" in four rows and "Kahretsin" in two.
     */
    private fun mostCommon(candidates: List<Entry>): GameTranslationMatch? {
        val read = readText
        // A read starting in lower case is the end of a longer line ("people?"), not a line of its own.
        val body = SPEAKER_PREFIX.find(read)?.let { read.substring(it.range.last + 1) } ?: read
        if (body.firstOrNull(Char::isLetter)?.isUpperCase() != true) return null
        // "Hey." has 3,400 rows: counted once, not on every frame it stays on screen.
        val key = "$read\u0000${candidates.size}\u0000${candidates.first().index}"
        if (commonCache.containsKey(key)) return commonCache[key]
        // Same text first (cheap), then each distinct text normalised once.
        val groups = candidates.groupBy { it.target }.entries.groupBy({ normalize(it.key) }, { it.value })
            .values.map { it.flatten() }.sortedByDescending { it.size }
        val match = if (groups.size < 2 || groups[0].size < 2 || groups[0].size <= groups[1].size) null else {
            val group = groups[0]
            val speakers = group.map { it.normalizedSpeaker }.distinct()
            punctuatedAsRead(group).toMatch(COMMON_EXACT_SCORE, COMMON_EXACT)
                .let { if (speakers.size > 1) it.copy(speaker = null) else it }
        }
        commonCache[key] = match
        return match
    }

    private val commonCache = object : LinkedHashMap<String, GameTranslationMatch?>(16, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, GameTranslationMatch?>?) = size > 64
    }

    /** The row whose punctuation is closest to the read's: its end first ("!", "..."), then all of it. */
    private fun punctuatedAsRead(candidates: List<Entry>): Entry {
        val read = readText
        val readEnd = endMarks(read)
        val readMarks = marks(read)
        return candidates.maxWithOrNull(compareBy<Entry>(
            { if (endMarks(it.source) == readEnd) 1 else 0 },
            { if (marks(it.source) == readMarks) 1 else 0 },
            { if (it.segmentCount == 1 || it.segmentCount == null) 1 else 0 },
            { -candidates.indexOf(it) },
        )) ?: candidates.first()
    }

    /**
     * The one of several rows with the same English ("What- they're comin'
     * here?" in two scenes, translated two ways) that sits in the script next
     * to the last line found. Null when none is close or the line is too short
     * to tell ("people?").
     */
    private fun inConversation(candidates: List<Entry>, query: String): Entry? {
        if (query.count { it == ' ' } + 1 < MIN_CONTEXT_WORDS) return null
        // The newest line read that has one of the rows close by decides.
        for (last in recentRecords) {
            if (last < 0) break
            val nearest = candidates.minByOrNull { kotlin.math.abs(store.entryRecord[it.index] - last) } ?: return null
            val distance = kotlin.math.abs(store.entryRecord[nearest.index] - last)
            if (distance > MAX_CONTEXT_RECORDS) continue
            // Two rows equally close tell nothing.
            val shown = normalize(nearest.target)
            if (candidates.any { kotlin.math.abs(store.entryRecord[it.index] - last) == distance && normalize(it.target) != shown }) return null
            return nearest
        }
        return null
    }

    private fun equivalentOutput(candidates: List<Entry>): Entry? {
        val first = candidates.firstOrNull() ?: return null
        if (candidates.all { it.target == first.target && it.normalizedSpeaker == first.normalizedSpeaker })
            return candidates.firstOrNull { it.segmentCount == 1 || it.segmentCount == null } ?: first
        // The same words, punctuated differently ("Hassiktir!" / "Hassiktir..."): one translation.
        val shown = normalize(first.target)
        if (shown.isEmpty() || candidates.any { normalize(it.target) != shown || it.normalizedSpeaker != first.normalizedSpeaker }) return null
        return punctuatedAsRead(candidates)
    }

    private fun findNormalized(
        query: String,
        expectedSpeaker: String?,
    ): GameTranslationMatch? {
        if (!isSafeExactQuery(query)) return null
        findExactNormalized(query, expectedSpeaker)?.let { return it }

        if (exactEntries(query).any { speakerMatches(it, expectedSpeaker) }) return null
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
        val wordSlots = IntArray(words.size) { store.words.find(words[it]) }
        val unknown = words.indices.filter { words[it].length >= 3 && wordSlots[it] < 0 }
        if (unknown.size > 1 || (unknown.isEmpty() && words.size < 5)) return ContextAttempt(null)
        val gap = unknown.singleOrNull()
        // Two rare anchors keep a real-but-wrong OCR word from hiding the row:
        // with one wrong word, at least one anchor must still be correct.
        val anchors = words.indices.filter { it != gap && wordSlots[it] >= 0 }
            .sortedBy { store.words.count(wordSlots[it]) }.take(if (gap == null) 2 else 1)
        if (anchors.isEmpty()) return ContextAttempt(null)
        val meaning = meaningTokens(query)
        val embeddedNumbers = embeddedOcrNumbersOnly(query)
        val candidates = ArrayList<Entry>()
        for ((anchorAt, anchor) in anchors.withIndex()) for (index in store.words.postings(wordSlots[anchor])) {
            // Cheap array checks first; every skip condition is independent.
            if (store.entryWordCount[index] != words.size ||
                !speakerMatchesRecord(store.entryRecord[index], speaker)) continue
            val entry = entry(index)
            if (anchorAt > 0 && words[anchors[0]] in entry.words) continue
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
            if (!speakerMatchesRecord(store.entryRecord[index], expectedSpeaker)) return@mapNotNull null
            val entry = entry(index)
            if (!((meaning.numbers == entry.meaning.numbers || (entry.meaning.numbers.isEmpty() && embeddedNumbers)) &&
                    (meaning.negated == entry.meaning.negated || (!meaning.negated && entry.meaning.negated && ocrNegation)))) {
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
        val rare = words.filter { it.length >= 3 }.distinct().map { it to store.words.find(it) }.filter { it.second >= 0 }
            .sortedBy { store.words.count(it.second) }.take(6)
        for ((_, slot) in rare) for (index in store.words.postings(slot)) {
            val length = store.entryLength[index]
            if (length in minLength..maxLength &&
                (length <= query.length * 1.10 || store.entrySentence[index] != WHOLE_PARENT)) {
                if (votes[index]++ == 0) touched.add(index)
            }
        }
        return topCandidates(touched.freeze(), votes, query.length)
    }

    private fun topCandidates(touched: IntArray, votes: IntArray, length: Int, minimum: Int = 1): List<Int> {
        val order = compareByDescending<Int> { votes[it] }
            .thenBy { kotlin.math.abs(store.entryLength[it] - length) }.thenBy { it }
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
            val length = store.entryLength[index]
            return length in minimumLength..maximumLength &&
                (length <= query.length * 1.10 || store.entrySentence[index] != WHOLE_PARENT)
        }
        // The rows whose fingerprints share the most with the read, instead of
        // counting every row that shares a single three-letter piece with it
        // (common pieces such as "the" touch most of a large pack). A short read
        // has few pieces, so a few misread letters weigh too much in its
        // fingerprint; it keeps the piece count, which is cheap for it.
        if (query.length >= MIN_PREFILTER_QUERY) prefilteredEntries(query, PREFILTER_ROWS, minimumLength, ::eligible)?.let { nearest ->
            val candidates = LinkedHashSet<Int>()
            candidates.addAll(wordCandidates)
            candidates.addAll(nearest)
            return withShortLines(candidates, words.size, minimumLength, maximumLength)
        }
        val grams = trigrams(query)
        val counts = gramVotes
        val touched = IntPostings()
        for (gram in grams) {
            val slot = store.grams.find(gramCode(gram, 0))
            if (slot < 0) continue
            for (index in store.grams.postings(slot)) {
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
        return withShortLines(candidates, words.size, minimumLength, maximumLength)
    }

    /** A one-word read also compares rows of a similar length. */
    private fun withShortLines(candidates: LinkedHashSet<Int>, wordCount: Int, minimumLength: Int, maximumLength: Int): List<Int> {
        if (wordCount <= 1) for (length in minimumLength..maximumLength) {
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
        target = target,
        score = score.coerceIn(0.0, 1.0),
        matchType = matchType,
        segmentIndex = segmentIndex,
        segmentCount = segmentCount,
    )

    /**
     * Writes the prepared blocks and arrays as they are. Reading it back skips JSON
     * parsing, text normalisation, sentence splitting and trigram indexing.
     */
    internal fun writeSnapshot(output: java.io.DataOutputStream, contentKey: String, buildTag: String) {
        require(store.textTables().none { it.hasIrregularText } &&
            speakerTranslations.all { (key, value) -> isWellFormedText(key) && isWellFormedText(value) } &&
            (gameProfileJson == null || isWellFormedText(gameProfileJson))) { "Oyun indeksi metni kaydedilemez." }
        output.writeInt(SNAPSHOT_MAGIC)
        output.writeInt(SNAPSHOT_VERSION)
        for (value in listOf(buildTag, gameId, sourceLanguage, targetLanguage, contentKey)) writeSnapshotText(output, value)
        output.writeInt(entryCount)
        if (gameProfileJson == null) output.writeInt(-1) else writeSnapshotText(output, gameProfileJson)
        output.writeInt(speakerTranslations.size)
        speakerTranslations.forEach { (name, translated) ->
            writeSnapshotText(output, name); writeSnapshotText(output, translated)
        }
        store.textTables().forEach { it.write(output) }
        store.intArrays().forEach { writeIntArray(output, it) }
        store.grams.write(output)
        store.words.write(output)
        // Derived data a reload would otherwise recompute for every entry.
        writeLongArray(output, exactIndex.keys)
        writeLongArray(output, compactIndex.keys)
        output.writeInt(availableMeanings.size)
        for (meaning in availableMeanings) {
            output.writeInt(if (meaning.negated) 1 else 0)
            output.writeInt(meaning.numbers.size)
            meaning.numbers.forEach { writeSnapshotText(output, it) }
        }
    }

    companion object {
        private const val SNAPSHOT_MAGIC = 0x47544D49 // "GTMI"
        private const val SNAPSHOT_VERSION = 3

        private fun isWellFormedText(value: String): Boolean {
            var index = 0
            while (index < value.length) {
                val character = value[index]
                if (Character.isHighSurrogate(character)) {
                    if (index + 1 >= value.length || !Character.isLowSurrogate(value[index + 1])) return false
                    index += 2
                    continue
                }
                if (Character.isLowSurrogate(character)) return false
                index++
            }
            return true
        }

        private fun writeSnapshotText(output: java.io.DataOutputStream, value: String) {
            val bytes = value.toByteArray(Charsets.UTF_8)
            output.writeInt(bytes.size)
            output.write(bytes)
        }

        private fun writeIntArray(output: java.io.DataOutputStream, values: IntArray) {
            output.writeInt(values.size)
            val buffer = java.nio.ByteBuffer.allocate(64 * 1024)
            var at = 0
            while (at < values.size) {
                val count = min(values.size - at, buffer.capacity() / 4)
                buffer.clear()
                buffer.asIntBuffer().put(values, at, count)
                output.write(buffer.array(), 0, count * 4)
                at += count
            }
        }

        private fun writeLongArray(output: java.io.DataOutputStream, values: LongArray) {
            output.writeInt(values.size)
            val buffer = java.nio.ByteBuffer.allocate(64 * 1024)
            var at = 0
            while (at < values.size) {
                val count = min(values.size - at, buffer.capacity() / 8)
                buffer.clear()
                buffer.asLongBuffer().put(values, at, count)
                output.write(buffer.array(), 0, count * 8)
                at += count
            }
        }

        private fun writeByteArray(output: java.io.DataOutputStream, values: ByteArray, length: Int = values.size) {
            output.writeInt(length)
            output.write(values, 0, length)
        }

        /**
         * Streams a snapshot without holding the file in memory. Every count is
         * checked against the bytes left, so damage cannot request a huge array.
         */
        private class SnapshotReader(input: java.io.InputStream, private val limit: Long) {
            private val data = java.io.DataInputStream(input)
            private var offset = 0L
            private val scratch = ByteArray(64 * 1024)
            private fun need(length: Long) {
                if (length < 0 || length > limit - offset) throw IllegalArgumentException("Oyun indeksi bozuk.")
            }
            fun int(): Int {
                need(4)
                offset += 4
                return data.readInt()
            }
            fun count(elementBytes: Int = 1): Int = int().also { need(it.toLong() * elementBytes) }
            fun bytes(): ByteArray {
                val length = count()
                return ByteArray(length).also { data.readFully(it); offset += length }
            }
            fun text(): String = String(bytes(), Charsets.UTF_8)
            fun optionalText(): String? {
                val length = int()
                if (length == -1) return null
                need(length.toLong())
                val value = ByteArray(length).also { data.readFully(it) }
                offset += length
                return String(value, Charsets.UTF_8)
            }
            fun ints(): IntArray {
                val size = count(4)
                val result = IntArray(size)
                var at = 0
                while (at < size) {
                    val chunk = min(size - at, scratch.size / 4)
                    data.readFully(scratch, 0, chunk * 4)
                    java.nio.ByteBuffer.wrap(scratch, 0, chunk * 4).asIntBuffer().get(result, at, chunk)
                    at += chunk
                }
                offset += size * 4L
                return result
            }
            fun longs(): LongArray {
                val size = count(8)
                val result = LongArray(size)
                var at = 0
                while (at < size) {
                    val chunk = min(size - at, scratch.size / 8)
                    data.readFully(scratch, 0, chunk * 8)
                    java.nio.ByteBuffer.wrap(scratch, 0, chunk * 8).asLongBuffer().get(result, at, chunk)
                    at += chunk
                }
                offset += size * 8L
                return result
            }
            /** Pages are read one by one; a damaged length cannot allocate beyond the bytes left. */
            fun textTable(): TextTable {
                val length = count()
                val pages = Array(TextTable.pageCount(length)) { page ->
                    ByteArray(min(TextTable.PAGE_SIZE, length - page * TextTable.PAGE_SIZE)).also { data.readFully(it) }
                }
                offset += length
                val offsets = ints()
                require(offsets.isNotEmpty() && offsets[0] == 0 && offsets.last() == length) { "Oyun indeksi bozuk." }
                for (i in 1 until offsets.size) require(offsets[i] >= offsets[i - 1]) { "Oyun indeksi bozuk." }
                return TextTable(pages, offsets)
            }
            val finished get() = offset == limit
        }

        /** Hides bytes beyond [limit] so the checksum covers exactly the snapshot body. */
        private class LimitedInputStream(input: java.io.InputStream, private var remaining: Long) :
            java.io.FilterInputStream(input) {
            override fun read(): Int {
                if (remaining <= 0) return -1
                val value = super.read()
                if (value >= 0) remaining--
                return value
            }
            override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
                if (remaining <= 0) return -1
                val count = super.read(buffer, offset, min(length.toLong(), remaining).toInt())
                if (count > 0) remaining -= count
                return count
            }
            override fun skip(count: Long): Long = super.skip(min(count, remaining)).also { remaining -= it }
            override fun available(): Int = min(super.available().toLong(), remaining).toInt()
            override fun markSupported() = false
        }

        /**
         * Reads a snapshot written by [writeSnapshot] for exactly this game, language pair,
         * pack version and app build. Any mismatch or damage throws; callers rebuild from JSON.
         */
        internal fun readSnapshot(
            bytes: ByteArray,
            gameId: String,
            sourceLanguage: String,
            targetLanguage: String,
            contentKey: String,
            buildTag: String,
        ): GameTranslationMemory = readSnapshot(java.io.ByteArrayInputStream(bytes), bytes.size.toLong(),
            gameId, sourceLanguage, targetLanguage, contentKey, buildTag)

        internal fun readSnapshot(
            file: java.io.File,
            gameId: String,
            sourceLanguage: String,
            targetLanguage: String,
            contentKey: String,
            buildTag: String,
        ): GameTranslationMemory = java.io.BufferedInputStream(file.inputStream(), 64 * 1024).use { input ->
            readSnapshot(input, file.length(), gameId, sourceLanguage, targetLanguage, contentKey, buildTag)
        }

        /** [length] includes the trailing CRC-32 of everything before it. */
        private fun readSnapshot(
            input: java.io.InputStream,
            length: Long,
            gameId: String,
            sourceLanguage: String,
            targetLanguage: String,
            contentKey: String,
            buildTag: String,
        ): GameTranslationMemory {
            require(length >= 16) { "Oyun indeksi bozuk." }
            val limit = length - 8
            val checksum = java.util.zip.CRC32()
            val body = java.util.zip.CheckedInputStream(LimitedInputStream(input, limit), checksum)
            val reader = SnapshotReader(body, limit)
            val memory = try {
                require(reader.int() == SNAPSHOT_MAGIC && reader.int() == SNAPSHOT_VERSION) { "Oyun indeksi sürümü farklı." }
                require(reader.text() == buildTag && reader.text() == gameId && reader.text() == sourceLanguage &&
                    reader.text() == targetLanguage && reader.text() == contentKey) { "Oyun indeksi bu paket için değil." }
                val entryCount = reader.int()
                val gameProfileJson = reader.optionalText()
                val speakers = LinkedHashMap<String, String>()
                repeat(reader.count(8)) { speakers[reader.text()] = reader.text() }
                fun table() = reader.textTable()
                val ids = table(); val sources = table(); val targets = table(); val chapters = table()
                val kinds = table(); val speakerNames = table(); val normalized = table()
                val ints = Array(17) { reader.ints() }
                fun postings(keyed: Boolean) = PostingTable(
                    keys = reader.longs(),
                    keyText = if (keyed) table() else null,
                    offsets = reader.ints(),
                    counts = reader.ints(),
                    data = reader.bytes(),
                )
                val grams = postings(keyed = false)
                val words = postings(keyed = true)
                val exactKeys = reader.longs()
                val compactKeys = reader.longs()
                val meanings = HashSet<MeaningTokens>()
                repeat(reader.count(8)) {
                    val negated = when (reader.int()) { 0 -> false; 1 -> true; else -> throw IllegalArgumentException("Oyun indeksi bozuk.") }
                    val numbers = List(reader.count(4)) { reader.text() }
                    meanings.add(MeaningTokens(numbers, negated))
                }
                require(reader.finished) { "Oyun indeksi bozuk." }
                val store = Store(ids, sources, targets, chapters, kinds, speakerNames, normalized,
                    ints[0], ints[1], ints[2], ints[3], ints[4], ints[5], ints[6], ints[7], ints[8], ints[9],
                    ints[10], ints[11], ints[12], ints[13], ints[14], ints[15], ints[16], grams, words)
                // The checksum is verified before the arrays are trusted for indexing.
                val stored = java.io.DataInputStream(input).readLong()
                require(stored == checksum.value) { "Oyun indeksi bozuk." }
                store.validate()
                val exact = HashIndex.read(exactKeys, store.entryCount)
                val compact = HashIndex.read(compactKeys, store.entryCount)
                GameTranslationMemory(gameId, sourceLanguage, targetLanguage, entryCount, gameProfileJson, store, speakers,
                    exact, compact, meanings)
            } catch (error: java.io.EOFException) {
                throw IllegalArgumentException("Oyun indeksi bozuk.", error)
            }
            return memory
        }

        /**
         * UTF-8 texts in fixed-size pages addressed by global byte offsets. Pages
         * never move or grow, so building a table never copies or doubles a large
         * array. A text that UTF-8 cannot carry exactly is kept aside unchanged.
         */
        private class TextTable(
            private val pages: Array<ByteArray>,
            private val offsets: IntArray,
            private val irregular: Map<Int, String> = emptyMap(),
        ) {
            val size get() = offsets.size - 1
            val byteLength get() = offsets[offsets.size - 1]
            val hasIrregularText get() = irregular.isNotEmpty()

            operator fun get(index: Int): String {
                irregular[index]?.let { return it }
                val start = offsets[index]
                val length = offsets[index + 1] - start
                val page = start ushr PAGE_SHIFT
                val at = start and PAGE_MASK
                if (at + length <= PAGE_SIZE) return String(pages[page], at, length, Charsets.UTF_8)
                val bytes = ByteArray(length)
                copyBytes(start, bytes, length)
                return String(bytes, Charsets.UTF_8)
            }

            fun optional(index: Int): String? = if (index < 0) null else get(index)

            private fun byteAt(position: Int) = pages[position ushr PAGE_SHIFT][position and PAGE_MASK]

            /** The text before the first [mark] in the first [maxBytes] bytes of [index], or null. */
            fun prefixBefore(index: Int, mark: Char, maxBytes: Int): String? {
                irregular[index]?.let { text ->
                    val at = text.indexOf(mark)
                    return if (at in 1..maxBytes) text.substring(0, at) else null
                }
                val start = offsets[index]
                val length = min(offsets[index + 1] - start, maxBytes + 1)
                for (offset in 1 until length) {
                    if (byteAt(start + offset) != mark.code.toByte()) continue
                    val bytes = ByteArray(offset)
                    copyBytes(start, bytes, offset)
                    return String(bytes, Charsets.UTF_8)
                }
                return null
            }

            private fun copyBytes(start: Int, target: ByteArray, length: Int) {
                var copied = 0
                while (copied < length) {
                    val position = start + copied
                    val at = position and PAGE_MASK
                    val count = min(length - copied, PAGE_SIZE - at)
                    System.arraycopy(pages[position ushr PAGE_SHIFT], at, target, copied, count)
                    copied += count
                }
            }

            fun hash(index: Int, skipSpaces: Boolean): Long {
                var hash = FNV_OFFSET
                for (position in offsets[index] until offsets[index + 1]) {
                    val value = byteAt(position)
                    if (skipSpaces && value == SPACE) continue
                    hash = (hash xor (value.toLong() and 255)) * FNV_PRIME
                }
                return finishHash(hash)
            }

            fun sameBytes(index: Int, other: ByteArray, skipSpaces: Boolean): Boolean {
                var left = offsets[index]
                val leftEnd = offsets[index + 1]
                if (!skipSpaces) {
                    if (leftEnd - left != other.size) return false
                    for (i in other.indices) if (byteAt(left + i) != other[i]) return false
                    return true
                }
                var right = 0
                while (true) {
                    while (left < leftEnd && byteAt(left) == SPACE) left++
                    while (right < other.size && other[right] == SPACE) right++
                    if (left == leftEnd || right == other.size) return left == leftEnd && right == other.size
                    if (byteAt(left++) != other[right++]) return false
                }
            }

            fun write(output: java.io.DataOutputStream) {
                output.writeInt(byteLength)
                var remaining = byteLength
                for (page in pages) {
                    if (remaining <= 0) break
                    val count = min(remaining, PAGE_SIZE)
                    output.write(page, 0, count)
                    remaining -= count
                }
                writeIntArray(output, offsets)
            }

            /** Logical size: identical for a parsed table and the same table read from a snapshot. */
            fun retainedBytes() = 32L + byteLength + 16L * pages.size + 16L + 4L * offsets.size +
                irregular.values.sumOf { 64L + 2L * it.length }

            companion object {
                const val PAGE_SHIFT = 16
                const val PAGE_SIZE = 1 shl PAGE_SHIFT
                const val PAGE_MASK = PAGE_SIZE - 1

                fun pageCount(length: Int) = (length + PAGE_SIZE - 1) / PAGE_SIZE
            }
        }

        private class TextTableBuilder {
            private val pages = ArrayList<ByteArray>()
            private var length = 0
            private var offsets = IntArray(1024)
            var size = 0
                private set
            private val irregular = HashMap<Int, String>()

            fun add(value: String): Int {
                if (size + 1 >= offsets.size) offsets = offsets.copyOf(offsets.size * 2)
                if (isWellFormedText(value)) {
                    val encoded = value.toByteArray(Charsets.UTF_8)
                    require(length.toLong() + encoded.size <= Int.MAX_VALUE - TextTable.PAGE_SIZE) { "Oyun çeviri paketi çok büyük." }
                    var copied = 0
                    while (copied < encoded.size) {
                        val at = length and TextTable.PAGE_MASK
                        if (at == 0 && (length ushr TextTable.PAGE_SHIFT) == pages.size) pages.add(ByteArray(TextTable.PAGE_SIZE))
                        val count = min(encoded.size - copied, TextTable.PAGE_SIZE - at)
                        System.arraycopy(encoded, copied, pages[length ushr TextTable.PAGE_SHIFT], at, count)
                        copied += count
                        length += count
                    }
                } else {
                    irregular[size] = value
                }
                offsets[++size] = length
                return size - 1
            }

            operator fun get(index: Int): String {
                irregular[index]?.let { return it }
                val start = offsets[index]
                val bytes = ByteArray(offsets[index + 1] - start)
                var copied = 0
                while (copied < bytes.size) {
                    val position = start + copied
                    val at = position and TextTable.PAGE_MASK
                    val count = min(bytes.size - copied, TextTable.PAGE_SIZE - at)
                    System.arraycopy(pages[position ushr TextTable.PAGE_SHIFT], at, bytes, copied, count)
                    copied += count
                }
                return String(bytes, Charsets.UTF_8)
            }

            /** Hands the pages over; only the last partial page is trimmed. The builder is empty afterwards. */
            fun build(): TextTable {
                val count = TextTable.pageCount(length)
                val used = Array(count) { pages[it] }
                val tail = length and TextTable.PAGE_MASK
                if (count > 0 && tail != 0) used[count - 1] = used[count - 1].copyOf(tail)
                val table = TextTable(used, offsets.copyOf(size + 1), HashMap(irregular))
                pages.clear()
                offsets = IntArray(1)
                length = 0
                size = 0
                irregular.clear()
                return table
            }
        }

        /** Distinct optional values (chapter, kind, speaker) stored once, referenced by index. */
        private class ValueTableBuilder {
            private val indices = HashMap<String, Int>()
            val table = TextTableBuilder()
            fun ref(value: String?): Int = if (value == null) -1 else indices.getOrPut(value) { table.add(value) }
        }

        private class IntArrayBuilder(capacity: Int = 1024) {
            private var values = IntArray(capacity)
            var size = 0
                private set
            fun add(value: Int) {
                if (size == values.size) values = values.copyOf(size * 2)
                values[size++] = value
            }
            operator fun get(index: Int) = values[index]
            operator fun set(index: Int, value: Int) { values[index] = value }
            /** Hands the values over; the builder is empty afterwards. */
            fun build(): IntArray {
                val result = if (size == values.size) values else values.copyOf(size)
                values = IntArray(0)
                size = 0
                return result
            }
        }

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

        private fun varintLength(value: Int): Int {
            var delta = value
            var length = 0
            do { length++; delta = delta ushr 7 } while (delta != 0)
            return length
        }

        /**
         * First pass over the stored texts: exact posting count and encoded size per key.
         * Posting IDs arrive sorted, so most deltas need one byte instead of four.
         */
        private class PostingCounter {
            var counts = IntArray(1024)
                private set
            var lengths = IntArray(1024)
                private set
            private var last = IntArray(1024)
            fun count(slot: Int, index: Int) {
                if (slot >= counts.size) {
                    val capacity = max(slot + 1, counts.size * 2)
                    counts = counts.copyOf(capacity); lengths = lengths.copyOf(capacity); last = last.copyOf(capacity)
                }
                if (counts[slot] > 0 && last[slot] == index) return
                lengths[slot] += varintLength(index - if (counts[slot] == 0) 0 else last[slot])
                counts[slot]++
                last[slot] = index
            }
        }

        /** Second pass: writes each key's deltas at its precomputed position in one exact block. */
        private class PostingWriter(private val data: ByteArray, private val cursor: IntArray) {
            private val last = IntArray(cursor.size)
            private val started = BooleanArray(cursor.size)
            fun write(rank: Int, index: Int) {
                if (started[rank] && last[rank] == index) return
                var delta = index - if (started[rank]) last[rank] else 0
                started[rank] = true
                last[rank] = index
                var at = cursor[rank]
                do {
                    data[at++] = ((delta and 127) or if (delta >= 128) 128 else 0).toByte()
                    delta = delta ushr 7
                } while (delta != 0)
                cursor[rank] = at
            }
        }

        /** Open addressing: trigram code → slot, without boxing millions of keys. */
        private class LongSlots {
            private var keys = LongArray(1 shl 16)
            private var slots = IntArray(1 shl 16) { -1 }
            var codes = LongArray(1024)
                private set
            var size = 0
                private set
            private fun mix(code: Long): Long {
                val value = code * MIX_1
                return value xor (value ushr 29)
            }
            fun slot(code: Long): Int {
                val mask = keys.size - 1
                var at = (mix(code) and mask.toLong()).toInt()
                while (true) {
                    val slot = slots[at]
                    if (slot < 0) break
                    if (keys[at] == code) return slot
                    at = (at + 1) and mask
                }
                val slot = size++
                if (slot == codes.size) codes = codes.copyOf(codes.size * 2)
                codes[slot] = code
                slots[at] = slot
                keys[at] = code
                if (size * 2 > keys.size) grow()
                return slot
            }
            /** Slot of a code already added in the first pass. */
            fun existing(code: Long): Int {
                val mask = keys.size - 1
                var at = (mix(code) and mask.toLong()).toInt()
                while (keys[at] != code || slots[at] < 0) at = (at + 1) and mask
                return slots[at]
            }
            private fun grow() {
                val oldKeys = keys
                val oldSlots = slots
                keys = LongArray(oldKeys.size * 2)
                slots = IntArray(oldKeys.size * 2) { -1 }
                val mask = keys.size - 1
                for (i in oldKeys.indices) {
                    val slot = oldSlots[i]
                    if (slot < 0) continue
                    var at = (mix(oldKeys[i]) and mask.toLong()).toInt()
                    while (slots[at] >= 0) at = (at + 1) and mask
                    keys[at] = oldKeys[i]
                    slots[at] = slot
                }
            }
        }

        /**
         * Sorted 64-bit keys with delta-encoded postings in one block. Trigram keys are
         * their three characters; word keys are hashes verified against [keyText].
         */
        private class PostingTable(
            val keys: LongArray,
            val keyText: TextTable?,
            val offsets: IntArray,
            val counts: IntArray,
            val data: ByteArray,
        ) {
            fun find(key: Long): Int {
                val at = java.util.Arrays.binarySearch(keys, key)
                return if (at >= 0) at else -1
            }

            fun find(word: String): Int {
                val text = keyText ?: return -1
                val encoded = word.toByteArray(Charsets.UTF_8)
                val hash = hash64(encoded, 0, encoded.size, false)
                var at = java.util.Arrays.binarySearch(keys, hash)
                if (at < 0) return -1
                while (at > 0 && keys[at - 1] == hash) at--
                while (at < keys.size && keys[at] == hash) {
                    if (text.sameBytes(at, encoded, false)) return at
                    at++
                }
                return -1
            }

            fun count(slot: Int) = counts[slot]

            fun postings(slot: Int): IntIterator = object : IntIterator() {
                private var offset = offsets[slot]
                private val end = offsets[slot + 1]
                private var previous = 0
                override fun hasNext() = offset < end
                override fun nextInt(): Int {
                    if (!hasNext()) throw NoSuchElementException()
                    var delta = 0
                    var shift = 0
                    do {
                        val value = data[offset++].toInt() and 255
                        delta = delta or ((value and 127) shl shift)
                        shift += 7
                    } while (value and 128 != 0)
                    previous += delta
                    return previous
                }
            }

            fun validate(entries: Int) {
                require(offsets.size == keys.size + 1 && counts.size == keys.size && offsets[0] == 0 &&
                    offsets.last() == data.size && (keyText == null || keyText.size == keys.size)) { "Oyun indeksi bozuk." }
                for (i in keys.indices) {
                    require(offsets[i + 1] >= offsets[i] && counts[i] >= 0 && (i == 0 || keys[i] >= keys[i - 1])) {
                        "Oyun indeksi bozuk."
                    }
                }
                // Each posting takes at least one byte and at most five; the CRC covers the bytes themselves.
                for (i in keys.indices) {
                    val length = offsets[i + 1] - offsets[i]
                    require(counts[i] <= length && length <= 5L * counts[i] && (counts[i] == 0 || entries > 0)) {
                        "Oyun indeksi bozuk."
                    }
                }
            }

            fun write(output: java.io.DataOutputStream) {
                writeLongArray(output, keys)
                keyText?.write(output)
                writeIntArray(output, offsets)
                writeIntArray(output, counts)
                writeByteArray(output, data)
            }

            fun retainedBytes() = 64L + 8L * keys.size + (keyText?.retainedBytes() ?: 0L) +
                4L * offsets.size + 4L * counts.size + data.size

            companion object {
                /**
                 * Builds both tables from the stored normalized texts in two passes:
                 * sizes first, then one exactly sized block per table. Nothing grows.
                 */
                fun build(normalized: TextTable): Pair<PostingTable, PostingTable> {
                    val gramSlots = LongSlots()
                    val wordSlots = HashMap<String, Int>()
                    val gramCounter = PostingCounter()
                    val wordCounter = PostingCounter()
                    for (index in 0 until normalized.size) {
                        val text = normalized[index]
                        for (at in 0..text.length - 3) gramCounter.count(gramSlots.slot(gramCode(text, at)), index)
                        for (word in text.split(' ')) if (word.length >= 3) {
                            wordCounter.count(wordSlots.getOrPut(word) { wordSlots.size }, index)
                        }
                    }
                    // Trigram keys sort by code; word keys by hash, then text, so a snapshot rebuilds identically.
                    val gramCount = gramSlots.size
                    val gramOrder = (0 until gramCount).sortedBy { gramSlots.codes[it] }
                    val gramRank = IntArray(gramCount).also { rank -> gramOrder.forEachIndexed { at, slot -> rank[slot] = at } }
                    val wordTexts = arrayOfNulls<String>(wordSlots.size)
                    for ((word, slot) in wordSlots) wordTexts[slot] = word
                    val wordHashes = LongArray(wordTexts.size) {
                        val encoded = wordTexts[it]!!.toByteArray(Charsets.UTF_8)
                        hash64(encoded, 0, encoded.size, false)
                    }
                    val wordOrder = wordTexts.indices.sortedWith(compareBy<Int> { wordHashes[it] }.thenBy { wordTexts[it]!! })
                    val wordRank = IntArray(wordTexts.size).also { rank -> wordOrder.forEachIndexed { at, slot -> rank[slot] = at } }
                    val keyText = TextTableBuilder().also { table -> wordOrder.forEach { table.add(wordTexts[it]!!) } }.build()

                    fun layout(order: List<Int>, counter: PostingCounter): Triple<IntArray, IntArray, ByteArray> {
                        val offsets = IntArray(order.size + 1)
                        val counts = IntArray(order.size)
                        var total = 0L
                        for ((rank, slot) in order.withIndex()) {
                            total += counter.lengths[slot]
                            require(total <= Int.MAX_VALUE - 16) { "Oyun çeviri paketi çok büyük." }
                            offsets[rank + 1] = total.toInt()
                            counts[rank] = counter.counts[slot]
                        }
                        return Triple(offsets, counts, ByteArray(total.toInt()))
                    }
                    val (gramOffsets, gramCounts, gramData) = layout(gramOrder, gramCounter)
                    val (wordOffsets, wordCounts, wordData) = layout(wordOrder, wordCounter)
                    val gramWriter = PostingWriter(gramData, gramOffsets.copyOf(gramCount))
                    val wordWriter = PostingWriter(wordData, wordOffsets.copyOf(wordTexts.size))
                    for (index in 0 until normalized.size) {
                        val text = normalized[index]
                        for (at in 0..text.length - 3) gramWriter.write(gramRank[gramSlots.existing(gramCode(text, at))], index)
                        for (word in text.split(' ')) if (word.length >= 3) wordWriter.write(wordRank[wordSlots.getValue(word)], index)
                    }
                    val grams = PostingTable(LongArray(gramCount) { gramSlots.codes[gramOrder[it]] }, null,
                        gramOffsets, gramCounts, gramData)
                    val words = PostingTable(LongArray(wordTexts.size) { wordHashes[wordOrder[it]] }, keyText,
                        wordOffsets, wordCounts, wordData)
                    return grams to words
                }
            }
        }

        /**
         * Entry indexes sorted by a 40-bit text hash (high bits) and the entry index
         * (low 24 bits). Equal hashes keep ascending entry order, as the former
         * per-text lists did; every hit is verified against the stored bytes.
         */
        private class HashIndex(val keys: LongArray) {
            fun find(texts: TextTable, query: String, skipSpaces: Boolean): List<Int> {
                val encoded = query.toByteArray(Charsets.UTF_8)
                val prefix = hash64(encoded, 0, encoded.size, skipSpaces) and HASH_MASK
                var low = 0
                var high = keys.size
                while (low < high) {
                    val middle = (low + high) ushr 1
                    if (keys[middle] < prefix) low = middle + 1 else high = middle
                }
                var result: ArrayList<Int>? = null
                while (low < keys.size && (keys[low] and HASH_MASK) == prefix) {
                    val index = (keys[low] and INDEX_MASK).toInt()
                    if (texts.sameBytes(index, encoded, skipSpaces)) {
                        (result ?: ArrayList<Int>(2).also { result = it }).add(index)
                    }
                    low++
                }
                return result ?: emptyList()
            }

            fun retainedBytes() = 16L + 8L * keys.size

            companion object {
                const val INDEX_BITS = 24
                const val INDEX_MASK = (1L shl INDEX_BITS) - 1
                const val HASH_MASK = INDEX_MASK.inv()

                /** Every entry exactly once, in key order; the hashes themselves are covered by the CRC. */
                fun read(keys: LongArray, entries: Int): HashIndex {
                    require(keys.size == entries) { "Oyun indeksi bozuk." }
                    val seen = BooleanArray(entries)
                    for (i in keys.indices) {
                        val index = (keys[i] and INDEX_MASK).toInt()
                        require(index < entries && !seen[index] && (i == 0 || keys[i] > keys[i - 1])) { "Oyun indeksi bozuk." }
                        seen[index] = true
                    }
                    return HashIndex(keys)
                }

                fun build(texts: TextTable, skipSpaces: Boolean): HashIndex {
                    require(texts.size <= INDEX_MASK) { "Oyun çeviri paketi çok büyük." }
                    val keys = LongArray(texts.size) { index ->
                        (texts.hash(index, skipSpaces) and HASH_MASK) or index.toLong()
                    }
                    keys.sort()
                    return HashIndex(keys)
                }
            }
        }

        private const val SPACE = ' '.code.toByte()
        private val FNV_OFFSET = 0xcbf29ce484222325UL.toLong()
        private const val FNV_PRIME = 0x100000001b3L
        private val MIX_1 = 0xff51afd7ed558ccdUL.toLong()
        private val MIX_2 = 0xc4ceb9fe1a85ec53UL.toLong()

        private fun hash64(bytes: ByteArray, from: Int, to: Int, skipSpaces: Boolean): Long {
            var hash = FNV_OFFSET
            for (i in from until to) {
                val value = bytes[i]
                if (skipSpaces && value == SPACE) continue
                hash = (hash xor (value.toLong() and 255)) * FNV_PRIME
            }
            return finishHash(hash)
        }

        private fun finishHash(value: Long): Long {
            var hash = value xor (value ushr 33)
            hash *= MIX_1
            hash = hash xor (hash ushr 33)
            hash *= MIX_2
            return hash xor (hash ushr 33)
        }

        private const val WHOLE_SINGLE = -2
        private const val WHOLE_PARENT = -1

        /** Trigram key: the three UTF-16 code units of normalized text. */
        private fun gramCode(text: String, at: Int): Long =
            (text[at].code.toLong() shl 32) or (text[at + 1].code.toLong() shl 16) or text[at + 2].code.toLong()

        /**
         * Collects records, sentences, entries and spans while the pack streams in.
         * Rows are deduplicated by (normalized source, target, speaker) exactly as
         * before, without keeping a Triple of Strings per row.
         */
        private class StoreBuilder {
            val ids = TextTableBuilder()
            val sources = TextTableBuilder()
            val targets = TextTableBuilder()
            val chapters = ValueTableBuilder()
            val kinds = ValueTableBuilder()
            val speakers = ValueTableBuilder()
            val normalized = TextTableBuilder()
            val recordChapter = IntArrayBuilder()
            val recordKind = IntArrayBuilder()
            val recordSpeaker = IntArrayBuilder()
            val recordSentenceFirst = IntArrayBuilder()
            val recordSentenceCount = IntArrayBuilder()
            val recordEntry = IntArrayBuilder()
            val sentenceSourceStart = IntArrayBuilder()
            val sentenceSourceEnd = IntArrayBuilder()
            val sentenceTargetStart = IntArrayBuilder()
            val sentenceTargetEnd = IntArrayBuilder()
            val entryRecord = IntArrayBuilder()
            val entryLength = IntArrayBuilder()
            val entryWordCount = IntArrayBuilder()
            val entrySentence = IntArrayBuilder()
            val spanRecord = IntArrayBuilder()
            val spanStart = IntArrayBuilder()
            val spanEnd = IntArrayBuilder()
            val spanLength = IntArrayBuilder()

            private var translationKeys = LongArray(1 shl 12)
            private var translationRecords = IntArray(1 shl 12) { -1 }
            private var translationCount = 0

            private fun translationHash(normalized: String, target: String, speaker: String?): Long {
                var hash = FNV_OFFSET
                fun add(value: String) {
                    for (character in value) hash = (hash xor character.code.toLong()) * FNV_PRIME
                    hash = (hash xor 0x10000L) * FNV_PRIME // separator outside the char range
                }
                add(normalized); add(target)
                if (speaker == null) hash = (hash xor 0x20000L) * FNV_PRIME else add(speaker)
                return finishHash(hash)
            }

            private fun sameTranslation(record: Int, normalized: String, target: String, speaker: String?) =
                this.normalized[recordEntry[record]] == normalized && targets[record] == target &&
                    recordSpeaker[record].let { if (it < 0) null else speakers.table[it] } == speaker

            /** Returns the new record, or -1 when the same translation is already indexed. */
            fun addRecord(id: String, chapter: String?, kind: String?, speaker: String?, source: String,
                target: String, normalized: String): Int {
                val hash = translationHash(normalized, target, speaker)
                var mask = translationKeys.size - 1
                var at = (hash and mask.toLong()).toInt()
                while (true) {
                    val record = translationRecords[at]
                    if (record < 0) break
                    if (translationKeys[at] == hash && sameTranslation(record, normalized, target, speaker)) return -1
                    at = (at + 1) and mask
                }
                val record = ids.add(id)
                sources.add(source)
                targets.add(target)
                recordChapter.add(chapters.ref(chapter))
                recordKind.add(kinds.ref(kind))
                recordSpeaker.add(speakers.ref(speaker))
                recordSentenceFirst.add(-1)
                recordSentenceCount.add(0)
                recordEntry.add(entryRecord.size)
                translationKeys[at] = hash
                translationRecords[at] = record
                if (++translationCount * 2 > translationKeys.size) {
                    val oldKeys = translationKeys
                    val oldRecords = translationRecords
                    translationKeys = LongArray(oldKeys.size * 2)
                    translationRecords = IntArray(oldKeys.size * 2) { -1 }
                    mask = translationKeys.size - 1
                    for (i in oldKeys.indices) {
                        if (oldRecords[i] < 0) continue
                        var slot = (oldKeys[i] and mask.toLong()).toInt()
                        while (translationRecords[slot] >= 0) slot = (slot + 1) and mask
                        translationKeys[slot] = oldKeys[i]
                        translationRecords[slot] = oldRecords[i]
                    }
                }
                return record
            }

            /** Normalized text has single spaces between word tokens and none at the ends. */
            fun addEntry(record: Int, normalizedText: String, sentence: Int) {
                entryRecord.add(record)
                normalized.add(normalizedText)
                entryLength.add(normalizedText.length)
                entryWordCount.add(if (normalizedText.isEmpty()) 0 else normalizedText.count { it == ' ' } + 1)
                entrySentence.add(sentence)
            }

            /** Stores the record's aligned sentence ranges; returns the first sentence's global index. */
            fun addSentences(record: Int, sourceRanges: IntArray, targetRanges: IntArray): Int {
                val first = sentenceSourceStart.size
                val count = sourceRanges.size / 2
                for (i in 0 until count) {
                    sentenceSourceStart.add(sourceRanges[2 * i]); sentenceSourceEnd.add(sourceRanges[2 * i + 1])
                    sentenceTargetStart.add(targetRanges[2 * i]); sentenceTargetEnd.add(targetRanges[2 * i + 1])
                }
                recordSentenceFirst[record] = first
                recordSentenceCount[record] = count
                return first
            }

            fun addSpan(record: Int, start: Int, end: Int, normalizedLength: Int) {
                spanRecord.add(record); spanStart.add(start); spanEnd.add(end); spanLength.add(normalizedLength)
            }

            fun build(): Store {
                translationKeys = LongArray(0)
                translationRecords = IntArray(0)
                recordEntry.build()
                val normalizedTable = normalized.build()
                val (grams, words) = PostingTable.build(normalizedTable)
                return Store(
                    ids.build(), sources.build(), targets.build(), chapters.table.build(), kinds.table.build(),
                    speakers.table.build(), normalizedTable, recordChapter.build(), recordKind.build(),
                    recordSpeaker.build(), recordSentenceFirst.build(), recordSentenceCount.build(),
                    sentenceSourceStart.build(), sentenceSourceEnd.build(), sentenceTargetStart.build(),
                    sentenceTargetEnd.build(), entryRecord.build(), entryLength.build(), entryWordCount.build(),
                    entrySentence.build(), spanRecord.build(), spanStart.build(), spanEnd.build(), spanLength.build(),
                    grams, words,
                )
            }
        }

        private data class MeaningTokens(val numbers: List<String>, val negated: Boolean)
        private val NUMBER = Regex("""\p{N}+""")
        private val NEGATIONS = setOf("no", "not", "never", "nothing", "nobody", "nowhere", "neither", "nor", "without", "aint",
            "dont", "doesnt", "didnt", "isnt", "arent", "wasnt", "werent", "wont", "wouldnt", "couldnt", "shouldnt",
            "cant", "cannot", "havent", "hasnt", "hadnt", "mustnt")
        private val NEGATION_STEMS = NEGATIONS.filter { it.endsWith("nt") }.map { it.dropLast(1) }.toSet()
        private val APOSTROPHIZED_NEGATION = Regex("""\b([\p{L}]{1,24})['‘’ʼ]t""")
        /**
         * Same result as splitting on ' ' and matching \p{N}+ (kept below as the
         * reference), without a regex or a String per word: it runs for every entry.
         */
        private fun meaningTokens(value: String): MeaningTokens {
            var numbers: ArrayList<String>? = null
            var runStart = -1
            var at = 0
            while (at < value.length) {
                val codePoint = value.codePointAt(at)
                val size = Character.charCount(codePoint)
                if (isNumberCodePoint(codePoint)) {
                    if (runStart < 0) runStart = at
                } else if (runStart >= 0) {
                    (numbers ?: ArrayList<String>(2).also { numbers = it }).add(value.substring(runStart, at))
                    runStart = -1
                }
                at += size
            }
            if (runStart >= 0) (numbers ?: ArrayList<String>(1).also { numbers = it }).add(value.substring(runStart))
            return MeaningTokens(numbers ?: emptyList(), hasNegation(value))
        }

        private fun isNumberCodePoint(codePoint: Int): Boolean = when (Character.getType(codePoint)) {
            Character.DECIMAL_DIGIT_NUMBER.toInt(), Character.LETTER_NUMBER.toInt(), Character.OTHER_NUMBER.toInt() -> true
            else -> false
        }

        /** A word in [NEGATIONS], or a word followed by a lone "t" that together form one ("don t"). */
        private fun hasNegation(value: String): Boolean {
            var start = 0
            var previousStart = -1
            var previousEnd = -1
            while (start <= value.length) {
                var end = value.indexOf(' ', start)
                if (end < 0) end = value.length
                val length = end - start
                if (length in 2..MAX_NEGATION_LENGTH && value.substring(start, end) in NEGATIONS) return true
                if (length == 1 && value[start] == 't' && previousStart >= 0 &&
                    previousEnd - previousStart + 1 in 2..MAX_NEGATION_LENGTH &&
                    value.substring(previousStart, previousEnd) + "t" in NEGATIONS) return true
                previousStart = start
                previousEnd = end
                start = end + 1
            }
            return false
        }

        private val MAX_NEGATION_LENGTH = NEGATIONS.maxOf { it.length }

        @Suppress("unused") // Reference definition the scanner above must match.
        private fun referenceMeaningTokens(value: String): MeaningTokens {
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
        ): GameTranslationMemory = parse(gameId, sourceLanguage, targetLanguage, java.io.StringReader(json))

        /**
         * Streams the pack: large (also gzip-expanded) JSON never exists as one
         * String or a JSONObject tree, only as the blocks kept for matching.
         */
        fun parse(
            gameId: String,
            sourceLanguage: String,
            targetLanguage: String,
            json: java.io.Reader,
        ): GameTranslationMemory {
            val sink = object : RowSink {
                var builder: StoreBuilder? = StoreBuilder()
                override fun add(id: String, chapter: String?, kind: String?, speaker: String?, source: String,
                    target: String, normalized: String) =
                    addRow(builder!!, id, chapter, kind, speaker, source, target, normalized)
                override fun reset() { builder = StoreBuilder() }
            }
            val (entryCount, speakerTranslations, gameProfileJson) = readEntries(json, sourceLanguage, targetLanguage, sink)
            val store = sink.builder!!.build()
            sink.builder = null // Let the build scratch go before the indexes are derived.
            return GameTranslationMemory(gameId, sourceLanguage, targetLanguage, entryCount, gameProfileJson,
                store, speakerTranslations)
        }

        /** Same rules as before: one translation indexed once, aligned sentences and spans added. */
        private fun addRow(builder: StoreBuilder, id: String, chapter: String?, kind: String?, speaker: String?,
            source: String, target: String, normalized: String) {
            if (normalized.isEmpty() || target.isBlank()) return
            // Localisation tables repeat identical text under different IDs.
            // Keep every file record, but index the same translation once.
            val record = builder.addRecord(id, chapter, kind, speaker, source, target, normalized)
            if (record < 0) return
            val sourceSentences = sentenceRanges(source)
            val sourceCount = sourceSentences.size / 2
            if (sourceCount == 1) {
                builder.addEntry(record, normalized, WHOLE_SINGLE)
                return
            }
            builder.addEntry(record, normalized, WHOLE_PARENT)
            val targetSentences = sentenceRanges(target)
            if (sourceCount <= 1 || sourceCount != targetSentences.size / 2) return
            val first = builder.addSentences(record, sourceSentences, targetSentences)
            val normalizedSentences = Array(sourceCount) {
                normalize(source.substring(sourceSentences[2 * it], sourceSentences[2 * it + 1]))
            }
            for (sentenceIndex in 0 until sourceCount) {
                val normalizedSentence = normalizedSentences[sentenceIndex]
                if (normalizedSentence.isNotEmpty() &&
                    !isBlankRange(target, targetSentences[2 * sentenceIndex], targetSentences[2 * sentenceIndex + 1])) {
                    builder.addEntry(record, normalizedSentence, first + sentenceIndex)
                }
            }
            // Index only aligned, complete sentences. A visible prefix can
            // resolve without adding a later sentence such as "Ciao, Gaspare."
            for (start in 0 until sourceCount) {
                val last = min(sourceCount - 1, start + 5)
                var normalizedLength = normalizedSentences[start].length
                for (end in start + 1..last) {
                    val added = normalizedSentences[end].length
                    if (added > 0) normalizedLength += added + if (normalizedLength > 0) 1 else 0
                    if (start == 0 && end == sourceCount - 1) continue
                    builder.addSpan(record, start, end, normalizedLength)
                }
            }
        }

        private fun isBlankRange(value: String, start: Int, end: Int): Boolean {
            for (i in start until end) if (!value[i].isWhitespace()) return false
            return true
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

        /** Index lists per length, ascending; counted first so no index is boxed. */
        private fun lengthPostings(size: Int, length: (Int) -> Int): Map<Int, IntArray> {
            var longest = -1
            for (index in 0 until size) longest = max(longest, length(index))
            if (longest < 0) return emptyMap()
            val counts = IntArray(longest + 1)
            for (index in 0 until size) counts[length(index)]++
            val lists = arrayOfNulls<IntArray>(longest + 1)
            for (value in counts.indices) if (counts[value] > 0) lists[value] = IntArray(counts[value])
            val filled = IntArray(longest + 1)
            for (index in 0 until size) {
                val value = length(index)
                lists[value]!![filled[value]++] = index
            }
            val result = HashMap<Int, IntArray>()
            for (value in lists.indices) lists[value]?.let { result[value] = it }
            return result
        }

        /** A JSON value that is not a string, kept as org.json's optString showed it. */
        private class OtherValue(val text: String)
        private object Missing

        /** Only the fields the format uses; validated after the whole object is read. */
        private class RawEntry {
            val values = arrayOfNulls<Any?>(ENTRY_FIELDS.size).also { it.fill(Missing) }
            fun has(field: String) = values[ENTRY_FIELDS.indexOf(field)] !== Missing
            fun value(field: String) = values[ENTRY_FIELDS.indexOf(field)].takeUnless { it === Missing }
            fun requiredText(field: String): String = (value(field) as? String)?.takeIf(String::isNotBlank)
                ?: throw IllegalArgumentException("Oyun JSON: $field dolu metin olmalı.")
            fun optionalString(field: String): String? = when (val value = value(field)) {
                null -> null
                is OtherValue -> value.text.takeIf(String::isNotBlank)
                else -> (value as String).takeIf(String::isNotBlank)
            }
        }
        private val ENTRY_FIELDS = arrayOf("id", "english", "turkish", "sourceText", "targetText", "speaker", "chapter", "kind")

        private fun JsonReader.anyValue(): Any? = when (peek()) {
            JsonToken.STRING -> nextString()
            JsonToken.NULL -> { nextNull(); null }
            JsonToken.NUMBER -> OtherValue(nextString())
            JsonToken.BOOLEAN -> OtherValue(nextBoolean().toString())
            else -> OtherValue(JsonParser.parseReader(this).toString())
        }

        private interface RowSink {
            fun add(id: String, chapter: String?, kind: String?, speaker: String?, source: String, target: String,
                normalized: String)
            /** A repeated "entries" key replaces the earlier list, as it always did. */
            fun reset()
        }

        /** Duplicate-ID detection without one String object per row: IDs live in a UTF-8 block. */
        private class IdSet {
            private val texts = TextTableBuilder()
            private var keys = LongArray(1 shl 12)
            private var slots = IntArray(1 shl 12) { -1 }
            private var count = 0

            private fun hash(value: String): Long {
                var hash = FNV_OFFSET
                for (character in value) hash = (hash xor character.code.toLong()) * FNV_PRIME
                hash = hash xor (hash ushr 33)
                hash *= MIX_1
                return hash xor (hash ushr 33)
            }

            fun add(id: String): Boolean {
                val hash = hash(id)
                var mask = keys.size - 1
                var at = (hash and mask.toLong()).toInt()
                while (slots[at] >= 0) {
                    if (keys[at] == hash && texts[slots[at]] == id) return false
                    at = (at + 1) and mask
                }
                keys[at] = hash
                slots[at] = texts.add(id)
                if (++count * 2 > keys.size) {
                    val oldKeys = keys
                    val oldSlots = slots
                    keys = LongArray(oldKeys.size * 2)
                    slots = IntArray(oldKeys.size * 2) { -1 }
                    mask = keys.size - 1
                    for (i in oldKeys.indices) {
                        if (oldSlots[i] < 0) continue
                        var slot = (oldKeys[i] and mask.toLong()).toInt()
                        while (slots[slot] >= 0) slot = (slot + 1) and mask
                        keys[slot] = oldKeys[i]
                        slots[slot] = oldSlots[i]
                    }
                }
                return true
            }
        }

        /** Per-entry checks shared by the streaming and buffered paths; same order and messages. */
        private class EntryChecks(private val schemaVersion: Int, private val sink: RowSink) {
            private val ids = IdSet()
            // Speakers in first-seen order: putIfAbsent later then matches the earlier per-entry loop.
            val speakers = LinkedHashSet<String>()
            var count = 0
                private set

            fun accept(value: RawEntry) {
                val index = count++
                val id = value.requiredText("id")
                if (!ids.add(id)) {
                    throw IllegalArgumentException("JSON entries[$index]: yinelenen ID $id.")
                }
                require(if (schemaVersion == 2) !value.has("english") && !value.has("turkish") else !value.has("sourceText") && !value.has("targetText")) { "Oyun JSON biçimleri karıştırılamaz." }
                val entrySource = value.requiredText(if (schemaVersion == 2) "sourceText" else "english").replace(DELAY_DIRECTIVE, "")
                val entryTarget = value.requiredText(if (schemaVersion == 2) "targetText" else "turkish").replace(DELAY_DIRECTIVE, "")
                require(!value.has("speaker") || value.value("speaker") == null || value.value("speaker") is String) {
                    "JSON entries[$index]: speaker metin olmalı."
                }
                val speaker = value.optionalString("speaker")
                speaker?.let(speakers::add)
                sink.add(id, value.optionalString("chapter"), value.optionalString("kind"), speaker,
                    entrySource, entryTarget, normalize(entrySource))
            }
        }

        /** Rows checked while reading; the first failure is raised where the buffered loop would raise it. */
        private class StreamedEntries(
            val checks: EntryChecks,
            val failure: IllegalArgumentException?,
            val version: Int,
            val rows: Int,
        )

        private fun readRawEntry(reader: JsonReader): RawEntry {
            val raw = RawEntry()
            reader.beginObject()
            while (reader.hasNext()) {
                val field = ENTRY_FIELDS.indexOf(reader.nextName())
                if (field < 0) reader.skipValue() else raw.values[field] = reader.anyValue()
            }
            reader.endObject()
            return raw
        }

        private fun schemaVersionOf(version: Any?): Int = when (val value = if (version === Missing) null else version) {
            null -> if (version === Missing) 1 else 0
            is OtherValue -> value.text.toIntOrNull()?.takeIf { value.text == it.toString() } ?: 0
            else -> 0
        }

        private fun readEntries(
            json: java.io.Reader,
            sourceLanguage: String,
            targetLanguage: String,
            sink: RowSink,
        ): Triple<Int, Map<String, String>, String?> {
            val input = java.io.PushbackReader(json, 1)
            val first = input.read()
            if (first != -1 && first != 0xFEFF) input.unread(first)
            val reader = JsonReader(input)
            var version: Any? = Missing
            var game: Any? = Missing
            var source: Any? = Missing
            var target: Any? = Missing
            var entries: ArrayList<RawEntry>? = null
            var streamed: StreamedEntries? = null
            var entriesSeen = false
            var speakers: List<Pair<String, Any?>>? = null
            var speakersSeen = false
            var profile: Any? = Missing

            /**
             * Rows can be checked and stored while they stream in only when a valid
             * header already precedes them (as in every published pack). Otherwise they
             * are buffered and checked afterwards, exactly as before.
             */
            fun streamingVersion(): Int? {
                if (version === Missing || game === Missing || source === Missing || target === Missing) return null
                val schemaVersion = schemaVersionOf(version)
                if (schemaVersion != 1 && schemaVersion != 2) return null
                if (schemaVersion == 1 && !(sourceLanguage == "en" && targetLanguage == "tr")) return null
                if ((game as? String)?.isNotBlank() != true) return null
                if (source != sourceLanguage || target != targetLanguage) return null
                return schemaVersion
            }

            try {
                require(reader.peek() == JsonToken.BEGIN_OBJECT) { "Oyun JSON kökü bir nesne olmalı." }
                reader.beginObject()
                while (reader.hasNext()) {
                    when (reader.nextName()) {
                        "schemaVersion" -> version = reader.anyValue()
                        "game" -> game = reader.anyValue()
                        "source" -> source = reader.anyValue()
                        "target" -> target = reader.anyValue()
                        "entries" -> {
                            entriesSeen = true
                            entries = null
                            streamed = null
                            sink.reset()
                            if (reader.peek() != JsonToken.BEGIN_ARRAY) { reader.skipValue(); continue }
                            val streamVersion = streamingVersion()
                            reader.beginArray()
                            if (streamVersion != null) {
                                val checks = EntryChecks(streamVersion, sink)
                                var failure: IllegalArgumentException? = null
                                var position = 0
                                while (reader.hasNext()) {
                                    require(reader.peek() == JsonToken.BEGIN_OBJECT) { "JSON entries[$position]: nesne olmalı." }
                                    val raw = readRawEntry(reader)
                                    position++
                                    if (failure == null) {
                                        try { checks.accept(raw) } catch (error: IllegalArgumentException) { failure = error }
                                    }
                                }
                                streamed = StreamedEntries(checks, failure, streamVersion, position)
                            } else {
                                val list = ArrayList<RawEntry>()
                                while (reader.hasNext()) {
                                    require(reader.peek() == JsonToken.BEGIN_OBJECT) { "JSON entries[${list.size}]: nesne olmalı." }
                                    list.add(readRawEntry(reader))
                                }
                                entries = list
                            }
                            reader.endArray()
                        }
                        "speakers" -> {
                            speakersSeen = true
                            speakers = null
                            if (reader.peek() != JsonToken.BEGIN_OBJECT) { reader.skipValue(); continue }
                            val names = ArrayList<Pair<String, Any?>>()
                            reader.beginObject()
                            while (reader.hasNext()) names.add(reader.nextName() to reader.anyValue())
                            reader.endObject()
                            speakers = names
                        }
                        "gameProfile" -> profile = when (reader.peek()) {
                            JsonToken.NULL -> { reader.nextNull(); null }
                            JsonToken.BEGIN_OBJECT -> JsonParser.parseReader(reader).asJsonObject
                            else -> { reader.skipValue(); OtherValue("") }
                        }
                        else -> reader.skipValue()
                    }
                }
                reader.endObject()
            } catch (error: MalformedJsonException) {
                throw IllegalArgumentException("Oyun JSON dosyası bozuk: ${error.message}", error)
            } catch (error: java.io.EOFException) {
                throw IllegalArgumentException("Oyun JSON dosyası eksik veya yarım.", error)
            } catch (error: IllegalStateException) {
                throw IllegalArgumentException("Oyun JSON dosyası bozuk: ${error.message}", error)
            } catch (error: com.google.gson.JsonParseException) {
                throw IllegalArgumentException("Oyun JSON dosyası bozuk: ${error.message}", error)
            }

            // Same checks, order and messages as the earlier JSONObject reader.
            val schemaVersion = schemaVersionOf(version)
            require(schemaVersion == 1 || schemaVersion == 2) { "Oyun JSON schemaVersion geçersiz." }
            require(schemaVersion == 2 || sourceLanguage == "en" && targetLanguage == "tr") { "english/turkish biçimi yalnızca İngilizce → Türkçe içindir." }
            require((game as? String)?.isNotBlank() == true) { "Oyun JSON: game dolu metin olmalı." }
            require(source == sourceLanguage && target == targetLanguage) { "Oyun JSON dil bilgileri geçersiz." }
            if (!entriesSeen) throw IllegalArgumentException("Oyun JSON: entries listesi bulunamadı.")
            val stream = streamed
            val values = entries
            if (stream == null && values == null) throw IllegalArgumentException("Oyun JSON: entries bir liste olmalı.")
            require(profile === Missing || profile == null || profile is com.google.gson.JsonObject) {
                "Oyun JSON: gameProfile nesne olmalı."
            }
            val checks = if (stream != null) {
                require(stream.rows > 0) { "Oyun JSON entries listesi boş." }
                // A schemaVersion key repeated after the rows would change how they read.
                require(stream.version == schemaVersion) { "Oyun JSON schemaVersion geçersiz." }
                stream.failure?.let { throw it }
                stream.checks
            } else {
                require(values!!.isNotEmpty()) { "Oyun JSON entries listesi boş." }
                EntryChecks(schemaVersion, sink).also { checks ->
                    for (index in values.indices) {
                        checks.accept(values[index])
                        values[index] = EMPTY_ENTRY // Release the raw texts as they move into the blocks.
                    }
                }
            }
            val speakerTranslations = LinkedHashMap<String, String>()
            if (speakersSeen) {
                val names = speakers ?: throw IllegalArgumentException("Oyun JSON: speakers nesne olmalı.")
                for ((name, translated) in names) {
                    require((translated as? String)?.isNotBlank() == true) { "Oyun JSON: $name dolu metin olmalı." }
                    val key = normalize(name)
                    require(key.isNotEmpty()) { "Oyun JSON: konuşmacı adı boş olamaz." }
                    speakerTranslations[key] = translated as String
                }
            }
            for (speaker in checks.speakers) speakerTranslations.putIfAbsent(normalize(speaker), speaker)
            return Triple(stream?.rows ?: values!!.size, speakerTranslations,
                (profile as? com.google.gson.JsonObject)?.toString())
        }
        private val EMPTY_ENTRY = RawEntry()

        private fun isApostrophe(character: Char) =
            character == '\'' || character == '\u2018' || character == '\u2019' || character == '\u02bc'

        /** [APOSTROPHIZED_NEGATION] needs an apostrophe directly followed by "t"; without one it changes nothing. */
        private fun mayHaveApostrophizedNegation(value: String): Boolean {
            for (i in 0 until value.length - 1) if (value[i + 1] == 't' && isApostrophe(value[i])) return true
            return false
        }

        private fun normalize(value: String): String {
            if (value.isEmpty()) return ""
            val lower = value.lowercase(Locale.ROOT)
            val raw = if (lower.any { it.code > 127 })
                Normalizer.normalize(lower, Normalizer.Form.NFD).filter { Character.getType(it) != Character.NON_SPACING_MARK.toInt() }
                else lower
            val lowered = if (!mayHaveApostrophizedNegation(raw)) raw else APOSTROPHIZED_NEGATION.replace(raw) { match ->
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
                if (isApostrophe(character) || character == '\u00ad') continue
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

        /**
         * Character ranges [start, end) of the trimmed, non-blank sentences, as pairs.
         * Identical to splitting with substring(...).trim() and dropping blank pieces.
         */
        private fun sentenceRanges(value: String): IntArray {
            val ranges = IntArrayBuilder(8)
            fun add(from: Int, to: Int) {
                var start = from
                var end = to
                while (start < end && value[start].isWhitespace()) start++
                while (end > start && value[end - 1].isWhitespace()) end--
                if (start < end) { ranges.add(start); ranges.add(end) }
            }
            var start = 0
            // A boundary needs one of these characters; most UI strings have none.
            if (value.any { it in SENTENCE_ENDINGS }) {
                for (boundary in SENTENCE_BOUNDARY.findAll(value)) {
                    val end = boundary.range.last + 1
                    add(start, end)
                    start = end
                }
            }
            add(start, value.length)
            return ranges.build()
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

        private val DELAY_DIRECTIVE = Regex("""\[delay:\s*-?\d+(?:\.\d+)?\]""", RegexOption.IGNORE_CASE)
        private const val MAX_OCR_SPLIT_WORDS = 2
        /** Rows the fingerprint prefilter hands to the exact comparison. */
        private const val PREFILTER_ROWS = 96
        /** Shorter reads keep the three-letter piece count. */
        private const val MIN_PREFILTER_QUERY = 32
        /** Small packs build fingerprints at once; large ones on their own thread. */
        private const val SYNC_PREFILTER_RECORDS = 20_000
        private const val MAX_QUICK_SENTENCES = 8
        private const val MIN_VARIANT_LETTERS = 6
        private const val MAX_VARIANT_LETTERS = 48
        private const val MIN_INSERT_LETTERS = 10
        private const val OCR_VARIANT_SCORE = 0.99
        private val QUICK_SENTENCE_BREAK = Regex("""(?<=[.!?…]["'’”)]?)\s+(?=["'“‘(]?[\p{Lu}\p{N}])""")

        /** Whole sentences of [text]; a break needs a capital (or a digit) after it. */
        private fun quickSentences(text: String): List<String> =
            QUICK_SENTENCE_BREAK.split(text.trim()).map(String::trim).filter { it.any(Char::isLetterOrDigit) }

        /**
         * Letter groups OCR reads for one another in game fonts: what was read,
         * and what it may have been. A plain letter never becomes any other
         * letter ("honey" must not turn into "money").
         */
        private val OCR_CONFUSIONS = listOf(
            "rn" to "m", "m" to "rn", "cl" to "d", "vv" to "w", "ri" to "n", "li" to "h", "ii" to "u",
            "l" to "i", "i" to "l", "1" to "l", "1" to "i", "0" to "o", "5" to "s", "8" to "b", "j" to "i",
            "c" to "e", "e" to "c", "u" to "v", "v" to "u", "f" to "t", "t" to "f", "h" to "b", "b" to "h",
        )

        /**
         * [query] (normalized) with one OCR misreading undone: a confused letter
         * group replaced, one stray character dropped, and with [insertLetters]
         * one lost letter put back.
         */
        private fun ocrVariants(query: String, words: List<IntRange>, insertLetters: Boolean): Set<String> {
            val variants = LinkedHashSet<String>()
            fun add(value: String) {
                if (value.isNotEmpty() && !value.startsWith(' ') && !value.endsWith(' ') && "  " !in value) variants.add(value)
            }
            for (word in words) {
                for (index in word) {
                    for ((read, real) in OCR_CONFUSIONS) {
                        if (index + read.length <= word.last + 1 && query.startsWith(read, index))
                            add(query.substring(0, index) + real + query.substring(index + read.length))
                    }
                    add(query.removeRange(index, index + 1))
                }
                if (insertLetters) for (index in word.first..word.last + 1) for (letter in 'a'..'z') {
                    add(query.substring(0, index) + letter + query.substring(index))
                }
            }
            variants.remove(query)
            return variants
        }
        private const val INLINE_LABEL_BYTES = 48
        private const val CONTEXT_EXACT = "context_exact"
        private const val COMMON_EXACT = "common_exact"
        private const val COMMON_EXACT_SCORE = 0.99
        /** Picked among several translations: not cached, a later scene may pick another. */
        private val UNSETTLED_EXACT = setOf(CONTEXT_EXACT, COMMON_EXACT)
        private fun endMarks(text: String): String {
            val trimmed = text.trimEnd()
            var start = trimmed.length
            while (start > 0 && !trimmed[start - 1].isLetterOrDigit()) start--
            return marksOf(trimmed.substring(start))
        }
        private fun marks(text: String) = marksOf(text)
        private fun marksOf(text: String) = text.replace("…", "...")
            .filter { !it.isLetterOrDigit() && !it.isWhitespace() && it !in "'’\"“”" }
        private const val MIN_CONTEXT_QUERY = 12
        private const val MIN_CONTEXT_WORDS = 3
        private const val MAX_CONTEXT_RECORDS = 64
        private const val RECENT_RECORDS = 8
        private const val MAX_SCRAP_LETTERS = 3
        private val SPEAKER_PREFIX = Regex("""^\s*([\p{L}\p{N}][\p{L}\p{N} .’'-]{0,23}):\s*""")
        private val SENTENCE_BOUNDARY = Regex("""[.!?…؟。！？]+["'’”)]*(?:\s+|$)""")
        private const val SENTENCE_ENDINGS = ".!?…؟。！？"

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
