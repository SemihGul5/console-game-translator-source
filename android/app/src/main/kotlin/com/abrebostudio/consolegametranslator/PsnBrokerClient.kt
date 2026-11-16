package com.abrebostudio.consolegametranslator

import org.json.JSONObject
import java.net.URI
import java.net.URL
import java.security.MessageDigest
import java.util.Locale
import javax.net.ssl.HttpsURLConnection

/** Public broker address only. Sony credentials and tokens never enter Android. */
internal class PsnBrokerClient(origin: String) {
    val origin = validateOrigin(origin)

    fun exchange(code: String, turnstileToken: String): String {
        val connection = URL("$origin/v1/psn/account-id").openConnection() as HttpsURLConnection
        try {
            connection.requestMethod = "POST"
            connection.instanceFollowRedirects = false
            connection.useCaches = false
            connection.connectTimeout = 20_000
            connection.readTimeout = 60_000
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            connection.setRequestProperty("Cache-Control", "no-store")
            connection.doOutput = true
            val body = JSONObject().put("code", code).put("turnstileToken", turnstileToken)
                .toString().toByteArray(Charsets.UTF_8)
            connection.setFixedLengthStreamingMode(body.size)
            try {
                connection.outputStream.use { it.write(body) }
            } finally {
                body.fill(0)
            }
            val status = connection.responseCode
            if (status !in 200..299) {
                // Do not display or log arbitrary upstream bodies or exception URLs.
                val message = when (status) {
                    400 -> "PSN giriş kodu kabul edilmedi. PSN ile yeniden giriş yap."
                    403 -> "Güvenlik doğrulaması tamamlanamadı. Tekrar dene."
                    429 -> "Çok fazla doğrulama denemesi yapıldı. Bir dakika sonra tekrar dene."
                    503 -> "PSN hesap doğrulama hizmeti henüz hazır değil."
                    else -> "PSN hesap doğrulama hizmetine ulaşılamadı. Tekrar dene."
                }
                throw IllegalStateException(message)
            }
            val response = connection.inputStream.use { stream ->
                val bytes = ByteArray(4097)
                var count = 0
                while (count < bytes.size) {
                    val read = stream.read(bytes, count, bytes.size - count)
                    if (read == -1) break
                    count += read
                }
                check(count <= 4096) { "PSN hesap yanıtı geçersiz." }
                String(bytes, 0, count, Charsets.UTF_8)
            }
            return parseAccountId(response)
        } finally {
            connection.disconnect()
        }
    }

    companion object {
        fun validateOrigin(value: String): String {
            val uri = try { URI(value) } catch (_: Exception) { null }
            check(uri != null && uri.scheme == "https" && !uri.host.isNullOrEmpty() &&
                uri.rawUserInfo == null && uri.port in listOf(-1, 443) &&
                uri.rawPath in listOf("", "/") && uri.rawQuery == null && uri.rawFragment == null) {
                "PSN hesap doğrulama sunucusu yapılandırılmamış."
            }
            return URI("https", null, uri.host.lowercase(Locale.ROOT), -1, null, null, null).toASCIIString()
        }

        fun codeDigest(code: String): String = MessageDigest.getInstance("SHA-256")
            .digest(code.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }

        fun parseAccountId(response: String): String {
            val json = JSONObject(response)
            val accountId = json.opt("accountId") as? String
            // Canonical Base64 of exactly 8 bytes, including zero padding bits.
            check(json.length() == 1 && accountId != null &&
                accountId.matches(Regex("^[A-Za-z0-9+/]{10}[AEIMQUYcgkosw048]=$"))) {
                "PSN hesap yanıtı geçersiz."
            }
            return accountId
        }
    }
}
