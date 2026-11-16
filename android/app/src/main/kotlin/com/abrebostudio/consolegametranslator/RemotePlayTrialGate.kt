package com.abrebostudio.consolegametranslator

/** One claim when requested Remote Play connects; independent of OCR, models and TV listeners. */
internal class RemotePlayTrialGate {
    private enum class Phase { IDLE, CONNECTED, CLAIMING }
    @Volatile private var phase = Phase.IDLE
    val hasPendingConnection: Boolean get() = phase != Phase.IDLE

    @Synchronized fun connected() { if (phase == Phase.IDLE) phase = Phase.CONNECTED }

    @Synchronized fun takeClaim(translationRequested: Boolean, unusedTrialVerified: Boolean, storeBusy: Boolean): Boolean {
        if (phase != Phase.CONNECTED || !translationRequested || !unusedTrialVerified || storeBusy) return false
        phase = Phase.CLAIMING
        return true
    }

    @Synchronized fun reset() { phase = Phase.IDLE }
}
