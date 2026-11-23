package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class UnmatchedOcrPreparationTest {
    private val table = OcrCorrectionTable.parse(javaClass.getResource("/${OcrCorrectionTable.ASSET_PATH}")!!.readText())
    private val memory = GameTranslationMemory.parse("partial-game", "en", "tr",
        """{"schemaVersion":2,"game":"partial-game","source":"en","target":"tr","entries":[
          {"id":"known","sourceText":"I'll call you.","targetText":"Seni arayacağım."}]}""")

    @Test fun onlyConfirmedMissesOrNoGameAllowPreparation() {
        assertFalse(canPrepareUnmatchedOcr(true, true, true))
        assertFalse(canPrepareUnmatchedOcr(true, false, false))
        assertFalse(canPrepareUnmatchedOcr(false, false, true))
        assertTrue(canPrepareUnmatchedOcr(true, true, false))
        assertTrue(canPrepareUnmatchedOcr(false, false, false))
    }

    @Test fun knownJsonKeepsTheIdenticalReadWithoutCorrectionOrAnotherSearch() {
        val original = selectSubtitleSource("I'll call you.", .05f, memory) { error("JSON must win") }
        val result = prepareUnmatchedOcr(original, true, true,
            correct = { error("Matched JSON must never be corrected") },
            findGameTranslation = { error("Matched JSON must not be searched again") })
        assertSame(original, result.read)
        assertSame(original.memoryMatch, result.read.memoryMatch)
        assertEquals("Seni arayacağım.", result.read.memoryMatch?.target)
        assertEquals(0, result.corrections)
    }

    @Test fun selectedButNotReadyOrWrongLanguageKeepsTheExistingRead() {
        val raw = SubtitleOcrRead("Im going to the harbour.", .8f)
        val result = prepareUnmatchedOcr(raw, true, false,
            correct = { error("No completed lookup yet") },
            findGameTranslation = { error("The selected pack is not ready") })
        assertSame(raw, result.read)
    }

    @Test fun selectedPackMissGetsTheSameCorrectionsAsTheNoGamePath() {
        val raw = SubtitleOcrRead("Im going to the harbour.", .8f)
        assertNull(memory.find(raw.text))
        var lookups = 0
        val result = prepareUnmatchedOcr(raw, true, true,
            correct = { table.correct(it, "en", true, gameLookupMiss = true) },
            findGameTranslation = { lookups++; memory.find(it) })
        assertEquals(table.correct(raw.text, "en", false).text, result.read.text)
        assertEquals("I'm going to the harbour.", result.read.text)
        assertNull(result.read.memoryMatch)
        assertEquals(.8f, result.read.confidence)
        assertEquals(1, lookups)
    }

    @Test fun aCorrectedMissCanFindJsonThroughTheUnchangedMatcher() {
        val raw = SubtitleOcrRead("lIl caII y0u.", .8f)
        // The fuzzy matcher may also recover this read; the corrected text must not need it.
        assertNull("The read itself is no exact JSON line", memory.findExact(raw.text))
        var lookups = 0
        val result = prepareUnmatchedOcr(raw, true, true,
            correct = { table.correct(it, "en", true, gameLookupMiss = true) },
            findGameTranslation = { lookups++; memory.find(it) })
        assertEquals("I'll call you.", result.read.text)
        assertEquals("Seni arayacağım.", result.read.memoryMatch?.target)
        assertEquals("known", result.read.memoryMatch?.entryId)
        assertEquals(1, lookups)
    }

    @Test fun unchangedMissDoesNotRepeatAnAlreadyCompletedGameSearch() {
        val raw = SubtitleOcrRead("We should head towards the harbour.", .9f)
        val result = prepareUnmatchedOcr(raw, true, true,
            correct = { OcrCorrectionTable.Result(it) },
            findGameTranslation = { error("Unchanged text was already searched") })
        assertSame(raw, result.read)
        assertEquals(0, result.corrections)
    }

    @Test fun noGameAndBlankReadsKeepTheirExistingBehaviourWithoutGameQueries() {
        val result = prepareUnmatchedOcr(SubtitleOcrRead("Im going to the harbour.", .8f), false, false,
            correct = { table.correct(it, "en", false) },
            findGameTranslation = { error("No game selected") })
        assertEquals("I'm going to the harbour.", result.read.text)
        val blank = SubtitleOcrRead("", 0f)
        assertSame(blank, prepareUnmatchedOcr(blank, true, true,
            correct = { error("Empty OCR needs no preparation") },
            findGameTranslation = { error("Empty OCR needs no search") }).read)
    }

    @Test fun jsonFoundInARecoveryReadIsImmediatelyAuthoritativeEvenAtLowConfidence() {
        val recovered = selectSubtitleSource("I'll call you.", .1f, memory) { error("Recovered JSON must win") }
        assertFalse(canPrepareUnmatchedOcr(true, true, recovered.memoryMatch != null))
        assertEquals("Seni arayacağım.", recovered.memoryMatch?.target)
    }
}
