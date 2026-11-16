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

/** Gameplay-only OCR readings from the user's 2026-11-15 trace; no account data. */
class DeepLLoggedOcrReplayTest {
    @get:Rule val temporary = TemporaryFolder()

    @Test fun noisyGameplayDoesNotCreateAPaidCandidateForEverySpelling() {
        replayFixture("deepl-ocr-2026-11-15.json", 11, listOf("thanks, man", "find the boat",
            "we ain't going to find", "i can ask around", "insurance company", "fire and theft",
            "piracy claims", "paperwork", "yachting", "not any more"))
    }

    @Test fun followupGameplayPreservesAllNewDialogueAndReusesPaidResults() {
        replayFixture("deepl-ocr-2026-11-15-followup.json", 27, listOf("find the boat",
            "insurance company", "piracy claims", "before", "his room all day",
            "other people to go with", "marina", "clear my head", "other dreams",
            "sure, whatever", "look after", "thousand", "should be cool", "sure you're good"))
    }

    private fun replayFixture(resource: String, maxRequests: Int, expectedFragments: List<String>) {
        val rows = JSONArray(javaClass.getResource("/$resource")!!.readText())
        val cacheFile = File(temporary.root, "translations.jsonl")
        var requests = 0
        var billedCharacters = 0
        fun engine() = DeepLTranslationEngine(DeepLTranslationCache(cacheFile), client = { key ->
            DeepLClient(key) { url -> object : HttpURLConnection(url) {
                val body = ByteArrayOutputStream()
                override fun connect() {}
                override fun disconnect() {}
                override fun usingProxy() = false
                override fun getOutputStream() = body
                override fun getResponseCode(): Int { requests++; return 200 }
                override fun getInputStream(): ByteArrayInputStream {
                    val text = JSONObject(body.toString("UTF-8")).getJSONArray("text").getString(0)
                    val count = text.codePointCount(0, text.length)
                    billedCharacters += count
                    return ByteArrayInputStream(JSONObject().put("translations", JSONArray().put(
                        JSONObject().put("text", "translated: $text").put("billed_characters", count),
                    )).toString().toByteArray(Charsets.UTF_8))
                }
            } }
        })
        val keys = linkedSetOf<String>()
        fun millis(value: String): Long {
            val parts = value.split(':', '.')
            return ((parts[0].toLong() * 60 + parts[1].toLong()) * 60 + parts[2].toLong()) * 1000 + parts[3].toLong()
        }
        fun replay(engine: DeepLTranslationEngine) {
            var elapsed = 0L
            val policy = DeepLOcrPolicy { elapsed }
            var lastNonempty = 0L
            for (i in 0 until rows.length()) {
                val row = rows.getJSONObject(i)
                val text = row.getString("text")
                val now = millis(row.getString("time"))
                val until = if (i + 1 < rows.length()) millis(rows.getJSONObject(i + 1).getString("time")) else now + 67
                // Unchanged OCR frames are omitted from the diagnostic trace. Replay
                // the held reading at the logged 15 Hz, bounded to the hide interval.
                for (time in now..minOf(until - 1, now + 2_000) step 67) {
                    elapsed = time
                    if (text.isBlank() || row.getDouble("confidence") < .35 || isControllerOcrHint(text)) {
                        policy.discardPending()
                        if (time - lastNonempty >= 2_000) policy.clear()
                        continue
                    }
                    lastNonempty = time
                    policy.observe(text, row.getDouble("confidence").toFloat(), "en", 67)?.let {
                        keys.add(it.key)
                        val result = engine.translate("en", "tr", it.key, it.text, "test-key", 0)
                        assertEquals(it.key, deepLTextKey(result.text.removePrefix("translated: "), "en"))
                    }
                }
            }
        }
        replay(engine())
        val firstRequests = requests
        val firstCharacters = billedCharacters
        println("Gameplay replay $resource: requests=$firstRequests characters=$firstCharacters")
        assertEquals(keys.size, requests)
        assertTrue("Noisy OCR still creates $requests candidates", requests <= maxRequests)
        expectedFragments.forEach { fragment ->
            assertTrue("A real subtitle disappeared: $fragment", keys.any { it.contains(fragment) })
        }
        // Reopening the app and replaying these subtitles must cost nothing.
        replay(engine())
        assertEquals(firstRequests, requests)
        assertEquals(firstCharacters, billedCharacters)
    }
}
