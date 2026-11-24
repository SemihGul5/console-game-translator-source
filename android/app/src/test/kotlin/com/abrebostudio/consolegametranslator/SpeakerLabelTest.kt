package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class SpeakerLabelTest {
    @Test fun aSpeakerNameStaysOutOfTheMachineTranslation() {
        // The log: "Final Chapter: Uh-huh... hang on." -> "Son Bölüm: Uh-ha ... asılı."
        val split = splitSpeakerLabel("Final Chapter: Uh-huh... hang on.")
        assertEquals("Final Chapter", split.label)
        assertEquals("Uh-huh... hang on.", split.body)
        assertEquals("Final Chapter: Bir saniye.", split.relabel("Bir saniye."))
        assertEquals("Lucia", splitSpeakerLabel("AYHO Lucia: 'Cause they're gonna help us!").label)
        assertEquals("Jason", splitSpeakerLabel("Jason: Why? Why, Lu?").label)
    }

    @Test fun interfaceLabelsAndPlainLinesAreTranslatedWhole() {
        assertNull(splitSpeakerLabel("Tip: Hold the button to sprint.").label)
        assertNull(splitSpeakerLabel("Meet me at 5: the docks").label)
        assertNull(splitSpeakerLabel("No label here.").label)
        assertNull(splitSpeakerLabel("Jason: ...").label)
        assertEquals("No label here.", splitSpeakerLabel("No label here.").relabel("No label here."))
    }

    @Test fun theSendersNameIsLeftOutOfAPhoneMessage() {
        val message = "Hey, I'm back. Sahara put up a good fight"
        assertEquals(message, withoutSenderName("Burned Man $message", "Burned Man"))
        assertEquals(message, withoutSenderName("O Burned Man $message", "Burned Man"))
        // The name elsewhere, or nothing after it: unchanged.
        assertEquals("I met Burned Man today", withoutSenderName("I met Burned Man today", "Burned Man"))
        assertEquals("Burned Man", withoutSenderName("Burned Man", "Burned Man"))
    }
}
