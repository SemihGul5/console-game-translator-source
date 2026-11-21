package com.abrebostudio.consolegametranslator

import java.io.File
import java.io.FilterInputStream
import java.io.IOException
import java.io.InputStream
import java.io.InputStreamReader
import java.io.Reader
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets
import java.security.DigestInputStream
import java.security.MessageDigest
import java.util.zip.GZIPInputStream

/**
 * Only a bounded, hash-verified pack inside the app cache enters the fast path.
 * Plain packs are `pack-<sha>.json` (≤ 25 MiB); larger ones arrive as
 * `pack-<sha>.json.gz` (≤ 25 MiB download, ≤ 64 MiB expanded). The SHA-256
 * always covers the downloaded file's exact bytes.
 */
internal object GameTranslationPackFile {
    const val MAX_FILE_BYTES = 25L * 1024 * 1024
    const val MAX_EXPANDED_BYTES = 64L * 1024 * 1024

    class TooLargeException(message: String) : IOException(message)

    /**
     * Streams the file once: hashes the raw bytes while [parse] reads the
     * (expanded) UTF-8 JSON. The result is returned only when the whole file
     * was read and its hash and size match; otherwise it is discarded.
     */
    fun <T> read(root: File, path: String, sha256: String, expectedBytes: Long, parse: (Reader) -> T): T {
        require(sha256.matches(Regex("[a-f0-9]{64}")) && expectedBytes in 1..MAX_FILE_BYTES) {
            "Oyun çeviri dosyası bilgileri geçersiz."
        }
        val file = File(path).canonicalFile
        val compressed = file.name == "pack-$sha256.json.gz"
        require(file.path.startsWith(root.canonicalPath + File.separator) &&
            (compressed || file.name == "pack-$sha256.json") && file.isFile && file.length() == expectedBytes) {
            "Oyun çeviri dosyası bulunamadı veya boyutu değişmiş."
        }
        val digest = MessageDigest.getInstance("SHA-256")
        val raw = CountingInputStream(DigestInputStream(file.inputStream(), digest), expectedBytes,
            "Oyun çeviri dosyası boyutu değişmiş.")
        raw.use {
            val json: InputStream = if (compressed) {
                CountingInputStream(GZIPInputStream(raw, 64 * 1024), MAX_EXPANDED_BYTES,
                    "Açılmış oyun çeviri dosyası 64 MiB sınırını aşıyor.")
            } else raw.buffered(64 * 1024)
            json.use { return verifiedParse(json, raw, digest, sha256, expectedBytes, parse) }
        }
    }

    private fun <T> verifiedParse(
        json: InputStream,
        raw: CountingInputStream,
        digest: MessageDigest,
        sha256: String,
        expectedBytes: Long,
        parse: (Reader) -> T,
    ): T {
        val decoder = StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
            .onUnmappableCharacter(CodingErrorAction.REPORT)
        val result = parse(InputStreamReader(json, decoder))
        // Read what the JSON reader did not need (gzip trailer, trailing
        // whitespace) so the hash covers the complete file.
        val skip = ByteArray(16 * 1024)
        while (json.read(skip) >= 0) { /* drain */ }
        while (raw.read(skip) >= 0) { /* drain */ }
        require(raw.count == expectedBytes) { "Oyun çeviri dosyası eksik." }
        val hash = digest.digest().joinToString("") { "%02x".format(it) }
        require(hash == sha256) { "Oyun çeviri dosyası doğrulanamadı." }
        return result
    }

    /** Fails as soon as a stream yields more bytes than allowed (also a gzip bomb). */
    private class CountingInputStream(input: InputStream, private val limit: Long, private val message: String) :
        FilterInputStream(input) {
        var count = 0L
            private set

        override fun read(): Int = super.read().also { if (it >= 0) add(1) }

        override fun read(buffer: ByteArray, offset: Int, length: Int): Int =
            super.read(buffer, offset, length).also { if (it > 0) add(it.toLong()) }

        override fun skip(n: Long): Long = super.skip(n).also { add(it) }

        override fun markSupported() = false

        private fun add(bytes: Long) {
            count += bytes
            if (count > limit) throw TooLargeException(message)
        }
    }
}
