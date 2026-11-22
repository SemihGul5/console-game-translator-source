package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class CoverPromptsTest {
    // Words at a 0.03 line height, laid out left to right with the given gaps.
    private fun row(top: Float, vararg parts: Pair<String, Float>, line: Boolean = true): List<CoverWordLine> {
        var x = .40f
        val words = parts.map { (text, gapBefore) ->
            x += gapBefore
            val word = CoverWord(text, CoverBox(x, top, x + text.length * .012f, top + .03f))
            x = word.box.right
            word
        }
        val box = words.map { it.box }.reduce(CoverBox::union)
        return if (line) listOf(CoverWordLine(CoverLine(words.joinToString(" ") { it.text }, box), words))
            else words.map { CoverWordLine(CoverLine(it.text, it.box), listOf(it)) }
    }

    @Test fun promptRowBecomesOneLabelPerButton() {
        // The screenshot: PHOTO STUDIO [□]  SELECT [X]  BACK [O].
        val split = splitCoverPrompts(row(.80f, "PHOTO" to 0f, "STUDIO" to .008f, "SELECT" to .05f, "BACK" to .05f))
        assertEquals(listOf("PHOTO STUDIO", "SELECT", "BACK"), split.prompts.map { it.text })
        assertTrue(split.prompts.all { it.prompt })
        assertTrue(split.rest.isEmpty())
        // Each label's box is its own English, not the gap with the button.
        assertTrue(split.prompts[0].box.right < split.prompts[1].box.left)
    }

    @Test fun buttonsReadAsTokensAlsoSeparateLabels() {
        val split = splitCoverPrompts(row(.80f, "PHOTO" to 0f, "STUDIO" to .008f, "@" to .008f,
            "SELECT" to .008f, "(X)" to .008f, "BACK" to .008f, "O" to .008f))
        assertEquals(listOf("PHOTO STUDIO", "SELECT", "BACK"), split.prompts.map { it.text })
    }

    @Test fun labelsInSeparateOcrLinesAreJoinedIntoOneRowFirst() {
        val split = splitCoverPrompts(row(.80f, "Select" to 0f, "Back" to .05f, line = false))
        assertEquals(listOf("Select", "Back"), split.prompts.map { it.text })
    }

    @Test fun sentenceAcrossAButtonStaysOneLine() {
        listOf(
            row(.80f, "Hold" to 0f, "to" to .05f, "view" to .008f, "camera" to .008f, "settings" to .008f),
            row(.80f, "Press" to 0f, "To" to .05f, "Continue" to .008f),
            row(.80f, "Press" to 0f, "Continue" to .05f),
            row(.80f, "Jason:" to 0f, "Okay." to .008f, "Fine" to .05f),
            row(.80f, "DIVE" to 0f, "RO" to .008f, "SURFACE" to .008f),
            row(.80f, "SURFACE" to 0f, "O" to .008f),
            row(.80f, "Wait" to 0f, "for" to .008f, "me" to .008f, "over" to .008f, "there" to .008f, "Back" to .05f),
        ).forEach { lines ->
            val split = splitCoverPrompts(lines)
            assertTrue(lines.first().line.text, split.prompts.isEmpty())
            assertEquals(lines.size, split.rest.size)
        }
    }

    @Test fun otherRowsKeepTheirNormalGrouping() {
        val prompts = row(.90f, "SELECT" to 0f, "BACK" to .05f)
        val subtitle = row(.70f, "Lucia:" to 0f, "Come" to .008f, "on." to .008f)
        val split = splitCoverPrompts(subtitle + prompts)
        assertEquals(listOf("SELECT", "BACK"), split.prompts.map { it.text })
        assertEquals(listOf("Lucia: Come on."), split.rest.map { it.text })
    }

    @Test fun buttonTokens() {
        listOf("%", "(R1", "[O]", "O", "X", "R1", "l2", "©").forEach { assertTrue(it, isIconMisread(it)) }
        listOf("A", "OK", "BACK", "R1D2", "GO").forEach { assertFalse(it, isIconMisread(it)) }
    }

    @Test fun promptLabelsGetSeparateCoversWithoutTheLiveText() {
        val tracker = SubtitleCoverTracker()
        val select = CoverUnit("SELECT", CoverBox(.60f, .90f, .66f, .93f), .03f, prompt = true)
        val back = CoverUnit("BACK", CoverBox(.70f, .90f, .74f, .93f), .03f, prompt = true)
        // Only the whole area's live translation so far: nothing is drawn over the labels.
        tracker.setLiveText("SEÇ GERİ", "SELECT BACK")
        assertNull(tracker.observe(listOf(CoverObservation(select, null), CoverObservation(back, null)), 0))
        val items = requireNotNull(tracker.observe(listOf(
            CoverObservation(select, CoverMatch("seg:SELECT", "SEÇ", true)),
            CoverObservation(back, CoverMatch("seg:BACK", "GERİ", true)),
        ), 100))
        assertEquals(listOf("SEÇ", "GERİ"), items.map { it.text })
        assertTrue(items.all { it.fit })
        assertEquals(.60f, items[0].box.left, 1e-4f)
    }

    @Test fun hudAreaCoversEachShortRowOnItsOwn() {
        // The photo: CHEMICALS [X] / TAUNT [□] / FINAL CHAPTER [+] stacked in OCR 2.
        val stack = row(.80f, "CHEMICALS" to 0f, "@" to .01f) + row(.835f, "TAUNT" to 0f, "O" to .01f) +
            row(.87f, "FINAL" to 0f, "CHAPTER" to .008f)
        val hud = splitCoverPrompts(stack, everyRowIsLabel = true)
        assertEquals(listOf("CHEMICALS", "TAUNT", "FINAL CHAPTER"), hud.prompts.map { it.text })
        assertTrue(hud.rest.isEmpty())
        // In a subtitle strip the same rows stay ordinary lines.
        assertTrue(splitCoverPrompts(stack).prompts.isEmpty())
    }

    @Test fun hudAreaKeepsSentencesAsLines() {
        val lines = row(.80f, "Meet" to 0f, "me" to .008f, "at" to .008f, "the" to .008f, "dock" to .008f) +
            row(.84f, "Dialing..." to 0f) + row(.88f, "Okay." to 0f)
        val hud = splitCoverPrompts(lines, everyRowIsLabel = true)
        assertTrue(hud.prompts.isEmpty())
        assertEquals(3, hud.rest.size)
        // A sentence across a button stays a line: no cover over the button.
        val press = splitCoverPrompts(row(.80f, "Press" to 0f, "Continue" to .05f), everyRowIsLabel = true)
        assertTrue(press.prompts.isEmpty())
    }

    @Test fun buttonsReadAsLettersAtALabelEdgeAreLeftUncovered() {
        // Logged: "CHEMICALS? A" (triangle), "RECENTER 3" (R3), "ADD MARKER\"O", "KYLE(O".
        val hud = splitCoverPrompts(
            row(.75f, "RECENTER" to 0f, "3" to .008f) +
                row(.79f, "CHEMICALS?" to 0f, "A" to .008f) +
                row(.83f, "SEE" to 0f, "A" to .008f, "DOCTOR" to .008f) +
                row(.87f, "ADD" to 0f, "MARKER\"O" to .008f) +
                row(.91f, "KYLE(O" to 0f),
            everyRowIsLabel = true,
        )
        assertEquals(listOf("RECENTER", "CHEMICALS?", "SEE A DOCTOR", "ADD MARKER", "KYLE"), hud.prompts.map { it.text })
        // The cut word's box ends where its letters end, not over the button.
        val marker = hud.prompts[3].box
        val glued = row(.87f, "ADD" to 0f, "MARKER\"O" to .008f).single().words.last().box
        assertEquals(glued.left + glued.width * 6f / 8f, marker.right, 1e-4f)
        val kyle = hud.prompts[4].box
        assertTrue(kyle.width < .012f * 6 * .7f)
    }
}
