package com.abrebostudio.consolegametranslator

import org.json.JSONObject
import java.io.File
import java.util.LinkedHashMap

/** Bounded local journal. Only successful translations are retained; keys never enter it. */
internal class DeepLTranslationCache(
    private val file: File,
    private var maxEntries: Int = 50_000,
    private var maxBytes: Long = 32L * 1024 * 1024,
    private val clock: () -> Long = System::currentTimeMillis,
    private var maxAgeMs: Long = 90L * 24 * 60 * 60 * 1000,
) {
    internal data class Entry(val source: String, val target: String, val key: String,
        val translated: String, val at: Long) {
        fun json() = JSONObject().put("v", 1).put("source", source).put("target", target)
            .put("key", key).put("translation", translated).put("at", at)
    }
    private val entries = object : LinkedHashMap<String, Entry>(128, .75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Entry>?) = size > maxEntries
    }
    private var loaded = false
    private var journalRows = 0
    private fun id(source: String, target: String, key: String) = "$source\u0000$target\u0000$key"

    @Synchronized fun get(source: String, target: String, key: String): String? {
        load()
        val id = id(source, target, key)
        val entry = entries[id] ?: return null
        if (clock() - entry.at > maxAgeMs || entry.at > clock()) { entries.remove(id); return null }
        return entry.translated
    }

    /** OCR can reuse the loaded cache without doing file I/O on its executor. */
    @Synchronized fun getIfLoaded(source: String, target: String, key: String): String? =
        if (loaded) get(source, target, key) else null

    @Synchronized fun put(source: String, target: String, key: String, translation: String) {
        load()
        if (translation.isBlank() || key.isBlank()) return
        val entry = Entry(source, target, key, translation, clock())
        val row = entry.json().toString() + "\n"
        if (row.toByteArray(Charsets.UTF_8).size > maxBytes / 4) return
        entries[id(source, target, key)] = entry
        // Disk failure must not turn an already paid, successful translation into a retry.
        runCatching {
            file.parentFile?.mkdirs()
            if (file.length() + row.toByteArray(Charsets.UTF_8).size > maxBytes || journalRows >= maxEntries * 2) {
                compact()
            } else {
                file.appendText(row, Charsets.UTF_8)
                journalRows++
            }
        }
    }

    private fun load() {
        if (loaded) return
        loaded = true
        val backup = File(file.parentFile, "${file.name}.bak")
        if (!file.exists() && backup.exists()) backup.renameTo(file)
        if (!file.exists() || file.length() > maxBytes) return
        runCatching {
            file.useLines(Charsets.UTF_8) { lines -> lines.forEach { line ->
                journalRows++
                runCatching {
                    val row = JSONObject(line)
                    if (row.optInt("v") != 1) return@runCatching
                    val entry = Entry(row.getString("source"), row.getString("target"), row.getString("key"),
                        row.getString("translation"), row.getLong("at"))
                    if (entry.key.isNotBlank() && entry.translated.isNotBlank() && clock() - entry.at in 0..maxAgeMs) {
                        entries[id(entry.source, entry.target, entry.key)] = entry
                    }
                }
            } }
        }
    }

    private fun compact() {
        val temporary = File(file.parentFile, "${file.name}.tmp")
        var bytes = 0L
        val rows = mutableListOf<String>()
        // Most recently used entries fit first when the byte cap is reached.
        for (entry in entries.values.toList().asReversed()) {
            if (clock() - entry.at !in 0..maxAgeMs) continue
            val row = entry.json().toString() + "\n"
            val size = row.toByteArray(Charsets.UTF_8).size
            if (bytes + size > maxBytes) continue
            bytes += size
            rows.add(row)
        }
        temporary.bufferedWriter(Charsets.UTF_8).use { writer -> rows.asReversed().forEach { writer.write(it) } }
        val backup = File(file.parentFile, "${file.name}.bak")
        if (backup.exists() && !backup.delete()) throw java.io.IOException("Cache backup could not be removed")
        if (file.exists() && !file.renameTo(backup)) throw java.io.IOException("Cache could not be staged")
        if (!temporary.renameTo(file)) {
            backup.renameTo(file)
            throw java.io.IOException("Cache could not be replaced")
        }
        backup.delete()
        journalRows = rows.size
    }

    @Synchronized fun snapshot(): List<Entry> {
        load()
        val now = clock()
        return entries.values.filter { now - it.at in 0..maxAgeMs }
    }

    @Synchronized fun statistics(): Map<String, Any> = mapOf(
        "count" to snapshot().size, "bytes" to file.length(),
    )

    @Synchronized fun configure(policy: TranslationCachePolicy) {
        load() // Read with the old byte cap before applying a smaller one.
        val previous = Triple(maxEntries, maxBytes, maxAgeMs)
        val oldRows = entries.values.toList()
        try {
            maxEntries = policy.maxEntries
            maxBytes = policy.maxBytes
            maxAgeMs = policy.maxAgeMs
            replace(snapshot())
        } catch (error: Exception) {
            maxEntries = previous.first; maxBytes = previous.second; maxAgeMs = previous.third
            entries.clear(); oldRows.forEach { entries[id(it.source, it.target, it.key)] = it }
            throw error
        }
    }

    /** Management operations report disk failures instead of silently claiming a saved import. */
    @Synchronized fun replace(rows: List<Entry>) {
        load()
        val previous = entries.values.toList()
        entries.clear()
        rows.forEach { entries[id(it.source, it.target, it.key)] = it }
        try {
            file.parentFile?.mkdirs()
            compact()
            // Match the durable, bounded set, including evictions caused by the byte limit.
            entries.clear(); loaded = false; journalRows = 0
            load()
        } catch (error: Exception) {
            entries.clear(); previous.forEach { entries[id(it.source, it.target, it.key)] = it }
            throw error
        }
    }
}
