package com.abrebostudio.consolegametranslator

import android.content.Context
import org.json.JSONObject

internal class TranslationCacheManager private constructor(context: Context) {
    private val preferences = context.getSharedPreferences("translation_cache_limits", Context.MODE_PRIVATE)
    val repository: TranslationCacheRepository
    init {
        val policy = runCatching {
            val json = JSONObject(preferences.getString("policy", null) ?: error("Default policy"))
            TranslationCachePolicy.fromMap(mapOf("maxEntries" to json.getInt("maxEntries"),
                "days" to json.getInt("days"), "maxMiB" to json.getInt("maxMiB")))
        }.getOrDefault(TranslationCachePolicy())
        repository = TranslationCacheRepository(context.noBackupFilesDir, policy)
    }

    @Synchronized fun updatePolicy(policy: TranslationCachePolicy) {
        val previous = repository.policy
        val previousDeepL = repository.deepL.snapshot()
        val previousGemini = repository.gemini.snapshot()
        repository.configure(policy)
        if (!preferences.edit().putString("policy", JSONObject(policy.toMap()).toString()).commit()) {
            repository.configure(previous)
            repository.deepL.replace(previousDeepL)
            repository.gemini.replace(previousGemini)
            throw java.io.IOException("Cache settings could not be saved")
        }
    }

    companion object {
        @Volatile private var instance: TranslationCacheManager? = null
        fun get(context: Context): TranslationCacheManager = instance ?: synchronized(this) {
            instance ?: TranslationCacheManager(context.applicationContext).also { instance = it }
        }
    }
}
