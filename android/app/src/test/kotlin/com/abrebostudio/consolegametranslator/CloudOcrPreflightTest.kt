package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class CloudOcrPreflightTest {
    @Test fun unfilteredLoggedTimersAndTheirDamagedVariantsHaveNothingToTranslate() {
        listOf("00:14 00:14", "00:14 O0:14", "00:1a 00:14", "n014 o0:14", "o:1",
            "o:14", "o0:14", "00:14", "00:14 04:59", "04:59", "02:5 02:59",
            "02:5 02:5", "02:5", "01:22", "VI:00", "VI：OO", "00 : 14\nO0 : 14")
            .forEach { assertTrue(it, isNonLinguisticOcr(it)) }
    }

    @Test fun standaloneNumbersAndPunctuationDoNotNeedACloudRequest() {
        listOf("", "...", "12", "123 456", "12.5", "100%", "١٢٣", "１２３")
            .forEach { assertTrue(it, isNonLinguisticOcr(it)) }
    }

    @Test fun actualRepliesCodesNamesAndDialogueContainingTimesRemainEligible() {
        listOf("I", "A", "No!", "Go!", "tl", "VI: Go now!", "VI: Meet me at 00:14.",
            "We have 00:14 left.", "Room 12", "Gate 13", "n014", "A1 00:14", "Chapter VI",
            "Don't wait!", "Meet me at 12.5.", "اذهب الآن", "ไม่", "行け！", "Hayır!")
            .forEach { assertFalse(it, isNonLinguisticOcr(it)) }
    }

    @Test fun videoPlayerTimesFromALocalOpusSessionAreNotTranslated() {
        // Logged with OPUS-MT on 21 Nov 2026: a web video player's progress bar.
        listOf("00:14 00:14", "00:1", "02:59 04:59", "7 02:59 04:59", "02:59 14:59", "02:59 14-59",
            "04:59 02", "o4: 59", "02:59")
            .forEach { assertTrue(it, isNonLinguisticOcr(it)) }
    }

    @Test fun decoderUnknownTokensAreDetectedOnlyAsTheLiteralToken() {
        listOf("02:59 <unk>4:59", "<unk>", "Merhaba <unk> dünya").forEach { assertTrue(it, containsUnknownToken(it)) }
        listOf("Merhaba dünya", "unk", "<un k>", "Jason: Burada ne var?").forEach { assertFalse(it, containsUnknownToken(it)) }
    }

    @Test fun liveOutputEqualToTheSourceIsAnUntranslatedEcho() {
        listOf(
            "AYHO" to "AYHO",
            "02:5e" to "02: 5e",
            "L1/R1 Sekmeler Arasında Geçiş" to "L1/R1 Sekmeler Arasında Geçiş",
            "Jason!" to "jason",
        ).forEach { (source, translated) -> assertTrue(source, isUntranslatedEcho(source, translated)) }
        listOf(
            "Jason: What- they're comin' here?" to "Jason: Burada ne var?",
            "OK" to "Tamam",
            "..." to "...",
        ).forEach { (source, translated) -> assertFalse(source, isUntranslatedEcho(source, translated)) }
    }

    @Test fun misreadClockSecondsAreNotLanguage() {
        listOf("02:5e", "02:5S", "02:5g").forEach { assertTrue(it, isNonLinguisticOcr(it)) }
    }

    @Test fun jsonMatchStillWinsBeforeCloudNoiseRejection() {
        val memory = GameTranslationMemory.parse("test", "en", "tr", """
            {"schemaVersion":2,"game":"test","source":"en","target":"tr","entries":[
                {"id":"timer","sourceText":"00:14","targetText":"On dört saniye."}]}
        """.trimIndent())
        val read = selectSubtitleSource("00:14", .8f, memory) { error("JSON must win first") }
        assertEquals("On dört saniye.", requireNotNull(read.memoryMatch).target)
        assertTrue(isNonLinguisticOcr(read.text))
    }
}
