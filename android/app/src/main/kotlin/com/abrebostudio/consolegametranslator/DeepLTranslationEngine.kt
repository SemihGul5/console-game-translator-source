package com.abrebostudio.consolegametranslator

/** Serialized by the OCR network executor. Cached results never call the API factory. */
internal class DeepLTranslationEngine(
    private val cache: DeepLTranslationCache,
    private val client: (String) -> DeepLClient = { DeepLClient(it) },
    private val diagnostic: (String) -> Unit = {},
    private val elapsedMillis: () -> Long = { System.nanoTime() / 1_000_000 },
) {
    data class Result(val text: String, val fromCache: Boolean)
    private var requestSequence = 0L

    fun translate(source: String, target: String, key: String, text: String,
        apiKey: String, regionIndex: Int, context: String? = null): Result {
        val chars = text.codePointCount(0, text.length)
        cache.get(source, target, key)?.let {
            diagnostic("DEEPL_CACHE_HIT area=${regionIndex + 1} sourceChars=$chars")
            return Result(it, true)
        }
        val id = ++requestSequence
        val started = elapsedMillis()
        diagnostic("DEEPL_REQUEST id=$id area=${regionIndex + 1} $source->$target sourceChars=$chars")
        val translated = client(apiKey).translateWithUsage(text, source, target, context)
        diagnostic("DEEPL_RESPONSE id=$id latencyMs=${elapsedMillis() - started} billedChars=${translated.billedCharacters ?: "unknown"}")
        cache.put(source, target, key, translated.text)
        return Result(translated.text, false)
    }
}
