package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class GeminiKeyPoolTest {
    private fun limited(ms: Long = 60000) = GeminiException("GEMINI_RATE_LIMIT", "Wait", ms)

    @Test fun aReadyKeyStaysSelectedAndOnlyALimitedKeyIsRotated() {
        val pool = GeminiKeyPool { 1000L }
        pool.configure(listOf("private-a", "private-b", "private-c"))
        repeat(100) { assertEquals("private-a", pool.acquire()) }
        pool.failed("private-a", limited())
        assertEquals("private-b", pool.acquire())
        pool.succeeded("private-b")
        repeat(100) { assertEquals("private-b", pool.acquire()) }
        assertNull(pool.blockedStatus())
        val snapshots = pool.snapshot()["keys"] as List<*>
        assertEquals("waiting", (snapshots[0] as Map<*, *>)["state"])
    }

    @Test fun allKeysAreTriedAtMostOnceWithinTheirCooldownAndEarliestDeadlineResumes() {
        var now = 1000L
        val pool = GeminiKeyPool { now }
        pool.configure(listOf("a", "b"))
        assertEquals("a", pool.acquire())
        pool.failed("a", limited(120000))
        assertEquals("b", pool.acquire())
        now += 1000
        pool.failed("b", limited(60000))
        repeat(1000) { assertNull(pool.acquire()) }
        assertEquals(60000L, pool.blockedStatus()!!["delayMs"])
        val global = CloudTranslationRetryPolicy { now }
        global.defer("GEMINI_RATE_LIMIT", "", pool.blockedStatus()!!["delayMs"] as Long)
        now += 59999
        assertNull(pool.acquire())
        assertTrue(global.waiting)
        now++
        assertFalse(global.waiting)
        assertNull(pool.blockedStatus())
        assertEquals("b", pool.acquire())
    }

    @Test fun dailyAndInvalidCredentialsDoNotBlockAnotherReadyKeyOrItsTimedRetry() {
        var now = 1000L
        val pool = GeminiKeyPool { now }
        pool.configure(listOf("daily", "invalid", "timed"))
        pool.failed("daily", GeminiException("GEMINI_QUOTA", "Daily", Long.MAX_VALUE))
        assertEquals("invalid", pool.acquire())
        pool.failed("invalid", GeminiException("GEMINI_AUTH", "Invalid", Long.MAX_VALUE))
        assertEquals("timed", pool.acquire())
        pool.failed("timed", limited())
        assertEquals("waiting", pool.blockedStatus()!!["state"])
        assertEquals(60000L, pool.blockedStatus()!!["delayMs"])
        now += 60000
        assertEquals("timed", pool.acquire())
    }

    @Test fun allDailyKeysStayPausedWithoutProbeRequestsAndRetainLocalFallback() {
        val pool = GeminiKeyPool { 1000L }
        pool.configure(listOf("a", "b"))
        pool.failed("a", GeminiException("GEMINI_QUOTA", "Daily", Long.MAX_VALUE))
        pool.failed("b", GeminiException("GEMINI_AUTH", "Invalid", Long.MAX_VALUE))
        repeat(1000) { assertNull(pool.acquire()); pool.snapshot() }
        assertEquals("GEMINI_QUOTA", pool.blockedStatus()!!["code"])
        assertEquals(Long.MAX_VALUE, pool.blockedStatus()!!["delayMs"])
        val global = CloudTranslationRetryPolicy { 1000L }
        global.defer("GEMINI_QUOTA", "Daily", Long.MAX_VALUE)
        assertTrue(global.allowsGeminiFallback)
    }

    @Test fun configurationDeduplicatesBoundsAndRemovesDeletedKeysWithoutLeakingSecrets() {
        val pool = GeminiKeyPool { 1000L }
        pool.configure(listOf("", "private-a", "private-a", "private-b"))
        assertEquals(2, pool.snapshot()["keyCount"])
        assertFalse(pool.snapshot().toString().contains("private-"))
        assertEquals(pool.snapshot(), pool.snapshot())
        pool.configure(listOf("private-b"))
        assertEquals("private-b", pool.acquire())
        pool.configure(emptyList())
        assertNull(pool.acquire())
        assertEquals(0, pool.snapshot()["activeKeyIndex"])
        pool.configure((1..100).map { "secret-$it" })
        assertEquals(GeminiKeyList.MAX_KEYS, pool.snapshot()["keyCount"])
    }

    @Test fun contentErrorsAndNetworkOutagesMustNotSpendRequestsAcrossEveryKey() {
        for (code in listOf("GEMINI_BLOCKED", "GEMINI_RESPONSE", "GEMINI_NETWORK", "GEMINI_UNAVAILABLE", "GEMINI_REQUEST"))
            assertFalse(GeminiKeyPool.canFailOver(code))
        for (code in listOf("GEMINI_RATE_LIMIT", "GEMINI_QUOTA", "GEMINI_AUTH"))
            assertTrue(GeminiKeyPool.canFailOver(code))
    }
}
