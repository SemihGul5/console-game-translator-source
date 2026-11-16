package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class FreeTrialPolicyTest {
    @Test fun acceptsRemoteDurationsIncludingOffersLongerThanAnHour() {
        for (minutes in listOf(1L, 15L, 60L, 90L, 120L, 1440L)) {
            assertEquals(minutes.toInt(), FreeTrialPolicy.minutes(minutes))
        }
    }

    @Test fun rejectsMissingMalformedOrUnboundedOffers() {
        for (value in listOf(null, 0L, -1L, 1441L, 60.5, "60", true)) {
            assertThrows(IllegalArgumentException::class.java) { FreeTrialPolicy.minutes(value) }
        }
    }
}
