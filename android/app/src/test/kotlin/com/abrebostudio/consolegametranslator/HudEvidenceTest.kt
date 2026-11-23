package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class HudEvidenceTest {
    private val vocabulary = setOf("hey", "back", "sahara", "put", "good", "fight", "but", "once", "showed", "them",
        "pics", "collect", "cash", "from", "completed", "jobs", "your", "mailbox", "the", "keys", "leaving", "now",
        "farm", "equipment", "haulage", "repairs", "tractors", "work", "covering", "with", "brian", "were", "this",
        "remember", "that", "left", "taste", "donnie", "press", "aim", "you", "owe")
    private val knows: (String) -> Boolean = { it in vocabulary }

    @Test fun brokenReadsFromTheLogAreGarbled() {
        for (read in listOf("SIUWLLAVING", "PRCSLEUTEO)", "PHOSLCTEO)", "wIaT ke tha", "Wn", "217RT Sekmeler")) {
            assertTrue(read, isGarbledRead(read, knows) || read == "Wn")
        }
        assertFalse(isGarbledRead("Wn", knows)) // two letters are no evidence either way; settling handles it
    }

    @Test fun realHudTextIsNotGarbled() {
        for (read in listOf("Collect cash from completed jobs from your mailbox",
            "Hey, I'm back. Sahara put up a good fight, but once I showed them pics",
            "Donnie Good work covering with Brian b4. Were in this 2gether remember that! Left a taste",
            "Press R2 to aim", "You owe $500 on the PS5", "Hmm. Pfft.")) {
            assertFalse(read, isGarbledRead(read, knows))
        }
        // Without a pack, only the shape of the words counts.
        assertFalse(isGarbledRead("Hey Sahara, I'm back", null))
        assertTrue(isGarbledRead("wIaT Gtt rnnk", null))
    }

    @Test fun billboardLinesAreSignLinesButSentencesAndLabelsWithPunctuationAreNot() {
        for (line in listOf("FARMFIX", "FARM EQUIPMENT & HAULAGE", "TRACTORS HAULERS SPREADERS", "NOW LEAVING")) assertTrue(line, isSignLine(line))
        for (line in listOf("Collect cash from completed jobs", "TIP:", "WATCH OUT!", "Hold to view and adjust your camera settings",
            "THIS LINE IS FAR TOO LONG TO BE A SIGN LINE AT ALL")) assertFalse(line, isSignLine(line))
    }

    private fun line(text: String, top: Float, left: Float = .10f) =
        SceneTextLine(text, left, top, left + text.length * .02f, top + .08f, 0f, .9f, emptyList())

    @Test fun textSettlesOnlyAfterStayingInPlace() {
        val tracker = HudSettleTracker(settleMillis = 200)
        val tip = listOf(line("Collect cash from completed jobs", .30f))
        assertFalse(tracker.settled("Collect cash from completed jobs", tip, 0)); tracker.endFrame(0)
        assertFalse(tracker.settled("Collect cash from completed jobs", tip, 110)); tracker.endFrame(110)
        // A slightly different read of the same box keeps its age.
        assertTrue(tracker.settled("Collect cash from cornpleted jobs", tip, 220)); tracker.endFrame(220)
    }

    @Test fun aSlidingOrPassingBlockNeverSettles() {
        val tracker = HudSettleTracker(settleMillis = 200)
        for ((step, top) in listOf(.10f, .20f, .30f, .40f, .50f).withIndex()) {
            assertFalse(tracker.settled("The Keys", listOf(line("The Keys", top)), step * 100L))
            tracker.endFrame(step * 100L)
        }
        // A glimpse that comes back after a long gap starts over.
        val glimpse = listOf(line("R5", .60f))
        assertFalse(tracker.settled("R5", glimpse, 0)); tracker.endFrame(0)
        assertFalse(tracker.settled("R5", glimpse, 2000)); tracker.endFrame(2000)
    }

    @Test fun panelMeasurementTellsAFlatDarkBoxFromATexturedBackground() {
        val width = 200; val height = 60
        val box = intArrayOf(20, 20, 180, 40)
        fun inText(x: Int, y: Int) = x in 20..180 && y in 20..40 && (x / 3) % 2 == 0
        // A dark, even panel with white letters.
        val panel = requireNotNull(measurePanel(width, height, listOf(box)) { x, y -> if (inText(x, y)) 235 else 30 })
        assertTrue(panel.flatPanel)
        // A painted sign in the world: its letters stand out far less (measured |ink| <= ~57).
        val world = requireNotNull(measurePanel(width, height, listOf(box)) { x, y ->
            if (inText(x, y)) 130 else 150 + ((x * 37 + y * 91) % 60)
        })
        assertFalse(world.flatPanel)
        assertTrue(world.ink < 0)
        // A phone app's white panel with dark text is a panel too.
        val phone = requireNotNull(measurePanel(width, height, listOf(box)) { x, y -> if (inText(x, y)) 60 else 220 })
        assertTrue(phone.flatPanel)
        assertTrue(phone.ink < 0)
    }

    @Test fun aMessageReadsAsASentenceAndASignDoesNot() {
        assertTrue(isSentenceLike("Hey, I'm back. Sahara put up a good fight"))
        assertTrue(isSentenceLike("Collect cash from completed jobs"))
        assertFalse(isSentenceLike("FARM EQUIPMENT REPAIR AND PARTS"))
        assertFalse(isSentenceLike("The Keys"))
        assertFalse(isSentenceLike("Burned Man"))
    }

    @Test fun aLoneContactNameIsNameLike() {
        assertTrue(isNameLike("Burned Man"))
        assertTrue(isNameLike("Donnie"))
        assertFalse(isNameLike("FARMFIX"))
        assertFalse(isNameLike("Inspect the chemicals"))
        assertFalse(isNameLike("Collect cash from completed jobs from your mailbox"))
    }
}
