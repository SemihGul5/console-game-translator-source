package com.abrebostudio.consolegametranslator

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

/** The hash-only lookups that run before any fuzzy search ([GameTranslationMemory.findQuick]). */
class GameQuickLookupTest {
    private fun memory(vararg rows: Pair<String, String>): GameTranslationMemory {
        val entries = rows.mapIndexed { index, (source, target) -> JSONObject()
            .put("id", "$index").put("english", source).put("turkish", target)
        }
        return GameTranslationMemory.parse("test-game", "en", "tr", JSONObject()
            .put("game", "test-game").put("source", "en").put("target", "tr")
            .put("entries", JSONArray(entries)).toString())
    }

    @Test fun twoPackLinesReadTogetherAreJoinedSentenceBySentence() {
        val memory = memory(
            "You're who Kyle sent? You don't look like a farmer to me." to "Kyle'ın gönderdiği sen misin? Bana çiftçi gibi görünmüyorsun.",
            "Inspect the chemicals." to "Kimyasalları incele.",
        )
        val match = requireNotNull(memory.findQuick("You're who Kyle sent? You don't look like a farmer to me. Inspect the chemicals."))
        assertEquals("sentence_exact", match.matchType)
        assertEquals("0+1", match.entryId)
        assertEquals("Kyle'ın gönderdiği sen misin? Bana çiftçi gibi görünmüyorsun. Kimyasalları incele.", match.target)
        // One sentence the pack does not know: no partial answer from the quick path.
        assertNull(memory.findQuick("Inspect the chemicals. Somebody else said this."))
    }

    @Test fun oneUsualOcrMisreadingOfAShortLineIsUndone() {
        val memory = memory("I'm mad at you." to "Sana kızgınım.", "Go to the van" to "Minibüse git",
            "Meet me at the docks" to "Benimle rıhtımda buluş")
        val confused = requireNotNull(memory.findQuick("I'm rnad at you."))
        assertEquals("Sana kızgınım.", confused.target)
        assertEquals("ocr_variant", confused.matchType)
        assertEquals("Minibüse git", memory.findQuick("Go to tbe van")?.target)
        // A stray letter and a lost one.
        assertEquals("Minibüse git", memory.findQuick("Go to thhe van")?.target)
        assertEquals("Benimle rıhtımda buluş", memory.findQuick("Meet me at the dcks")?.target)
    }

    @Test fun aFixMayNotChangeANumberOrPickBetweenTwoLines() {
        val memory = memory("Wait at gate 15" to "15 numaralı kapıda bekle", "Wait at gate 16" to "16 numaralı kapıda bekle",
            "Bring the bait" to "Yemi getir", "Bring the bolt" to "Cıvatayı getir",
            "Take the left road" to "Sol yola sap", "Take the lift road" to "Asansör yoluna sap")
        assertNull(memory.findQuick("Wait at gate 18"))
        assertEquals("Yemi getir", memory.findQuick("Bring the balt")?.target)
        // A stray "i" or a stray "e": two lines, two answers, none taken.
        assertNull(memory.findQuick("Take the leift road"))
    }

    @Test fun aCleanReadIsNeverTurnedIntoAnotherLine() {
        // The log: "Really?" (two translations in the pack) was shown as "Rally" -> "Ralli".
        val memory = memory("Rally" to "Ralli", "Really?" to "Gerçekten mi?", "Really?" to "Sahiden mi?",
            "Is that really true" to "Bu gerçekten doğru mu", "Rally the crew" to "Ekibi topla")
        assertNull(memory.findQuick("Really?"))
        assertNull(memory.find("Really?"))
        // Every word is known: a line the pack does not have, not a misreading.
        assertNull(memory.findQuick("Really the crew"))
    }

    @Test fun aLineWithTwoTranslationsTakesTheOneInTheConversationBeingRead() {
        val filler = (1..200).map { "Filler line number $it is here." to "Dolgu satırı $it." }
        val memory = memory(*(listOf("What, they're coming here?" to "Buraya mı geliyorlar?") + filler + listOf(
            "Oh, the guy who is connected to people?" to "Bağlantılı adam mı?",
            "What, they're coming here?" to "Ne, buraya mı geliyorlar?",
        )).toTypedArray())
        // Nothing read yet: two translations, none taken.
        assertNull(memory.find("What, they're coming here?"))
        assertNotNull(memory.findExact("Oh, the guy who is connected to people?"))
        val match = requireNotNull(memory.find("What, they're coming here?"))
        assertEquals("Ne, buraya mı geliyorlar?", match.target)
        assertEquals("context_exact", match.matchType)
        // A line read meanwhile far from both (another OCR area: a tip top left)
        // does not undo it: the conversation is still placed by the line before.
        assertNotNull(memory.findExact("Filler line number 100 is here."))
        assertEquals("Ne, buraya mı geliyorlar?", memory.find("What, they're coming here?")?.target)
    }

    @Test fun withoutAnyLineReadNearbyTwoTranslationsStayUndecided() {
        val filler = (1..200).map { "Filler line number $it is here." to "Dolgu satırı $it." }
        val memory = memory(*(listOf("Collect your cash today" to "Paranı bugün al") + filler +
            listOf("Collect your cash today" to "Bugün paranı topla")).toTypedArray())
        assertNotNull(memory.findExact("Filler line number 100 is here."))
        assertNull(memory.find("Collect your cash today"))
    }

    @Test fun rowsThatDifferOnlyInPunctuationAreOneLine() {
        val memory = memory("Watch out!" to "Dikkat et!", "Watch out." to "Dikkat et.", "Watch out..." to "Dikkat et…")
        assertEquals("Dikkat et.", memory.findExact("Watch out.")?.target)
        assertEquals("Dikkat et!", memory.findExact("Watch out!")?.target)
        assertEquals("Dikkat et…", memory.find("Watch out…")?.target)
        assertEquals("exact", memory.find("Watch out")?.matchType)
    }

    @Test fun withoutAConversationTheTranslationMostRowsGiveIsShown() {
        // The pack: seven "Oh shit" rows, four "Hassiktir", two "Kahretsin" (24 Nov).
        val memory = memory("Oh, shit!" to "Hassiktir!", "Oh shit," to "Hassiktir,", "Oh shit..." to "Kahretsin...",
            "Oh shit…" to "Hassiktir...", "Oh shit." to "Hassiktir.", "Oh! Shit." to "Kahretsin.",
            "Got it." to "Anladım.", "Got it!" to "Tamam!")
        val match = requireNotNull(memory.find("Oh shit..."))
        assertEquals("common_exact", match.matchType)
        assertEquals("Hassiktir...", match.target)
        assertEquals("Hassiktir!", memory.find("Oh, shit!")?.target)
        assertEquals("Hassiktir!", memory.findQuick("Oh, shit!")?.target)
        // One row each: no translation leads, none taken.
        assertNull(memory.find("Got it."))
        // The end of a longer line read alone is no line of its own.
        assertNull(memory.find("oh shit."))
    }

    @Test fun aTinyScrapMatchesAPackLabelOnlyWithItsCapitals() {
        val memory = memory("SG" to "ŞUTÖR GARD", "No." to "Hayır.")
        assertNull(memory.findExact("sg"))
        assertNull(memory.find("sg"))
        assertEquals("ŞUTÖR GARD", memory.findExact("SG")?.target)
        assertEquals("Hayır.", memory.findExact("No.")?.target)
    }

    @Test fun sceneScrapsBeforeASpeakerLabelAreNotPartOfTheName() {
        val memory = memory("'Cause they're gonna help us!" to "Çünkü bize yardım edecekler!",
            "He looks after his people," to "Adamlarına sahip çıkar,")
        assertEquals("Lucia", memory.find("AYHO Lucia: 'Cause they're gonna help us!")?.speaker)
        assertEquals("Lucia", memory.find("AYHO A Lucia: 'Cause they're gonna help us!")?.speaker)
        assertEquals("Mattia", memory.find("M Mattia: He looks after his people,")?.speaker)
        assertEquals("Final Chapter", memory.find("Final Chapter: He looks after his people,")?.speaker)
    }

    @Test fun aLoneWordIsNeverUndoneIntoAnotherWord() {
        // The log: the sign "NOW LEAVING" read as "SLAVING" was covered with "Kaydediliyor".
        val memory = memory("Saving" to "Kaydediliyor", "Farmfix" to "Farmfix")
        assertNull(memory.findQuick("SLAVING"))
        assertNull(memory.findQuick("FARMFIDX"))
    }

    @Test fun aWordOcrSplitsThatThePackWritesJoinedStillMatchesExactly() {
        val source = "Good work covering with Brian b4. Were in this 2gether remember that! Lefta taste of the profits 4u in yr mailbox."
        val memory = memory(source to "Az önce Brian'la yaptığın iş harikaydı.")
        val match = requireNotNull(memory.findQuick(source.replace("Lefta", "Left a")))
        assertEquals("spacing_exact", match.matchType)
    }
}
