package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class PartialReadHoldTest {
    @Test fun partOfTheShownPromptKeepsItsTranslation() {
        // Logged: "DIVE RO SURFACE" and "SURFACE" alternated every few hundred ms.
        val hold = PartialReadHold()
        hold.shown("DIVE RO SURFACE")
        assertTrue(hold.holds("SURFACE", 0))
        assertTrue(hold.holds("DIVE (R1", 300))
        assertFalse(hold.holds("DIVE RI SURFACE O", 600))
        assertTrue(hold.holds("SURFACE", 700))
    }

    @Test fun lastingPartialReadReplacesTheShownText() {
        val hold = PartialReadHold()
        hold.shown("DIVE RO SURFACE")
        assertTrue(hold.holds("SURFACE", 0))
        assertTrue(hold.holds("SURFACE", 1_000))
        assertFalse(hold.holds("SURFACE", 1_600))
    }

    @Test fun newOrLongerTextIsNeverHeld() {
        val hold = PartialReadHold()
        hold.shown("SURFACE")
        assertFalse(hold.holds("DIVE RO SURFACE", 0))
        assertFalse(hold.holds("PULL OUT CHEST", 0))
        hold.shown("A Map Game Store")
        assertTrue(hold.holds("A Map Game", 0))
        assertTrue(hold.holds("Map Game", 100))
        hold.shown(null)
        assertFalse(hold.holds("Map Game", 200))
    }
}
