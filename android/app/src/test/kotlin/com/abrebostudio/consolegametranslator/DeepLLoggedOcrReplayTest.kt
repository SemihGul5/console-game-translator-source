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

/** Gameplay-only OCR readings from the user's traces; no account data or real HTTP. */
class DeepLLoggedOcrReplayTest {
    @get:Rule val temporary = TemporaryFolder()

    @Test fun noisyGameplayDoesNotCreateAPaidCandidateForEverySpelling() {
        replayFixture("deepl-ocr-2026-11-15.json", 11, listOf("thanks, man", "find the boat",
            "we ain't going to find", "i can ask around", "insurance company", "fire and theft",
            "piracy claims", "paperwork", "yachting", "not any more"))
    }

    @Test fun followupGameplayPreservesAllNewDialogueAndReusesPaidResults() {
        replayFixture("deepl-ocr-2026-11-15-followup.json", 25, listOf("find the boat",
            "insurance company", "piracy claims", "before", "his room all day",
            "other people to go with", "marina", "clear my head", "other dreams",
            "sure, whatever", "look after", "thousand", "should be cool", "sure you're good"))
    }

    @Test fun unfilteredNoGameGameplayDoesNotBuyTimerNoiseOrFadeInSpellings() = replayNoGameTrace("deepl")

    @Test fun geminiAlsoAvoidsTimersAndCorroboratesNoisyDialogueInTheEarlierNoGameTrace() = replayNoGameTrace("gemini")

    private fun replayNoGameTrace(provider: String) {
        replayFixture("deepl-ocr-2026-11-17-no-game.json", if (provider == "gemini") 25 else 24, listOf("thanks, man",
            "find the boat", "we ain't going to find", "i can ask around", "insurance company",
            "fire and theft", "piracy claims", "paperwork", "yachting", "not any more",
            "before", "please", "this is a family", "it is binding", "to betray",
            "commit yourself", "show you how", "just give me a minute", "missing out",
            "prefer the company", "compliment", "your father", "bends the knee"), intervalMs = 100,
            maxCharacters = 1150, provider = provider)
    }

    @Test fun followupNoGameTracePreservesDialogueWithoutPayingForDuplicatePronounGlyphs() =
        replayLatestTrace("deepl")

    @Test fun geminiUsesTheSameNoiseContractionAndPersistentCacheGuards() = replayLatestTrace("gemini")

    private fun replayLatestTrace(provider: String) {
        replayFixture("cloud-ocr-2026-11-17-followup.json", 14, listOf("mafioso", "another drink",
            "where to again", "san celeste", "sit down", "how does it feel", "really good",
            "whatever the fuck", "boss of this crew", "moving to palermo", "what time it is",
            "behind a bush", "not everyone else"), intervalMs = 100, maxCharacters = 770, provider = provider)
    }

    private fun replayFixture(resource: String, maxRequests: Int, expectedFragments: List<String>,
        intervalMs: Long = 67, maxCharacters: Int = Int.MAX_VALUE, provider: String = "deepl") {
        val rows = JSONArray(javaClass.getResource("/$resource")!!.readText())
        val cacheFile = File(temporary.root, "translations.jsonl")
        var requests = 0
        var sourceCharacters = 0
        fun connection(url: URL) = object : HttpURLConnection(url) {
            val body = ByteArrayOutputStream()
            override fun connect() {}
            override fun disconnect() {}
            override fun usingProxy() = false
            override fun getOutputStream() = body
            override fun getResponseCode(): Int { requests++; return 200 }
            override fun getInputStream(): ByteArrayInputStream {
                val json = JSONObject(body.toString("UTF-8"))
                val text = if (provider == "deepl") json.getJSONArray("text").getString(0)
                    else json.getJSONArray("contents").getJSONObject(0).getJSONArray("parts").getJSONObject(0).getString("text")
                assertFalse("$provider must never receive standalone clock/number noise: $text", isNonLinguisticCloudOcr(text))
                val count = text.codePointCount(0, text.length)
                sourceCharacters += count
                val response = if (provider == "gemini") geminiResponse("translated: $text")
                    else JSONObject().put("translations", JSONArray().put(
                        JSONObject().put("text", "translated: $text").put("billed_characters", count),
                    )).toString()
                return ByteArrayInputStream(response.toByteArray(Charsets.UTF_8))
            }
        }
        fun engine(): (String, String) -> String {
            val cache = DeepLTranslationCache(cacheFile)
            if (provider == "gemini") {
                val engine = GeminiTranslationEngine(cache, client = { key -> GeminiClient(key, ::connection) })
                return { key, text -> engine.translate("en", "tr", key, text, "test-key").text }
            }
            val engine = DeepLTranslationEngine(cache, client = { key -> DeepLClient(key, ::connection) })
            return { key, text -> engine.translate("en", "tr", key, text, "test-key", 0).text }
        }
        val keys = linkedSetOf<String>()
        fun millis(value: String): Long {
            val parts = value.split(':', '.')
            return ((parts[0].toLong() * 60 + parts[1].toLong()) * 60 + parts[2].toLong()) * 1000 + parts[3].toLong()
        }
        fun replay(translate: (String, String) -> String) {
            var elapsed = 0L
            val policy = DeepLOcrPolicy { elapsed }
            var lastNonempty = 0L
            for (i in 0 until rows.length()) {
                val row = rows.getJSONObject(i)
                val text = row.getString("text")
                val now = millis(row.getString("time"))
                val until = if (i + 1 < rows.length()) millis(rows.getJSONObject(i + 1).getString("time")) else now + 67
                // Unchanged OCR frames are omitted from the diagnostic trace. Replay
                // the held reading at the logged interval, bounded to the hide interval.
                for (time in now..minOf(until - 1, now + 2_000) step intervalMs) {
                    elapsed = time
                    if (text.isBlank() || isNonLinguisticCloudOcr(text) ||
                        row.getDouble("confidence") < .35 || isControllerOcrHint(text)) {
                        policy.discardPending()
                        if (time - lastNonempty >= 2_000) policy.clear()
                        continue
                    }
                    lastNonempty = time
                    policy.observeCloud(text, row.getDouble("confidence").toFloat(), "en", intervalMs,
                        engine = provider)?.let {
                        keys.add(it.key)
                        val result = translate(it.key, it.text)
                        assertEquals(it.key, deepLTextKey(result.removePrefix("translated: "), "en"))
                    }
                }
            }
        }
        replay(engine())
        val firstRequests = requests
        val firstCharacters = sourceCharacters
        println("Gameplay replay $provider $resource: requests=$firstRequests characters=$firstCharacters")
        assertEquals(keys.size, requests)
        assertTrue("Noisy OCR still creates $requests candidates", requests <= maxRequests)
        assertTrue("Noisy OCR still sends $sourceCharacters characters", sourceCharacters <= maxCharacters)
        if (resource == "cloud-ocr-2026-11-17-followup.json") {
            assertEquals("$provider bought another spelling of the Palermo line", 1,
                keys.count { it.contains("moving to palermo") })
        }
        expectedFragments.forEach { fragment ->
            assertTrue("A real subtitle disappeared: $fragment", keys.any { it.contains(fragment) })
        }
        // Reopening the app and replaying these subtitles must cost nothing.
        replay(engine())
        assertEquals(firstRequests, requests)
        assertEquals(firstCharacters, sourceCharacters)
    }
}
