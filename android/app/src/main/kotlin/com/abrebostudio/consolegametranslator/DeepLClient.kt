package com.abrebostudio.consolegametranslator

import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

internal class DeepLException(val code: String, message: String, val retryDelayMs: Long = 0) :
    IllegalStateException(message)

internal data class DeepLTranslation(val text: String, val billedCharacters: Long?)

/** Synchronous client; callers run it on a dedicated network executor. */
internal class DeepLClient(
    apiKey: String,
    private val openConnection: (URL) -> HttpURLConnection = { it.openConnection() as HttpURLConnection },
) {
    private val key = validateKey(apiKey)
    private val origin = if (key.endsWith(":fx")) "https://api-free.deepl.com" else "https://api.deepl.com"

    fun checkConnection() { request("/v2/usage") }

    fun usage(): Map<String, Long> = parseResponse {
        val response = JSONObject(request("/v2/usage"))
        val count = (response.opt("character_count") as? Number)?.toLong()
        val limit = (response.opt("character_limit") as? Number)?.toLong()
        if (count == null || limit == null || count < 0 || limit < 0) {
            throw DeepLException("DEEPL_RESPONSE", "DeepL kullanım bilgisi alınamadı. Tekrar dene.")
        }
        mapOf("characterCount" to count, "characterLimit" to limit)
    }

    fun languages(source: Boolean): List<Map<String, Any>> = parseResponse {
        val response = JSONArray(request("/v2/languages?type=${if (source) "source" else "target"}"))
        (0 until response.length()).map { index ->
            val row = response.getJSONObject(index)
            val code = row.getString("language").lowercase(Locale.ROOT)
            val locale = Locale.forLanguageTag(code)
            mapOf("code" to code, "name" to locale.getDisplayName(Locale.forLanguageTag("tr")),
                "englishName" to row.getString("name"), "nativeName" to locale.getDisplayName(locale), "downloaded" to true)
        }
    }

    fun translate(text: String, source: String, target: String): String =
        translateWithUsage(text, source, target).text

    /** [context] describes where the text appears; DeepL uses it but does not translate or bill it. */
    fun translateWithUsage(text: String, source: String, target: String, context: String? = null): DeepLTranslation = parseResponse {
        val body = JSONObject().put("text", JSONArray().put(text))
            .put("source_lang", source.uppercase(Locale.ROOT))
            .put("target_lang", target.uppercase(Locale.ROOT))
            .put("split_sentences", "nonewlines")
            .put("show_billed_characters", true)
        if (!context.isNullOrBlank()) body.put("context", context)
        val response = JSONObject(request("/v2/translate", body.toString()))
        val row = response.getJSONArray("translations").getJSONObject(0)
        val translated = row.getString("text")
        if (translated.isBlank()) throw DeepLException("DEEPL_RESPONSE", "DeepL çeviri yanıtı geçersiz.")
        DeepLTranslation(translated, (row.opt("billed_characters") as? Number)?.toLong()?.takeIf { it >= 0 })
    }

    private fun <T> parseResponse(read: () -> T): T = try {
        read()
    } catch (error: DeepLException) {
        throw error
    } catch (_: Exception) {
        throw DeepLException("DEEPL_RESPONSE", "DeepL çeviri yanıtı geçersiz.", 5_000)
    }

    private fun request(path: String, body: String? = null): String {
        val connection = openConnection(URL("$origin$path"))
        try {
            connection.requestMethod = if (body == null) "GET" else "POST"
            connection.instanceFollowRedirects = false
            connection.useCaches = false
            connection.connectTimeout = 8_000
            connection.readTimeout = 12_000
            connection.setRequestProperty("Authorization", "DeepL-Auth-Key $key")
            connection.setRequestProperty("Accept", "application/json")
            if (body != null) {
                connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
                connection.doOutput = true
                val bytes = body.toByteArray(Charsets.UTF_8)
                connection.setFixedLengthStreamingMode(bytes.size)
                connection.outputStream.use { it.write(bytes) }
            }
            val status = connection.responseCode
            if (status !in 200..299) throw errorForStatus(status)
            return connection.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
        } catch (error: DeepLException) {
            throw error
        } catch (_: Exception) {
            // Never expose response bodies, keys, request URLs or upstream exceptions.
            throw DeepLException("DEEPL_NETWORK", "DeepL bağlantısı kurulamadı. İnternet bağlantını kontrol et.", 5_000)
        } finally {
            connection.disconnect()
        }
    }

    companion object {
        fun validateKey(value: String): String {
            val key = value.trim()
            if (key.isEmpty() || key.length > 512 || key.any { it.isWhitespace() || it.code !in 33..126 }) {
                throw DeepLException("DEEPL_KEY_REQUIRED", "Geçerli bir DeepL API anahtarı gir.")
            }
            return key
        }

        fun errorForStatus(status: Int): DeepLException = when (status) {
            401, 403 -> DeepLException("DEEPL_AUTH", "DeepL API anahtarı kabul edilmedi. Anahtarını kontrol et.", Long.MAX_VALUE)
            456 -> DeepLException("DEEPL_QUOTA", "DeepL karakter kotası doldu. DeepL hesabını kontrol et.", Long.MAX_VALUE)
            429 -> DeepLException("DEEPL_RATE_LIMIT", "DeepL istek sınırına ulaşıldı. Biraz sonra tekrar dene.", 10_000)
            400 -> DeepLException("DEEPL_LANGUAGE", "DeepL dil seçimini kontrol et.", Long.MAX_VALUE)
            else -> DeepLException("DEEPL_UNAVAILABLE", "DeepL şu anda yanıt veremiyor. Biraz sonra tekrar dene.", 5_000)
        }
    }
}
