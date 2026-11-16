package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class SubscriptionAccessTest {
    private fun access(active: Boolean = true, failed: Boolean = false, trial: Boolean = true,
                       expiry: Long? = 10_000, renew: Boolean = true, server: Long = 1_000,
                       wall: Long = 1_000, elapsed: Long = 100,
                       previous: SubscriptionAccess = SubscriptionAccess()) =
        SubscriptionAccess.fromEntitlement(active, failed, trial, expiry, renew, server, wall, elapsed, previous)

    @Test fun aTrialRequiresAnActiveStoreEntitlement() {
        assertFalse(access(active = false).isActive(100))
        assertTrue(access().isActive(100))
        assertEquals("trial", access().state)
    }
    @Test fun cancellationKeepsAccessUntilTheExistingPeriodEnds() {
        val cancelled = access(renew = false)
        assertFalse(cancelled.willRenew)
        assertTrue(cancelled.isActive(9_099))
        assertFalse(cancelled.isActive(9_100))
    }
    @Test fun expiredOrUnverifiedResponsesCannotGrantAccess() {
        assertFalse(access(expiry = 1_000).isActive(100))
        assertEquals("verification_required", access(failed = true).state)
        assertFalse(access(failed = true).isActive(100))
        assertFalse(access(trial = true, expiry = null).isActive(100))
    }
    @Test fun lifetimeAndPaidSubscriptionsDoNotNeedAUsageCounter() {
        assertEquals("premium", access(trial = false).state)
        val lifetime = access(trial = false, expiry = null)
        assertEquals("lifetime", lifetime.state)
        assertTrue(lifetime.isActive(365L * 86_400_000))
    }
    @Test fun clockRollbackOrCachedResponsesCannotExtendTheSamePeriod() {
        val first = access()
        val cached = access(wall = 0, elapsed = 5_000, previous = first)
        assertEquals(first.deadlineElapsedMs, cached.deadlineElapsedMs)
        assertFalse(cached.isActive(9_100))
        assertFalse(access(server = 11_000, wall = 0).isActive(100))
    }
    @Test fun aRenewedStorePeriodCanExtendAccess() {
        val renewed = access(expiry = 20_000, server = 10_000, wall = 10_000, elapsed = 9_100, previous = access())
        assertEquals("trial", renewed.state)
        assertTrue(renewed.isActive(19_099))
        assertFalse(renewed.isActive(19_100))
    }
    @Test fun aSixtyMinuteCalendarTrialCountsNetworkDelayAndNeverPauses() {
        val serverIssued = 1_800_000L
        val requestStarted = 100L
        val trial = access(expiry = serverIssued + 60 * 60_000L,
            server = serverIssued + 1000L, wall = serverIssued + 1000L, elapsed = requestStarted)
        assertTrue(trial.isActive(requestStarted + 5000L))
        // Stopping translation, app backgrounding, or elapsed time after the RPC
        // does not change the deadline or award another sixty minutes.
        assertTrue(trial.isActive(requestStarted + 59 * 60_000L))
        assertFalse(trial.isActive(requestStarted + 60 * 60_000L))
    }
}
