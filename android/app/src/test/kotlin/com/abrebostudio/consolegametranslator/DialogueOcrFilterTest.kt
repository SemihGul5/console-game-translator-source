package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class DialogueOcrFilterTest {
    @Test
    fun keepsIsabellaOpeningBlockAndTenantEndingTogether() {
        val lines = listOf(
            line("ISABELLA: Oh, didn't you know?", 0, 0.02f, 0.10f),
            line("The Baron owns this land.", 0, 0.12f, 0.20f),
            line("The great Don Torrisi is", 0, 0.22f, 0.30f),
            line("just his tenant.", 1, 0.65f, 0.80f),
        )
        assertEquals(lines, filterDialogueOcrLines(lines))
    }

    @Test
    fun keepsAllFourLinesOfLongTinoDialogue() {
        val lines = listOf(
            line("TINO: Make a mess of this", 0, 0.02f, 0.15f),
            line("and any misguided faith the Don", 0, 0.17f, 0.30f),
            line("has in you will be lost,", 0, 0.32f, 0.45f),
            line("u capisti?", 0, 0.47f, 0.60f),
        )
        assertEquals(lines, filterDialogueOcrLines(lines))
    }

    @Test
    fun stillRejectsTimerAndAllCapsMenuText() {
        val lines = listOf(
            line("00:14 01:22 L1", 0, 0.50f, 0.60f),
            line("GRAPHICS SETTINGS", 1, 0.70f, 0.80f),
        )
        assertTrue(filterDialogueOcrLines(lines).isEmpty())
    }

    @Test fun consoleHomeChromeRejectsActivityTextWithoutKnowingAnyUsername() {
        val lines = listOf(line("Arkadaş Etkinliği Konsol Depolama Boş alan", 0, .4f, .5f),
            line("Player123 RENNSPORT oyunu.", 1, .6f, .8f))
        assertTrue(filterDialogueOcrLines(lines).isEmpty())
        assertTrue(filterDialogueOcrLines(listOf(line("Friends Activity Console Storage Free Space", 0, .5f, .8f))).isEmpty())
    }

    @Test fun reportedShareCommandsAndTheirGlyphErrorsDoNotReachLiveTranslation() {
        listOf("ro Ekran Görüntüsü Al", "Ekran Görüntüsü AI", "Ekran Görüntüsü A",
            "Yakın Zamandaki Oyun Deneyimini Kaydet", "Take a Screenshot", "Save Recent Gameplay").forEach {
            assertTrue(it, filterDialogueOcrLines(listOf(line(it, 0, .5f, .8f))).isEmpty())
        }
    }

    @Test fun dialogueAboutStorageOrScreenshotsIsStillKept() {
        listOf("We have some free space on the boat.", "Take a screenshot and send it to me.",
            "Ekran görüntüsü al ve bana gönder.", "Konsol depolama alanını sonra kontrol ederiz.").forEach {
            val lines = listOf(line(it, 0, .5f, .8f))
            assertEquals(it, lines, filterDialogueOcrLines(lines))
        }
    }

    @Test fun reportedBrowseButtonPromptsAreFilteredWithoutDiscardingNearbyDialogue() {
        for (hint in listOf("Browse LU RT", "Browse LI RT", "Browse LT RT", "Browse L1 R1")) {
            val dialogue = line("We should leave before the guards return.", 0, .5f, .7f)
            val prompt = line(hint, 1, .8f, .95f)
            assertEquals(hint, listOf(dialogue), filterDialogueOcrLines(listOf(dialogue, prompt)))
        }
        for (text in listOf("JOHN: Press LT and RT.", "Browse the Internet.", "The guard told me to press L1 and R1.")) {
            val lines = listOf(line(text, 0, .5f, .8f))
            assertEquals(lines, filterDialogueOcrLines(lines))
        }
    }

    private fun line(text: String, block: Int, top: Float, bottom: Float) = OcrLineCandidate(
        rawText = text, text = text, blockIndex = block, confidenceValues = listOf(0.85f),
        left = 0.1f, top = top, right = 0.9f, bottom = bottom,
    )
}
