package com.abrebostudio.consolegametranslator

/**
 * A short fingerprint of every pack row, so the slow fuzzy comparison only
 * looks at rows that can possibly be the one read.
 *
 * A row's normalized text loses its spaces and the letters OCR confuses are
 * made one (l, 1, ı, j -> i; 0 -> o; 5 -> s). Each three-letter piece of what
 * is left sets one bit of a 64, 128 or 256 bit set (longer rows get more bits).
 * Counting the bits a read shares with a row is a few machine instructions, so
 * every row of a large pack is compared in milliseconds. A read with a few
 * misread letters still shares most of its pieces with its row; a read the pack
 * does not hold shares no more than chance with any row.
 */
internal class FuzzySignatures private constructor(
    /** `offsets[row]`: the row's first word in [words]; `offsets[count]` is the end. */
    private val offsets: IntArray,
    private val words: LongArray,
    /** The row's normalized length, for the length window of a search. */
    private val lengths: IntArray,
) {
    val count get() = lengths.size

    /** Memory held, in bytes. */
    val retainedBytes: Long get() = 4L * offsets.size + 8L * words.size + 8L * lengths.size

    /**
     * Up to [limit] rows of length [minLength]..[maxLength], best first, whose
     * fingerprint holds at least [minimumScore] (0-100, chance removed) of the
     * read's pieces, or of the row's own pieces when the row is the shorter one
     * (a read with something extra beside the subtitle).
     */
    @Synchronized
    fun nearest(query: String, limit: Int, minLength: Int, maxLength: Int, minimumScore: Double = MINIMUM_SCORE): IntArray {
        val hashes = gramHashes(fold(query))
        if (hashes.isEmpty() || count == 0 || limit <= 0) return IntArray(0)
        val queries = Array(3) { tier -> bloom(hashes, 64 shl tier) }
        val queryOnes = IntArray(3) { tier -> queries[tier].sumOf { java.lang.Long.bitCount(it) } }
        val queryLength = query.length
        // Scores go to a scratch array and a 0-100 histogram: the best rows are
        // then taken without sorting or a heap over the whole pack.
        val histogram = IntArray(101)
        for (row in 0 until count) {
            scores[row] = -1f
            val length = lengths[row]
            if (length < minLength || length > maxLength) continue
            val start = offsets[row]
            val size = offsets[row + 1] - start
            val tier = if (size == 1) 0 else if (size == 2) 1 else 2
            val queryBits = queries[tier]
            var both = 0
            var inRow = 0
            for (word in 0 until size) {
                val value = words[start + word]
                both += java.lang.Long.bitCount(queryBits[word] and value)
                inRow += java.lang.Long.bitCount(value)
            }
            val inQuery = queryOnes[tier]
            if (inQuery == 0 || inRow == 0) continue
            val bits = 64 * size
            val score = if (length >= queryLength) coverage(both, inQuery, inRow, bits) else coverage(both, inRow, inQuery, bits)
            if (score < minimumScore) continue
            scores[row] = score.toFloat()
            histogram[score.toInt().coerceIn(0, 100)]++
        }
        // Whole buckets from the top while they fit; the last bucket is cut by score.
        var kept = 0
        var cut = 100
        while (cut >= 0 && kept + histogram[cut] <= limit) kept += histogram[cut--]
        val found = ArrayList<Int>(limit)
        val partial = ArrayList<Int>()
        for (row in 0 until count) {
            val score = scores[row]
            if (score < 0f) continue
            val bucket = score.toInt().coerceIn(0, 100)
            if (bucket > cut) found.add(row) else if (bucket == cut) partial.add(row)
        }
        if (cut >= 0) partial.sortedByDescending { scores[it] }.take(limit - kept).let(found::addAll)
        return found.sortedByDescending { scores[it] }.toIntArray()
    }

    /** Scratch for [nearest]: each row's score in the current search, -1 when not taken. */
    private val scores = FloatArray(lengths.size)

    companion object {
        /** Rows below this share little more than chance with the read. */
        const val MINIMUM_SCORE = 45.0

        /** Fingerprints of [count] rows: [text] gives a row's normalized text. */
        fun build(count: Int, text: (Int) -> String): FuzzySignatures {
            val lengths = IntArray(count)
            val offsets = IntArray(count + 1)
            // First pass: sizes, from the folded length (a row is read twice rather than kept).
            for (row in 0 until count) {
                val value = text(row)
                lengths[row] = value.length
                offsets[row + 1] = offsets[row] + sizeFor(value.count { it != ' ' }) / 64
            }
            val words = LongArray(offsets[count])
            for (row in 0 until count) {
                val hashes = gramHashes(fold(text(row)))
                val bits = 64 * (offsets[row + 1] - offsets[row])
                val start = offsets[row]
                for (hash in hashes) {
                    val bit = (hash and (bits - 1).toLong()).toInt()
                    words[start + (bit ushr 6)] = words[start + (bit ushr 6)] or (1L shl (bit and 63))
                }
            }
            return FuzzySignatures(offsets, words, lengths)
        }

        /** Bits for a row of [letters] letters: about three per piece, 64 to 256. */
        private fun sizeFor(letters: Int): Int {
            var bits = 64
            while (bits < 256 && letters * 3 > bits) bits *= 2
            return bits
        }

        /** Without spaces, the letters OCR confuses made one. */
        internal fun fold(text: String): String {
            val output = StringBuilder(text.length)
            for (character in text) when (character) {
                ' ' -> Unit
                'l', '1', 'ı', 'j' -> output.append('i')
                '0' -> output.append('o')
                '5' -> output.append('s')
                else -> output.append(character)
            }
            return output.toString()
        }

        /** One 64-bit hash (FNV-1a) per different three-character piece. */
        private fun gramHashes(text: String): LongArray {
            if (text.length < 3) return LongArray(0)
            val hashes = LinkedHashSet<Long>()
            for (index in 0..text.length - 3) {
                var hash = -0x340d631b7bdddcdbL
                for (offset in 0 until 3) {
                    hash = (hash xor text[index + offset].code.toLong()) * 0x100000001b3L
                }
                hashes.add(hash xor (hash ushr 29))
            }
            return hashes.toLongArray()
        }

        private fun bloom(hashes: LongArray, bits: Int): LongArray {
            val words = LongArray(bits / 64)
            for (hash in hashes) {
                val bit = (hash and (bits - 1).toLong()).toInt()
                words[bit ushr 6] = words[bit ushr 6] or (1L shl (bit and 63))
            }
            return words
        }

        /** How much of the [own] bits are in the other set beyond chance (0-100). */
        private fun coverage(both: Int, own: Int, other: Int, bits: Int): Double {
            val fill = other.toDouble() / bits
            if (fill >= 1.0) return 0.0
            return 100.0 * (both.toDouble() / own - fill) / (1.0 - fill)
        }
    }
}
