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

    @Test fun hudAreaKeepsAWrappedMessageAsOneParagraph() {
        // A phone message in OCR 2 wrapped into short rows: one paragraph, not three labels.
        val message = row(.80f, "Where" to 0f, "are" to .008f, "you" to .008f) +
            row(.835f, "at?" to 0f, "I'm" to .008f, "waiting" to .008f) +
            row(.87f, "outside" to 0f)
        val hud = splitCoverPrompts(message, everyRowIsLabel = true)
        assertTrue(hud.prompts.isEmpty())
        assertEquals(listOf("Where are you at? I'm waiting outside"), groupCoverUnits(hud.rest).map { it.text })
    }

    @Test fun sentenceCaseHudRowWithAButtonIsStillALabel() {
        val hud = splitCoverPrompts(row(.80f, "Answer" to 0f, "@" to .01f), everyRowIsLabel = true)
        assertEquals(listOf("Answer"), hud.prompts.map { it.text })
    }

    private fun unit(text: String, top: Float, prompt: Boolean = false) =
        CoverUnit(text, CoverBox(.05f, top, .05f + text.length * .01f, top + .03f), .03f, prompt)

    @Test fun piecesOfTheAreasPackLineBecomeOneCover() {
        // A notification split at its icon: a label row and the rest of the message.
        val units = listOf(
            unit("Lucia", .10f, prompt = true),
            unit("Meet me at the docks after", .14f),
            unit("midnight. Come alone.", .18f),
            unit("SELECT", .40f, prompt = true),
        )
        val (joined, one) = joinUnitsOfPackLine(units, "Lucia: Meet me at the docks after midnight. Come alone.")
        assertEquals("Lucia Meet me at the docks after midnight. Come alone.", one?.text)
        assertEquals(listOf(one?.text, "SELECT"), joined.map { it.text })
        assertFalse(one!!.prompt)
        assertEquals(.10f, one.box.top, 1e-4f)
        assertEquals(.21f, one.box.bottom, 1e-4f)
    }

    private fun line(text: String, top: Float, left: Float = .55f) =
        CoverLine(text, CoverBox(left, top, left + text.length * .008f, top + .03f))

    @Test fun phoneSenderNameStaysApartFromItsMessage() {
        // The photo: "Donnie" (icon read into it) above a four-line message in OCR 2.
        val rows = listOf(
            line("3Donnie", .70f),
            line("Good work covering with Brian b4.", .75f),
            line("Were in this 2gether remember", .79f),
            line("that! Left a taste of the profits 4u", .83f),
            line("in yr mailbox. And fck the king...", .87f),
        )
        val sender = requireNotNull(senderHeader(rows))
        assertEquals("Donnie", sender.name)
        assertSame(rows[0], sender.line)
        val message = groupCoverUnits(rows.drop(1))
        assertEquals(1, message.size)
        // The pack line holds the name: the message alone takes it, without the name.
        val source = withoutLeadingName("donnie good work covering with brian b4. were in this 2gether remember that! " +
            "lefta taste of the profits 4u in yr mailbox. and fck the king", "Donnie", java.util.Locale.ROOT)!!
        val (units, joined) = joinUnitsOfPackLine(message, source)
        assertEquals(message.single().text, joined?.text)
        assertEquals(1, units.size)
        assertEquals("Az önce Brian'la yaptığın iş harikaydı.",
            withoutLeadingName("Donnie, az önce Brian'la yaptığın iş harikaydı.", "Donnie", java.util.Locale.forLanguageTag("tr")))
        assertNull(withoutLeadingName("Az önce Donnie ile konuştum.", "Donnie", java.util.Locale.ROOT))
    }

    @Test fun aTimeAndAContactIconAroundTheNameDoNotHideTheSender() {
        // "2:59" above "Burned Man" (as in the log), then the message.
        val rows = listOf(
            line("2:59", .66f),
            line("Burned Man", .70f),
            line("Hey, I'm back. Sahara put up a good", .75f),
            line("fight, but once I showed them pics", .79f),
        )
        val sender = requireNotNull(senderHeader(rows))
        assertEquals("Burned Man", sender.name)
        assertSame(rows[1], sender.line)
        // The icon read as a token, and a time on the name's own row.
        assertEquals("Burned Man", senderHeader(listOf(line("O Burned Man", .70f),
            line("Hey, I'm back. Sahara put up a good", .75f)))?.name)
        assertEquals("Donnie", senderHeader(listOf(line("0:14", .70f, left = .80f), line("Donnie", .705f),
            line("Good work covering with Brian b4.", .75f)))?.name)
        assertEquals("Burned Man", senderHeader(listOf(line("Burned Man 2:59", .70f),
            line("I sent you the cut we agreed on, so", .75f)))?.name)
    }

    @Test fun aNameLeftAsItsOwnUnitIsStillTheSender() {
        // The log: "S Burned Man" / "p Burrned Man" (the contact icon read as a letter) over its message.
        for (read in listOf("Burned Man", "S Burned Man", "p Burrned Man", "Burned Man 2:59")) {
            val name = unit(read, .817f, prompt = true)
            val message = unit("I sent you the cut we agreed on, so... we're good, right?", .857f)
            val found = requireNotNull(senderUnit(listOf(message, name)))
            assertSame(name, found.first)
        }
        // A payment row keeps its name too: "Burned Man" over "$15,000 Pending" was
        // covered as "Sarılmış Adam 15.000 Dolarlık Bekleyen" (24 Nov log).
        val payee = unit("Burned Man", .90f, prompt = true)
        assertSame(payee, senderUnit(listOf(payee, unit("$15,000 Pending", .935f)))?.first)
        assertEquals("Burned Man", senderHeader(listOf(line("Burned Man", .90f), line("$15,000 Pending", .935f)))?.name)
        // A short line without an amount is still no message.
        assertNull(senderHeader(listOf(line("Burned Man", .90f), line("Call back", .935f))))
        assertEquals("Donnie", senderHeader(listOf(line("p Donnie", .70f), line("Good work covering with Brian b4.", .75f)))?.name)
    }

    @Test fun titlesAndCountersAreNotSenders() {
        assertNull(senderHeader(listOf(line("Chuck's Gun Shop", .70f), line("00:27", .75f))))
        assertNull(senderHeader(listOf(line("FINAL CHAPTER", .70f), line("Meet me at the docks after midnight.", .75f))))
        assertNull(senderHeader(listOf(line("Hey, I'm back.", .70f), line("Sahara put up a good fight, but once", .75f))))
    }

    @Test fun aSubtitlesSecondLineReadApartJoinsItsPackLine() {
        // "devices, so." read as its own unit was translated live as "Cihazlar, öyle."
        val units = listOf(
            unit("we both know what you get into when you're left to your own", .86f),
            unit("devices, so.", .895f),
        )
        val (kept, joined) = joinUnitsOfPackLine(units,
            "we both know what you get into when you're left to your own devices, so...")
        assertEquals("we both know what you get into when you're left to your own devices, so.", joined?.text)
        assertEquals(listOf(joined), kept)
    }

    @Test fun twoSpeakersAreNeverJoinedIntoOneCover() {
        val units = listOf(
            unit("Cal: Look, I'm sorry. Okay? I just say whatever comes into my head.", .80f),
            unit("Jason: I keep telling him.", .84f),
        )
        val source = "Cal: Look, I'm sorry. Okay? I just say whatever comes into my head. Jason: I keep telling him."
        val (kept, joined) = joinUnitsOfPackLine(units, source)
        assertNull(joined)
        assertEquals(units, kept)
    }

    @Test fun unrelatedRowsAreNotJoinedToAPackLine() {
        val menu = listOf(unit("CHEMICALS", .10f, true), unit("TAUNT", .14f, true), unit("FINAL CHAPTER", .18f, true))
        // One row matching the area's line is not a reason to join anything.
        assertNull(joinUnitsOfPackLine(menu, "Final Chapter").second)
        assertNull(joinUnitsOfPackLine(menu, "Use the chemicals to taunt them in the final chapter of the story").second)
        assertEquals(menu, joinUnitsOfPackLine(menu, "Taunt").first)
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
