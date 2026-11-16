package com.abrebostudio.consolegametranslator

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Stores the Chiaki credentials encrypted with an Android Keystore AES key. */
internal class RegisteredConsoleStore(context: Context) {
    private val preferences = context.getSharedPreferences("registered_console", Context.MODE_PRIVATE)

    data class Console(
        val host: String,
        val nickname: String,
        val registrationKey: ByteArray,
        val morning: ByteArray,
    )

    @Synchronized
    fun save(console: Console) {
        val json = JSONObject()
            .put("host", console.host)
            .put("nickname", console.nickname)
            .put("registrationKey", Base64.encodeToString(console.registrationKey, Base64.NO_WRAP))
            .put("morning", Base64.encodeToString(console.morning, Base64.NO_WRAP))
            .toString()
            .toByteArray(Charsets.UTF_8)

        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey())
        val encrypted = cipher.doFinal(json)
        check(preferences.edit()
            .putString(KEY_IV, Base64.encodeToString(cipher.iv, Base64.NO_WRAP))
            .putString(KEY_DATA, Base64.encodeToString(encrypted, Base64.NO_WRAP))
            .commit()) { "Konsol bilgileri güvenli depoya yazılamadı." }
    }

    @Synchronized
    fun load(): Console? {
        val ivText = preferences.getString(KEY_IV, null) ?: return null
        val dataText = preferences.getString(KEY_DATA, null) ?: return null
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(
            Cipher.DECRYPT_MODE,
            getOrCreateKey(),
            GCMParameterSpec(128, Base64.decode(ivText, Base64.NO_WRAP)),
        )
        val json = JSONObject(String(cipher.doFinal(Base64.decode(dataText, Base64.NO_WRAP)), Charsets.UTF_8))
        return Console(
            host = json.getString("host"),
            nickname = json.optString("nickname"),
            registrationKey = Base64.decode(json.getString("registrationKey"), Base64.NO_WRAP),
            morning = Base64.decode(json.getString("morning"), Base64.NO_WRAP),
        )
    }

    @Synchronized
    fun clear() {
        check(preferences.edit().clear().commit()) { "Güvenli kayıt silinemedi." }
        KeyStore.getInstance("AndroidKeyStore").apply { load(null) }.deleteEntry(KEY_ALIAS)
    }

    @Synchronized
    fun clearAccountId() {
        check(preferences.edit().remove(ACCOUNT_IV).remove(ACCOUNT_DATA).commit()) {
            "PSN Account ID güvenli depodan silinemedi."
        }
    }

    @Synchronized
    fun resetAfterDecryptionFailure() {
        preferences.edit().clear().commit()
        try {
            KeyStore.getInstance("AndroidKeyStore").apply { load(null) }.deleteEntry(KEY_ALIAS)
        } catch (_: Exception) {
            // The next authentication attempt will surface any remaining Keystore failure.
        }
    }

    @Synchronized
    fun saveAccountId(accountId: ByteArray) {
        require(accountId.size == 8) { "PSN Account ID 8 bayt olmalı." }
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey())
        val encrypted = cipher.doFinal(accountId)
        check(preferences.edit()
            .putString(ACCOUNT_IV, Base64.encodeToString(cipher.iv, Base64.NO_WRAP))
            .putString(ACCOUNT_DATA, Base64.encodeToString(encrypted, Base64.NO_WRAP))
            .commit()) { "PSN Account ID güvenli depoya yazılamadı." }
    }

    @Synchronized
    fun loadAccountId(): ByteArray? {
        val iv = preferences.getString(ACCOUNT_IV, null) ?: return null
        val data = preferences.getString(ACCOUNT_DATA, null) ?: return null
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(), GCMParameterSpec(128, Base64.decode(iv, Base64.NO_WRAP)))
        return cipher.doFinal(Base64.decode(data, Base64.NO_WRAP)).also {
            require(it.size == 8) { "Kayıtlı PSN Account ID geçersiz." }
        }
    }

    @Synchronized
    private fun getOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            ).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build(),
        )
        return generator.generateKey()
    }

    companion object {
        private const val KEY_ALIAS = "gametranslate.chiaki.console"
        private const val KEY_IV = "iv"
        private const val KEY_DATA = "data"
        private const val ACCOUNT_IV = "account_iv"
        private const val ACCOUNT_DATA = "account_data"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
    }
}
