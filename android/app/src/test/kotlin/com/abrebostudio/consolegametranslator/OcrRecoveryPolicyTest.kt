package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class OcrRecoveryPolicyTest {
    private fun read(text: String, confidence: Float) = OcrRecoveryPolicy.Read(text, confidence, text, confidence)

    @Test fun selectedGameAlwaysBypassesRecoveryEvenWhenDictionaryIsNotReadyOrNoLineMatches() {
        val policy = OcrRecoveryPolicy { 1000L }
        assertNull(policy.region(listOf(0, 1), gameSelected = true))
        assertFalse(policy.begin(read("Th|s sh1p is sinking", .3f), true, false, false))
        assertEquals(0, policy.region(listOf(0, 1), gameSelected = false))
    }

    @Test fun healthyReadingVisualReuseAndDebugComparisonDoNotAddOcrPasses() {
        val policy = OcrRecoveryPolicy { 1000L }
        assertFalse(policy.begin(read("We should find the boat.", .85f), false, false, false))
        assertFalse(policy.begin(read("Find the b0at.", .4f), false, true, false))
        assertFalse(policy.begin(read("Find the b0at.", .4f), false, false, true))
        assertFalse(policy.begin(read("R2D2 is waiting by the PS5.", .9f), false, false, false))
    }

    @Test fun consoleMenusControllerHintsTimersAndEmptyCropsAreNotRecoveredAsDialogue() {
        val policy = OcrRecoveryPolicy { 1000L }
        for (text in listOf("", "...", "00:14 00:14", "VI:00", "vI:00", "VI：OO", "Look behind L2 R2",
            "Arkadaş Etkinliği Konsol Depolama Alanı Boş alan")) {
            assertFalse(text, policy.begin(OcrRecoveryPolicy.Read(text, .5f, "", 0f), false, false, false))
        }
        assertFalse(policy.begin(OcrRecoveryPolicy.Read("Some menu instructions appear here", .9f, "", 0f), false, false, false))
    }

    @Test fun oneWeakReadGetsAtMostTwoDifferentAlternativesWithATimeAndRateBudget() {
        var now = 1000L
        val policy = OcrRecoveryPolicy { now }
        val weak = read("We can find the boat.", .6f)
        assertTrue(policy.begin(weak, false, false, false))
        assertEquals(listOf(1, 4), policy.modes(0))
        assertEquals(listOf(0, 4), policy.modes(1))
        assertEquals(listOf(0, 1), policy.modes(4))
        assertTrue(policy.modes(8).size <= 2)
        assertTrue(policy.withinBudget(now))
        now += 181
        assertFalse(policy.withinBudget(1000))
        repeat(100) { assertFalse(policy.begin(weak, false, false, false)) }
        assertNull(policy.region(listOf(0, 1), false))
        now = 1750
        assertTrue(policy.begin(weak, false, false, false))
    }

    @Test fun recoveryKeepsTheOriginalUnlessACompleteFilteredAlternativeIsBetter() {
        val policy = OcrRecoveryPolicy { 0L }
        val weak = read("Help me get out of this room right now.", .60f)
        assertEquals(1, policy.best(listOf(weak, read(weak.text, .86f)), "en"))
        assertEquals(0, policy.best(listOf(weak, read("Help me.", .96f)), "en"))
        assertEquals(0, policy.best(listOf(weak, read("", 0f)), "en"))
        assertEquals(0, policy.best(listOf(weak, read(weak.text, .63f)), "en"))
        assertEquals(1, policy.best(listOf(read("Th|s sh1p is sinking very fast.", .80f),
            read("This ship is sinking very fast.", .79f)), "en"))
    }

    @Test fun negationNumbersAndDirectionsCannotFlipOnOneAlternativeReading() {
        val policy = OcrRecoveryPolicy { 0L }
        for ((before, after) in listOf(
            "Go left and wait near the boat." to "Go right and wait near the boat.",
            "There are 5 guards near the boat." to "There are 6 guards near the boat.",
            "We should not wait near the boat." to "We should wait near the boat.",
        )) {
            val original = read(before, .65f)
            val alternative = read(after, .94f)
            assertEquals(0, policy.best(listOf(original, alternative), "en"))
            assertEquals(1, policy.best(listOf(original, alternative, read(after, .91f)), "en"))
        }
    }

    @Test fun unsupportedEnglishHeuristicsAreNotRequiredForOtherSourceLanguages() {
        val policy = OcrRecoveryPolicy { 0L }
        assertEquals(1, policy.best(listOf(read("يجب أن نجد القارب الآن", .60f),
            read("يجب أن نجد القارب الآن", .90f)), "ar"))
    }

    @Test fun aLowConfidenceSupportingReadCannotAuthorizeANumberChange() {
        val policy = OcrRecoveryPolicy { 0L }
        assertEquals(0, policy.best(listOf(read("There are 5 guards near the boat.", .65f),
            read("There are 6 guards near the boat.", .94f),
            read("There are 6 guards near the boat.", .20f)), "en-US"))
    }

    @Test fun weakRejectedTextCanRecoverOnlyThroughAnAcceptedDialogueRead() {
        val policy = OcrRecoveryPolicy { 1000L }
        val rejected = OcrRecoveryPolicy.Read("Th|s sh1p is sinking", .30f, "", 0f)
        assertTrue(policy.begin(rejected, false, false, false))
        val stillRejected = OcrRecoveryPolicy.Read("Some menu appears here", .95f, "", 0f)
        assertEquals(0, policy.best(listOf(rejected, stillRejected), "en"))
        assertEquals(2, policy.best(listOf(rejected, stillRejected,
            read("This ship is sinking.", .90f)), "en"))
    }

    @Test fun onlyOneRegionRetainsARawFrameAndRegionsRotateBeforeAnyRetryIsNeeded() {
        val policy = OcrRecoveryPolicy { 1000L }
        assertEquals(listOf(2, 5, 7, 2), (1..4).map { policy.region(listOf(2, 5, 7), false) })
        policy.reset()
        assertEquals(2, policy.region(listOf(2, 5, 7), false))
    }
}
