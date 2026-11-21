package com.abrebostudio.consolegametranslator

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.ByteArrayOutputStream
import java.io.File
import java.security.MessageDigest
import java.util.zip.GZIPOutputStream

class GameTranslationPackFileTest {
    @get:Rule val folder = TemporaryFolder()

    private val json = JSONObject().put("schemaVersion", 2).put("game", "test-game").put("source", "en").put("target", "tr")
        .put("gameProfile", JSONObject().put("regions", JSONArray()))
        .put("entries", JSONArray().put(JSONObject().put("id", "1").put("sourceText", "Please open the northern gate.")
            .put("targetText", "Lütfen kuzey kapısını aç."))).toString().toByteArray()

    private fun sha(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
    private fun gzip(bytes: ByteArray) = ByteArrayOutputStream().also { out -> GZIPOutputStream(out).use { it.write(bytes) } }.toByteArray()
    private fun store(bytes: ByteArray, compressed: Boolean, name: String = "pack-${sha(bytes)}.json${if (compressed) ".gz" else ""}") =
        File(folder.root, name).apply { writeBytes(bytes) }
    private fun read(file: File, hash: String, size: Long = file.length()) =
        GameTranslationPackFile.read(folder.root, file.path, hash, size) { GameTranslationMemory.parse("test-game", "en", "tr", it) }

    // Restored from the original suite, adapted to the streaming read(..) { parse }.
    private fun packIn(bytes: ByteArray, root: File) = File(root, "pack-${sha(bytes)}.json").apply { writeBytes(bytes) }

    @Test fun localJsonKeepsTranslationsSpeakersAndFontMetadata() {
        val root = folder.newFolder("cache")
        val json = """{"game":"test","source":"en","target":"tr","speakers":{"Sweet":"Sweet"},
          "entries":[{"id":"1","english":"Open the northern gate.","turkish":"Kuzey kapısını aç."}],
          "gameProfile":{"regions":[{"enabled":true,"style":{"fontId":"test-font"}}],"fonts":[]}}"""
        val bytes = json.toByteArray(Charsets.UTF_8)
        val file = packIn(bytes, root)
        val memory = GameTranslationPackFile.read(root, file.path, sha(bytes), bytes.size.toLong()) {
            GameTranslationMemory.parse("test", "en", "tr", it)
        }
        assertEquals("Kuzey kapısını aç.", memory.find("Sweet: Open the northern gate.")?.target)
        assertEquals("test-font", JSONObject(memory.gameProfileJson!!).getJSONArray("regions").getJSONObject(0).getJSONObject("style").getString("fontId"))
    }

    @Test fun mismatchedHashSizeAndFilesOutsideTheAppCacheAreRejected() {
        val root = folder.newFolder("cache")
        val bytes = "{}".toByteArray()
        val file = packIn(bytes, root)
        val text: (java.io.Reader) -> String = { it.readText() }
        assertThrows(IllegalArgumentException::class.java) { GameTranslationPackFile.read(root, file.path, sha(bytes), 3, text) }
        file.writeText("[]")
        assertThrows(IllegalArgumentException::class.java) { GameTranslationPackFile.read(root, file.path, sha(bytes), 2, text) }
        val outside = packIn(bytes, folder.newFolder("outside"))
        assertThrows(IllegalArgumentException::class.java) { GameTranslationPackFile.read(root, outside.path, sha(bytes), 2, text) }
        assertThrows(IllegalArgumentException::class.java) { GameTranslationPackFile.read(root, file.path, sha(bytes), 26L * 1024 * 1024, text) }
    }

    @Test fun invalidUtf8CannotEnterTheDictionaryThroughTheFileShortcut() {
        val root = folder.newFolder("cache")
        val bytes = byteArrayOf(0xc3.toByte(), 0x28)
        val file = packIn(bytes, root)
        assertThrows(java.nio.charset.CharacterCodingException::class.java) {
            GameTranslationPackFile.read(root, file.path, sha(bytes), bytes.size.toLong()) { it.readText() }
        }
        val packed = gzip(bytes)
        val compressed = File(root, "pack-${sha(packed)}.json.gz").apply { writeBytes(packed) }
        assertThrows(java.nio.charset.CharacterCodingException::class.java) {
            GameTranslationPackFile.read(root, compressed.path, sha(packed), packed.size.toLong()) { it.readText() }
        }
    }

    @Test fun plainAndGzipPacksProduceTheSameMemory() {
        val plain = read(store(json, compressed = false), sha(json))
        val packed = gzip(json)
        val expanded = read(store(packed, compressed = true), sha(packed))
        for (memory in listOf(plain, expanded)) {
            assertEquals("Lütfen kuzey kapısını aç.", memory.find("Please open the northern gate.")?.target)
            assertEquals("""{"regions":[]}""", memory.gameProfileJson)
        }
    }

    @Test fun hashCoversTheCompressedBytesAndTamperingIsRejected() {
        val packed = gzip(json)
        val file = store(packed, compressed = true)
        // The hash of the expanded JSON is not accepted for a .json.gz file.
        assertThrows(Exception::class.java) { read(file, sha(json)) }
        val tampered = packed.copyOf().also { it[it.size - 5] = (it[it.size - 5] + 1).toByte() }
        file.writeBytes(tampered)
        assertThrows(Exception::class.java) { read(file, sha(packed)) }
        // Appended bytes change the size and the hash.
        file.writeBytes(packed + byteArrayOf(0, 0))
        assertThrows(Exception::class.java) { read(file, sha(packed), packed.size.toLong()) }
    }

    @Test fun brokenGzipAndWrongNamesAreRejected() {
        val notGzip = "not gzip".toByteArray()
        assertThrows(Exception::class.java) { read(store(notGzip, compressed = true), sha(notGzip)) }
        val truncated = gzip(json).copyOf(20)
        assertThrows(Exception::class.java) { read(store(truncated, compressed = true), sha(truncated)) }
        val packed = gzip(json)
        val misnamed = store(packed, compressed = false, name = "pack-${sha(packed)}.json")
        assertThrows(Exception::class.java) { read(misnamed, sha(packed)) }
        val outside = File(folder.newFolder("other"), "pack-${sha(packed)}.json.gz").apply { writeBytes(packed) }
        assertThrows(Exception::class.java) {
            GameTranslationPackFile.read(File(folder.root, "missing"), outside.path, sha(packed), outside.length()) { it.read() }
        }
    }

    @Test fun expansionAbove64MiBStopsEarly() {
        val bomb = ByteArrayOutputStream().also { out ->
            GZIPOutputStream(out).use { zip ->
                zip.write("""{"game":"test-game","pad":"""".toByteArray())
                val spaces = ByteArray(1024 * 1024) { ' '.code.toByte() }
                repeat(65) { zip.write(spaces) }
                zip.write("\"}".toByteArray())
            }
        }.toByteArray()
        assertTrue(bomb.size < 1024 * 1024)
        val error = assertThrows(GameTranslationPackFile.TooLargeException::class.java) {
            read(store(bomb, compressed = true), sha(bomb))
        }
        assertTrue(error.message!!.contains("64 MiB"))
    }
}
