package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

class DeepLTranslationEngineTest {
    @get:Rule val temporary = TemporaryFolder()
    private var requests = 0
    private val events = mutableListOf<String>()
    private fun client(key: String) = DeepLClient(key) { url ->
        requests++
        object : HttpURLConnection(url) {
            override fun connect() {}
            override fun disconnect() {}
            override fun usingProxy() = false
            override fun getResponseCode() = 200
            override fun getOutputStream() = ByteArrayOutputStream()
            override fun getInputStream() = ByteArrayInputStream(
                """{"translations":[{"text":"Merhaba","billed_characters":5}]}""".toByteArray())
        }
    }
    private fun engine(file: File) = DeepLTranslationEngine(DeepLTranslationCache(file),
        client = ::client, diagnostic = events::add)

    @Test fun onePaidCallIsSharedAcrossRegionsRestartsAndKeyRotation() {
        val file = File(temporary.root, "cache.jsonl")
        val first = engine(file)
        val key = deepLTextKey("Hello", "en")
        assertFalse(first.translate("en", "tr", key, "Hello", "private-key", 0).fromCache)
        assertTrue(first.translate("en", "tr", key, "Hello", "private-key", 1).fromCache)
        val restarted = engine(file)
        assertTrue(restarted.translate("en", "tr", key, "Hello", "new-private-key", 0).fromCache)
        assertEquals(1, requests)
        assertEquals(1, events.count { it.startsWith("DEEPL_REQUEST ") })
        assertEquals(1, events.count { it.startsWith("DEEPL_RESPONSE ") && it.contains("billedChars=5") })
        assertEquals(2, events.count { it.startsWith("DEEPL_CACHE_HIT ") })
        assertFalse(events.toString().contains("private-key"))
        assertFalse(file.readText().contains("private-key"))
        assertFalse(restarted.translate("en", "de", key, "Hello", "private-key", 0).fromCache)
        assertEquals(2, requests)
    }

    @Test fun ocrPolicyAndEngineTogetherSendOneRequestForRepeatedReportedVariants() {
        val engine = engine(File(temporary.root, "cache.jsonl"))
        val policy = DeepLOcrPolicy()
        val variants = listOf(
            "ENZO: And be stuck with those two? l'd much sooner ride... and I know l'l| prefer the",
            "ENZO: And be stuck with those two? l'd much sooner ride... and I know I'll prefer the",
            "ENZO: And be stuck with those two? l'd much sooner ride... and know l'll prefer the",
            "ENZO: And be stuck with those two? l'd much sooner ride... and know I'll prefer the",
            "ENZO: And be stuck vith those two? l'd much sooner ride... and I know l'll prefer the",
            "ENZO: And be stuck with those two? l'd much sooner ride... and I know l'l prefer the",
        )
        variants.forEach { text -> repeat(5) {
            policy.observe(text, .8f, "en", 67)?.let { read ->
                assertEquals("Merhaba", engine.translate("en", "tr", read.key, read.text, "key", 0).text)
            }
        } }
        assertEquals(1, requests)
        val newLine = "Don't go with those two. Stay here!"
        assertNull(policy.observe(newLine, .8f, "en", 67))
        assertNull(policy.observe(newLine, .8f, "en", 67))
        policy.observe(newLine, .8f, "en", 67)!!.let { read ->
            engine.translate("en", "tr", read.key, read.text, "key", 0)
        }
        assertEquals(2, requests)
    }
}
