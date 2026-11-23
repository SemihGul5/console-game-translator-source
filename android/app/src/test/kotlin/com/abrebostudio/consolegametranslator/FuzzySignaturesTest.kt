package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class FuzzySignaturesTest {
    private val rows = listOf(
        "hey im back sahara put up a good fight but once i showed them pics",
        "i sent you the cut we agreed on so were good right please dont come after me",
        "we both know what you get into when youre left to your own devices so",
        "go to the van",
        "collect cash from completed jobs from your mailbox",
    )
    private val signatures = FuzzySignatures.build(rows.size) { rows[it] }

    @Test fun aMisreadRowIsTheNearest() {
        // Joined and split words, l/I and 0/o confusions.
        val found = signatures.nearest("hey lm back sahara put upa g00d fight but once ishowed them pics", 3, 0, Int.MAX_VALUE)
        assertEquals(0, found.first())
        assertEquals(1, signatures.nearest("l sent you the cut we agreed on s were good right", 3, 0, Int.MAX_VALUE).first())
    }

    @Test fun aReadThePackDoesNotHoldFindsNothing() {
        assertEquals(0, signatures.nearest("the weather in vice city is lovely this time of year", 3, 0, Int.MAX_VALUE).size)
    }

    @Test fun theLengthWindowAndTheLimitAreKept() {
        assertTrue(signatures.nearest("we both know what you get into when youre left", 5, 70, Int.MAX_VALUE).all { rows[it].length >= 70 })
        assertTrue(signatures.nearest("collect cash from completed jobs", 1, 0, Int.MAX_VALUE).size <= 1)
    }
}
