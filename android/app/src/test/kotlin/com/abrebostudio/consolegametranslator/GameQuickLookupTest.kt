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

    @Test fun aWordOcrSplitsThatThePackWritesJoinedStillMatchesExactly() {
        val source = "Good work covering with Brian b4. Were in this 2gether remember that! Lefta taste of the profits 4u in yr mailbox."
        val memory = memory(source to "Az önce Brian'la yaptığın iş harikaydı.")
        val match = requireNotNull(memory.findQuick(source.replace("Lefta", "Left a")))
        assertEquals("spacing_exact", match.matchType)
    }
}
