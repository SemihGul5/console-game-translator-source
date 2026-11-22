package com.abrebostudio.consolegametranslator

import org.json.JSONArray
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

/** Replays subtitle-only OCR from the reported pause; no Google account or real API is used. */
class GeminiLoggedOcrReplayTest {
    @get:Rule val temp = TemporaryFolder()

    @Test fun corroboratesGameDialogueAndDoesNotSpendAnotherRequestOnTheSameCachedLine() {
        val rows = JSONArray(javaClass.getResource("/gemini-ocr-2026-11-16.json")!!.readText())
        val file = File(temp.root, "gemini.jsonl")
        val requested = mutableListOf<String>()
        fun engine() = GeminiTranslationEngine(DeepLTranslationCache(file), client = { key -> GeminiClient(key) { url ->
            object : java.net.HttpURLConnection(url) {
                private val body = java.io.ByteArrayOutputStream()
                override fun connect() {}
                override fun disconnect() {}
                override fun usingProxy() = false
                override fun getOutputStream() = body
                override fun getResponseCode() = 200
                override fun getInputStream(): java.io.InputStream {
                    val text = org.json.JSONObject(body.toString("UTF-8")).getJSONArray("contents")
                        .getJSONObject(0).getJSONArray("parts").getJSONObject(0).getString("text")
                    requested.add(text)
                    return java.io.ByteArrayInputStream(geminiResponse("translated: $text").toByteArray(Charsets.UTF_8))
                }
            }
        } })
        fun millis(value: String): Long {
            val parts = value.split(':', '.')
            return ((parts[0].toLong() * 60 + parts[1].toLong()) * 60 + parts[2].toLong()) * 1000 + parts[3].toLong()
        }
        fun replay(engine: GeminiTranslationEngine) {
            var elapsed = 0L
            var lastNonempty = 0L
            val policy = DeepLOcrPolicy { elapsed }
            for (index in 0 until rows.length()) {
                val row = rows.getJSONObject(index)
                val start = millis(row.getString("time"))
                val until = if (index + 1 < rows.length()) millis(rows.getJSONObject(index + 1).getString("time")) else start + 67
                for (time in start..minOf(until - 1, start + 2000) step 67) {
                    elapsed = time
                    val text = row.getString("text")
                    if (text.isBlank() || isNonLinguisticOcr(text) || row.getDouble("confidence") < .35) {
                        policy.discardPending()
                        if (time - lastNonempty >= 2000) policy.clear()
                        continue
                    }
                    lastNonempty = time
                    val accepted = policy.observeCloud(text, row.getDouble("confidence").toFloat(), "en", 67,
                        engine = "gemini") ?: continue
                    engine.translate("en", "tr", accepted.key, accepted.text, "test-key")
                }
            }
        }
        replay(engine())
        val firstCount = requested.size
        println("Gemini replay: requests=$firstCount")
        assertTrue("The reported trace must not buy another spelling for every OCR edit: $firstCount", firstCount <= 26)
        for (fragment in listOf("paying", "calm down", "misunderstanding", "wasn't like that", "cuckold")) {
            assertTrue("A genuine subtitle was lost: $fragment", requested.any { it.contains(fragment, true) })
        }
        replay(engine())
        assertEquals(firstCount, requested.size)
    }
}
