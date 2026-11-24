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

    @Test fun aNameThePackDoesNotListStaysAsReadAroundEvenAShortLine() {
        // A pack without any speaker list still shows its short lines.
        for ((memory, ocr) in listOf(memory(names = "") to "JASON: What?", memory() to "STRANGER: What?")) {
            val match = requireNotNull(memory.findExact(ocr))
            assertEquals("Ne?", match.target)
            assertEquals("${ocr.substringBefore(':')}: Ne?", subtitleTextEvent(0, match.target, "none", match)["text"])
        }
        // A plain sentence with a colon is no name label.
        assertNull(memory().findExact("Remember this: What?"))
    }

    @Test fun aNameLabelThePackDoesNotListStillFindsItsLongLine() {
        val memory = GameTranslationMemory.parse("gta6", "en", "tr", """{
          "schemaVersion":2,"game":"gta6","source":"en","target":"tr",
          "speakers":{"Jason":"Jason"},"entries":[
            {"id":"44p1","sourceText":"Got someone coming in for Kyle's batch.",
             "targetText":"Kyle'ın malı için biri geliyor.","speaker":""},
            {"id":"44p2","sourceText":"Copy, I'll keep eyes on 'em.","targetText":"Anlaşıldı, gözüm üstlerinde."},
            {"id":"44p3","sourceText":"Uh-huh... hang on.","targetText":"Hı-hı... bekle biraz..."}]}""")
        // A short line (11 letters) is found without the label too, which stays as the game shows it.
        assertEquals("Final Chapter: Hı-hı... bekle biraz...", memory.findExact("Final Chapter: Uh-huh... hang on.")?.let {
            subtitleTextEvent(0, it.target, "none", it)["text"] })
        val exact = requireNotNull(memory.findExact("Final Chapter: Got someone coming in for Kyle's batch."))
        assertEquals("44p1", exact.entryId)
        assertEquals("Final Chapter: Kyle'ın malı için biri geliyor.",
            subtitleTextEvent(0, exact.target, "game_memory", exact)["text"])
        val fuzzy = requireNotNull(memory.find("Final Chapter: Copy, I'l keep eyes on 'em."))
        assertEquals("44p2", fuzzy.entryId)
        assertEquals("Final Chapter", fuzzy.speaker)
        val read = selectSubtitleSource("Final Chapter: Got someone coming in for Kyle's batch.", 0f, memory) {
            error("A pack line behind an unknown label must not reach live translation")
        }
        assertEquals("44p1", read.memoryMatch?.entryId)
    }

    @Test fun aLabelWrittenIntoThePacksRowsKeepsItsWholeRowSearch() {
        val memory = GameTranslationMemory.parse("gta6", "en", "tr", """{
          "schemaVersion":2,"game":"gta6","source":"en","target":"tr",
          "speakers":{"Jason":"Jason"},"entries":[
            {"id":"71sl","sourceText":"Cal: Look, I'm sorry. Okay? I just say whatever comes into my head.",
             "targetText":"Cal: Bak, özür dilerim. Tamam mı? Aklıma ne gelirse söylüyorum işte."}]}""")
        val match = requireNotNull(memory.find("Cal: Look, l'm sorry. Okay? I just say whatever comes into mny head."))
        assertEquals("71sl", match.entryId)
        assertEquals("Cal: Bak, özür dilerim. Tamam mı? Aklıma ne gelirse söylüyorum işte.",
            subtitleTextEvent(0, match.target, "game_memory", match)["text"])
    }

    @Test fun anotherExplicitSpeakerCannotBeUsedForJason() {
        assertNull(memory("Lucia", "\"Jason\":\"Jason\",\"Lucia\":\"Lucia\"")
            .findExact("JASON: What?"))
    }
}
