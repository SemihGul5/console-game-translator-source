package com.abrebostudio.consolegametranslator

/**
 * A subtitle split into its speaker label ("Final Chapter", "Lucia") and what
 * is said. A translation model is given only the words said: it turned the
 * name "Final Chapter" into "Son Bölüm" (24 Nov log). The label goes back in
 * front of the translation as the game shows it.
 */
internal class LabelledText(val label: String?, val body: String) {
    fun relabel(translated: String): String =
        if (label == null || translated.isBlank()) translated else "$label: ${translated.trim()}"
}

internal fun splitSpeakerLabel(text: String): LabelledText {
    val match = SPEAKER_LABEL.find(text) ?: return LabelledText(null, text)
    val words = match.groupValues[1].split(' ').filter(String::isNotEmpty).toMutableList()
    // A scrap of scene text read before the name ("AYHO Lucia:") is no part of it.
    while (words.size > 1 && words.first().let { first ->
            first.count(Char::isLetter) <= 1 || first.all { !it.isLetter() || it.isUpperCase() } }) words.removeAt(0)
    val label = words.joinToString(" ")
    val body = match.groupValues[2].trim()
    if (label.lowercase() in INTERFACE_LABELS || body.count(Char::isLetter) < 2) return LabelledText(null, text)
    return LabelledText(label, body)
}

/** One to three words, each starting with a capital, then ":" and the line. */
private val SPEAKER_LABEL = Regex("""^\s*(\p{Lu}[\p{L}\p{N}’'.-]*(?: \p{Lu}[\p{L}\p{N}’'.-]*){0,3}):\s+(.+)$""",
    RegexOption.DOT_MATCHES_ALL)

/** Labels that are words of the interface, translated with the line. */
private val INTERFACE_LABELS = setOf("tip", "note", "hint", "objective", "warning", "reward", "new", "goal", "task")

/**
 * [text] without the sender's name read in front of a phone message ("Burned
 * Man Hey, I'm back…" -> "Hey, I'm back…"); a contact icon read as a letter or
 * two before the name goes with it. Unchanged when the name is not at the start.
 */
internal fun withoutSenderName(text: String, sender: String): String {
    val at = text.indexOf(sender)
    if (at < 0 || at > MAX_SENDER_SCRAP) return text
    if (text.substring(0, at).any { it.isLetter() } && text.substring(0, at).trim().count(Char::isLetterOrDigit) > 2) return text
    val rest = text.substring(at + sender.length).trimStart(' ', ':', ',', '-', '·', '\n')
    return if (rest.count(Char::isLetter) >= 2) rest else text
}

private const val MAX_SENDER_SCRAP = 4
