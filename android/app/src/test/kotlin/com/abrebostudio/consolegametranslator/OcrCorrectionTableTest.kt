package com.abrebostudio.consolegametranslator

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class OcrCorrectionTableTest {
    private val json = javaClass.getResource("/${OcrCorrectionTable.ASSET_PATH}")!!.readText()
    private val table = OcrCorrectionTable.parse(json)
    private fun correct(text: String, source: String = "en", selected: Boolean = false) = table.correct(text, source, selected)

    @Test fun aSelectedGameBypassesAllTableRulesEvenIfItsPackHasNoMatchingLine() {
        val text = "Im guessing th1s is hisroom. l'd come down and waIk."
        assertEquals(OcrCorrectionTable.Result(text), correct(text, selected = true))
        assertNotEquals(text, correct(text).text)
    }

    @Test fun corruptedGlyphsAndContractionsShareOneTextBeforeAnyTranslationEngine() {
        assertEquals("I'm guessing they don't know. I'd come down. I'll call. This is all we need.",
            correct("Irn guessing they dont know. l'd come down. Ill call. Th1s is aIl we need.").text)
        assertEquals("I'd come down. I'll call. I've got this. It's all good.",
            correct("Id come down. \"ll call. l've got this. Jt's all good.").text)
        assertEquals("a drink in his room", correct("a dririk in his roorn").text)
    }

    @Test fun ambiguousRealWordsNeedTheWhitelistedContext() {
        assertEquals("I'll call you. I'd come down.", correct("Ill call you. Id come down.").text)
        assertEquals("Ill patients need help. Read the Id field.", correct("Ill patients need help. Read the Id field.").text)
        assertEquals("I can't wait. They won't go.", correct("I cant wait. They wont go.").text)
        assertEquals("The cant is visible. He is wont to wait.", correct("The cant is visible. He is wont to wait.").text)
        assertEquals("I don't have a drink.", correct("Idont have a dririk.").text)
        assertEquals("Dririk named ship", correct("Dririk named ship").text)
    }

    @Test fun namesValidWordsNegationDirectionsAndQuantitiesAreNotGuessed() {
        val text = "Jacgueline and Jaccueline were well. The shell is hot, not cold. " +
            "Turn left, not right; meet at gate 12. An ill person and an ID card. Hell, it's fine."
        assertEquals(OcrCorrectionTable.Result(text), correct(text))
    }

    @Test fun wholeWordBoundariesKeepIdentifiersAndOtherWordsIntact() {
        val text = "notth1s th1s_extra th1s123 éth1s th1s\u0301 TH1S 001 12:30 -5.0"
        assertEquals(text, correct(text).text)
        assertEquals("this, (this)!", correct("th1s, (th1s)!").text)
    }

    @Test fun urlsAndEmailAddressesAreNeverRewritten() {
        val text = "https://example.com/th1s?value=waIk www.th1s.com th1s@example.com + th1s"
        assertEquals("https://example.com/th1s?value=waIk www.th1s.com th1s@example.com + this", correct(text).text)
    }

    @Test fun languageSelectionAndCurlyApostrophesDoNotAlterUnrelatedText() {
        val text = "l’m sure. We’re ready."
        assertEquals("I'm sure. We’re ready.", correct(text, "en-US").text)
        for (language in listOf("tr", "ar", "id", "th", "ru", "hi")) assertEquals(text, correct(text, language).text)
        assertEquals(text, OcrCorrectionTable.EMPTY.correct(text, "en", false).text)
    }

    @Test fun optionalCaseFoldingPreservesSentenceAndUppercaseStyle() {
        assertEquals("Don't worry. DON'T worry. don't worry.", correct("Dont worry. DONT worry. dont worry.").text)
        assertEquals("we'll were well shell hell its", correct("we'll were well shell hell its").text)
    }

    @Test fun everyBundledVariantWorksWithItsContextAndTheResultIsIdempotent() {
        val rules = JSONObject(json).getJSONObject("languages").getJSONArray("en")
        var variants = 0
        for (index in 0 until rules.length()) {
            val row = rules.getJSONObject(index)
            val prefix = row.optJSONArray("previous")?.getString(0)?.plus(" ") ?: ""
            val suffix = row.optJSONArray("next")?.getString(0)?.let { " $it" } ?: ""
            val from = row.getJSONArray("from")
            for (variant in 0 until from.length()) {
                val input = prefix + from.getString(variant) + suffix
                val expected = prefix + row.getString("to") + suffix
                val result = correct(input)
                assertEquals("Rule ${row.getString("id")} variant $variant", expected, result.text)
                assertEquals("Rule ${row.getString("id")} cascaded", result.text, correct(result.text).text)
                variants++
            }
        }
        assertTrue("Include likely errors beyond one recording", rules.length() >= 100 && variants >= 200)
    }

    @Test fun matchingUsesLiteralStringsAndNeverCascadesWithinOneReading() {
        val literal = parseRules("""{"id":"literal","from":["a+b"],"to":"sum"}""")
        assertEquals("aaab sum", literal.correct("aaab a+b", "en", false).text)
        val chained = parseRules("""{"id":"one","from":["th1s"],"to":"this"},
            {"id":"two","from":["this"],"to":"that"}""")
        assertEquals("this", chained.correct("th1s", "en", false).text)
    }

    @Test fun completeContractionsAreRepairedWithoutReplacingAFragmentInsideAnotherWord() {
        assertEquals("I'll call you. I'll call you.", correct("I'Ill call you. 'Ill call you.").text)
        assertEquals("He said 'I'll call you.'", correct("He said 'Ill call you.'").text)
        assertEquals("D'Ill call you. th1s's name", correct("D'Ill call you. th1s's name").text)
        assertEquals("I'd come down. I'll call.", correct("1d come down. lIl call.").text)
        assertEquals("1d wait, 1d 2h, 1d time", correct("1d wait, 1d 2h, 1d time").text)
    }

    @Test fun followupMissingLettersAndJoinedWordsNeedTheirListedContext() {
        assertEquals("I'm guessing they don't have many people. I liked looking at it.",
            correct("Imguessíng they donlt haye many people. I liked ooking at it.").text)
        assertEquals("I'm guessing they will come.", correct("Im guessíng they will come.").text)
        assertEquals("I'm guessing", correct("Irm guessing").text)
        assertEquals("Haye and Wooking are names. and don't go.", correct("Haye and Wooking are names. and don't go.").text)
    }

    @Test fun followupGameplayRepairsTheActualInputsThatProducedDamagedModelPrompts() {
        val rows = JSONArray(javaClass.getResource("/ocr-corrections-2026-11-16-followup.json")!!.readText())
        val rawReadings = mutableSetOf<String>()
        val outputReadings = mutableSetOf<String>()
        var changed = 0
        var timers = 0
        for (index in 0 until rows.length()) {
            val row = rows.getJSONObject(index)
            if (row.getString("text").isBlank()) continue
            val raw = row.getString("raw")
            assertEquals(raw, correct(raw, selected = true).text)
            if (isStandaloneOcrTimer(raw)) { timers++; continue }
            val result = correct(raw)
            rawReadings.add(raw); outputReadings.add(result.text)
            if (result.replacements > 0) changed++
            assertEquals(result.text, correct(result.text).text)
        }
        assertEquals(1, timers)
        assertTrue(changed >= 100)
        assertTrue(outputReadings.size < rawReadings.size)
        println("Followup OCR correction replay: changed=$changed uniqueRaw=${rawReadings.size} uniqueOutput=${outputReadings.size} timersRejected=$timers")
    }

    @Test fun badTablesAreRejectedInsteadOfSilentlyGuessingFieldMeanings() {
        val invalid = listOf(
            """{"version":2,"languages":{"en":[]}}""",
            """{"version":1,"languages":{"english":[]}}""",
            """{"version":1,"languages":{"en":[]}}""",
            """{"version":1,"language":{"en":[]}}""",
        )
        invalid.forEach { expectRejected { OcrCorrectionTable.parse(it) } }
        for (row in listOf(
            """{"id":"a","from":["x"],"to":"y","nexxt":["call"]}""",
            """{"id":"a","from":["x"],"to":"y","next":[]}""",
            """{"id":"a","from":["x"],"to":"y","caseSensitive":"false"}""",
            """{"id":"a","from":["x"],"to":"x"}""",
            """{"id":"a","from":[" x"],"to":"y"}""",
        )) expectRejected { parseRules(row) }
    }

    @Test fun overlappingVariantsAndDuplicateIdsFailValidation() {
        expectRejected { parseRules("""{"id":"a","from":["dont","Dont"],"to":"don't","caseSensitive":false}""") }
        expectRejected { parseRules("""{"id":"a","from":["x"],"to":"y"},{"id":"a","from":["z"],"to":"y"}""") }
        expectRejected { parseRules("""{"id":"a","from":["dont"],"to":"don't","caseSensitive":false},
            {"id":"b","from":["Dont"],"to":"Don't"}""") }
    }

    @Test fun malformedOrOversizedInputsDoNotCreateUnboundedWork() {
        val large = "th1s ".repeat(2_000)
        assertEquals(large, correct(large).text)
        assertEquals(OcrCorrectionTable.Result(""), correct(""))
        expectRejected { OcrCorrectionTable.parse(" ".repeat(262_145)) }
    }

    @Test fun gameplayVariantsBecomeMoreConsistentWithoutTouchingSelectedGameReadings() {
        val rows = JSONArray(javaClass.getResource("/ocr-corrections-2026-11-16.json")!!.readText())
        val before = mutableSetOf<String>()
        val after = mutableSetOf<String>()
        var changed = 0
        for (index in 0 until rows.length()) {
            val text = rows.getJSONObject(index).getString("text")
            if (text.isEmpty()) continue
            val result = correct(text)
            before.add(text); after.add(result.text)
            if (result.replacements > 0) changed++
            assertEquals(text, correct(text, selected = true).text)
            assertEquals(result.text, correct(result.text).text)
        }
        println("OCR correction replay: readingsChanged=$changed uniqueBefore=${before.size} uniqueAfter=${after.size}")
        assertTrue("Observed OCR errors should be repaired", changed >= 100)
        assertTrue("Do not create additional spellings", after.size < before.size)
    }

    private fun parseRules(rows: String) = OcrCorrectionTable.parse("""{"version":1,"languages":{"en":[$rows]}}""")
    private fun expectRejected(block: () -> Unit) {
        try { block(); fail("Invalid OCR table accepted") } catch (_: IllegalArgumentException) { }
        catch (_: org.json.JSONException) { }
    }
}
