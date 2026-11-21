package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class GameSpeakerFallbackTest {
    @Test fun anyKnownSpeakerCanUseUnlabelledJsonSentencesAcrossEveryTranslationEngine() {
        val memory = GameTranslationMemory.parse("gta6", "en", "tr", """{
          "schemaVersion":2,"game":"gta6","source":"en","target":"tr",
          "speakers":{"Jason":"Jason","Lucia":"Lucia","Isabella":"Isabella"},
          "entries":[
            {"id":"1","sourceText":"We should leave this place.","targetText":"Buradan gitmeliyiz.","speaker":""},
            {"id":"2","sourceText":"Meet me at gate 12 after midnight.","targetText":"Gece yarısından sonra 12 numaralı kapıda buluşalım."},
            {"id":"3","sourceText":"Don't take the left road.","targetText":"Soldaki yola girme.","speaker":""}
          ]}""")
        for ((source, target) in listOf(
            "We should leave this place." to "Buradan gitmeliyiz.",
            "Meet me at gate 12 after midnight." to "Gece yarısından sonra 12 numaralı kapıda buluşalım.",
            "Don't take the left road." to "Soldaki yola girme.",
        )) {
            for (name in listOf("Jason", "Lucia", "Isabella")) {
                val read = selectSubtitleSource("${name.uppercase()}: $source", 0f, memory) {
                    error("Known JSON dialogue must not invoke a translation fallback")
                }
                val match = requireNotNull(read.memoryMatch)
                assertEquals(target, match.target)
                assertEquals(name, match.speaker)
                for (engine in listOf("opus", "mlkit", "deepl", "gemini")) {
                    val event = subtitleTextEvent(0, match.target, engine, match)
                    assertEquals("$name: $target", event["text"])
                    assertEquals("game_memory", event["translationEngine"])
                }
            }
        }
    }

    private fun memory(speaker: String = "", names: String = "\"Jason\":\"Jason\"") =
        GameTranslationMemory.parse("gta6", "en", "tr", """{
          "schemaVersion":2,"game":"gta6","source":"en","target":"tr",
          "speakers":{$names},"entries":[{"id":"004253","sourceText":"What?",
          "targetText":"Ne?","speaker":"$speaker"}]}""")

    @Test fun knownJasonWithBlankEntrySpeakerUsesShortJsonLineBeforeAnyFallback() {
        val memory = memory()
        for (ocr in listOf("JASON: What?", "Jason: What ?", "JASON: What?!")) {
            val read = selectSubtitleSource(ocr, 0f, memory) {
                error("JSON hit must not reach filtered/model/API fallback")
            }
            val match = requireNotNull(read.memoryMatch)
            assertEquals("004253", match.entryId)
            assertEquals("Ne?", match.target)
            assertEquals("Jason", match.speaker)
            val event = subtitleTextEvent(0, match.target, "deepl", match)
            assertEquals("Jason: Ne?", event["text"])
            assertEquals("game_memory", event["translationEngine"])
        }
    }

    @Test fun unrecognisedNameIsNotBlindlyRemovedFromTheOcr() {
        assertNull(memory(names = "").findExact("JASON: What?"))
        assertNull(memory().findExact("STRANGER: What?"))
    }

    @Test fun anotherExplicitSpeakerCannotBeUsedForJason() {
        assertNull(memory("Lucia", "\"Jason\":\"Jason\",\"Lucia\":\"Lucia\"")
            .findExact("JASON: What?"))
    }
}
