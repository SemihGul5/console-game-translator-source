package com.abrebostudio.consolegametranslator

import com.google.gson.Strictness
import com.google.gson.stream.JsonReader
import com.google.gson.stream.JsonToken
import org.json.JSONObject
import java.io.InputStream
import java.io.OutputStream
import java.io.StringReader
import java.nio.charset.CodingErrorAction
import java.security.MessageDigest

/** Streaming JSONL backup, with an allowlist of fields and no credential/settings source. */
internal object TranslationCacheBackup {
    const val MAX_FILE_BYTES = 72L * 1024 * 1024
    private const val MAX_LINE_CHARS = 1024 * 1024
    private const val MAX_ROWS = 100_000
    val models = mapOf("deepl" to "deepl-default-v1", "gemini" to GeminiClient.MODEL)
    data class Row(val provider: String, val entry: DeepLTranslationCache.Entry)
    data class Report(val valid: Int, val expired: Int, val duplicates: Int) {
        fun toMap(): Map<String, Int> = mapOf("valid" to valid, "expired" to expired, "duplicates" to duplicates)
    }

    fun write(output: OutputStream, rows: Sequence<Row>, now: Long,
        maxRows: Int = Int.MAX_VALUE, maxBytes: Long = Long.MAX_VALUE): Int {
        var count = 0
        output.bufferedWriter(Charsets.UTF_8).use { writer ->
            val header = JSONObject().put("format", "anlaoyna-translation-cache")
                .put("version", 1).put("exportedAt", now).toString() + "\n"
            var bytes = header.toByteArray(Charsets.UTF_8).size.toLong()
            require(bytes <= maxBytes)
            writer.write(header)
            for (row in rows) {
                if (count >= maxRows) break
                val entry = row.entry
                val line = JSONObject().put("provider", row.provider).put("model", models.getValue(row.provider))
                    .put("source", entry.source).put("target", entry.target).put("key", entry.key)
                    .put("translation", entry.translated).put("at", entry.at).toString() + "\n"
                val size = line.toByteArray(Charsets.UTF_8).size
                if (bytes + size > maxBytes) continue
                writer.write(line); bytes += size; count++
            }
        }
        return count
    }

    /** Validate the whole file before any cache is modified; age never resets on import. */
    fun scan(input: InputStream, now: Long, maxAgeMs: Long, accept: (Row) -> Unit = {}): Report {
        val decoder = Charsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
            .onUnmappableCharacter(CodingErrorAction.REPORT)
        var valid = 0; var expired = 0; var duplicates = 0; var count = 0
        val seen = HashSet<String>()
        val language = Regex("[a-z]{2,3}(?:-[a-z0-9]{2,8})*")
        java.io.InputStreamReader(input, decoder).buffered().use { reader ->
            fun line(): String? {
                val text = StringBuilder()
                while (true) {
                    val char = reader.read()
                    if (char < 0) return if (text.isEmpty()) null else text.toString()
                    if (char == 10) return text.toString().removeSuffix("\r")
                    require(text.length < MAX_LINE_CHARS) { "Backup line too large" }
                    text.append(char.toChar())
                }
            }
            val header = fields((line() ?: error("Missing backup header")).removePrefix("\uFEFF"))
            require(header.keys == setOf("format", "version", "exportedAt") &&
                header["format"] == "anlaoyna-translation-cache" && header["version"] == 1L &&
                header["exportedAt"] is Long) { "Unsupported backup" }
            while (true) {
                val text = line() ?: break
                if (text.isBlank()) continue
                require(++count <= MAX_ROWS) { "Too many backup rows" }
                val row = fields(text)
                require(row.keys == setOf("provider", "model", "source", "target", "key", "translation", "at"))
                val provider = row["provider"] as? String ?: error("Missing provider")
                require(models[provider] != null && models[provider] == row["model"]) { "Unsupported model" }
                val source = row["source"] as? String ?: error("Missing source")
                val target = row["target"] as? String ?: error("Missing target")
                require(language.matches(source) && language.matches(target)) { "Invalid language" }
                val key = row["key"] as? String ?: error("Missing source text")
                val translation = row["translation"] as? String ?: error("Missing translation")
                val at = row["at"] as? Long ?: error("Invalid timestamp")
                require(key.isNotBlank() && key.length <= 16_384 && '\u0000' !in key &&
                    translation.isNotBlank() && translation.length <= 131_072 && at >= 0) { "Invalid translation" }
                if (now - at !in 0..maxAgeMs) { expired++; continue }
                val digest = MessageDigest.getInstance("SHA-256").digest(
                    "$provider\u0000$source\u0000$target\u0000$key".toByteArray(Charsets.UTF_8),
                )
                val identity = buildString(64) {
                    val hex = "0123456789abcdef"
                    digest.forEach { append(hex[(it.toInt() and 255) ushr 4]); append(hex[it.toInt() and 15]) }
                }
                if (!seen.add(identity)) duplicates++ else valid++
                accept(Row(provider, DeepLTranslationCache.Entry(source, target, key, translation, at)))
            }
        }
        return Report(valid, expired, duplicates)
    }

    private fun fields(line: String): Map<String, Any> {
        val result = linkedMapOf<String, Any>()
        JsonReader(StringReader(line)).use { reader ->
            reader.setStrictness(Strictness.STRICT)
            reader.beginObject()
            while (reader.hasNext()) {
                val name = reader.nextName()
                require(name !in result) { "Duplicate backup field" }
                result[name] = when (reader.peek()) {
                    JsonToken.STRING -> reader.nextString()
                    JsonToken.NUMBER -> reader.nextString().toLong()
                    else -> error("Invalid backup field")
                }
            }
            reader.endObject()
            require(reader.peek() == JsonToken.END_DOCUMENT) { "Trailing backup data" }
        }
        return result
    }
}
