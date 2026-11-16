package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class GeminiKeyListTest {
    @Test fun legacyEncryptedPayloadIsKeptWhenAddingAndReopeningMultipleKeys() {
        val legacy = GeminiKeyList.decode(" original-private-key ")
        val updated = GeminiKeyList.adding(legacy, " second-private-key ")
        assertEquals(listOf("original-private-key", "second-private-key"), GeminiKeyList.decode(GeminiKeyList.encode(updated)))
        val remaining = updated.filterNot { GeminiKeyList.id(it) == GeminiKeyList.id(updated.first()) }
        assertEquals(listOf("second-private-key"), GeminiKeyList.decode(GeminiKeyList.encode(remaining)))
    }

    @Test fun duplicatesAndFullListsFailLocallyAndNeverOverwriteExistingKeys() {
        val keys = (1..5).map { "private-$it" }
        val duplicate = assertThrows(GeminiException::class.java) { GeminiKeyList.adding(keys, "private-2") }
        assertEquals("GEMINI_KEY_DUPLICATE", duplicate.code)
        val full = assertThrows(GeminiException::class.java) { GeminiKeyList.adding(keys, "private-6") }
        assertEquals("GEMINI_KEY_LIMIT", full.code)
        assertEquals(keys, GeminiKeyList.decode(GeminiKeyList.encode(keys)))
    }

    @Test fun malformedPayloadIsRejectedAsAWholeInsteadOfSilentlyLosingKeys() {
        for (payload in listOf("[", "[\"good\",null]", "[\"good\",42]", "[\"good\",\"bad key\"]"))
            assertThrows(Exception::class.java) { GeminiKeyList.decode(payload) }
    }

    @Test fun flutterMetadataContainsOnlyStableOpaqueIdentifiersAndCounts() {
        val keys = listOf("first-private-key", "second-private-key")
        val metadata = GeminiKeyList.metadata(keys)
        assertEquals(2, metadata["keyCount"])
        assertEquals(true, metadata["hasKey"])
        assertFalse(metadata.toString().contains("private-key"))
        assertEquals(GeminiKeyList.id(keys[1]), GeminiKeyList.id(GeminiKeyList.decode(GeminiKeyList.encode(keys))[1]))
        assertNotEquals(GeminiKeyList.id(keys[0]), GeminiKeyList.id(keys[1]))
    }
}
