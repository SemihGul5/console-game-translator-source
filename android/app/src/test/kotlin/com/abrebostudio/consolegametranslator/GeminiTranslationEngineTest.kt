package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class GeminiTranslationEngineTest {
    @get:Rule val temp = TemporaryFolder()

    @Test fun repeatedSubtitlesAndPersistedResultsDoNotSpendAdditionalRequests() {
        val file = File(temp.root, "gemini.jsonl")
        var calls = 0
        val engine = GeminiTranslationEngine(DeepLTranslationCache(file), client = { apiKey ->
            GeminiClient(apiKey) { url -> calls++; GeminiTestConnection(url) }
        })
        assertFalse(engine.translate("en", "tr", "hello", "Hello", "private-key").fromCache)
        repeat(30) { assertTrue(engine.translate("en", "tr", "hello", "Hello", "private-key").fromCache) }
        val reopened = GeminiTranslationEngine(DeepLTranslationCache(file), client = { error("Must not call the API") })
        assertTrue(reopened.translate("en", "tr", "hello", "Hello", "other-key").fromCache)
        assertEquals(1, calls)
        assertFalse(file.readText().contains("private-key"))
    }

    @Test fun providersAndLanguagePairsUseSeparateCacheNamespaces() {
        val deepLFile = File(temp.root, "deepl.jsonl")
        DeepLTranslationCache(deepLFile).put("en", "tr", "hello", "DeepL result")
        val geminiFile = File(temp.root, "gemini-model.jsonl")
        var calls = 0
        val engine = GeminiTranslationEngine(DeepLTranslationCache(geminiFile), client = { apiKey ->
            GeminiClient(apiKey) { url -> calls++; GeminiTestConnection(url, response = geminiResponse("Gemini $calls")) }
        })
        assertEquals("Gemini 1", engine.translate("en", "tr", "hello", "Hello", "key").text)
        assertEquals("Gemini 2", engine.translate("en", "ar", "hello", "Hello", "key").text)
        assertEquals(2, calls)
        assertEquals("DeepL result", DeepLTranslationCache(deepLFile).get("en", "tr", "hello"))
    }

    @Test fun blockedSubtitlesAreNotRepeatedlySentButOtherLinesStillTranslate() {
        var calls = 0
        val engine = GeminiTranslationEngine(DeepLTranslationCache(File(temp.root, "gemini.jsonl")), client = { apiKey ->
            GeminiClient(apiKey) { url ->
                calls++
                GeminiTestConnection(url, response = if (calls == 1)
                    """{"promptFeedback":{"blockReason":"SAFETY"}}""" else geminiResponse("Devam et."))
            }
        })
        repeat(10) { assertThrows(GeminiException::class.java) {
            engine.translate("en", "tr", "blocked", "Blocked subtitle", "key")
        } }
        assertEquals(1, calls)
        assertEquals("Devam et.", engine.translate("en", "tr", "next", "Go on", "key").text)
        assertEquals(2, calls)
    }

    @Test fun correctedCredentialsCanRetryAndQuotaFailuresAreNeverCachedAsTranslations() {
        var calls = 0
        val engine = GeminiTranslationEngine(DeepLTranslationCache(File(temp.root, "gemini.jsonl")), client = { apiKey ->
            GeminiClient(apiKey) { url -> calls++; GeminiTestConnection(url, if (apiKey == "bad") 403 else 200) }
        })
        assertThrows(GeminiException::class.java) { engine.translate("en", "tr", "hello", "Hello", "bad") }
        assertEquals("Merhaba.", engine.translate("en", "tr", "hello", "Hello", "good").text)
        assertEquals(2, calls)
    }
}
