package com.abrebostudio.consolegametranslator

import android.content.Context
import android.content.ContextWrapper
import android.content.SharedPreferences
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AppUiLanguageResourcesTest {
    @Test
    fun switchesNativeStatusAndAppNameWithoutReinstallingOrChangingSystemLanguage() {
        val base = InstrumentationRegistry.getInstrumentation().targetContext
        // Keep the real user's language and console/session preferences untouched.
        val preferences = base.getSharedPreferences("language_resource_test", Context.MODE_PRIVATE)
        val context = object : ContextWrapper(base) {
            override fun getSharedPreferences(name: String, mode: Int): SharedPreferences =
                if (name == "personalization_settings") preferences else super.getSharedPreferences(name, mode)
        }
        try {
            for (language in listOf("en", "tr", "en")) {
                check(preferences.edit().putString("app_language", language).commit())
                val localized = AppUiLanguage.localizedContext(context)
                val name = localized.getString(R.string.app_name)
                val status = localized.getString(R.string.local_translation_status, name)
                if (language == "tr") {
                    assertEquals("AnlaOyna", name)
                    assertEquals("Çevrildi · AnlaOyna Yerel", status)
                } else {
                    assertEquals("Console Game Translator", name)
                    assertEquals("Translated · Console Game Translator Local", status)
                }
            }
        } finally {
            check(preferences.edit().clear().commit())
        }
    }
}
