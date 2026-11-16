package com.abrebostudio.consolegametranslator

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL

class DeepLClientTest {
    private class Connection(url: URL, private val status: Int = 200,
        private val response: String = "{}") : HttpURLConnection(url) {
        val body = ByteArrayOutputStream()
        var disconnected = false
        override fun connect() {}
        override fun disconnect() { disconnected = true }
        override fun usingProxy() = false
        override fun getResponseCode() = status
        override fun getInputStream() = ByteArrayInputStream(response.toByteArray(Charsets.UTF_8))
        override fun getOutputStream() = body
    }

    @Test fun sendsFreeKeyOnlyInHeaderAndTranslatesUnicode() {
        lateinit var connection: Connection
        val client = DeepLClient(" test-key:fx ") { url ->
            Connection(url, response = """{"translations":[{"text":"Çıkış burada."}]}""").also { connection = it }
        }
        assertEquals("Çıkış burada.", client.translate("The exit is here.\nLet's go!", "en", "tr"))
        assertEquals("https://api-free.deepl.com/v2/translate", connection.url.toString())
        assertEquals("POST", connection.requestMethod)
        assertEquals("DeepL-Auth-Key test-key:fx", connection.getRequestProperty("Authorization"))
        val body = JSONObject(connection.body.toString("UTF-8"))
        assertEquals("The exit is here.\nLet's go!", body.getJSONArray("text").getString(0))
        assertEquals("EN", body.getString("source_lang"))
        assertEquals("TR", body.getString("target_lang"))
        assertEquals("nonewlines", body.getString("split_sentences"))
        assertTrue(body.getBoolean("show_billed_characters"))
        assertFalse(body.has("auth_key"))
        assertFalse(connection.instanceFollowRedirects)
        assertTrue(connection.disconnected)
        assertTrue(connection.connectTimeout > 0)
        assertTrue(connection.readTimeout > 0)
    }

    @Test fun connectionTestUsesProUsageEndpointWithoutBillableText() {
        lateinit var connection: Connection
        DeepLClient("pro-key") { url -> Connection(url).also { connection = it } }.checkConnection()
        assertEquals("https://api.deepl.com/v2/usage", connection.url.toString())
        assertEquals("GET", connection.requestMethod)
        assertEquals(0, connection.body.size())
    }

    @Test fun keepsConfirmedBillableCharactersSeparateFromAnUnknownCount() {
        val reported = DeepLClient("key") { url ->
            Connection(url, response = """{"translations":[{"text":"Merhaba","billed_characters":5}]}""")
        }.translateWithUsage("Hello", "en", "tr")
        assertEquals(5L, reported.billedCharacters)
        val unknown = DeepLClient("key") { url ->
            Connection(url, response = """{"translations":[{"text":"Merhaba"}]}""")
        }.translateWithUsage("Hello", "en", "tr")
        assertNull(unknown.billedCharacters)
    }

    @Test fun readsAccountUsageWithoutTranslatingOrExposingCredentials() {
        lateinit var connection: Connection
        val usage = DeepLClient("private-key") { url ->
            Connection(url, response = """{"character_count":12345,"character_limit":500000}""")
                .also { connection = it }
        }.usage()
        assertEquals(12345L, usage["characterCount"])
        assertEquals(500000L, usage["characterLimit"])
        assertEquals("GET", connection.requestMethod)
        assertEquals("/v2/usage", connection.url.path)
        assertEquals(0, connection.body.size())
        assertFalse(usage.toString().contains("private-key"))
        assertThrows(DeepLException::class.java) {
            DeepLClient("key") { url -> Connection(url, response = "{}") }.usage()
        }
    }

    @Test fun discoversSourceAndTargetLanguagesIncludingVariants() {
        val paths = mutableListOf<String>()
        val client = DeepLClient("key") { url ->
            paths.add(url.toString())
            Connection(url, response = """[{"language":"EN-US","name":"English (American)"},{"language":"TR","name":"Turkish"}]""")
        }
        assertEquals("en-us", client.languages(false)[0]["code"])
        assertEquals("Turkish", client.languages(true)[1]["englishName"])
        assertEquals("Türkçe", client.languages(true)[1]["nativeName"])
        assertTrue(paths[0].endsWith("?type=target"))
        assertTrue(paths[1].endsWith("?type=source"))
    }

    @Test fun reportsAuthenticationQuotaAndRateLimitsWithoutUpstreamSecrets() {
        mapOf(403 to "DEEPL_AUTH", 456 to "DEEPL_QUOTA", 429 to "DEEPL_RATE_LIMIT",
            400 to "DEEPL_LANGUAGE", 503 to "DEEPL_UNAVAILABLE", 302 to "DEEPL_UNAVAILABLE").forEach { (status, code) ->
            lateinit var connection: Connection
            val client = DeepLClient("private-key") { url ->
                Connection(url, status, "private-key secret server response").also { connection = it }
            }
            val error = assertThrows(DeepLException::class.java) { client.checkConnection() }
            assertEquals(code, error.code)
            assertFalse(error.message.orEmpty().contains("private-key"))
            assertTrue(error.retryDelayMs >= 5_000)
            assertTrue(connection.disconnected)
        }
    }

    @Test fun rejectsBlankKeysAndHeaderInjectionBeforeConnecting() {
        listOf("", " ", "key\r\nHeader: value", "a".repeat(513)).forEach { value ->
            assertThrows(DeepLException::class.java) { DeepLClient(value) { fail("Should not connect"); error("") } }
        }
    }

    @Test fun malformedOrEmptyTranslationCannotReachTheSubtitleOverlay() {
        listOf("{}", "not json", """{"translations":[]}""",
            """{"translations":[{"text":" "}]}""").forEach { body ->
            val client = DeepLClient("key") { url -> Connection(url, response = body) }
            assertEquals("DEEPL_RESPONSE", assertThrows(DeepLException::class.java) {
                client.translate("Hello", "en", "tr")
            }.code)
        }
    }
}
