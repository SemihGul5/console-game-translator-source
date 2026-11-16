package com.abrebostudio.consolegametranslator

import org.json.JSONObject
import org.json.JSONArray
import org.junit.Assert.*
import org.junit.Test
import kotlin.random.Random

class GameTranslationMemoryTest {
    @Test fun newFormatMatchesEnglishToThaiIndonesianAndArabic() {
        for ((target, text) in mapOf("th" to "มานี่!", "id" to "Kemarilah!", "ar" to "تعال إلى هنا!")) {
            val json = JSONObject().put("schemaVersion", 2).put("game", "test-game").put("source", "en").put("target", target)
                .put("entries", JSONArray().put(JSONObject().put("id", "1").put("sourceText", "Come here!").put("targetText", text)))
            val memory = GameTranslationMemory.parse("test-game", "en", target, json.toString())
            assertEquals(text, memory.find("Come here!")?.target)
            try {
                GameTranslationMemory.parse("test-game", "en", "tr", json.toString())
                fail("wrong target accepted")
            } catch (_: IllegalArgumentException) { }
        }
    }
    @Test fun oneCompletelyUnreadableWordUsesUniqueSurroundingJsonContext() {
        val memory = memory("Please open the northern gate." to "Lütfen kuzey kapısını aç.")
        val match = requireNotNull(memory.find("Please open the qzxvzz gate."))
        assertEquals("Lütfen kuzey kapısını aç.", match.target)
        assertEquals("one_word_context", match.matchType)
        val sequence = memory("We blocked in! Damn!" to "Sıkıştık! Hay aksi!")
        assertEquals("Sıkıştık! Hay aksi!", sequence.find("We blocked in! qzxvzz")?.target)
    }

    @Test fun unreadableWordCannotChooseBetweenDifferentTranslationsOrEraseMeaning() {
        val memory = memory("Place the heavy box outside." to "Ağır kutuyu dışarı koy.",
            "Place the small box outside." to "Küçük kutuyu dışarı koy.")
        assertNull(memory.find("Place the qzxvzz box outside."))
        assertNull(memory("Please do not open the gate." to "Lütfen kapıyı açma.")
            .find("Please do qzxvzz open the gate."))
        assertNull(memory("Please do not open the gate." to "Lütfen kapıyı açma.",
            "Please do always open the gate." to "Lütfen kapıyı hep aç.")
            .find("Please do qzxvzz open the gate."))
        assertNull(memory("Bring 15 boxes to the northern gate." to "Kuzey kapısına 15 kutu getir.")
            .find("Bring 16 boxes to the qzxvzz gate."))
    }

    @Test fun completelyWrongKnownWordCanUseFourExactNeighboursButCannotGuessBetweenRows() {
        val memory = memory("Please open the northern gate." to "Lütfen kuzey kapısını aç.",
            "Coffee is ready." to "Kahve hazır.")
        assertEquals("Lütfen kuzey kapısını aç.", memory.find("Please open the coffee gate.")?.target)
        assertNull(memory("Please open the northern gate." to "Kuzey kapısını aç.",
            "Please open the southern gate." to "Güney kapısını aç.",
            "Coffee is ready." to "Kahve hazır.").find("Please open the coffee gate."))
        assertNull(memory("Please never open the northern gate." to "Kuzey kapısını asla açma.",
            "Coffee is ready." to "Kahve hazır.").find("Please coffee open the northern gate."))
    }

    @Test fun inlineSpeakerRowsWorkWithoutAnUnlabelledDuplicate() {
        val memory = GameTranslationMemory.parse("test-game", "en", "tr", """{
          "game":"test-game","source":"en","target":"tr","speakers":{"Isabella":"Isabella"},
          "entries":[{"id":"1","english":"Isabella: We should leave this place.",
             "turkish":"Isabella: Buradan gitmeliyiz."}]}""")
        for (label in listOf("ISABELLA", "1sabella")) {
            val match = requireNotNull(memory.find("$label: We should leave this place."))
            assertEquals("Isabella: Buradan gitmeliyiz.", subtitleTextEvent(0, match.target, "game_memory", match)["text"])
            assertNotNull(memory.findExact("$label: We should leave this place."))
        }
    }

    @Test fun engineTimingDirectivesAreNotVisibleTextOrConflictingTranslations() {
        val memory = memory("Please open [delay:-1.3]the northern gate." to "Lütfen [delay:-1.3]kuzey kapısını aç.",
            "Please open the northern gate." to "Lütfen kuzey kapısını aç.")
        assertEquals("Lütfen kuzey kapısını aç.", memory.findExact("Please open the northern gate.")?.target)
    }

    @Test fun aCachedFuzzyHitCannotMasqueradeAsAnExactOcrBlock() {
        val memory = memory("Secure northern window." to "Kuzey penceresini koru.")
        assertNotNull(memory.find("Secvre northerm windov."))
        assertNull(memory.findExact("Secvre northerm windov."))
        assertNotNull(memory.findExact("Secure northern window."))
    }

    @Test fun rootSpeakerDictionaryWorksWithoutPerEntrySpeakersAndCorrectsOcrLabels() {
        val json = """{"game":"test-game","source":"en","target":"tr",
          "speakers":{"Michael":"Michael","Trevor":"Trevor","Isabella":"Isabella"},
          "entries":[{"id":"1","english":"We should leave this place.","turkish":"Buradan gitmeliyiz."}]}"""
        val memory = GameTranslationMemory.parse("test-game", "en", "tr", json)
        for ((label, canonical) in listOf("MICHAEL" to "Michael", "Trev0r" to "Trevor", "1sabella" to "Isabella")) {
            val match = requireNotNull(memory.find("$label: We should leave this place."))
            assertEquals("Buradan gitmeliyiz.", match.target)
            assertEquals(canonical, match.speaker)
        }
    }

    @Test fun shortCompleteJsonLinesAreImmediateButShortFuzzyGuessesRemainForbidden() {
        val memory = memory("Go!" to "Git!", "Come on!" to "Hadi!", "Yes." to "Evet.")
        assertEquals("Git!", memory.find("Go!")?.target)
        assertEquals("Hadi!", memory.find("Come on!")?.target)
        assertEquals("Evet.", memory.findExact("Yes.")?.target)
        assertNull(memory.find("G0!"))
        assertNull(memory.find("Corn on!"))
    }

    @Test fun identicalStandaloneAndAlignedSentenceOutputsAreNotFalseAmbiguities() {
        val memory = memory("We should leave now." to "Hemen gitmeliyiz.",
            "We should leave now. Get in the car." to "Hemen gitmeliyiz. Arabaya bin.")
        assertEquals("Hemen gitmeliyiz.", memory.find("We should leave now.")?.target)
    }

    @Test fun nearbySpellingsWithTheSameTurkishOutputDoNotCreateFalseFuzzyAmbiguity() {
        val memory = memory("Come here I wanna show you something." to "Buraya gel, sana bir şey göstereyim.",
            "Come here, I want to show you something." to "Buraya gel, sana bir şey göstereyim.")
        assertEquals("Buraya gel, sana bir şey göstereyim.", memory.find("Come here I wanna seow you something.")?.target)
    }

    @Test fun jsonObjectiveEntriesAreIndexedAndSpeakerMetadataSurvives() {
        val json = """{
          "game":"test-game","source":"en","target":"tr",
          "speakers":{"Sweet":"Sweet","Isabella":"Isabella"},
          "entries":[
            {"id":"objective-01","english":"Reach the old warehouse.","turkish":"Eski depoya ulaş."},
            {"id":"dialogue-01","english":"We should leave this place.","turkish":"Buradan gitmeliyiz.",
             "speaker":"Sweet","chapter":"I","kind":"dialogue"}
          ]
        }"""
        val memory = GameTranslationMemory.parse("test-game", "en", "tr", json)
        assertEquals(2, memory.entryCount)
        assertEquals("Eski depoya ulaş.", memory.find("Reach the old warehouse.")?.target)
        val dialogue = requireNotNull(memory.find("Sweet: We should leave this place."))
        assertEquals("Sweet", dialogue.speaker)
        assertEquals("dialogue-01", dialogue.entryId)
        assertEquals("I", dialogue.chapter)
        assertEquals("dialogue", dialogue.kind)
    }

    @Test fun malformedJsonEntriesCannotBeSilentlySkipped() {
        val base = JSONObject().put("game", "test-game").put("source", "en").put("target", "tr")
        val entry = JSONObject().put("id", "1").put("english", "Reach the old warehouse.")
            .put("turkish", "Eski depoya ulaş.")
        for (entries in listOf(JSONArray(), JSONArray().put(entry).put(entry),
                JSONArray().put(JSONObject(entry.toString()).put("english", 1)),
                JSONArray().put(JSONObject(entry.toString()).put("turkish", "")))) {
            assertThrows(Exception::class.java) {
                GameTranslationMemory.parse("test-game", "en", "tr", base.put("entries", entries).toString())
            }
        }
        assertThrows(Exception::class.java) {
            GameTranslationMemory.parse("test-game", "tr", "en", base.toString())
        }
    }

    private fun memory(vararg rows: Pair<String, String>): GameTranslationMemory {
        val entries = rows.mapIndexed { index, (source, target) -> JSONObject()
            .put("id", "$index").put("english", source).put("turkish", target)
        }
        return GameTranslationMemory.parse("test-game", "en", "tr", JSONObject()
            .put("game", "test-game").put("source", "en").put("target", "tr")
            .put("entries", JSONArray(entries)).toString())
    }

    @Test fun omittedNegationCannotSelectOppositeMeaning() {
        val memory = memory("You must not open the northern gate." to "Kuzey kapısını açmamalısın.")
        assertNull(memory.find("You must open the northern gate."))
        assertNotNull(memory.find("You must not open the northern gate."))
    }

    @Test fun addedNegationCannotSelectPositiveMeaning() {
        assertNull(memory("You must open the northern gate." to "Kuzey kapısını açmalısın.")
            .find("You must not open the northern gate."))
    }

    @Test fun contractionsAreProtectedEvenWhenOcrSplitsTheApostrophe() {
        val memory = memory("You don't have to stay in this room." to "Bu odada kalmak zorunda değilsin.")
        assertNull(memory.find("You do have to stay in this room."))
        assertNotNull(memory.find("You don t have to stay in this room."))
        assertNotNull(memory.find("You don’thave to stay in this room."))
        assertNotNull(memory("What about your cousin? Doesn't she take photographs?" to
            "Kuzenin ne olacak? O fotoğraf çekmiyor mu?").find("What about your cousin? Doeen't she take photographs?"))
        assertNotNull(memory("This can't be right." to "Bu doğru olamaz.").find("Thiscan’t be right."))
        assertNotNull(memory.find("You doe’t have to stay in this room."))
    }

    @Test fun changedNumbersCannotMatchButOtherOcrTyposWithTheSameNumberCan() {
        val memory = memory("Bring 15 fuel cans to the northern camp." to "Kuzey kampına 15 yakıt bidonu getir.")
        assertNull(memory.find("Bring 16 fuel cans to the northern camp."))
        assertNotNull(memory.find("Bring 15 fuel cans to the northem camp."))
    }

    @Test fun alignedSentenceNeverRevealsLaterSentences() {
        val memory = memory("Open the heavy northern gate. Wait for me at the tower." to
            "Kuzeydeki ağır kapıyı aç. Kulede beni bekle.")
        val match = requireNotNull(memory.find("Open the heavy northern gate. Wait for me"))
        assertEquals("Kuzeydeki ağır kapıyı aç.", match.target)
        assertFalse(match.target.contains("bekle"))
    }

    @Test fun unalignedParentCannotBeReturnedForAVisibleFragment() {
        val memory = memory("Open the heavy northern gate. Wait for me at the tower." to
            "Kuzey kapısını açıp kulede beni bekle.")
        assertNull(memory.find("Open the heavy northern gate."))
    }

    @Test fun contradictoryVariantsAreRejectedRatherThanChosenBySessionRandomness() {
        assertNull(memory("Open the northern gate." to "Kuzey kapısını aç.",
            "Open the northern gate." to "Kuzey kapısını açma.").find("Open the northern gate."))
    }

    @Test fun repeatedLocalisationIdsWithTheSameTranslationStillResolve() {
        val memory = memory("Vehicle Wrecked" to "Araç Hurdaya Döndü",
            "Vehicle Wrecked" to "Araç Hurdaya Döndü")
        assertEquals(2, memory.entryCount)
        assertEquals("Araç Hurdaya Döndü", memory.find("Vehicle Wrecked")?.target)
    }

    @Test fun characterIndexRecoversQueriesWhoseEveryWordHasAnOcrTypo() {
        assertNotNull(memory("Secure northern window." to "Kuzey penceresini emniyete al.")
            .find("Secvre northerm windov."))
    }

    @Test fun fuzzyIndexesKeepDistantRecordsReachableInLargeDictionaries() {
        val rows = listOf("Secure southern doorway." to "Güneydeki girişi koru.") +
            (1..400).map { "Open storage compartment number $it." to "$it numaralı depoyu aç." } +
            listOf("Secure northern window." to "Kuzey penceresini emniyete al.")
        assertEquals("Kuzey penceresini emniyete al.",
            memory(*rows.toTypedArray()).find("Secvre northerm windov.")?.target)
    }

    @Test fun softHyphensAndCurlyApostrophesDoNotBreakExactMatching() {
        val memory = memory("Don't open the blue gateway." to "Mavi geçidi açma.")
        assertEquals("exact", memory.find("Don’t open the blue gate\u00adway.")?.matchType)
    }

    @Test fun joinedOcrWordsStillPreferJsonWithoutRevealingTheNextSentence() {
        assertEquals("spacing_exact", memory("Come, stay a while." to "Gel, biraz kal.").find("Come, staya while.")?.matchType)
        val memory = memory("Open the heavy northern gate. Wait for me at the tower." to
            "Kuzeydeki ağır kapıyı aç. Kulede beni bekle.")
        val match = requireNotNull(memory.find("Open theheavy northern gate."))
        assertEquals("Kuzeydeki ağır kapıyı aç.", match.target)
        assertEquals("spacing_exact", match.matchType)
    }

    @Test fun ambiguousWordJoinsAreNotResolvedByGuessing() {
        assertNull(memory("Watch the man." to "Adamı izle.", "Watch them an." to "Diğer kaydı izle.")
            .find("Watch theman."))
    }

    @Test fun optimizedDistanceHasTheSameResultsAsAnIndependentMatrixReference() {
        val method = GameTranslationMemory.Companion.javaClass.declaredMethods.single {
            it.name == "editDistance" && it.parameterCount == 3
        }.apply { isAccessible = true }
        fun reference(left: String, right: String): Int {
            val grid = Array(left.length + 1) { IntArray(right.length + 1) }
            for (i in 0..left.length) grid[i][0] = i
            for (j in 0..right.length) grid[0][j] = j
            for (i in 1..left.length) for (j in 1..right.length) grid[i][j] = minOf(
                grid[i - 1][j] + 1, grid[i][j - 1] + 1,
                grid[i - 1][j - 1] + if (left[i - 1] == right[j - 1]) 0 else 1)
            return grid[left.length][right.length]
        }
        val random = Random(91)
        repeat(300) {
            val left = (0 until random.nextInt(1, 16)).map { "abcde"[random.nextInt(5)] }.joinToString("")
            val right = (0 until random.nextInt(1, 16)).map { "abcde"[random.nextInt(5)] }.joinToString("")
            val expected = reference(left, right)
            for (limit in 0..maxOf(left.length, right.length)) {
                val actual = method.invoke(GameTranslationMemory.Companion, left, right, limit) as Int
                if (expected <= limit) assertEquals("$left / $right / $limit", expected, actual)
                else assertTrue(actual > limit)
            }
        }
    }
}
