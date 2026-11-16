package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File

class TranslationCacheRepositoryTest {
    @get:Rule val temp = TemporaryFolder()
    private val now = 100_000L
    private fun repository(name: String) = TranslationCacheRepository(File(temp.root, name), clock = { now })
    private fun backup(repository: TranslationCacheRepository): File {
        val file = temp.newFile()
        file.outputStream().use(repository::export)
        return file
    }

    @Test fun backupRoundTripPreservesUnicodeLanguageProviderAndDateWithoutCredentials() {
        val source = repository("source")
        source.deepL.put("en", "tr", "hello", "Merhaba\nÇıkış şu köşede.")
        source.gemini.put("en", "ar", "hello", "مرحبا بك")
        File(temp.root, "source/gemini_api_key").writeText("credential-must-never-be-exported")
        val file = backup(source)
        assertFalse(file.readText().contains("credential-must-never-be-exported"))
        assertTrue(file.readText().contains(GeminiClient.MODEL))
        val target = repository("target")
        assertEquals(2, target.preview(file).valid)
        assertNull(target.deepL.get("en", "tr", "hello")) // Preview is read-only.
        target.importFile(file)
        assertEquals("Merhaba\nÇıkış şu köşede.", target.deepL.get("en", "tr", "hello"))
        assertEquals("مرحبا بك", target.gemini.get("en", "ar", "hello"))
        assertNull(target.deepL.get("en", "ar", "hello"))
        assertEquals(now, target.gemini.snapshot().single().at)
        val reopened = TranslationCacheRepository(File(temp.root, "target"), clock = { now })
        assertEquals("مرحبا بك", reopened.gemini.get("en", "ar", "hello"))
    }

    @Test fun newestDuplicateWinsAndImportDoesNotOverwritePolicyOrResetAge() {
        val source = repository("source")
        source.deepL.put("en", "tr", "hello", "Older incoming")
        val file = backup(source)
        val row = file.readLines()[1]
        file.appendText("$row\n")
        val target = TranslationCacheRepository(File(temp.root, "target"),
            TranslationCachePolicy(1000, 30, 4), clock = { now + 1 })
        target.deepL.put("en", "tr", "hello", "Newer existing")
        val report = target.importFile(file)
        assertEquals(1, report.valid)
        assertEquals(1, report.duplicates)
        assertEquals("Newer existing", target.deepL.get("en", "tr", "hello"))
        assertEquals(TranslationCachePolicy(1000, 30, 4), target.policy)
        assertEquals(now + 1, target.deepL.snapshot().single().at)
    }

    @Test fun corruptedLateRowOrUnknownModelCannotPartiallyImportAnEarlierValidRow() {
        val source = repository("source")
        source.deepL.put("en", "tr", "new", "Incoming")
        source.gemini.put("en", "tr", "gemini", "Gemini incoming")
        val file = backup(source)
        val valid = file.readText()
        val target = repository("target")
        target.deepL.put("en", "tr", "old", "Existing")
        for (bad in listOf(valid + "not json\n", valid.replace(GeminiClient.MODEL, "wrong-model"))) {
            file.writeText(bad)
            assertThrows(Exception::class.java) { target.importFile(file) }
            assertNull(target.deepL.get("en", "tr", "new"))
            assertEquals("Existing", target.deepL.get("en", "tr", "old"))
            assertTrue(target.gemini.snapshot().isEmpty())
        }
    }

    @Test fun clearIsProviderSpecificAndWorksAfterRestartWithoutTouchingKeys() {
        val target = repository("target")
        target.deepL.put("en", "tr", "hello", "DeepL")
        target.gemini.put("en", "tr", "hello", "Gemini")
        val secret = File(temp.root, "target/gemini_api_key").apply { writeText("private-key") }
        target.clear("deepl")
        assertNull(target.deepL.get("en", "tr", "hello"))
        assertEquals("Gemini", target.gemini.get("en", "tr", "hello"))
        val reopened = repository("target")
        assertNull(reopened.deepL.get("en", "tr", "hello"))
        assertEquals("Gemini", reopened.gemini.get("en", "tr", "hello"))
        assertEquals("private-key", secret.readText())
    }

    @Test fun reducingByteBudgetCompactsExistingLargeFileInsteadOfDiscardingIt() {
        val target = repository("target")
        val file = File(temp.root, "target/deepl_translations_v1.jsonl")
        file.parentFile!!.mkdirs()
        val text = "Çeviri " + "ç".repeat(500)
        file.bufferedWriter().use { writer -> repeat(6000) { index ->
            writer.write(DeepLTranslationCache.Entry("en", "tr", "line $index", text, now).json().toString())
            writer.newLine()
        } }
        assertTrue(file.length() > 4L * 1024 * 1024)
        target.configure(TranslationCachePolicy(20000, 90, 4))
        assertTrue(file.length() in 1..4L * 1024 * 1024)
        assertEquals(text, target.deepL.get("en", "tr", "line 5999"))
        assertNull(target.deepL.get("en", "tr", "line 0"))
        val reopened = TranslationCacheRepository(File(temp.root, "target"), target.policy, clock = { now })
        assertEquals(text, reopened.deepL.get("en", "tr", "line 5999"))
    }

    @Test fun changingCountAndAgeBoundsThenRestoringDefaultsDoesNotDeleteFreshRows() {
        var clock = now
        val target = TranslationCacheRepository(File(temp.root, "target"), clock = { clock })
        repeat(1200) { target.deepL.put("en", "tr", "line $it", "Çeviri $it") }
        target.configure(TranslationCachePolicy(1000, 7, 4))
        assertEquals(1000, target.deepL.snapshot().size)
        assertNull(target.deepL.get("en", "tr", "line 0"))
        clock += 8L * 24 * 60 * 60 * 1000
        target.gemini.put("en", "tr", "fresh", "Fresh")
        target.configure(TranslationCachePolicy(1000, 14, 4))
        target.configure(TranslationCachePolicy())
        assertEquals("Fresh", target.gemini.get("en", "tr", "fresh"))
        assertEquals(TranslationCachePolicy(), target.policy)
    }

    @Test fun strictBackupRejectsDuplicateFieldsUnknownSecretFieldsAndInvalidLanguages() {
        val source = repository("source")
        source.deepL.put("en", "tr", "hello", "Merhaba")
        val valid = backup(source).readText()
        val bad = listOf(
            valid.replace("\"provider\":\"deepl\"", "\"provider\":\"deepl\",\"provider\":\"gemini\""),
            valid.replace("\"source\":\"en\"", "\"source\":\"invalid_language\""),
            valid.trimEnd() + " trailing",
            valid.replace("\"target\":\"tr\"", "\"target\":\"tr\",\"apiKey\":\"private\""),
            valid.replace("\"version\":1", "\"version\":2"),
        )
        for (text in bad) assertThrows(Exception::class.java) {
            TranslationCacheBackup.scan(ByteArrayInputStream(text.toByteArray()), now, TranslationCachePolicy().maxAgeMs)
        }
    }

    @Test fun expiredAndFutureRowsAreSkippedWithoutExtendingTheirTimestamps() {
        val source = repository("source")
        source.deepL.put("en", "tr", "hello", "Merhaba")
        val file = backup(source)
        val bytes = file.readBytes()
        val day = 24L * 60 * 60 * 1000
        assertEquals(1, TranslationCacheBackup.scan(ByteArrayInputStream(bytes), now + 91 * day, 90 * day).expired)
        assertEquals(1, TranslationCacheBackup.scan(ByteArrayInputStream(bytes), now - 1, 90 * day).expired)
        assertEquals(0, TranslationCacheBackup.scan(ByteArrayInputStream(bytes), now - 1, 90 * day).valid)
    }

    @Test fun interruptedAtomicReplacementRecoversPreviousPaidCache() {
        val file = File(temp.root, "paid.jsonl")
        DeepLTranslationCache(file).put("en", "tr", "hello", "Merhaba")
        assertTrue(file.renameTo(File(temp.root, "paid.jsonl.bak")))
        File(temp.root, "paid.jsonl.tmp").writeText("interrupted data")
        assertEquals("Merhaba", DeepLTranslationCache(file).get("en", "tr", "hello"))
    }

    @Test fun policyRejectsOutOfRangeFractionalAndMissingValues() {
        for (map in listOf(
            mapOf("maxEntries" to 50001, "days" to 90, "maxMiB" to 16),
            mapOf("maxEntries" to 20000, "days" to 181, "maxMiB" to 16),
            mapOf("maxEntries" to 20000, "days" to 90, "maxMiB" to 33),
            mapOf("maxEntries" to 20000.5, "days" to 90, "maxMiB" to 16),
            emptyMap<String, Int>(),
        )) assertThrows(Exception::class.java) { TranslationCachePolicy.fromMap(map) }
    }

    @Test fun developerContributionIsABoundedRecentSampleAndLeavesFullBackupUnchanged() {
        val source = repository("contribution")
        source.deepL.replace((0..6000).map { index ->
            DeepLTranslationCache.Entry("en", "tr", "line $index", "Çeviri $index", now - index)
        })
        source.gemini.put("en", "ar", "greeting", "مرحبا")
        File(temp.root, "contribution/gemini_api_key").writeText("secret-must-not-be-shared")
        val output = ByteArrayOutputStream()
        assertEquals(5000, source.contribution(output))
        assertTrue(output.size() <= 5L * 1024 * 1024)
        assertFalse(output.toString("UTF-8").contains("secret-must-not-be-shared"))
        val rows = mutableListOf<TranslationCacheBackup.Row>()
        val report = TranslationCacheBackup.scan(ByteArrayInputStream(output.toByteArray()), now, source.policy.maxAgeMs, rows::add)
        assertEquals(5000, report.valid)
        assertTrue(rows.any { it.provider == "gemini" && it.entry.target == "ar" })
        assertTrue(rows.none { it.entry.key == "line 6000" })
        assertEquals(6001, source.deepL.snapshot().size)
        assertEquals(6002, source.preview(backup(source)).valid)
    }

    @Test fun largeContributionUsesWholeRowsWithinEmailByteLimitAndEmptyCacheIsHarmless() {
        val source = repository("large-contribution")
        source.deepL.replace((0..999).map { index ->
            DeepLTranslationCache.Entry("en", "tr", "line $index", "ç".repeat(4000), now)
        })
        val output = ByteArrayOutputStream()
        val count = source.contribution(output)
        assertTrue(count in 1..999)
        assertTrue(output.size() <= 5L * 1024 * 1024)
        assertEquals(count, TranslationCacheBackup.scan(ByteArrayInputStream(output.toByteArray()), now, source.policy.maxAgeMs).valid)
        val empty = repository("empty")
        val emptyOutput = ByteArrayOutputStream()
        assertEquals(0, empty.contribution(emptyOutput))
        assertEquals(0, TranslationCacheBackup.scan(ByteArrayInputStream(emptyOutput.toByteArray()), now, empty.policy.maxAgeMs).valid)
    }
}
