package com.abrebostudio.consolegametranslator

import java.nio.ByteBuffer
import java.nio.ByteOrder
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class LoggedOcrRegressionTest {
    private fun memory(vararg rows: Pair<String, String>) = GameTranslationMemory.parse("regression", "en", "tr",
        JSONObject().put("game", "regression").put("source", "en").put("target", "tr")
            .put("entries", JSONArray(rows.mapIndexed { i, (en, tr) ->
                JSONObject().put("id", "$i").put("english", en).put("turkish", tr)
            })).toString())

    @Test fun noisyWholeRowWinsBeforeAnUnreadableShortSentencePrefix() {
        val source = "Yeah. I'd come down to the marina, sit on the dock, pour myself a drink, and look at her -"
        val target = "Aynen. Marina anısı."
        val memory = memory(source to target)
        val variants = listOf(
            "Yyat. ld come down to the marina, sit on the dock, pour myself a drink, and look at her -",
            "Yyan. ld come down to the marina, sit on the dock, pour myself a drink, and look at her -",
            "Yyat. ld come down to the marina, sit on the dock, pour myself a drink, and look at her-",
            "Yyan. ld come down to the marina, sit on the dock, pour myself a drink, and look at her-",
            "9an. ld come down to the marina, sit on the dock, pour myself a drink, and look at her -",
            "Yean. ld come down to the marina, sit on the dock, pour myself a dirink, and look at her -",
            "Y9a. ld come down to the marina, sit on the dock, pour myself a drink, and look at her -",
            "eat. 'd come down to the marina, sit on the dock, pour myselfa drínk, and look at her -",
            "Yeat. 'd come down to the marina, sit on the dock, pour myselfa drínk, and look at her -",
            "Seah. 'd come down to the marina, sit on the dock, pour myselfa drink, and look at her -",
            "eat. come down to the marina, sit on the dock, pour myselfa drínk, and look at her -",
            "Yeat. come down to the marina, sit on the dock, pour myselfa drínk, and look at her -",
            "Seah. come down to the marina, sit on the dock, pour myselfa drink, and look at her -",
            "Yeah'd come down to the marina, sit on the dock, pour myself a dririk, and look at her -",
            "Yeat. l'd cOMgdoyn to the marina, sit on the dock, pour myselfa dink, and look at her",
            "Y9ah. I'd come down to the marina, sit on the dock, pour myself a drink, and look at her -",
        )
        for (text in variants) {
            val match = requireNotNull(memory.find(text)) { text }
            assertEquals(text, "0", match.entryId)
            assertEquals(text, target, match.target)
            assertEquals(text, source, match.source)
        }
        assertNull(memory.find("Yyan. ld come down to the marina,"))
    }

    @Test fun joinedWordsCannotExposeAnUnseenSentenceEvenWhenTheEndingRepeats() {
        val first = "We should drive down to the northern harbor before sunrise and check the old warehouse carefully before we leave this quiet neighborhood and continue our journey to the mountains."
        val source = "$first Get in the car. Get in the car."
        val memory = memory(source to "Önce depoya bak. Arabaya bin. Sonraki cümle.")
        val query = "$first Get in the car.".replace("should drive", "shoulddrive").replace("carefully", "carefullv")
        assertFalse(memory.find(query)?.target.orEmpty().contains("Sonraki"))
    }

    @Test fun aNoisyFullRowCannotGuessBetweenConflictingTranslations() {
        val memory = memory(
            "Yeah. I'd come down to the marina, sit on the dock, pour myself a drink, and look at her -" to "Birinci çeviri.",
            "Yeah. I'd come down to the marina, sit on the dock, pour myself a drink, and look at him -" to "İkinci çeviri.",
        )
        assertNull(memory.find("Yyan. ld come down to the marina, sit on the dock, pour myself a drink, and look at hxr -"))
    }

    @Test fun multipleOcrGlyphErrorsAndJoinedWordsRecoverTheRobLine() {
        val memory = memory("You're not gonna rob me again?" to "Beni yine soymayacaksın değil mi?",
            "Man, I never robbed you." to "Hadi ama, ben seni soymadım.")
        for (text in listOf("You're not yorina roD rnsagain?", "You're not gyonria rob ns again?", "Yours riot gorrna rob rne again?")) {
            assertEquals(text, "Beni yine soymayacaksın değil mi?", memory.find(text)?.target)
        }
        assertEquals("Hadi ama, ben seni soymadım.", memory.find("Man, I nev9r robbshyou.")?.target)
    }

    @Test fun embeddedOcrDigitsAndAccentsDoNotHideAnOtherwiseRecognisableLine() {
        val memory = memory("I wasn't really serious about that." to "O konuda pek ciddi değildim.",
            "you call it whatever you wanna call it." to "öyle olsun bakalım.")
        assertEquals("O konuda pek ciddi değildim.", memory.find("I wasn't r9ally serious abour that.")?.target)
        assertEquals("exact", memory.find("you call ít whatever you wanna call it.")?.matchType)
    }

    @Test fun realNumbersAndActuallyMissingNegationRemainProtected() {
        assertNull(memory("Bring 15 boxes to the northern gate." to "15 kutu getir.").find("Bring 16 boxes to the northern gate."))
        assertNull(memory("Bring Room15 boxes to the northern gate." to "Room15 kutularını getir.").find("Bring Room16 boxes to the northern gate."))
        assertNull(memory("You must not open the northern gate." to "Kapıyı açmamalısın.").find("You must open the northern gate."))
        assertNull(memory("You must open the northern gate." to "Kapıyı açmalısın.").find("You must not open the northern gate."))
    }

    @Test fun bulkReadbackKeepsColourChannelsAndVerticalOrientationOnEitherByteOrder() {
        // OpenGL bottom row: blue/white; top row: red/green.
        val bytes = byteArrayOf(0, 0, -1, -1, -1, -1, -1, -1, -1, 0, 0, -1, 0, -1, 0, -1)
        for (order in listOf(ByteOrder.LITTLE_ENDIAN, ByteOrder.BIG_ENDIAN)) {
            val pixels = rgbaReadbackPixels(ByteBuffer.wrap(bytes).order(order).asIntBuffer(), 2, 2, order == ByteOrder.LITTLE_ENDIAN)
            assertArrayEquals(intArrayOf(0xffff0000.toInt(), 0xff00ff00.toInt(), 0xff0000ff.toInt(), 0xffffffff.toInt()), pixels)
        }
    }

    @Test fun weightedGlyphDistanceIsSymmetricAndDoesNotDiscardASplitGlyphAtTheLimit() {
        for ((left, right) in listOf("rne" to "me", "riot" to "not", "never" to "nev9r", "youwith" to "you with")) {
            assertEquals(ocrTextDistance(left, right, 1000), ocrTextDistance(right, left, 1000))
            assertTrue(ocrTextDistance(left, right, 40) <= 40)
        }
        assertTrue(ocrTextDistance("can", "cant", 40) > 40)
        val random = kotlin.random.Random(314)
        repeat(160) {
            fun word() = (0 until random.nextInt(1, 15)).map { " rniclmvwe9"[random.nextInt(10)] }.joinToString("")
            val left = word(); val right = word()
            val expected = ocrTextDistance(left, right, 10000)
            for (limit in listOf(30, 60, 100, 200, 400)) {
                val actual = ocrTextDistance(left, right, limit)
                if (expected <= limit) assertEquals(expected, actual) else assertTrue(actual > limit)
            }
        }
    }
}
