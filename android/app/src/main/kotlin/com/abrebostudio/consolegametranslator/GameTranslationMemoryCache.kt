package com.abrebostudio.consolegametranslator

internal data class GameTranslationMemoryKey(
    val gameId: String,
    val sourceLanguage: String,
    val targetLanguage: String,
    val contentKey: String,
)

/** Keeps recently prepared indexes, not JSON strings. Versions and languages never mix. */
internal class GameTranslationMemoryCache(
    private val maxEntries: Int = 2,
    private val maxBytes: Long = 64L * 1024 * 1024,
) {
    private val entries = java.util.LinkedHashMap<GameTranslationMemoryKey, GameTranslationMemory>(4, 0.75f, true)
    private var retainedBytes = 0L
    private var largeKey: GameTranslationMemoryKey? = null
    private var largeMemory: java.lang.ref.WeakReference<GameTranslationMemory>? = null

    @Synchronized fun get(key: GameTranslationMemoryKey): GameTranslationMemory? =
        entries[key] ?: largeMemory?.get()?.takeIf { largeKey == key }

    @Synchronized fun put(key: GameTranslationMemoryKey, memory: GameTranslationMemory) {
        require(key.gameId == memory.gameId && key.sourceLanguage == memory.sourceLanguage && key.targetLanguage == memory.targetLanguage)
        entries.remove(key)?.let { retainedBytes -= it.estimatedRetainedBytes }
        if (memory.estimatedRetainedBytes > maxBytes || maxEntries <= 0) {
            entries.clear()
            retainedBytes = 0
            // An active/recent large game can be reused without forcing its
            // indexes to remain resident when Android needs the heap back.
            largeKey = key.takeIf { maxEntries > 0 }
            largeMemory = if (maxEntries > 0) java.lang.ref.WeakReference(memory) else null
            return
        }
        largeKey = null
        largeMemory = null
        entries[key] = memory
        retainedBytes += memory.estimatedRetainedBytes
        val iterator = entries.entries.iterator()
        while ((entries.size > maxEntries || retainedBytes > maxBytes) && iterator.hasNext()) {
            retainedBytes -= iterator.next().value.estimatedRetainedBytes
            iterator.remove()
        }
    }

    @Synchronized fun removeGame(gameId: String, source: String? = null, target: String? = null) {
        fun matches(key: GameTranslationMemoryKey) = key.gameId == gameId &&
            (source == null || key.sourceLanguage == source) && (target == null || key.targetLanguage == target)
        if (largeKey?.let(::matches) == true) {
            largeKey = null
            largeMemory = null
        }
        val iterator = entries.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (matches(entry.key)) {
                retainedBytes -= entry.value.estimatedRetainedBytes
                iterator.remove()
            }
        }
    }
}
