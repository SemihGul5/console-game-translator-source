package com.abrebostudio.consolegametranslator

/** Shared output contract for the mobile overlay and TV subtitle forwarding. */
internal fun subtitleTextEvent(
    regionIndex: Int,
    translatedText: String,
    engine: String,
    match: GameTranslationMatch? = null,
): Map<String, Any?> {
    val speaker = match?.speaker?.trim()?.takeIf(String::isNotEmpty)
    val displayText = if (speaker == null || translatedText.trimStart().startsWith("$speaker:", ignoreCase = true)) {
        translatedText
    } else {
        "$speaker: $translatedText"
    }
    return buildMap {
        put("type", "subtitleText")
        put("text", displayText)
        put("regionIndex", regionIndex)
        put("translationEngine", if (match == null) engine else "game_memory")
        if (speaker != null) put("speaker", speaker)
        if (match != null) put("translationMemory", mapOf(
            "gameId" to match.gameId,
            "id" to match.entryId,
            "score" to match.score,
            "matchType" to match.matchType,
            "speaker" to speaker,
            "source" to match.source,
        ))
    }
}
