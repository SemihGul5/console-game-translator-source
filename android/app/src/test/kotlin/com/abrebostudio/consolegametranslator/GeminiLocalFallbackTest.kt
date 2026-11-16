package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class GeminiLocalFallbackTest {
    @Test fun bothInstalledPreferAAndCacheRepeatedLinesWithoutInference() {
        val calls = mutableListOf<String>()
        var checks = 0
        val fallback = GeminiLocalFallback({ _, _ -> checks++; setOf("opus", "mlkit") },
            { engine, _, _, text -> calls.add(engine); "translated $text" })
        assertEquals("opus", fallback.translate("en", "tr", "hello", "Hello").engine)
        assertTrue(fallback.translate("en", "tr", "hello", "Hello!").fromCache)
        assertEquals(listOf("opus"), calls)
        assertEquals(1, checks)
    }

    @Test fun onlyBInstalledUsesBWithoutTryingA() {
        val calls = mutableListOf<String>()
        val fallback = GeminiLocalFallback({ _, _ -> setOf("mlkit") },
            { engine, _, _, _ -> calls.add(engine); "Merhaba" })
        assertEquals("mlkit", fallback.translate("en", "tr", "hello", "Hello").engine)
        assertEquals(listOf("mlkit"), calls)
    }

    @Test fun noPackOrUnsupportedPairUsesOnlyExistingCacheAndDoesNotKeepChecking() {
        var checks = 0
        var calls = 0
        val fallback = GeminiLocalFallback({ source, target ->
            checks++
            if (source == "en" && target == "tr") setOf("opus") else emptySet()
        }, { _, _, _, _ -> calls++; "Merhaba" })
        assertNotNull(fallback.translate("en", "tr", "hello", "Hello").text)
        repeat(100) {
            val result = fallback.translate("en", "ar", "hello", "Hello")
            assertEquals("unavailable", result.engine)
            assertNull(result.text)
        }
        assertNull(fallback.cached("en", "ar", "hello"))
        assertTrue(fallback.translate("en", "tr", "hello", "Hello").fromCache)
        assertEquals(2, checks)
        assertEquals(1, calls)
    }

    @Test fun corruptAUsesInstalledBAndDoesNotRetryBrokenPackForEveryLine() {
        val calls = mutableListOf<String>()
        val fallback = GeminiLocalFallback({ _, _ -> setOf("opus", "mlkit") },
            { engine, _, _, text ->
                calls.add(engine)
                if (engine == "opus") error("corrupt pack")
                "translated $text"
            })
        assertEquals("mlkit", fallback.translate("en", "tr", "hello", "Hello").engine)
        assertEquals("mlkit", fallback.translate("en", "tr", "bye", "Bye").engine)
        assertEquals(listOf("opus", "mlkit", "mlkit"), calls)
    }

    @Test fun failedLocalEnginesAreReportedWithoutReturningSourceAsTranslation() {
        var calls = 0
        val fallback = GeminiLocalFallback({ _, _ -> setOf("opus", "mlkit") },
            { _, _, _, _ -> calls++; "" })
        repeat(100) {
            val result = fallback.translate("en", "tr", "line $it", "Line $it")
            assertNull(result.text)
            assertEquals("failed", result.engine)
        }
        assertEquals(2, calls)
    }

    @Test fun fallbackNeverClearsCloudCooldownAndCloudResumesWithoutReadingLocalCache() {
        var now = 1000L
        val retry = CloudTranslationRetryPolicy { now }
        val cloud = mutableMapOf<String, String>()
        var cloudCalls = 0
        var localCalls = 0
        val fallback = GeminiLocalFallback({ _, _ -> setOf("opus") },
            { _, _, _, _ -> localCalls++; "local" })
        fun route(key: String): String? = cloud[key] ?: if (retry.allowsGeminiFallback)
            fallback.translate("en", "tr", key, key).text
        else { cloudCalls++; "Gemini".also { cloud[key] = it } }
        cloud["known"] = "cached Gemini"
        retry.fail("GEMINI_RATE_LIMIT", "", 60000)
        assertEquals("cached Gemini", route("known"))
        assertEquals(0, localCalls)
        assertEquals("local", route("new"))
        assertEquals("local", route("new"))
        assertEquals(0, cloudCalls)
        assertEquals(1, localCalls)
        assertTrue(retry.waiting)
        now += 60000
        assertFalse(retry.allowsGeminiFallback)
        assertEquals("Gemini", route("new"))
        assertEquals(1, cloudCalls)
        assertEquals("local", fallback.cached("en", "tr", "new")!!.text)
    }

    @Test fun dailyQuotaCanUseLocalButAuthenticationAndInputErrorsCannot() {
        val retry = CloudTranslationRetryPolicy { 1000L }
        retry.fail("GEMINI_QUOTA", "", Long.MAX_VALUE)
        assertTrue(retry.allowsGeminiFallback)
        for (code in listOf("GEMINI_AUTH", "GEMINI_KEY_REQUIRED", "GEMINI_REQUEST", "GEMINI_MODEL")) {
            retry.fail(code, "", Long.MAX_VALUE)
            assertFalse(retry.allowsGeminiFallback)
        }
    }
}
