package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class RemotePlayTrialGateTest {
    @Test fun signInSetupAndFramesNeverRequestATrialWrite() {
        val gate = RemotePlayTrialGate()
        repeat(1000) { assertFalse(gate.takeClaim(true, true, false)) }
        assertFalse(gate.hasPendingConnection)
    }

    @Test fun connectionRequestsExactlyOneClaimBeforeAnySubtitleOrTvListenerExists() {
        val gate = RemotePlayTrialGate()
        var claims = 0
        repeat(1000) {
            gate.connected()
            if (gate.takeClaim(true, true, false)) claims++
        }
        assertEquals(1, claims)
        assertTrue(gate.hasPendingConnection)
        gate.reset() // The existing deadline now authorizes OCR and TV delivery.
        assertFalse(gate.hasPendingConnection)
    }

    @Test fun anInFlightEligibilityReadDefersTheSingleClaimRatherThanRepeatingIt() {
        val gate = RemotePlayTrialGate()
        gate.connected()
        repeat(50) { assertFalse(gate.takeClaim(true, true, true)) }
        assertTrue(gate.takeClaim(true, true, false))
        assertFalse(gate.takeClaim(true, true, false))
    }

    @Test fun stoppedUnverifiedAndAlreadyUsedTrialsCannotCreateANewDeadline() {
        val gate = RemotePlayTrialGate()
        gate.connected()
        assertFalse(gate.takeClaim(false, true, false))
        assertFalse(gate.takeClaim(true, false, false))
        gate.reset() // Stop, disconnect or change account before starting the claim.
        assertFalse(gate.takeClaim(true, true, false))
        gate.connected()
        assertFalse(gate.takeClaim(true, false, false)) // Active/expired stored trial is never renewed.
    }

    @Test fun manualRemotePlayConnectionWaitsForTheTranslationStartButton() {
        val gate = RemotePlayTrialGate()
        gate.connected()
        repeat(100) { assertFalse(gate.takeClaim(false, true, false)) }
        assertTrue(gate.takeClaim(true, true, false))
        assertFalse(gate.takeClaim(true, true, false))
    }

    @Test fun disconnectDuringEligibilityCheckCancelsTheDeferredClaimUntilReconnection() {
        val gate = RemotePlayTrialGate()
        gate.connected()
        assertFalse(gate.takeClaim(true, true, true))
        gate.reset()
        assertFalse(gate.takeClaim(true, true, false))
        gate.connected()
        assertTrue(gate.takeClaim(true, true, false))
    }

    @Test fun aConnectedTrialCanAuthorizeSubtitlesWithoutWaitingForASubtitleAndNeverRenewsOnRestart() {
        val gate = RemotePlayTrialGate()
        val serverNow = 1_800_000L
        val elapsed = 1000L
        var trial = SubscriptionAccess()
        var claims = 0
        gate.connected()
        if (gate.takeClaim(true, true, false)) {
            claims++
            trial = SubscriptionAccess.fromEntitlement(true, false, true, serverNow + 60 * 60_000L,
                false, serverNow, serverNow, elapsed)
        }
        assertTrue(trial.isActive(elapsed)) // Ready for the very first OCR/TV event; no Premium restore needed.
        gate.reset()
        gate.connected()
        assertFalse(gate.takeClaim(true, false, false)) // The account already owns an immutable deadline.
        assertEquals(1, claims)
        assertTrue(trial.isActive(elapsed + 59 * 60_000L))
        assertFalse(trial.isActive(elapsed + 60 * 60_000L))
    }
}
