package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class GameSubtitleEventTest {
    private val memory = GameTranslationMemory.parse("display-test", "en", "tr",
        requireNotNull(javaClass.getResourceAsStream("/game-json-display.json"))
            .bufferedReader().use { it.readText() })

    @Test fun jsonMatchReachesTheDisplayEventWithNamesTurkishCharactersAndNewlines() {
        val match = requireNotNull(memory.find("Sweet: We should leave before nightfall."))
        val event = subtitleTextEvent(0, match.target, "none", match)
        assertEquals("Sweet: Gece çökmeden gitmeliyiz.\nÇıkış şu köşede.", event["text"])
        assertEquals("Sweet", event["speaker"])
        assertEquals("game_memory", event["translationEngine"])
        assertEquals("subtitleText", event["type"])
        assertEquals(0, event["regionIndex"])
        assertEquals("dialogue-sweet", (event["translationMemory"] as Map<*, *>)["id"])
        assertFalse(event.toString().contains("ai_draft"))
    }

    @Test fun aSpeakerIsAddedOnceAndObjectivesGetNoInventedName() {
        val match = requireNotNull(memory.find("Isabella: Watch the entrance to the house."))
        assertEquals("Isabella: Evin girişini gözetle.", subtitleTextEvent(0, match.target, "none", match)["text"])
        assertEquals("Isabella: Evin girişini gözetle.",
            subtitleTextEvent(0, "Isabella: Evin girişini gözetle.", "none", match)["text"])
        val objective = requireNotNull(memory.find("Reach the old warehouse."))
        val event = subtitleTextEvent(1, objective.target, "none", objective)
        assertEquals("Eski depoya ulaş.", event["text"])
        assertFalse(event.containsKey("speaker"))
        assertEquals(1, event["regionIndex"])
    }

    @Test fun liveTranslationOutputKeepsItsExistingEngineAndText() {
        val event = subtitleTextEvent(0, "Canlı çeviri sonucu.", "hplt")
        assertEquals("Canlı çeviri sonucu.", event["text"])
        assertEquals("hplt", event["translationEngine"])
        assertFalse(event.containsKey("translationMemory"))
    }
}
