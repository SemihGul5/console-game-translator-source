package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class CloudTranslationRetryPolicyTest {
    @Test fun reportedMinuteLimitExpiresWithoutAnyNewRequestOrWallClockDependence() {
        var now = 1000L
        val policy = CloudTranslationRetryPolicy { now }
        assertEquals(60000L, policy.fail("GEMINI_RATE_LIMIT", "Wait", 60000))
        now += 41000 // The user's trace ends 41 seconds into the 60-second cooldown.
        assertTrue(policy.waiting)
        assertEquals(19000L, policy.snapshot()["remainingMs"])
        assertEquals("waiting", policy.snapshot()["state"])
        now += 19000
        assertFalse(policy.waiting)
        assertEquals("idle", policy.snapshot()["state"])
    }

    @Test fun dailyQuotaOrAuthenticationFailuresDoNotTriggerAnAutomaticRetry() {
        var now = 1000L
        val policy = CloudTranslationRetryPolicy { now }
        policy.fail("GEMINI_QUOTA", "Daily quota exhausted", Long.MAX_VALUE)
        now += 86400000
        assertEquals(Long.MAX_VALUE, policy.remainingMs)
        assertEquals("paused", policy.snapshot()["state"])
        assertEquals(0L, policy.snapshot()["remainingMs"])
        policy.clear()
        assertFalse(policy.waiting)
    }

    @Test fun serverRetryAdviceAndExponentialNetworkBackoffArePreserved() {
        val policy = CloudTranslationRetryPolicy { 1000L }
        assertEquals(5000L, policy.fail("NETWORK", "", 5000))
        assertEquals(10000L, policy.fail("NETWORK", "", 5000))
        assertEquals(120000L, policy.fail("RATE_LIMIT", "", 120000))
        policy.clear()
        assertEquals(5000L, policy.fail("NETWORK", "", 5000))
    }

    @Test fun aRetryMustUseFreshConfirmedVideoTextInsteadOfTheOldFailedSubtitle() {
        var now = 1000L
        val policy = CloudTranslationRetryPolicy { now }
        policy.fail("GEMINI_RATE_LIMIT", "", 60000)
        assertFalse(policy.canRetryLatest(now, 67))
        now += 60000
        assertFalse(policy.canRetryLatest(1000, 67))
        assertFalse(policy.canRetryLatest(0, 67))
        assertTrue(policy.canRetryLatest(now - 500, 67))
        assertTrue(policy.canRetryLatest(now - 3000, 4000))
        assertFalse(policy.canRetryLatest(now + 1, 67))
    }
}
