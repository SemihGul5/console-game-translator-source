package com.abrebostudio.consolegametranslator

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class GameTranslationMemoryIndexStoreTest {
    @get:Rule val folder = TemporaryFolder()

    private val key = GameTranslationMemoryKey("test-game", "en", "tr", "test-game:" + "a".repeat(64))

    private fun memory(): GameTranslationMemory {
        val entries = JSONArray()
            .put(JSONObject().put("id", "1").put("english", "Please open the northern gate.").put("turkish", "Lütfen kuzey kapısını aç."))
            .put(JSONObject().put("id", "2").put("english", "We blocked in! Damn! Run to the river.")
                .put("turkish", "Sıkıştık! Hay aksi! Nehre koş.").put("speaker", "Arthur"))
            .put(JSONObject().put("id", "3").put("english", "Bring 15 boxes to the barn.").put("turkish", "Ahıra 15 kutu getir.")
                .put("chapter", "2").put("kind", "subtitle"))
            .put(JSONObject().put("id", "4").put("english", "Please open the northern gate.").put("turkish", "Lütfen kuzey kapısını aç."))
        val json = JSONObject().put("game", "test-game").put("source", "en").put("target", "tr")
            .put("speakers", JSONObject().put("Arthur", "Arthur"))
            .put("gameProfile", JSONObject().put("regions", JSONArray()))
            .put("entries", entries)
        return GameTranslationMemory.parse("test-game", "en", "tr", json.toString())
    }

    @Test fun savedIndexAnswersExactlyLikeTheParsedPack() {
        val store = GameTranslationMemoryIndexStore(folder.root, "build-1")
        val parsed = memory()
        assertFalse(store.exists(key))
        store.write(key, parsed, store.epoch(key.gameId))
        assertTrue(store.exists(key))
        val loaded = requireNotNull(store.read(key))
        assertEquals(parsed.entryCount, loaded.entryCount)
        assertEquals(parsed.gameProfileJson, loaded.gameProfileJson)
        assertEquals(parsed.estimatedRetainedBytes, loaded.estimatedRetainedBytes)
        for (query in listOf("Please open the northern gate.", "Please open the qzxvzz gate.", "PleaseOpen the northern gate.",
                "We blocked in! qzxvzz", "Arthur: Run to the river.", "ARTHUR: We blocked in! Damn!",
                "Bring 15 boxes to the barn.", "Bring 16 boxes to the barn.", "Damn! Run to the", "nothing like this")) {
            assertEquals(query, parsed.find(query), loaded.find(query))
            assertEquals(query, parsed.findExact(query), loaded.findExact(query))
            assertEquals(query, parsed.rejectionReason(query), loaded.rejectionReason(query))
        }
    }

    @Test fun damagedOrForeignIndexesAreRejectedAndRebuilt() {
        val store = GameTranslationMemoryIndexStore(folder.root, "build-1")
        store.write(key, memory(), store.epoch(key.gameId))
        assertNull(GameTranslationMemoryIndexStore(folder.root, "build-2").read(key))
        assertNull(store.read(key.copy(contentKey = "test-game:" + "b".repeat(64))))
        assertNull(store.read(key.copy(targetLanguage = "ar")))
        val file = folder.root.listFiles()!!.single { it.name.endsWith(".idx") }
        val bytes = file.readBytes()
        bytes[bytes.size / 2] = (bytes[bytes.size / 2] + 1).toByte()
        file.writeBytes(bytes)
        assertNull(store.read(key))
        assertFalse(file.exists())
    }

    @Test fun deletedGameIsNotSavedAgainByAnEarlierPreparation() {
        val store = GameTranslationMemoryIndexStore(folder.root, "build-1")
        val epoch = store.epoch(key.gameId)
        store.write(key, memory(), epoch)
        store.removeGame(key.gameId, key.sourceLanguage, key.targetLanguage)
        assertFalse(store.exists(key))
        store.write(key, memory(), epoch)
        assertFalse(store.exists(key))
    }

    @Test fun newPackVersionReplacesOldIndexAndOldBuildsAreCleaned() {
        val store = GameTranslationMemoryIndexStore(folder.root, "build-1")
        store.write(key, memory(), store.epoch(key.gameId))
        val updated = key.copy(contentKey = "test-game:" + "c".repeat(64))
        store.write(updated, memory(), store.epoch(key.gameId))
        assertFalse(store.exists(key))
        assertTrue(store.exists(updated))
        val newer = GameTranslationMemoryIndexStore(folder.root, "build-2")
        newer.deleteStale()
        assertTrue(folder.root.listFiles()!!.isEmpty())
    }

    @Test fun bundledAssetsWithoutAHashAreNotIndexed() {
        val store = GameTranslationMemoryIndexStore(folder.root, "build-1")
        val asset = key.copy(contentKey = "test-game:assets/games/test.json")
        store.write(asset, memory(), 0)
        assertFalse(store.exists(asset))
    }
}
