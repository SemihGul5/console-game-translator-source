package com.abrebostudio.consolegametranslator

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

class GameLibraryLiveFallbackTest {
    @get:Rule val temp = TemporaryFolder()

    @Test fun deepLOnlyBuysUncachedMissesAndReturnsToJsonImmediately() = replay("deepl")
    @Test fun geminiOnlyBuysUncachedMissesAndReturnsToJsonImmediately() = replay("gemini")

    private fun replay(provider: String) {
        val table = OcrCorrectionTable.parse(javaClass.getResource("/${OcrCorrectionTable.ASSET_PATH}")!!.readText())
        val memory = GameTranslationMemory.parse("partial-game", "en", "tr",
            """{"schemaVersion":2,"game":"partial-game","source":"en","target":"tr","entries":[
              {"id":"known","sourceText":"I'll call you.","targetText":"Seni arayacağım."}]}""")
        val requested = mutableListOf<String>()
        fun connection(url: URL) = object : HttpURLConnection(url) {
            private val body = ByteArrayOutputStream()
            override fun connect() {}
            override fun disconnect() {}
            override fun usingProxy() = false
            override fun getOutputStream() = body
            override fun getResponseCode() = 200
            override fun getInputStream(): ByteArrayInputStream {
                val json = JSONObject(body.toString("UTF-8"))
                val text = if (provider == "deepl") json.getJSONArray("text").getString(0)
                    else json.getJSONArray("contents").getJSONObject(0).getJSONArray("parts").getJSONObject(0).getString("text")
                requested.add(text)
                val result = "live: $text"
                val response = if (provider == "deepl") JSONObject().put("translations", JSONArray().put(
                    JSONObject().put("text", result))).toString() else geminiResponse(result)
                return ByteArrayInputStream(response.toByteArray(Charsets.UTF_8))
            }
        }
        val file = File(temp.root, "$provider.jsonl")
        fun engine(): (String, String) -> String {
            val cache = DeepLTranslationCache(file)
            if (provider == "deepl") {
                val engine = DeepLTranslationEngine(cache, client = { key -> DeepLClient(key, ::connection) })
                return { key, text -> engine.translate("en", "tr", key, text, "test-key", 0).text }
            }
            val engine = GeminiTranslationEngine(cache, client = { key -> GeminiClient(key, ::connection) })
            return { key, text -> engine.translate("en", "tr", key, text, "test-key").text }
        }
        var translate = engine()
        fun route(raw: String): String {
            val original = selectSubtitleSource(raw, .8f, memory) { SubtitleOcrRead(raw, .8f) }
            val prepared = prepareUnmatchedOcr(original, true, true,
                correct = { table.correct(it, "en", true, gameLookupMiss = true) },
                findGameTranslation = memory::find).read
            prepared.memoryMatch?.let { return it.target }
            return translate(deepLTextKey(prepared.text, "en"), prepared.text)
        }
        assertEquals("Seni arayacağım.", route("I'll call you."))
        assertEquals("Seni arayacağım.", route("lIl caII y0u."))
        assertEquals("Seni arayacağım.", route("lI'll call you."))
        assertTrue("Prepared JSON must not spend quota", requested.isEmpty())
        repeat(20) {
            assertEquals("live: I'm going to the harbour.", route("Im going to the harbour."))
            assertEquals("live: I'm going to the harbour.", route("I'm going to the harbour."))
            listOf("lI'm", "II'm", "Il'm", "|I'm", "II'rn", "I' m", "I 'm").forEach {
                assertEquals("live: I'm going to the harbour.", route("$it going to the harbour."))
            }
        }
        assertEquals(listOf("I'm going to the harbour."), requested)
        assertEquals("Seni arayacağım.", route("I'll call you."))
        // Restarting the provider engine retains its persistent cache.
        translate = engine()
        assertEquals("live: I'm going to the harbour.", route("Im going to the harbour."))
        assertEquals(1, requested.size)
        repeat(20) {
            val expected = "live: I remember the way. Don't worry about it."
            assertEquals(expected, route("I rememher the way. Donttworry aboutit."))
            assertEquals(expected, route("I remember the way. Don't worry about it."))
        }
        assertEquals("A second OCR spelling must use the same persistent entry", 2, requested.size)
    }
}
