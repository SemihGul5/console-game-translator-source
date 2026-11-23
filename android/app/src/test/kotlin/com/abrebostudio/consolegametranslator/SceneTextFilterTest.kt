package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class SceneTextFilterTest {
    @Test fun aPlateReadAfterASubtitleIsLeftOut() {
        assertEquals("Final Chapter: Uh-huh... hang on.", withoutTrailingPlate("Final Chapter: Uh-huh... hang on. HCO 11M"))
        assertEquals("Final Chapter: Uh-huh... hang on..", withoutTrailingPlate("Final Chapter: Uh-huh... hang on.. HCR 11M"))
        // Words after a sentence stay.
        assertEquals("Got it. Go to the van", withoutTrailingPlate("Got it. Go to the van"))
        assertEquals("Meet me at 5. Pier 39", withoutTrailingPlate("Meet me at 5. Pier 39"))
        assertEquals("No plate here", withoutTrailingPlate("No plate here"))
    }

    @Test fun plateOnAPassingCarIsRejected() {
        assertEquals("tilted", sceneTextReason(listOf(line("8ZJK 264", angle = 12f))))
        assertEquals("plate", sceneTextReason(listOf(line("LEONIDA", top = .40f), line("8ZJK 264", top = .52f))))
        assertEquals("plate", sceneTextReason(listOf(line("6ABC123"))))
        assertEquals("plate", sceneTextReason(listOf(line("LEO-4821"))))
    }

    @Test fun perspectiveSignIsRejectedByWordDriftOrBoxHeight() {
        val drifting = line("BEST CAR WASH", words = listOf(word(.10f, .40f), word(.30f, .46f), word(.50f, .52f)))
        assertEquals("tilted", sceneTextReason(listOf(drifting)))
        val tallBox = line("VICE CITY", top = .30f, bottom = .60f, words = listOf(word(.10f, .38f), word(.40f, .50f)))
        assertEquals("tilted", sceneTextReason(listOf(tallBox)))
    }

    @Test fun loggedSubtitlesAreKept() {
        listOf(
            "Cal: Look, I'm sorry. Okay? I just say whatever comes into my head.",
            "Mattia: Ha, yeah, my boss.",
            "Lucia: Why? Because they'll help us!",
            "Jason: I keep telling him.",
            "Over here",
            "Wait here",
            "Yeah.",
            "Arnold... He should be sitting in that chair, yeah.",
        ).forEach { assertNull(it, sceneTextReason(listOf(line(it)))) }
    }

    @Test fun horizontalTextWithRecognizerJitterIsNotTilted() {
        val jitter = line("I just say whatever comes", words = listOf(
            word(.05f, .50f), word(.15f, .52f), word(.30f, .49f), word(.50f, .53f), word(.70f, .50f)))
        assertFalse(isTiltedLine(jitter))
        assertFalse(isTiltedLine(line("Okay?", angle = 1.5f)))
        // A tiny angle on a two-character read is recognizer noise, not perspective.
        assertFalse(isTiltedLine(line("OK", angle = 9f)))
    }

    @Test fun speakerLabelledBlocksAreAlwaysDialogue() {
        assertNull(sceneTextReason(listOf(line("CAL: LOOK, I'M SORRY.", angle = 8f))))
        assertNull(sceneTextReason(listOf(line("TINO: 8ZJK 264"))))
    }

    @Test fun shortCodesHudAndMenusAreNotPlates() {
        listOf("MISSION 3", "GTA 6", "PS5", "ZONE 51", "R2 L1", "GRAPHICS SETTINGS", "Room 12", "Gate 13",
            "Meet me at 00:14.", "2026")
            .forEach { assertFalse(it, isPlateLike(listOf(line(it)))) }
    }

    @Test fun lowConfidenceFragmentsWithoutPunctuationAreRejected() {
        assertEquals("low_confidence", sceneTextReason(listOf(line("LEONIDA", confidence = .30f))))
        assertEquals("low_confidence", sceneTextReason(listOf(line("Sunshine State", confidence = .35f))))
        assertNull(sceneTextReason(listOf(line("Yeah.", confidence = .30f))))
        assertNull(sceneTextReason(listOf(line("Over here", confidence = .70f))))
        assertNull(sceneTextReason(listOf(line("Over here", confidence = -1f))))
        assertNull(sceneTextReason(listOf(line("We should leave this place", confidence = .30f))))
    }

    @Test fun straightOnSignsShirtsAndPostersInTheMiddleOfTheFrameAreRejected() {
        listOf("LIQUOR", "Frank's Autocare", "VICE CITY", "Exchange Towers", "SALE 50%")
            .forEach { assertEquals(it, "short_scene_label", sceneTextReason(listOf(line(it)), at(.50f), SubtitleBand())) }
    }

    @Test fun shortLinesInTheSubtitleStripsOrWithPunctuationAreKept() {
        // Mission objectives and subtitles sit near the bottom (or top) edge of the frame.
        assertNull(sceneTextReason(listOf(line("Recover Pete's stash")), at(.86f), SubtitleBand()))
        assertNull(sceneTextReason(listOf(line("Follow the plane")), at(.10f), SubtitleBand()))
        assertNull(sceneTextReason(listOf(line("Over here!")), at(.50f), SubtitleBand()))
        assertNull(sceneTextReason(listOf(line("Jason: Hey")), at(.50f), SubtitleBand()))
        // Two-line blocks and longer lines are not labels.
        assertNull(sceneTextReason(listOf(line("We should leave this place right now")), at(.50f), SubtitleBand()))
        assertNull(sceneTextReason(listOf(line("Open"), line("all night")), at(.50f), SubtitleBand()))
        // Without frame placement the rule never runs.
        assertNull(sceneTextReason(listOf(line("LIQUOR"))))
    }

    @Test fun shortDialogueAtARememberedSubtitleHeightIsKept() {
        val band = SubtitleBand()
        val subtitleHeight = at(.62f)
        val certain = listOf(line("Arnold... He should be sitting in that chair, yeah."))
        assertTrue(isCertainSubtitle(certain, subtitleHeight))
        band.remember(subtitleHeight)
        assertNull(sceneTextReason(listOf(line("Let's go")), at(.63f), band))
        assertEquals("short_scene_label", sceneTextReason(listOf(line("LIQUOR")), at(.40f), band))
        band.clear()
        assertEquals("short_scene_label", sceneTextReason(listOf(line("Let's go")), at(.63f), band))
    }

    @Test fun onlyCentredPunctuatedOrLabelledBlocksTeachTheSubtitleHeight() {
        assertTrue(isCertainSubtitle(listOf(line("Cal: Okay")), at(.50f, x = .20f)))
        assertFalse(isCertainSubtitle(listOf(line("SALE! 50% OFF EVERYTHING TODAY")), at(.50f, x = .15f)))
        assertFalse(isCertainSubtitle(listOf(line("Exchange Towers")), at(.50f)))
    }

    @Test fun placementMapsCropCoordinatesIntoTheFrame() {
        val placement = requireNotNull(scenePlacement(listOf(line("Hello there", top = .40f, bottom = .60f)),
            floatArrayOf(.10f, .70f, .80f, .20f)))
        assertEquals(.50f, placement.centerX, 1e-4f)
        assertEquals(.80f, placement.centerY, 1e-4f)
        assertEquals(.04f, placement.lineHeight, 1e-4f)
    }

    @Test fun subtitlePhoneAndMissionAreasAreToldApartByTheirPlaceInTheFrame() {
        assertTrue(isSubtitleShapedRegion(floatArrayOf(.10f, .78f, .80f, .22f)))   // bottom centre: subtitles
        assertTrue(isSubtitleShapedRegion(floatArrayOf(.20f, .60f, .60f, .30f)))
        assertFalse(isSubtitleShapedRegion(floatArrayOf(.70f, .45f, .25f, .50f)))  // bottom right: phone
        assertFalse(isSubtitleShapedRegion(floatArrayOf(.02f, .03f, .35f, .15f)))  // top left: mission info
        assertFalse(isSubtitleShapedRegion(floatArrayOf(.40f, .40f, .20f, .20f)))  // centred but narrow
    }

    @Test fun phoneAndMissionAreasKeepShortUiLinesButStillDropPlatesAndTiltedText() {
        val phone = floatArrayOf(.70f, .45f, .25f, .50f)
        val contact = listOf(line("Lucia", top = .20f, bottom = .26f))
        val placement = requireNotNull(scenePlacement(contact, phone))
        assertNull(sceneTextReason(contact, placement, SubtitleBand(), subtitleRegion = false))
        assertNull(sceneTextReason(listOf(line("New message", confidence = .30f)), placement, SubtitleBand(), subtitleRegion = false))
        assertEquals("plate", sceneTextReason(listOf(line("8ZJK 264")), placement, SubtitleBand(), subtitleRegion = false))
        assertEquals("tilted", sceneTextReason(listOf(line("BEST CAR WASH", angle = 14f)), placement, SubtitleBand(), subtitleRegion = false))
        // The same short line in a subtitle-shaped area at the same height is a sign.
        assertEquals("short_scene_label", sceneTextReason(contact, placement, SubtitleBand(), subtitleRegion = true))
    }

    private fun at(y: Float, x: Float = .50f) = ScenePlacement(x, y, .04f)

    @Test fun straightPieceOfARejectedSignIsSceneText() {
        // Logged: "GOOD SUIT ISA" rejected as tilted, then "SUIT" alone hit the pack.
        val memory = SceneWordMemory()
        memory.remember("THE ONLY\nGOOD\nSUTT\nI5A", 1_000)
        memory.remember("GOOD\nSUIT\n1SA", 2_000)
        listOf("SUIT", "GOOD SuIT ISA TSUIT", "ISUIT", "SA", "THE ONLY GOOD SUIT").forEach {
            assertTrue(it, memory.isSceneEcho(it, 3_000))
        }
        listOf("Hold to dive", "UNDER WATER", "SURFACE", "OK", "GOOD MORNING").forEach {
            assertFalse(it, memory.isSceneEcho(it, 3_000))
        }
        // Forgotten a few seconds after the sign was last rejected.
        assertFalse(memory.isSceneEcho("SUIT", 9_000))
    }

    @Test fun emptySceneWordMemoryRejectsNothing() {
        assertFalse(SceneWordMemory().isSceneEcho("SUIT", 0))
    }

    @Test fun speakerLinesAndCertainSubtitlesAreExempt() {
        assertTrue(isSceneExempt(listOf(line("Jason: Good suit.")), null))
        val centred = ScenePlacement(.5f, .85f, .04f)
        assertTrue(isSceneExempt(listOf(line("The only good suit is a wet suit.")), centred))
        assertFalse(isSceneExempt(listOf(line("SUIT")), centred))
    }

    @Test fun blockMovingWithTheCameraIsWorldText() {
        val tracker = SceneMotionTracker()
        assertFalse(tracker.moved(1, 0, "A Map Game Store", SceneBox(100f, 50f, 300f, 70f, 20f)))
        // Same frame evaluated again (OCR recovery): same answer.
        assertFalse(tracker.moved(1, 5, "A Map Game Store", SceneBox(100f, 50f, 300f, 70f, 20f)))
        assertTrue(tracker.moved(2, 400, "A Map Game Store", SceneBox(130f, 52f, 330f, 72f, 20f)))
        assertTrue(tracker.moved(2, 410, "A Map Game", SceneBox(130f, 52f, 290f, 72f, 20f)))
    }

    @Test fun stillHudTextIsNotMoving() {
        val tracker = SceneMotionTracker()
        tracker.moved(1, 0, "DIVE RO SURFACE", SceneBox(40f, 120f, 260f, 140f, 20f))
        // Box jitter and a misread last letter move one edge only.
        assertFalse(tracker.moved(2, 300, "DIVE RI SURFACE %", SceneBox(41f, 121f, 275f, 141f, 20f)))
        // A second line below grows the block downwards only.
        assertFalse(tracker.moved(3, 600, "DIVE RI SURFACE", SceneBox(40f, 120f, 260f, 165f, 20f)))
        // Different text is never compared.
        assertFalse(tracker.moved(4, 900, "PULL OUT CHEST", SceneBox(200f, 10f, 300f, 30f, 20f)))
    }

    @Test fun motionNeedsARecentFrame() {
        val tracker = SceneMotionTracker()
        tracker.moved(1, 0, "SUIT", SceneBox(10f, 10f, 60f, 30f, 20f))
        assertFalse(tracker.moved(2, 5_000, "SUIT", SceneBox(90f, 40f, 140f, 60f, 20f)))
        tracker.clear()
        assertFalse(tracker.moved(3, 5_100, "SUIT", SceneBox(10f, 10f, 60f, 30f, 20f)))
    }

    @Test fun similarTokensCoverCommonMisreads() {
        assertTrue(similarSceneToken("SUIT", "SUT"))
        assertTrue(similarSceneToken("TSUIT", "SUIT"))
        assertTrue(similarSceneToken("SURFACE", "SURRACE"))
        assertFalse(similarSceneToken("THE", "TIE"))
        assertFalse(similarSceneToken("DIVE", "DOCK"))
        assertEquals(listOf("ISA", "SUIT"), sceneTokens("1SA 5UIT r"))
    }

    private fun word(left: Float, centerY: Float, height: Float = .10f) =
        SceneTextWord(left, centerY - height / 2, left + .15f, centerY + height / 2)

    @Test fun sceneTextGluedBeforeASpeakerLabelIsDropped() {
        assertEquals("Lucia: These are people with money and influence,",
            stripSceneWordsBeforeSpeaker("YHO Lucia: These are people with money and influence,"))
        assertEquals("Lucia: Maybe they got some work?", stripSceneWordsBeforeSpeaker("AYHO, Lucia: Maybe they got some work?"))
        assertEquals("Mr. Smith: Hello there.", stripSceneWordsBeforeSpeaker("HC 44 Mr. Smith: Hello there."))
        listOf(
            "Lucia: These are people.",
            "I said Lucia: no.",
            "OK",
            "AYHO Lucia:",
            "Jason: Why? Why, Lu?",
            "LONGBRAND Lucia: Hi there.",
        ).forEach { assertEquals(it, it, stripSceneWordsBeforeSpeaker(it)) }
    }

    private fun line(
        text: String,
        top: Float = .45f,
        bottom: Float = top + .10f,
        angle: Float = 0f,
        confidence: Float = .80f,
        words: List<SceneTextWord> = text.split(' ').mapIndexed { i, _ -> SceneTextWord(.05f + i * .12f, top, .15f + i * .12f, bottom) },
    ) = SceneTextLine(text, .05f, top, .95f, bottom, angle, confidence, words)
}
