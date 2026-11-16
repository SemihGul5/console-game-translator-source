package com.abrebostudio.consolegametranslator

import com.google.gson.Gson
import com.google.gson.JsonParser
import java.security.MessageDigest

/** Encrypted payload codec. Legacy single-key plaintext is decoded without dropping it. */
internal object GeminiKeyList {
    const val MAX_KEYS = 5
    fun decode(payload: String): List<String> {
        val trimmed = payload.trim()
        val keys = if (trimmed.startsWith("[")) {
            val parsed = JsonParser.parseString(trimmed).asJsonArray
            require(parsed.size() <= MAX_KEYS)
            parsed.map { require(it.isJsonPrimitive && it.asJsonPrimitive.isString); GeminiClient.validateKey(it.asString) }
        } else listOf(GeminiClient.validateKey(trimmed))
        return keys.distinct()
    }
    fun encode(keys: List<String>): String {
        require(keys.size <= MAX_KEYS)
        return Gson().toJson(keys.map { GeminiClient.validateKey(it) }.distinct())
    }
    fun id(key: String): String = MessageDigest.getInstance("SHA-256")
        .digest(key.toByteArray(Charsets.UTF_8)).take(16).joinToString("") { "%02x".format(it) }

    fun metadata(keys: List<String>): Map<String, Any?> = mapOf(
        "hasKey" to keys.isNotEmpty(), "model" to GeminiClient.MODEL,
        "keyCount" to keys.size, "maxKeys" to MAX_KEYS,
        "keys" to keys.mapIndexed { index, key -> mapOf("id" to id(key), "index" to index + 1) },
    )

    fun adding(keys: List<String>, value: String): List<String> {
        val key = GeminiClient.validateKey(value)
        if (key in keys) throw GeminiException("GEMINI_KEY_DUPLICATE", "Bu Gemini anahtarı zaten kayıtlı.")
        if (keys.size >= MAX_KEYS) throw GeminiException("GEMINI_KEY_LIMIT", "En fazla 5 Gemini anahtarı kaydedebilirsin.")
        return keys + key
    }
}
