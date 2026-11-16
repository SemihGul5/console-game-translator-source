package com.abrebostudio.consolegametranslator

import java.io.File
import java.security.MessageDigest
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class GameTranslationPackFileTest {
    @get:Rule val temporary = TemporaryFolder()
    private fun hash(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
    private fun pack(bytes: ByteArray, root: File) = File(root, "pack-${hash(bytes)}.json").apply { writeBytes(bytes) }

    @Test fun localJsonKeepsTranslationsSpeakersAndFontMetadata() {
        val root = temporary.newFolder("cache")
        val json = """{"game":"test","source":"en","target":"tr","speakers":{"Sweet":"Sweet"},
          "entries":[{"id":"1","english":"Open the northern gate.","turkish":"Kuzey kapısını aç."}],
          "gameProfile":{"regions":[{"enabled":true,"style":{"fontId":"test-font"}}],"fonts":[]}}"""
        val bytes = json.toByteArray(Charsets.UTF_8)
        val file = pack(bytes, root)
        val loaded = GameTranslationPackFile.read(root, file.path, hash(bytes), bytes.size.toLong())
        val memory = GameTranslationMemory.parse("test", "en", "tr", loaded)
        assertEquals("Kuzey kapısını aç.", memory.find("Sweet: Open the northern gate.")?.target)
        assertEquals("test-font", JSONObject(memory.gameProfileJson!!).getJSONArray("regions").getJSONObject(0).getJSONObject("style").getString("fontId"))
    }

    @Test fun mismatchedHashSizeAndFilesOutsideTheAppCacheAreRejected() {
        val root = temporary.newFolder("cache")
        val bytes = "{}".toByteArray()
        val file = pack(bytes, root)
        assertThrows(IllegalArgumentException::class.java) { GameTranslationPackFile.read(root, file.path, hash(bytes), 3) }
        file.writeText("[]")
        assertThrows(IllegalArgumentException::class.java) { GameTranslationPackFile.read(root, file.path, hash(bytes), 2) }
        val outside = pack(bytes, temporary.newFolder("outside"))
        assertThrows(IllegalArgumentException::class.java) { GameTranslationPackFile.read(root, outside.path, hash(bytes), 2) }
        assertThrows(IllegalArgumentException::class.java) { GameTranslationPackFile.read(root, file.path, hash(bytes), 26L * 1024 * 1024) }
    }

    @Test fun invalidUtf8CannotEnterTheDictionaryThroughTheFileShortcut() {
        val root = temporary.newFolder("cache")
        val bytes = byteArrayOf(0xc3.toByte(), 0x28)
        val file = pack(bytes, root)
        assertThrows(java.nio.charset.CharacterCodingException::class.java) {
            GameTranslationPackFile.read(root, file.path, hash(bytes), bytes.size.toLong())
        }
    }
}
