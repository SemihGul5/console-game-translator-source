package com.abrebostudio.consolegametranslator

/** Same bounded persistent journal as DeepL, stored in a separate model-specific file. */
internal class GeminiTranslationEngine(
    private val cache: DeepLTranslationCache,
    private val client: (String) -> GeminiClient = { GeminiClient(it) },
    private val diagnostic: (String) -> Unit = {},
    private val elapsedMillis: () -> Long = { System.nanoTime() / 1_000_000 },
) {
    data class Result(val text: String, val fromCache: Boolean)
    private var sequence = 0L
    // Avoid repeatedly spending requests on a blocked or malformed subtitle.
    private val rejected = object : LinkedHashMap<String, GeminiException>(16, .75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, GeminiException>?) = size > 128
    }

    fun translate(source: String, target: String, key: String, text: String, apiKey: String): Result {
        cache.get(source, target, key)?.let {
            diagnostic("GEMINI_CACHE_HIT $source->$target")
            return Result(it, true)
        }
        val id = "$source\u0000$target\u0000$key"
        rejected[id]?.let { throw it }
        val request = ++sequence
        val started = elapsedMillis()
        diagnostic("GEMINI_REQUEST id=$request $source->$target sourceChars=${text.codePointCount(0, text.length)}")
        val translated = try { client(apiKey).translate(text, source, target) }
        catch (error: GeminiException) {
            if (error.code in setOf("GEMINI_BLOCKED", "GEMINI_RESPONSE")) rejected[id] = error
            throw error
        }
        diagnostic("GEMINI_RESPONSE id=$request latencyMs=${elapsedMillis() - started}")
        cache.put(source, target, key, translated)
        return Result(translated, false)
    }
}
