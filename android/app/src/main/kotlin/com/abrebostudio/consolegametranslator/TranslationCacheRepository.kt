package com.abrebostudio.consolegametranslator

import java.io.File
import java.io.OutputStream

/** One pair of caches for UI management and the live translators, using the existing file names. */
internal class TranslationCacheRepository(
    directory: File,
    initialPolicy: TranslationCachePolicy = TranslationCachePolicy(),
    private val clock: () -> Long = System::currentTimeMillis,
) {
    var policy = initialPolicy; private set
    val deepL = DeepLTranslationCache(File(directory, "deepl_translations_v1.jsonl"),
        policy.maxEntries, policy.maxBytes, clock, policy.maxAgeMs)
    val gemini = DeepLTranslationCache(File(directory, "gemini_3_5_flash_lite_translations_v1.jsonl"),
        policy.maxEntries, policy.maxBytes, clock, policy.maxAgeMs)
    private val caches get() = mapOf("deepl" to deepL, "gemini" to gemini)

    @Synchronized fun statistics(): Map<String, Any> = mapOf(
        "policy" to policy.toMap(),
        "providers" to caches.map { (provider, cache) -> mapOf("provider" to provider) + cache.statistics() },
    )

    @Synchronized fun configure(next: TranslationCachePolicy) {
        if (next == policy) return
        val previous = policy
        val old = caches.mapValues { it.value.snapshot() }
        try {
            caches.values.forEach { it.configure(next) }
            policy = next
        } catch (error: Exception) {
            caches.forEach { (name, cache) -> runCatching { cache.configure(previous); cache.replace(old.getValue(name)) } }
            throw error
        }
    }

    @Synchronized fun clear(provider: String) {
        (caches[provider] ?: error("Invalid provider")).replace(emptyList())
    }

    @Synchronized fun export(output: OutputStream) {
        val rows = caches.asSequence().flatMap { (name, cache) ->
            cache.snapshot().asSequence().map { TranslationCacheBackup.Row(name, it) }
        }
        TranslationCacheBackup.write(output, rows, clock())
    }

    /** Email-sized sample; full user backups remain available separately. */
    @Synchronized fun contribution(output: OutputStream): Int {
        val rows = caches.flatMap { (name, cache) ->
            cache.snapshot().map { TranslationCacheBackup.Row(name, it) }
        }.sortedByDescending { it.entry.at }.asSequence()
        return TranslationCacheBackup.write(output, rows, clock(), maxRows = 5000, maxBytes = 5L * 1024 * 1024)
    }

    @Synchronized fun preview(file: File): TranslationCacheBackup.Report {
        require(file.length() <= TranslationCacheBackup.MAX_FILE_BYTES)
        return file.inputStream().use { TranslationCacheBackup.scan(it, clock(), policy.maxAgeMs) }
    }

    @Synchronized fun importFile(file: File): TranslationCacheBackup.Report {
        require(file.length() <= TranslationCacheBackup.MAX_FILE_BYTES)
        val old = caches.mapValues { it.value.snapshot() }
        val buffers = old.mapValues { (_, rows) -> MergeBuffer(policy, rows) }
        // Parsing and building both bounded results completes before the first write.
        val report = file.inputStream().use { input ->
            TranslationCacheBackup.scan(input, clock(), policy.maxAgeMs) { row -> buffers.getValue(row.provider).add(row.entry) }
        }
        try {
            caches.forEach { (name, cache) -> cache.replace(buffers.getValue(name).rows()) }
        } catch (error: Exception) {
            caches.forEach { (name, cache) -> runCatching { cache.replace(old.getValue(name)) } }
            throw error
        }
        return report
    }

    private class MergeBuffer(private val policy: TranslationCachePolicy, initial: List<DeepLTranslationCache.Entry>) {
        private val entries = LinkedHashMap<String, Pair<DeepLTranslationCache.Entry, Int>>()
        private var bytes = 0L
        init { initial.forEach(::add) }
        fun add(entry: DeepLTranslationCache.Entry) {
            val id = "${entry.source}\u0000${entry.target}\u0000${entry.key}"
            val old = entries[id]
            if (old != null && old.first.at >= entry.at) return
            val size = entry.json().toString().toByteArray(Charsets.UTF_8).size + 1
            if (size > policy.maxBytes) return
            if (old != null) { entries.remove(id); bytes -= old.second }
            entries[id] = entry to size; bytes += size
            while (entries.size > policy.maxEntries || bytes > policy.maxBytes) {
                val iterator = entries.entries.iterator()
                bytes -= iterator.next().value.second
                iterator.remove()
            }
        }
        fun rows(): List<DeepLTranslationCache.Entry> = entries.values.map { it.first }
    }
}
