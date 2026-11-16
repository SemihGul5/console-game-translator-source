package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class SubtitleSourceSelectorTest {
    @Test fun repeatedNoisyReadsKeepTheCanonicalJsonTextAndNewDialogueChangesImmediately() {
        val source = "Yeah. I'd come down to the marina, sit on the dock, pour myself a drink, and look at her -"
        val memory = GameTranslationMemory.parse("test-game", "en", "tr", org.json.JSONObject()
            .put("game", "test-game").put("source", "en").put("target", "tr")
            .put("entries", org.json.JSONArray()
                .put(org.json.JSONObject().put("id", "marina").put("english", source).put("turkish", "Aynen. Marina anısı."))
                .put(org.json.JSONObject().put("id", "next").put("english", "Get in the car!").put("turkish", "Arabaya bin!")))
            .toString())
        val outputs = mutableSetOf<String>()
        repeat(8) {
            val variants = listOf("Yyat. ld", "Yyan. ld", "9an. ld", "Y9a. ld")
                .map { source.replace("Yeah. I'd", it) } + listOf(
                    "eat. 'd come down to the marina, sit on the dock, pour myselfa drínk, and look at her -",
                    "Yeat. come down to the marina, sit on the dock, pour myselfa drínk, and look at her -",
                    "Seah. 'd come down to the marina, sit on the dock, pour myselfa drink, and look at her -",
                )
            for (raw in variants) {
                val selected = selectSubtitleSource(raw, .8f, memory) {
                    throw AssertionError("An OCR variant must not switch JSON to live translation: $raw")
                }
                val match = requireNotNull(selected.memoryMatch)
                assertEquals("marina", match.entryId)
                assertEquals(source, match.source)
                val event = subtitleTextEvent(0, match.target, "game_memory", match)
                outputs.add(event["text"] as String)
                val key = "${match.gameId}:${match.entryId}:${match.source}"
                assertFalse(canUseLiveSubtitle(key, key, raw))
            }
        }
        assertEquals(setOf("Aynen. Marina anısı."), outputs)
        val next = selectSubtitleSource("Get in the car!", .8f, memory) {
            throw AssertionError("The next line must be immediate")
        }
        assertEquals("next", next.memoryMatch?.entryId)
        assertEquals("Arabaya bin!", next.memoryMatch?.target)
        val noisyBody = "Yeat. ld come down to the marina, sit on the dock, pour myself a drink, and look at her -"
        val hud = selectSubtitleSource("AATOTlL $noisyBody", .8f, memory) {
            SubtitleOcrRead(noisyBody, .8f)
        }
        assertEquals("marina", hud.memoryMatch?.entryId)
        assertEquals("Aynen. Marina anısı.", hud.memoryMatch?.target)
    }

    @Test fun aSeparateHudBlockCannotSendAnExactDialogueLineToLiveTranslation() {
        val json = """{"game":"test-game","source":"en","target":"tr","entries":[
          {"id":"1","english":"We should leave before nightfall.","turkish":"Gece çökmeden gitmeliyiz."}]}"""
        val memory = GameTranslationMemory.parse("test-game", "en", "tr", json)
        val selected = selectSubtitleSource("00:14 We should leave before nightfall.", 0f, memory,
            listOf("We should leave before nightfall.")) { throw AssertionError("Exact block was lost") }
        assertEquals("Gece çökmeden gitmeliyiz.", selected.memoryMatch?.target)
    }

    @Test fun rapidShortJsonDialogueNeverWaitsForASecondReadOrALiveReply() {
        val json = """{"game":"test-game","source":"en","target":"tr","entries":[
          {"id":"1","english":"Go!","turkish":"Git!"},
          {"id":"2","english":"Stop!","turkish":"Dur!"},
          {"id":"3","english":"Get down!","turkish":"Yere yat!"}]}"""
        val memory = GameTranslationMemory.parse("test-game", "en", "tr", json)
        val lines = listOf("Go!" to "Git!", "Stop!" to "Dur!", "Get down!" to "Yere yat!")
        repeat(20) {
            for ((source, target) in lines) {
                val result = selectSubtitleSource(source, 0f, memory) { throw AssertionError("JSON reached live translation") }
                assertEquals(target, result.memoryMatch?.target)
                val hudResult = selectSubtitleSource("00:14 $source", 0f, memory, listOf("00:14", source)) {
                    throw AssertionError("A short exact block reached live translation")
                }
                assertEquals(target, hudResult.memoryMatch?.target)
                assertFalse(canUseLiveSubtitle("json:${result.memoryMatch?.entryId}", "json:${result.memoryMatch?.entryId}", "old-live"))
            }
        }
    }

    @Test
    fun noisyDictionaryHitHasPriorityEvenWithZeroConfidence() {
        val noisyMemory = GameTranslationMemory.parse("test-game", "en", "tr",
            """{"game":"test-game","source":"en","target":"tr","entries":[{"id":"known","english":"Secure northern window.","turkish":"Kuzey penceresini emniyete al."}]}""")
        val selected = selectSubtitleSource("Secvre northerm windov.", 0f, noisyMemory) {
            throw AssertionError("A fuzzy JSON hit must bypass filtering and live translation")
        }
        assertEquals("known", selected.memoryMatch?.entryId)
    }

    @Test fun changingLiveEngineCannotReplaceAnActiveJsonResultWithCachedLiveText() {
        assertFalse(canUseLiveSubtitle("game:entry:line", "game:entry:line", "game:entry:line"))
    }

    @Test fun aDelayedLiveReplyCannotReplaceTheNewJsonResult() {
        assertFalse(canUseLiveSubtitle("game:entry:line", "game:entry:line", "old-ocr-line"))
    }

    @Test fun anUnmatchedCurrentLineMayUseTheExistingLiveFallback() {
        assertTrue(canUseLiveSubtitle("new-ocr-line", null, "new-ocr-line"))
    }

    @Test fun anOldLiveReplyCannotOverwriteANewerUnmatchedLineEither() {
        assertFalse(canUseLiveSubtitle("new-ocr-line", null, "old-ocr-line"))
    }
    @Test
    fun isabellaFullOcrWinsBeforeDialogueFilterCanReduceItToTenant() {
        val raw = "ISABELLA: Oh, didn't you know? The Baron owns this land. The great Don Torrisi is| just his tenant."
        val selected = selectSubtitleSource(raw, 0.87f, memory) {
            throw AssertionError("A known full OCR must bypass the dialogue filter")
        }
        assertEquals(raw, selected.text)
        val match = requireNotNull(selected.memoryMatch)
        assertEquals("001283", match.entryId)
        assertEquals("Aa, bilmiyor muydun? Bu topraklar Baron'un. Koca Don Torrisi burada yalnızca kiracı.", match.target)
        assertFalse("The next on-screen subtitle must not be revealed early", match.target.contains("Ciao"))
    }

    @Test
    fun longTinoLineUsesJsonEvenWithZeroOcrConfidence() {
        val raw = "TINO: Make a mess of this and any misguided faith the Don has in you will be lost, u capisti?"
        val selected = selectSubtitleSource(raw, 0f, memory) {
            throw AssertionError("The dialogue filter used to discard the entire long line")
        }
        assertEquals("001691", selected.memoryMatch?.entryId)
        assertEquals("Bu işi batırırsan Don’un sana beslediği o yersiz güven de yok olur, anladın mı?",
            selected.memoryMatch?.target)
    }

    @Test
    fun loggedOcrSpellingVariantsStillUseTheFullIsabellaTranslation() {
        val variants = listOf(
            "ISABELLA: Oh, didn't you know? The Baron owns this land. The great DonTorrisi is just his tenant.",
            "ISABELLA: Oh, didn't you know? The Baron owns this land. The great DonTorrisi is just his tenant",
            "ISABELLA: Oh, didn't you knowThe Baron owns this land. The great DonTorrisi is just his tenant.",
        )
        for (raw in variants) {
            val selected = selectSubtitleSource(raw, 0.70f, memory) {
                throw AssertionError("Logged OCR variant fell through to the tenant fragment: $raw")
            }
            val match = requireNotNull(selected.memoryMatch)
            assertEquals("001283", match.entryId)
            assertTrue(match.target.startsWith("Aa, bilmiyor muydun?"))
            assertTrue(match.target.endsWith("kiracı."))
            assertFalse(match.target.contains("Ciao"))
        }
    }

    @Test
    fun unmatchedHudTextStillUsesTheDialogueFilter() {
        var filtered = false
        val selected = selectSubtitleSource("00:14 01:22 L1", 0.9f, memory) {
            filtered = true
            SubtitleOcrRead("", 0f)
        }
        assertTrue(filtered)
        assertEquals("", selected.text)
        assertNull(selected.memoryMatch)
    }

    @Test
    fun filteredTextAlsoGetsJsonPriorityBeforeLiveTranslation() {
        val selected = selectSubtitleSource("00:14 01:22 CARLO: Don't be an idiota, avoid the main gate.", 0.8f, memory) {
            SubtitleOcrRead("CARLO: Don't be an idiota, avoid the main gate.", 0.88f)
        }
        assertEquals("001692", selected.memoryMatch?.entryId)
        assertEquals("Aptallık etme, ana kapıdan uzak dur.", selected.memoryMatch?.target)
    }

    @Test
    fun withoutASelectedGameTheExistingFilterRemainsInControl() {
        val selected = selectSubtitleSource("raw OCR", 0.9f, null) {
            SubtitleOcrRead("filtered dialogue", 0.75f)
        }
        assertEquals("filtered dialogue", selected.text)
        assertEquals(0.75f, selected.confidence)
        assertNull(selected.memoryMatch)
    }

    companion object {
        private val memory by lazy {
            // The production dictionary is downloaded now, not bundled as an asset.
            val fixture = requireNotNull(SubtitleSourceSelectorTest::class.java
                .getResourceAsStream("/subtitle-source-selector.json"))
                .bufferedReader().use { it.readText() }
            GameTranslationMemory.parse("mafia-old-country", "en", "tr", fixture)
        }
    }
}
