package com.abrebostudio.consolegametranslator

import org.json.JSONObject
import org.json.JSONArray
import org.junit.Assert.*
import org.junit.Test

class GameTranslationMemoryCacheTest {
    @Test fun deletingOneLanguageKeepsTheOtherLanguageOfTheSameGame() {
        val cache = GameTranslationMemoryCache()
        val tr = key()
        val ar = key(target = "ar")
        val arabic = GameTranslationMemory.parse("game", "en", "ar", """{"schemaVersion":2,"game":"game","source":"en","target":"ar","entries":[{"id":"1","sourceText":"Come here!","targetText":"تعال إلى هنا!"}]}""")
        cache.put(tr, memory(tr)); cache.put(ar, arabic)
        cache.removeGame("game", "en", "ar")
        assertNull(cache.get(ar)); assertNotNull(cache.get(tr))
    }
    private fun key(id: String = "game", version: String = "v1", target: String = "tr") =
        GameTranslationMemoryKey(id, "en", target, "$id:$version")

    private fun memory(key: GameTranslationMemoryKey): GameTranslationMemory = GameTranslationMemory.parse(
        key.gameId, key.sourceLanguage, key.targetLanguage,
        JSONObject().put("game", key.gameId).put("source", key.sourceLanguage).put("target", key.targetLanguage)
            .put("entries", JSONArray().put(JSONObject().put("id", "line")
                .put("english", "Open the northern gate.").put("turkish", "Kuzey kapısını aç."))).toString(),
    )

    @Test fun returningToAGameReusesThePreparedIndexesAndTranslation() {
        val cache = GameTranslationMemoryCache()
        val a = key("a")
        val prepared = memory(a)
        cache.put(a, prepared)
        cache.put(key("b"), memory(key("b")))
        val restored = cache.get(a)
        assertSame(prepared, restored)
        assertEquals("Kuzey kapısını aç.", restored!!.find("Open the northern gate.")!!.target)
    }

    @Test fun contentUpdatesAndLanguageChangesCannotReuseStaleIndexes() {
        val cache = GameTranslationMemoryCache()
        cache.put(key(), memory(key()))
        assertNull(cache.get(key(version = "v2")))
        assertNull(cache.get(key(target = "de")))
        assertNull(cache.get(key(id = "other")))
    }

    @Test fun leastRecentlyUsedGameIsEvicted() {
        val cache = GameTranslationMemoryCache(maxEntries = 2)
        val a = memory(key("a"))
        cache.put(key("a"), a)
        cache.put(key("b"), memory(key("b")))
        assertSame(a, cache.get(key("a")))
        cache.put(key("c"), memory(key("c")))
        assertNull(cache.get(key("b")))
        assertSame(a, cache.get(key("a")))
        assertNotNull(cache.get(key("c")))
    }

    @Test fun memoryBudgetEvictsOldIndexesAndReplacementDoesNotCountTwice() {
        val a = memory(key("a"))
        val cache = GameTranslationMemoryCache(maxEntries = 8, maxBytes = a.estimatedRetainedBytes)
        cache.put(key("a"), a)
        cache.put(key("a"), a)
        assertSame(a, cache.get(key("a")))
        val b = memory(key("b"))
        cache.put(key("b"), b)
        assertNull(cache.get(key("a")))
        assertSame(b, cache.get(key("b")))
    }

    @Test fun oversizedSelectionDoesNotRetainOlderGamesAlongsideIt() {
        val small = memory(key("a"))
        val cache = GameTranslationMemoryCache(maxBytes = small.estimatedRetainedBytes)
        cache.put(key("a"), small)
        val large = GameTranslationMemory.parse("large", "en", "tr", JSONObject()
            .put("game", "large").put("source", "en").put("target", "tr")
            .put("entries", JSONArray((1..10).map {
                JSONObject().put("id", "$it").put("english", "Open northern gate number $it.")
                    .put("turkish", "$it numaralı kapıyı aç.")
            })).toString())
        cache.put(key("large"), large)
        assertNull(cache.get(key("a")))
        assertSame(large, cache.get(key("large")))
        assertNull(cache.get(key("large", version = "v2")))
        assertNull(cache.get(key("large", target = "de")))
        cache.removeGame("large")
        assertNull(cache.get(key("large")))
    }

    @Test fun deletingAGameEvictsAllItsVersionsButKeepsOtherGames() {
        val cache = GameTranslationMemoryCache(maxEntries = 4)
        cache.put(key(), memory(key()))
        cache.put(key(version = "v2"), memory(key(version = "v2")))
        val other = memory(key("other"))
        cache.put(key("other"), other)
        cache.removeGame("game")
        assertNull(cache.get(key()))
        assertNull(cache.get(key(version = "v2")))
        assertSame(other, cache.get(key("other")))
    }
}
