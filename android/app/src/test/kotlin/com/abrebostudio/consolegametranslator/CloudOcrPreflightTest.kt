package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class CloudOcrPreflightTest {
    @Test fun unfilteredLoggedTimersAndTheirDamagedVariantsHaveNothingToTranslate() {
        listOf("00:14 00:14", "00:14 O0:14", "00:1a 00:14", "n014 o0:14", "o:1",
            "o:14", "o0:14", "00:14", "00:14 04:59", "04:59", "02:5 02:59",
            "02:5 02:5", "02:5", "01:22", "VI:00", "VI：OO", "00 : 14\nO0 : 14")
            .forEach { assertTrue(it, isNonLinguisticCloudOcr(it)) }
    }

    @Test fun standaloneNumbersAndPunctuationDoNotNeedACloudRequest() {
        listOf("", "...", "12", "123 456", "12.5", "100%", "١٢٣", "１２３")
            .forEach { assertTrue(it, isNonLinguisticCloudOcr(it)) }
    }

    @Test fun actualRepliesCodesNamesAndDialogueContainingTimesRemainEligible() {
        listOf("I", "A", "No!", "Go!", "tl", "VI: Go now!", "VI: Meet me at 00:14.",
            "We have 00:14 left.", "Room 12", "Gate 13", "n014", "A1 00:14", "Chapter VI",
            "Don't wait!", "Meet me at 12.5.", "اذهب الآن", "ไม่", "行け！", "Hayır!")
            .forEach { assertFalse(it, isNonLinguisticCloudOcr(it)) }
    }

    @Test fun jsonMatchStillWinsBeforeCloudNoiseRejection() {
        val memory = GameTranslationMemory.parse("test", "en", "tr", """
            {"schemaVersion":2,"game":"test","source":"en","target":"tr","entries":[
                {"id":"timer","sourceText":"00:14","targetText":"On dört saniye."}]}
        """.trimIndent())
        val read = selectSubtitleSource("00:14", .8f, memory) { error("JSON must win first") }
        assertEquals("On dört saniye.", requireNotNull(read.memoryMatch).target)
        assertTrue(isNonLinguisticCloudOcr(read.text))
    }
}
