package com.abrebostudio.consolegametranslator

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Device-bound encryption; the encrypted file is also excluded from Android backups. */
internal class GeminiCredentialStore(context: Context) {
    private val file = AtomicFile(File(context.noBackupFilesDir, "gemini_api_key"))
    private val alias = "gametranslate.gemini.api_key"

    @Synchronized fun read(): String? = readAll().firstOrNull()

    @Synchronized fun readAll(): List<String> {
        if (!file.baseFile.exists()) return emptyList()
        return try {
            val bytes = file.readFully()
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(128, bytes.copyOfRange(0, 12)))
            GeminiKeyList.decode(String(cipher.doFinal(bytes.copyOfRange(12, bytes.size)), Charsets.UTF_8))
        } catch (_: Exception) {
            throw GeminiException("GEMINI_KEY_STORAGE", "Gemini anahtarı okunamadı. Anahtarı yeniden gir.")
        }
    }

    @Synchronized fun save(value: String) {
        writeAll(GeminiKeyList.adding(readAll(), value))
    }

    @Synchronized fun remove(id: String) {
        val keys = readAll().filterNot { GeminiKeyList.id(it) == id }
        if (keys.isEmpty()) clear() else writeAll(keys)
    }

    @Synchronized fun metadata(): Map<String, Any?> {
        return GeminiKeyList.metadata(readAll())
    }

    private fun writeAll(keys: List<String>) {
        try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, secretKey())
            val bytes = cipher.iv + cipher.doFinal(GeminiKeyList.encode(keys).toByteArray(Charsets.UTF_8))
            val stream = file.startWrite()
            try {
                stream.write(bytes)
                file.finishWrite(stream)
            } catch (error: Exception) {
                file.failWrite(stream)
                throw error
            }
        } catch (_: Exception) {
            throw GeminiException("GEMINI_KEY_STORAGE", "Gemini anahtarı kaydedilemedi. Tekrar dene.")
        }
    }

    @Synchronized fun clear() { file.delete() }

    private fun secretKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
        }.generateKey()
    }
}
