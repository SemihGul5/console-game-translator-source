package com.abrebostudio.consolegametranslator

/** Local-only routing and cache. Never changes the selected cloud engine or its quota. */
internal class GeminiLocalFallback(
    private val installed: (String, String) -> Set<String>,
    private val translateInstalled: (String, String, String, String) -> String,
) {
    data class Result(val text: String?, val engine: String, val fromCache: Boolean = false)
    private data class Key(val source: String, val target: String, val text: String)
    private val available = mutableMapOf<Pair<String, String>, Set<String>>()
    private val broken = mutableSetOf<Triple<String, String, String>>()
    private val cache = object : LinkedHashMap<Key, Result>(1024, .75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<Key, Result>?) = size > 1024
    }

    @Synchronized fun cached(source: String, target: String, key: String): Result? =
        cache[Key(source, target, key)]?.copy(fromCache = true)

    // Called only on the local inference worker; subtitle delivery checks session/freshness separately.
    fun translate(source: String, target: String, key: String, text: String): Result {
        cached(source, target, key)?.let { return it }
        val pair = source to target
        val models = available.getOrPut(pair) { installed(source, target) }
        for (engine in listOf("opus", "mlkit")) {
            val identity = Triple(source, target, engine)
            if (engine !in models || identity in broken) continue
            val translated = runCatching { translateInstalled(engine, source, target, text) }.getOrNull()
            if (!translated.isNullOrBlank()) {
                val result = Result(translated, engine)
                synchronized(this) { cache[Key(source, target, key)] = result }
                return result
            }
            // Do not retry a broken/deleted pack on every OCR frame. Try the other installed model.
            broken.add(identity)
        }
        return Result(null, if (models.isEmpty()) "unavailable" else "failed")
    }
}
