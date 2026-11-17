package com.abrebostudio.consolegametranslator

import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/** Curated, literal OCR repairs. No edit-distance guesses, learned names or network requests. */
internal class OcrCorrectionTable private constructor(private val languages: Map<String, Language>) {
    data class Result(val text: String, val replacements: Int = 0)

    private data class Rule(
        val from: List<String>, val to: String, val caseSensitive: Boolean,
        val previous: Regex?, val next: Regex?,
    ) {
        fun replacement(matched: String): String {
            if (caseSensitive) return to
            val letters = matched.filter(Char::isLetter)
            return when {
                letters.isNotEmpty() && letters.all(Char::isUpperCase) -> to.uppercase(Locale.ROOT)
                matched.firstOrNull()?.isUpperCase() == true -> to.replaceFirstChar { it.titlecase(Locale.ROOT) }
                else -> to
            }
        }
    }

    private class Language(val rules: List<Rule>) {
        val exact = mutableMapOf<String, Rule>()
        val folded = mutableMapOf<String, Rule>()
        val pattern: Regex
        init {
            val alternatives = mutableListOf<Pair<String, Boolean>>()
            rules.forEach { rule -> rule.from.forEach { from ->
                require(exact.none { (old, _) -> old.equals(from, !rule.caseSensitive) } &&
                    !folded.containsKey(from.lowercase(Locale.ROOT))) { "Overlapping OCR correction: $from" }
                if (rule.caseSensitive) exact[from] = rule else folded[from.lowercase(Locale.ROOT)] = rule
                alternatives.add(from to rule.caseSensitive)
            } }
            val choices = alternatives.sortedByDescending { it.first.length }.joinToString("|") { (from, sensitive) ->
                if (sensitive) Regex.escape(from) else "(?i:${Regex.escape(from)})"
            }
            // Apostrophes inside contractions are word boundaries only when they quote a word.
            // Otherwise Ill inside I'Ill would turn into I'I'll instead of repairing the whole token.
            pattern = Regex("(?<!$WORD)(?<!$WORD')(?:$choices)(?!$WORD)(?!'$WORD)")
        }
    }

    fun correct(text: String, source: String, gameSelected: Boolean, gameLookupMiss: Boolean = false): Result {
        if ((gameSelected && !gameLookupMiss) || text.isBlank() || text.length > MAX_INPUT) return Result(text)
        val language = languages[source.substringBefore('-').lowercase(Locale.ROOT)] ?: return Result(text)
        // Canonical apostrophes preserve character offsets; untouched text stays byte-for-byte the same.
        val searchable = canonical(text)
        val protected = PROTECTED.findAll(searchable).map { it.range }.toList()
        var cursor = 0
        var changes = 0
        val output = StringBuilder(text.length)
        for (match in language.pattern.findAll(searchable)) {
            if (protected.any { match.range.first <= it.last && match.range.last >= it.first }) continue
            val rule = language.exact[match.value] ?: language.folded[match.value.lowercase(Locale.ROOT)] ?: continue
            if (rule.previous != null && !rule.previous.containsMatchIn(searchable.substring(0, match.range.first))) continue
            if (rule.next != null && !rule.next.containsMatchIn(searchable.substring(match.range.last + 1))) continue
            val replacement = rule.replacement(match.value).let { repaired ->
                // Remove a listed stray apostrophe, while retaining a real paired opening quote.
                if (match.value.startsWith("'") && !repaired.startsWith("'") &&
                    CLOSING_QUOTE.containsMatchIn(searchable.substring(match.range.last + 1))) "'$repaired" else repaired
            }
            output.append(text, cursor, match.range.first).append(replacement)
            cursor = match.range.last + 1
            changes++
        }
        if (changes == 0) return Result(text)
        output.append(text, cursor, text.length)
        return Result(output.toString(), changes)
    }

    companion object {
        const val ASSET_PATH = "ocr/ocr_corrections.v1.json"
        val EMPTY = OcrCorrectionTable(emptyMap())
        private const val MAX_INPUT = 8_192
        private const val WORD = "[\\p{L}\\p{M}\\p{N}_]"
        private val SPACES = Regex("\\s+")
        private val CLOSING_QUOTE = Regex("(?<=\\S)'(?=$|[\\s.,!?…])")
        private val PROTECTED = Regex("(?:https?://|www\\.)\\S+|[\\p{L}\\p{N}_.+%-]+@[\\p{L}\\p{N}.-]+\\.[\\p{L}]{2,}", RegexOption.IGNORE_CASE)
        private fun canonical(text: String) = text.replace('’', '\'').replace('‘', '\'')

        fun parse(json: String): OcrCorrectionTable {
            require(json.length <= 262_144) { "OCR correction table is too large" }
            val root = JSONObject(json)
            keys(root, setOf("version", "languages"))
            require(root.opt("version") == 1) { "Unsupported OCR correction version" }
            val languages = root.getJSONObject("languages")
            require(languages.length() in 1..32) { "Invalid OCR correction languages" }
            var total = 0
            val parsed = mutableMapOf<String, Language>()
            languages.keys().forEach { code ->
                require(code.matches(Regex("[a-z]{2,3}"))) { "Use base language codes in the OCR table" }
                val rows = languages.getJSONArray(code)
                require(rows.length() in 1..512 && total + rows.length() <= 512) { "Invalid OCR correction count" }
                total += rows.length()
                val ids = mutableSetOf<String>()
                val rules = (0 until rows.length()).map { index ->
                    val row = rows.getJSONObject(index)
                    keys(row, setOf("id", "from", "to", "caseSensitive", "previous", "next"))
                    val id = string(row.opt("id"))
                    require(id.matches(Regex("[a-z0-9][a-z0-9_-]{0,63}")) && ids.add(id)) { "Invalid or duplicate OCR rule ID" }
                    val from = strings(row.getJSONArray("from")).map(::canonical)
                    val to = string(row.opt("to"))
                    require(from.none { it == canonical(to) }) { "OCR correction must change its input" }
                    val sensitive = if (row.has("caseSensitive")) row.get("caseSensitive").also {
                        require(it is Boolean) { "caseSensitive must be boolean" }
                    } as Boolean else true
                    fun context(field: String, before: Boolean): Regex? {
                        if (!row.has(field)) return null
                        val choices = strings(row.getJSONArray(field)).joinToString("|") { Regex.escape(canonical(it)) }
                        return Regex(if (before) "(?<!$WORD)(?:$choices)\\s+$" else "^\\s+(?:$choices)(?!$WORD)", RegexOption.IGNORE_CASE)
                    }
                    Rule(from, to, sensitive, context("previous", true), context("next", false))
                }
                parsed[code] = Language(rules)
            }
            return OcrCorrectionTable(parsed)
        }

        private fun keys(value: JSONObject, allowed: Set<String>) {
            require(value.keys().asSequence().all { it in allowed }) { "Unknown OCR correction field" }
        }
        private fun strings(values: JSONArray): List<String> {
            require(values.length() in 1..64) { "Invalid OCR variants/context count" }
            return (0 until values.length()).map { string(values.get(it)) }
        }
        private fun string(value: Any?): String {
            require(value is String && value.length in 1..80 && value == value.trim() &&
                value.none(Char::isISOControl) && SPACES.replace(value, " ") == value) { "Invalid OCR correction text" }
            return value
        }
    }
}
