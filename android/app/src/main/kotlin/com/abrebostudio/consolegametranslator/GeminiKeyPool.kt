package com.abrebostudio.consolegametranslator

/** Bounded, serial failover. Status reads never select a key or send a request. */
internal class GeminiKeyPool(private val now: () -> Long) {
    private data class Entry(val key: String, val retry: CloudTranslationRetryPolicy)
    private var entries = emptyList<Entry>()
    private var active = 0

    @Synchronized fun configure(keys: List<String>) {
        val normalized = keys.filter { it.isNotBlank() }.distinct().take(GeminiKeyList.MAX_KEYS)
        entries = normalized.map { Entry(it, CloudTranslationRetryPolicy(now)) }
        active = 0
    }

    @Synchronized fun acquire(): String? {
        if (entries.isEmpty()) return null
        for (offset in entries.indices) {
            val index = (active + offset) % entries.size
            if (!entries[index].retry.waiting) {
                active = index
                return entries[index].key
            }
        }
        return null
    }

    @Synchronized fun failed(key: String, error: GeminiException) {
        val index = entries.indexOfFirst { it.key == key }
        if (index < 0) return
        entries[index].retry.fail(error.code, error.message.orEmpty(), error.retryDelayMs)
        active = (index + 1) % entries.size
    }

    @Synchronized fun succeeded(key: String) {
        entries.firstOrNull { it.key == key }?.retry?.clear()
    }

    /** Earliest usable credential wins; daily/auth pauses do not hide a timed retry. */
    @Synchronized fun blockedStatus(): Map<String, Any?>? {
        if (entries.isEmpty() || entries.any { !it.retry.waiting }) return null
        val earliest = entries.minByOrNull { it.retry.remainingMs }!!
        val chosen = if (earliest.retry.remainingMs == Long.MAX_VALUE)
            entries.firstOrNull { it.retry.allowsGeminiFallback } ?: earliest else earliest
        return chosen.retry.snapshot() + ("delayMs" to chosen.retry.remainingMs)
    }

    @Synchronized fun snapshot(): Map<String, Any?> = mapOf(
        "keyCount" to entries.size,
        "activeKeyIndex" to if (entries.isEmpty()) 0 else active + 1,
        "keys" to entries.mapIndexed { index, entry ->
            mapOf("index" to index + 1) + entry.retry.snapshot().filterKeys { it != "message" }
        },
    )

    companion object {
        // Content rejections and shared network/server failures must not fan out across keys.
        fun canFailOver(code: String) = code in setOf(
            "GEMINI_RATE_LIMIT", "GEMINI_QUOTA", "GEMINI_AUTH", "GEMINI_KEY_REQUIRED", "GEMINI_MODEL",
        )
    }
}
