package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class DeepLTranslationCacheTest {
    @get:Rule val temporary = TemporaryFolder()

    @Test fun paidTranslationSurvivesRestartWithoutMixingLanguagesOrChangingUnicode() {
        val file = File(temporary.root, "cache.jsonl")
        val key = deepLTextKey("Let's leave.", "en")
        DeepLTranslationCache(file).put("en", "tr", key, "Çıkış şu köşede.\nHadi gidelim!")
        val restarted = DeepLTranslationCache(file)
        assertNull(restarted.getIfLoaded("en", "tr", key))
        assertEquals("Çıkış şu köşede.\nHadi gidelim!", restarted.get("en", "tr", key))
        assertEquals("Çıkış şu köşede.\nHadi gidelim!", restarted.getIfLoaded("en", "tr", key))
        assertNull(restarted.get("en", "de", key))
        assertNull(restarted.get("de", "tr", key))
        assertFalse(file.readText().contains("api_key"))
    }

    @Test fun capacityIsBoundedAndRecentEntriesSurviveCompaction() {
        val file = File(temporary.root, "cache.jsonl")
        val cache = DeepLTranslationCache(file, maxEntries = 3, maxBytes = 2_048)
        repeat(30) { cache.put("en", "tr", "dialogue $it", "Çeviri $it") }
        assertTrue(file.length() <= 2_048)
        val restarted = DeepLTranslationCache(file, maxEntries = 3, maxBytes = 2_048)
        assertNull(restarted.get("en", "tr", "dialogue 0"))
        assertEquals("Çeviri 29", restarted.get("en", "tr", "dialogue 29"))
        assertEquals("Çeviri 28", restarted.get("en", "tr", "dialogue 28"))
    }

    @Test fun expiredResultsAndBrokenRowsCannotReachSubtitles() {
        val file = File(temporary.root, "cache.jsonl")
        var now = 1_000L
        DeepLTranslationCache(file, clock = { now }, maxAgeMs = 100).put("en", "tr", "hello", "Merhaba")
        file.appendText("not json\n{\"v\":1}\n")
        assertEquals("Merhaba", DeepLTranslationCache(file, clock = { now }, maxAgeMs = 100).get("en", "tr", "hello"))
        now += 101
        assertNull(DeepLTranslationCache(file, clock = { now }, maxAgeMs = 100).get("en", "tr", "hello"))
    }

    @Test fun storageFailureKeepsPaidResultInMemoryInsteadOfCausingAnotherApiCall() {
        val notDirectory = temporary.newFile("blocked")
        val cache = DeepLTranslationCache(File(notDirectory, "cache.jsonl"))
        cache.put("en", "tr", "hello", "Merhaba")
        assertEquals("Merhaba", cache.get("en", "tr", "hello"))
    }

    @Test fun existingJournalSurvivesBeyondThirtyDaysWithoutRefreshingItsCreationTime() {
        val day = 24L * 60 * 60 * 1000
        val file = File(temporary.root, "legacy-cache.jsonl")
        var now = 1000L
        DeepLTranslationCache(file, clock = { now }).put("en", "tr", "hello", "Merhaba")
        val originalJournal = file.readText()
        now += 60 * day
        val reopened = DeepLTranslationCache(file, clock = { now })
        assertEquals("Merhaba", reopened.get("en", "tr", "hello"))
        assertEquals(originalJournal, file.readText()) // Cache hits never add writes or prolong retention.
        now += 30 * day
        assertEquals("Merhaba", reopened.getIfLoaded("en", "tr", "hello"))
        now++
        assertNull(reopened.get("en", "tr", "hello"))
        assertNull(DeepLTranslationCache(file, clock = { now }).get("en", "tr", "hello"))
    }

    @Test fun aLongGameJournalLargerThanTheOldCountAndByteCapsStillLoadsAfterRestart() {
        val file = File(temporary.root, "long-game.jsonl")
        val now = 1000L
        val translation = "Çıkış şu köşede. " + "ç".repeat(500)
        // Existing v1 rows need no migration or retranslations when the app updates.
        file.bufferedWriter(Charsets.UTF_8).use { writer ->
            repeat(6000) { index ->
                writer.write(org.json.JSONObject().put("v", 1).put("source", "en").put("target", "tr")
                    .put("key", "line $index").put("translation", "$translation $index").put("at", now).toString())
                writer.newLine()
            }
        }
        assertTrue(file.length() > 4L * 1024 * 1024)
        val reopened = DeepLTranslationCache(file, clock = { now })
        assertEquals("$translation 0", reopened.get("en", "tr", "line 0"))
        assertEquals("$translation 5999", reopened.get("en", "tr", "line 5999"))
        assertNull(reopened.get("en", "ar", "line 0"))
        reopened.put("en", "tr", "next", "Yeni çeviri")
        val nextSession = DeepLTranslationCache(file, clock = { now })
        assertEquals("$translation 0", nextSession.get("en", "tr", "line 0"))
        assertEquals("Yeni çeviri", nextSession.get("en", "tr", "next"))
    }

    @Test fun blankResultsAndOversizedFilesAreIgnored() {
        val file = temporary.newFile("oversized")
        file.writeText("x".repeat(2_000))
        val cache = DeepLTranslationCache(file, maxBytes = 1_024)
        assertNull(cache.get("en", "tr", "hello"))
        cache.put("en", "tr", "empty", " ")
        assertNull(cache.get("en", "tr", "empty"))
        cache.put("en", "tr", "hello", "Merhaba")
        assertTrue(file.length() <= 1_024)
        assertEquals("Merhaba", DeepLTranslationCache(file, maxBytes = 1_024).get("en", "tr", "hello"))
    }
}
