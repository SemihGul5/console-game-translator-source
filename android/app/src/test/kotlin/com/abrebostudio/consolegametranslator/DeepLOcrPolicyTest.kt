package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class DeepLOcrPolicyTest {
    private fun newPolicy(): DeepLOcrPolicy {
        var now = 0L
        return DeepLOcrPolicy { now.also { now += 67 } }
    }

    private fun prime(policy: DeepLOcrPolicy, text: String): DeepLOcrPolicy.Read {
        var read: DeepLOcrPolicy.Read? = null
        repeat(3) { read = policy.observe(text, .8f, "en", 67) ?: read }
        return requireNotNull(read)
    }

    @Test fun reportedEnzoLineUsesOneTranslationDespiteSixRepeatedOcrSpellings() {
        val policy = newPolicy()
        val readings = listOf(
            "ENZO: And be stuck with those two? l'd much sooner ride... and I know l'l| prefer the",
            "ENZO: And be stuck with those two? l'd much sooner ride... and I know I'll prefer the",
            "ENZO: And be stuck with those two? l'd much sooner ride... and know l'll prefer the",
            "ENZO: And be stuck with those two? l'd much sooner ride... and know I'll prefer the",
            "ENZO: And be stuck vith those two? l'd much sooner ride... and I know l'll prefer the",
            "ENZO: And be stuck with those two? l'd much sooner ride... and I know l'l prefer the",
        )
        val acceptedKeys = mutableSetOf<String>()
        readings.forEach { text -> repeat(5) {
            policy.observe(text, .8f, "en", 67)?.let { acceptedKeys.add(it.key) }
        } }
        assertEquals(1, acceptedKeys.size)
        val first = requireNotNull(policy.observe(readings.first(), .8f, "en", 67))
        assertTrue(first.text.contains("I'd"))
        assertTrue(first.text.contains("I'll"))
        assertFalse(first.text.contains("l'l|"))
    }

    @Test fun reportedIsabellaAndGennaroGlyphErrorsDoNotSpendAnotherRequest() {
        listOf(
            listOf("ISABELLA: Not much of a compliment, but I'|l take it.",
                "ISABELLA: Not much of a compliment, but I'll take it.",
                "ISABELLA: Not much of a compliment, but I'|ll take it."),
            listOf("GENNARO: A country idiot like you wouldn't know what to do with her.",
                "GENNARO: A country idiot like you wwouldn't know what to do with her."),
        ).forEach { variants ->
            val policy = newPolicy()
            assertEquals(1, variants.flatMap { text -> List(4) { policy.observe(text, .8f, "en", 67)?.key } }
                .filterNotNull().distinct().size)
        }
    }

    @Test fun confirmedNegationAndDirectionChangesAreNeverReusedAsOcrNoise() {
        listOf(
            "Open the northern gate and wait for me." to "Do not open the northern gate and wait for me.",
            "Take the left road and wait by the entrance." to "Take the right road and wait by the entrance.",
            "Meet me at gate 12 beside the old warehouse." to "Meet me at gate 13 beside the old warehouse.",
            "We have one more chance to leave the building." to "We have two more chances to leave the building.",
            "JOHN: I will wait for you outside the old house." to "JOAN: I will wait for you outside the old house.",
        ).forEach { (old, next) ->
            val policy = newPolicy()
            val first = prime(policy, old)
            var second = policy.observe(next, .7f, "en", 67)
            repeat(4) { second = policy.observe(next, .7f, "en", 67) ?: second }
            assertNotEquals(first.key, requireNotNull(second).key)
        }
    }

    @Test fun ambiguousWordChangesNeedConsistencyButAreNeverFrozenAsOcrNoise() {
        val policy = newPolicy()
        val old = "I will meet John beside the entrance to the warehouse."
        val next = "I will meet Joan beside the entrance to the warehouse."
        prime(policy, old)
        repeat(4) { assertNull(policy.observe(next, .75f, "en", 67)) }
        assertEquals(next, requireNotNull(policy.observe(next, .74f, "en", 67)).text)
    }

    @Test fun lowSamplingAndShortNewDialogueStayImmediate() {
        val policy = newPolicy()
        assertEquals("Fire!", policy.observe("Fire!", .8f, "en", 67)?.text)
        assertEquals("Fine!", policy.observe("Fine!", .8f, "en", 67)?.text)
        policy.observe("I will meet John beside the old warehouse.", .8f, "en", 4_000)
        assertNotNull(policy.observe("I will meet Joan beside the old warehouse.", .8f, "en", 4_000))
    }

    @Test fun returningToAnchorBreaksConfirmationAndNewLongLinesWaitOnlyTwoFrames() {
        val policy = newPolicy()
        val anchor = "I will meet John beside the old warehouse."
        val variant = "I will meet Joan beside the old warehouse."
        prime(policy, anchor)
        repeat(5) {
            assertNull(policy.observe(variant, .8f, "en", 67))
            assertEquals(anchor, policy.observe(anchor, .8f, "en", 67)?.text)
        }
        assertNull(policy.observe("The boat is gone. Call the insurance company.", .7f, "en", 67))
        assertNull(policy.observe("The boat is gone. Call the insurance company.", .7f, "en", 67))
        assertNotNull(policy.observe("The boat is gone. Call the insurance company.", .7f, "en", 67))
        policy.clear()
        assertNull(policy.observe(variant, .7f, "en", 67))
        assertNull(policy.observe(variant, .7f, "en", 67))
        assertNotNull(policy.observe(variant, .7f, "en", 67))
    }

    @Test fun firstLongLineUsesCorroboratedHigherConfidenceReading() {
        val policy = newPolicy()
        assertNull(policy.observe("DON TORRISI: This is a famiy", .6f, "en", 67))
        assertNull(policy.observe("DON TORRISI: This is a family.", .9f, "en", 67))
        assertEquals("DON TORRISI: This is a family.",
            policy.observe("DON TORRISI: This is a family.", .8f, "en", 67)?.text)
    }

    @Test fun oneHigherConfidenceCorruptedFrameCannotBeatTwoCorroboratingReadings() {
        val policy = newPolicy()
        val correct = "I'm paying someone to work here, in my own bed?!"
        val glitch = "I'm paying someone to work here, in my Own bed2!"
        assertNull(policy.observe(correct, .82f, "en", 67, corroborateInitialCandidate = true))
        assertNull(policy.observe(glitch, .95f, "en", 67, corroborateInitialCandidate = true))
        val accepted = requireNotNull(policy.observe(correct, .81f, "en", 67, corroborateInitialCandidate = true))
        assertEquals(correct, accepted.text)
        assertEquals(accepted.key, policy.observe(correct, .85f, "en", 67)?.key)
    }

    @Test fun newUnconfirmedLineInvalidatesQueuedOldRequestAndTransientMissBreaksConfirmation() {
        val policy = newPolicy()
        val old = prime(policy, "The boat is gone. Call the insurance company.")
        assertEquals(old.key, policy.requestKey)
        val next = "Meet us outside the warehouse at sunrise."
        assertNull(policy.observe(next, .8f, "en", 67))
        assertNull(policy.requestKey)
        policy.discardPending()
        assertNull(policy.observe(next, .8f, "en", 67))
        assertNull(policy.observe(next, .8f, "en", 67))
        val accepted = requireNotNull(policy.observe(next, .8f, "en", 67))
        assertNotEquals(old.key, accepted.key)
        assertEquals(accepted.key, policy.requestKey)
    }

    @Test fun punctuationJitterReusesVisibleLineButNumbersQuestionsAndContractionsStayDistinct() {
        val policy = newPolicy()
        val first = prime(policy, "Man, I can ask around...")
        listOf("Man, I.can ask around..", "Man I can ask around.").forEach {
            assertEquals(first.key, policy.observe(it, .8f, "en", 67)?.key)
        }
        val yachting = "Eh, so you, ahh, do much yachting?"
        prime(policy, yachting)
        assertEquals(deepLTextKey(yachting, "en"),
            policy.observe("Eh, so you ahh, do much yachting?-", .8f, "en", 67)?.key)
        listOf("The target value is 12.5." to "The target value is 125.",
            "You know where to go?" to "You know where to go.",
            "We'll wait beside the entrance." to "Well wait beside the entrance.").forEach { (old, next) ->
            policy.clear()
            val previous = prime(policy, old)
            var accepted: DeepLOcrPolicy.Read? = null
            repeat(5) { accepted = policy.observe(next, .8f, "en", 67) ?: accepted }
            assertNotEquals(previous.key, requireNotNull(accepted).key)
        }
    }

    @Test fun repairsAreLanguageSpecificAndKeysKeepMeaningfulPunctuationAndContractions() {
        assertEquals("l'd with her", deepLRequestText("l'd with her", "fr"))
        assertEquals("Meet Vith beside the old gate.", deepLRequestText("Meet Vith beside the old gate.", "en"))
        assertNotEquals(deepLTextKey("We'll wait.", "en"), deepLTextKey("Well wait.", "en"))
        assertNotEquals(deepLTextKey("He is ill.", "en"), deepLTextKey("He is I'll.", "en"))
        assertNotEquals(deepLTextKey("You know?", "en"), deepLTextKey("You know.", "en"))
        assertEquals(deepLTextKey("Man, I can ask around..", "en"), deepLTextKey("Man, I can ask around...", "en"))
        assertEquals(deepLTextKey("Dont worry about it.", "en"), deepLTextKey("Don't worry about it.", "en"))
        assertEquals(deepLTextKey("Im guessing they left.", "en"), deepLTextKey("I'm guessing they left.", "en"))
        assertEquals("Im guessing", deepLRequestText("Im guessing", "fr"))
        assertEquals("The cant of the deck.", deepLRequestText("The cant of the deck.", "en"))
        assertEquals("It's his wont to wait.", deepLRequestText("It's his wont to wait.", "en"))
        assertEquals("Yeah I'd come down to the marina.", deepLRequestText("Yeah ld come down to the marina.", "en"))
        assertEquals("I'll call the insurance company.", deepLRequestText("Ill call the insurance company.", "en"))
        assertEquals("It'd clear my head. That'll cover it.", deepLRequestText("Itd clear my head. Thatll cover it.", "en"))
        for (text in listOf("He is ill.", "The ID card is here.", "The id can be studied.", "Its value is high.")) {
            assertEquals(text, deepLRequestText(text, "en"))
        }
        assertEquals("ld come down", deepLRequestText("ld come down", "de"))
    }

    @Test fun threeFastGlitchReadingsCannotTriggerAnotherPurchaseButSustainedChangesCan() {
        var now = 0L
        val policy = DeepLOcrPolicy { now }
        val anchor = "Nah, not really. This little kid stays in his room all day."
        val glitch = "Nah, not seally. This little kid stays in his room all day."
        var original: DeepLOcrPolicy.Read? = null
        repeat(3) { original = policy.observe(anchor, .85f, "en", 67); now += 67 }
        repeat(3) {
            assertNull(policy.observe(glitch, .84f, "en", 67))
            now += 67
        }
        assertEquals(original!!.key, policy.observe(anchor, .85f, "en", 67)?.key)
        val changed = "Nah, not really. This little kid stays in his room all night."
        var accepted: DeepLOcrPolicy.Read? = null
        repeat(5) {
            now += 67
            accepted = policy.observe(changed, .8f, "en", 67) ?: accepted
        }
        assertEquals(changed, requireNotNull(accepted).text)
    }
}
