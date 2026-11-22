package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class ButtonIconsTest {
    private val icon = ICON_PLACEHOLDER

    @Test fun aWideGapBetweenWordsOfOneRowIsAnIconPlace() {
        // "Hold [icon] to view": word space ~8 px, icon gap ~40 px, line height 30 px.
        val words = listOf(word(10, 60, text = "Hold"), word(100, 130, text = "to"), word(138, 200, text = "view"), word(208, 260, text = "map"))
        val gaps = buttonIconGaps(words, 400, 100)
        assertEquals(1, gaps.size)
        assertTrue(gaps[0].left in 60..66 && gaps[0].right in 94..100)
        assertTrue(gaps[0].top <= 35 && gaps[0].bottom >= 65)
    }

    @Test fun normalSpacesAndFarColumnsAreNotIcons() {
        assertTrue(buttonIconGaps(listOf(word(10, 60, text = "Press"), word(70, 120), word(128, 170)), 400, 100).isEmpty())
        // Five line heights apart: another label in a menu row, not an icon.
        assertTrue(buttonIconGaps(listOf(word(10, 60, text = "Press"), word(220, 300)), 400, 100).isEmpty())
        // Scene text in front of a speaker label is not a button.
        assertTrue(buttonIconGaps(listOf(word(10, 60, text = "Use"), word(100, 160, text = "Lucia:")), 400, 100).isEmpty())
        // Different rows never pair up.
        assertTrue(buttonIconGaps(listOf(word(10, 60, text = "Hold"), word(100, 160, top = 60)), 400, 120).isEmpty())
    }

    @Test fun dialogueAndMenusNeverGetIcons() {
        // A wide gap in a line of dialogue, even one that says "hold".
        assertTrue(buttonIconGaps(listOf(word(10, 60, text = "Cal:"), word(100, 130, text = "Hold"), word(138, 200, text = "on!")), 400, 100).isEmpty())
        assertTrue(buttonIconGaps(listOf(word(10, 60, text = "Ow!"), word(100, 160, text = "Fuck")), 400, 100).isEmpty())
        // A menu row without a button word.
        assertTrue(buttonIconGaps(listOf(word(10, 60, text = "CINEMATIC"), word(100, 160, text = "MARKERS")), 400, 100).isEmpty())
    }

    @Test fun onlyAContrastingCompactShapeCountsAsAnIcon() {
        val area = IconArea(0, 0, 40, 40)
        val dark = 0xFF101010.toInt()
        val light = 0xFFF0F0F0.toInt()
        // A white ring of a button on a dark background.
        val ring = IntArray(40 * 40) { i ->
            val x = i % 40 - 20; val y = i / 40 - 20; val d = x * x + y * y
            if (d in 144..256) light else dark
        }
        val box = requireNotNull(iconInk(ring, area, lineHeight = 30))
        assertTrue(box.width in 30..34 && box.height in 30..34)
        // Plain background, or a faint gradient, is no icon.
        assertNull(iconInk(IntArray(40 * 40) { dark }, area, 30))
        assertNull(iconInk(IntArray(40 * 40) { i -> 0xFF000000.toInt() or ((i / 40) * 0x010101) }, area, 30))
        // A thin horizontal stroke is not an icon either.
        assertNull(iconInk(IntArray(40 * 40) { i -> if (i / 40 == 20) light else dark }, area, 30))
    }

    @Test fun turkishIconsGoWhereTheButtonIsMeant() {
        assertEquals("Kamera ayarlarınızı görüntülemek için $icon tutun.",
            insertButtonIcons("Kamera ayarlarınızı görüntülemek için tutun.", 1, turkish = true))
        assertEquals("Araç içindeyken ayarlamak için $icon tuşuna basılı tutun.",
            insertButtonIcons("Araç içindeyken ayarlamak için bu tuşa basılı tutun.", 1, turkish = true))
        assertEquals("Oltayı geriye çekmek için $icon basılı tut.",
            insertButtonIcons("Oltayı geriye çekmek için basılı tut.", 1, turkish = true))
        assertEquals("Seçmek için $icon $icon düğmesine bas",
            insertButtonIcons("Seçmek için bu düğmeye bas", 2, turkish = true))
    }

    @Test fun withoutAButtonWordTheIconGoesFirstAfterTheSpeaker() {
        assertEquals("$icon Haritayı aç", insertButtonIcons("Haritayı aç", 1, turkish = true))
        assertEquals("Cal: $icon Haritayı aç", insertButtonIcons("Cal: Haritayı aç", 1, turkish = true))
        assertEquals("$icon Halte gedrückt", insertButtonIcons("Halte gedrückt", 1, turkish = false))
        assertEquals("Metin", insertButtonIcons("Metin", 0, turkish = true))
    }

    private fun word(left: Int, right: Int, top: Int = 35, text: String = "") = IconWord(left, top, right, top + 30, text)
}
