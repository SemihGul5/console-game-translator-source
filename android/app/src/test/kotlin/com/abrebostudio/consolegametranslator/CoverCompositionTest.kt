package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class CoverCompositionTest {
    private val pack = mapOf(
        "You're who Kyle sent?" to "Kyle'ın gönderdiği sen misin?",
        "You don't look like a fucking farmer to me." to "Pek siktiğimin çiftçisine benzemiyorsun.",
        "Here. Mutandis. Concentrate. 1000 liters." to "Al. Mutandis. Konsantre. 1000 litre.",
        "Should keep your friend goin' for another week." to "Arkadaşını bir hafta daha idare eder.",
    )
    private fun lookup(text: String) = pack[text]?.let { it to "gta6:${text.hashCode()}" }

    @Test fun boxWithTwoPackLinesIsTranslatedWhole() {
        // Logged: only the second sentence was shown, the first stayed English.
        val composed = composeFromSentences(
            "Final Chapter: You're who Kyle sent? You don't look like a fucking farmer to me.", ::lookup)
        assertEquals("Final Chapter: Kyle'ın gönderdiği sen misin? Pek siktiğimin çiftçisine benzemiyorsun.",
            composed?.text)
    }

    @Test fun aRunOfShortSentencesCanBeOnePackLine() {
        val composed = composeFromSentences(
            "Final Chapter: Here. Mutandis. Concentrate. 1000 liters. Should keep your friend goin' for another week.",
            ::lookup)
        assertEquals("Final Chapter: Al. Mutandis. Konsantre. 1000 litre. Arkadaşını bir hafta daha idare eder.",
            composed?.text)
    }

    @Test fun anyUnknownSentenceLeavesItToTheLiveTranslation() {
        assertNull(composeFromSentences("You're who Kyle sent? Nobody told me.", ::lookup))
        assertNull(composeFromSentences("You're who Kyle sent?", ::lookup))
    }

    @Test fun speakerLabelIsKeptApart() {
        assertEquals(SpokenLine("Final Chapter", "Here."), spokenLine("Final Chapter: Here."))
        assertEquals(SpokenLine(null, "Go to the van"), spokenLine("Go to the van"))
        assertEquals("Kyle: Selam", spokenLine("Kyle: Hi").withSpeaker("Selam"))
    }
}
