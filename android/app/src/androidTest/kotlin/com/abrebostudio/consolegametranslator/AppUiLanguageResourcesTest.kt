package com.abrebostudio.consolegametranslator

import android.content.Context
import android.content.ContextWrapper
import android.content.SharedPreferences
import android.content.res.Configuration
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import java.util.Locale

@RunWith(AndroidJUnit4::class)
class AppUiLanguageResourcesTest {
    @Test
    fun nativeStatusAndAppNameFollowDeviceLanguageAndIgnoreLegacyPreference() {
        val base = InstrumentationRegistry.getInstrumentation().targetContext
        // Keep the real user's language and console/session preferences untouched.
        val preferences = base.getSharedPreferences("language_resource_test", Context.MODE_PRIVATE)
        try {
            for (language in listOf("en", "tr", "de", "ar")) {
                val configuration = Configuration(base.resources.configuration).apply {
                    setLocale(Locale.forLanguageTag(language))
                }
                val context = object : ContextWrapper(base.createConfigurationContext(configuration)) {
                    override fun getSharedPreferences(name: String, mode: Int): SharedPreferences =
                        if (name == "personalization_settings") preferences else super.getSharedPreferences(name, mode)
                }
                for (savedLanguage in listOf("tr", "en", "system")) {
                    check(preferences.edit().putString("app_language", savedLanguage).commit())
                    val localized = AppUiLanguage.localizedContext(context)
                    val name = localized.getString(R.string.app_name)
                    val status = localized.getString(R.string.local_translation_status, name)
                    if (language == "tr") {
                        assertEquals("OyunÇevirmeni", name)
                        assertEquals("Çevrildi · OyunÇevirmeni Yerel", status)
                        assertEquals("Durdur", AppUiLanguage.text(context, "Durdur"))
                    } else {
                        assertEquals("Console Game Translator", name)
                        assertEquals("Translated · Console Game Translator Local", status)
                        assertEquals("Stop", AppUiLanguage.text(context, "Durdur"))
                    }
                }
            }
        } finally {
            check(preferences.edit().clear().commit())
        }
    }
}
