package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class SubtitleCoverTrackerTest {
    private val calLong = CoverMatch("gta6:cal-long", "Cal: Bak, özür dilerim. Tamam mı? Aklıma ne gelirse söylüyorum işte.", true)
    private val calShort = CoverMatch("gta6:cal-short", "Cal: Bak, özür dilerim, tamam mı?", true)
    private val jason = CoverMatch("gta6:jason", "Jason: Ben de ona hep söylüyorum.", true)

    @Test fun speakersTalkingOneAfterAnotherBecomeSeparateSubtitles() {
        val units = groupCoverUnits(listOf(
            line("Cal: Look, I'm sorry. Okay?", .80f),
            line("I just say whatever comes into my head.", .845f),
            line("Jason: I keep telling him.", .89f),
        ))
        assertEquals(2, units.size)
        assertEquals("Cal: Look, I'm sorry. Okay? I just say whatever comes into my head.", units[0].text)
        assertEquals("Jason: I keep telling him.", units[1].text)
        assertEquals(.80f, units[0].box.top, 1e-4f)
        assertEquals(.885f, units[0].box.bottom, 1e-4f)
    }

    @Test fun aClearGapOrAnotherColumnStartsANewSubtitle() {
        val gap = groupCoverUnits(listOf(line("First subtitle here", .50f), line("Second one far below", .70f)))
        assertEquals(2, gap.size)
        val columns = groupCoverUnits(listOf(line("Left text", .80f, left = .05f, right = .30f),
            line("Right text", .82f, left = .60f, right = .90f)))
        assertEquals(2, columns.size)
        val dashSpeaker = groupCoverUnits(listOf(line("- Lucia: Come on.", .80f), line("- Jason: Okay.", .845f)))
        assertEquals(2, dashSpeaker.size)
    }

    @Test fun twoSpeakersOnScreenAreCoveredSeparately() {
        val tracker = SubtitleCoverTracker()
        val items = requireNotNull(tracker.observe(listOf(seen(calUnit(), calLong), seen(jasonUnit(), jason)), 0))
        assertEquals(listOf(calLong.text, jason.text), items.map { it.text })
        assertEquals(.80f, items[0].box.top, 1e-4f)
        assertEquals(.89f, items[1].box.top, 1e-4f)
    }

    @Test fun readsAlternatingBetweenTwoMatchesNeverFlicker() {
        // The logged GTA 6 case: "I just" (long line) and "T just" (only the opening
        // matches a shorter entry) alternate frame after frame at the same place.
        val tracker = SubtitleCoverTracker()
        assertNotNull(tracker.observe(listOf(seen(calUnit(), calLong)), 0))
        var changes = 0
        for (frame in 1..40) {
            val match = if (frame % 2 == 0) calLong else calShort
            if (tracker.observe(listOf(seen(calUnit(), match)), frame * 100L) != null) changes++
        }
        assertEquals(0, changes)
    }

    @Test fun aRealNextLineReplacesTheCoverAfterTwoFrames() {
        val tracker = SubtitleCoverTracker()
        tracker.observe(listOf(seen(calUnit(), calLong)), 0)
        val next = CoverMatch("gta6:cal-next", "Cal: Düşünmeden konuşuyorum!", true)
        assertNull(tracker.observe(listOf(seen(calUnit(), next)), 100))
        val replaced = requireNotNull(tracker.observe(listOf(seen(calUnit(), next)), 200))
        assertEquals(listOf(next.text), replaced.map { it.text })
    }

    @Test fun ocrJitterDoesNotMoveTheCoverButARealMoveDoes() {
        val tracker = SubtitleCoverTracker()
        tracker.observe(listOf(seen(calUnit(), calLong)), 0)
        assertNull(tracker.observe(listOf(seen(calUnit(top = .805f), calLong)), 100))
        assertNull(tracker.observe(listOf(seen(calUnit(top = .797f), calLong)), 200))
        val moved = requireNotNull(tracker.observe(listOf(seen(calUnit(top = .60f), calLong)), 300))
        assertEquals(.60f, moved.single().box.top, 1e-4f)
    }

    @Test fun missedReadsKeepTheCoverUntilTheSubtitleIsReallyGone() {
        val tracker = SubtitleCoverTracker(missMillis = 800)
        tracker.observe(listOf(seen(calUnit(), calLong)), 0)
        assertNull(tracker.observe(emptyList(), 300))
        assertNull(tracker.observe(emptyList(), 700))
        assertNull(tracker.observe(listOf(seen(calUnit(), calLong)), 800))
        assertNull(tracker.observe(emptyList(), 1500))
        assertEquals(emptyList<CoverItem>(), tracker.observe(emptyList(), 1700))
    }

    @Test fun anUncertainNewSubtitleWaitsForASecondFrame() {
        val tracker = SubtitleCoverTracker()
        val fuzzy = CoverMatch("gta6:fuzzy", "Belki.", immediate = false)
        assertNull(tracker.observe(listOf(seen(calUnit(), fuzzy)), 0))
        assertEquals(listOf("Belki."), tracker.observe(listOf(seen(calUnit(), fuzzy)), 100)?.map { it.text })
        // A one-frame glimpse never appears.
        val glimpse = SubtitleCoverTracker()
        assertNull(glimpse.observe(listOf(seen(calUnit(), fuzzy)), 0))
        assertNull(glimpse.observe(emptyList(), 100))
        assertNull(glimpse.observe(listOf(seen(calUnit(), fuzzy)), 200))
        assertNull(glimpse.observe(emptyList(), 300))
    }

    @Test fun withoutAPackMatchTheLiveTranslationCoversAllOfTheEnglish() {
        val tracker = SubtitleCoverTracker()
        assertNull(tracker.observe(listOf(seen(calUnit(), null), seen(jasonUnit(), null)), 0))
        tracker.setLiveText("Canlı çeviri")
        val items = requireNotNull(tracker.observe(listOf(seen(calUnit(), null), seen(jasonUnit(), null)), 100))
        assertEquals("Canlı çeviri", items.single().text)
        assertEquals(.80f, items.single().box.top, 1e-4f)
        assertEquals(.93f, items.single().box.bottom, 1e-4f)
        // A newer live translation replaces it at once: it was already corroborated.
        tracker.setLiveText("Yeni çeviri")
        assertEquals("Yeni çeviri", tracker.observe(listOf(seen(calUnit(), null), seen(jasonUnit(), null)), 200)?.single()?.text)
    }

    @Test fun aLiveTranslationIsNeverDrawnOverUnrelatedTextLeftOnScreen() {
        val tracker = SubtitleCoverTracker()
        val jasonLive = CoverUnit("Jason: What- they're comin' here?", CoverBox(.30f, .89f, .70f, .93f), .04f)
        val bottle = CoverUnit("AYHO", CoverBox(.60f, .85f, .68f, .88f), .03f)
        tracker.setLiveText("Jason: Burada ne var?", "Jason: What- they're comin' here?")
        val shown = requireNotNull(tracker.observe(listOf(seen(jasonLive, null), seen(bottle, null)), 0)).single()
        assertEquals(.89f, shown.box.top, 1e-4f)
        // The subtitle has gone and only the bottle's brand is read: the old
        // translation stays put until it times out instead of jumping onto it.
        assertNull(tracker.observe(listOf(seen(bottle, null)), 100))
        assertEquals(emptyList<CoverItem>(), tracker.observe(listOf(seen(bottle, null)), 1_000))
    }

    @Test fun aRowSplitAtAButtonIconStaysOneSubtitle() {
        val units = groupCoverUnits(listOf(
            line("to view and adjust your camera.", .80f, left = .30f, right = .80f),
            line("Hold", .801f, left = .20f, right = .25f),
        ))
        assertEquals(listOf("Hold to view and adjust your camera."), units.map { it.text })
    }

    @Test fun aButtonIconFoundLaterIsAddedOnceAndNeverDropped() {
        val tracker = SubtitleCoverTracker()
        val plain = CoverMatch("gta6:hint", "Açmak için basılı tut", true)
        val withIcon = CoverMatch("gta6:hint", "Açmak için \uFFFC basılı tut", true, listOf("png"))
        tracker.observe(listOf(seen(jasonUnit(), plain)), 0)
        val upgraded = requireNotNull(tracker.observe(listOf(seen(jasonUnit(), withIcon)), 100)).single()
        assertEquals(listOf("png"), upgraded.icons)
        assertEquals(withIcon.text, upgraded.text)
        assertNull(tracker.observe(listOf(seen(jasonUnit(), plain)), 200))
    }

    @Test fun packMatchesWinOverTheLiveTranslation() {
        val tracker = SubtitleCoverTracker()
        tracker.setLiveText("Canlı çeviri")
        val items = requireNotNull(tracker.observe(listOf(seen(calUnit(), calLong), seen(jasonUnit(), null)), 0))
        assertEquals(listOf(calLong.text), items.map { it.text })
    }

    @Test fun resetClearsShownCoversOnce() {
        val tracker = SubtitleCoverTracker()
        tracker.observe(listOf(seen(calUnit(), calLong)), 0)
        assertEquals(emptyList<CoverItem>(), tracker.reset())
        assertNull(tracker.reset())
    }

    private fun line(text: String, top: Float, height: Float = .04f, left: Float = .20f, right: Float = .80f) =
        CoverLine(text, CoverBox(left, top, right, top + height))

    private fun calUnit(top: Float = .80f) = CoverUnit("Cal: Look, I'm sorry. Okay? I just say whatever comes into my head.",
        CoverBox(.20f, top, .80f, top + .08f), .04f)

    private fun jasonUnit() = CoverUnit("Jason: I keep telling him.", CoverBox(.30f, .89f, .70f, .93f), .04f)

    private fun seen(unit: CoverUnit, match: CoverMatch?) = CoverObservation(unit, match)
}
