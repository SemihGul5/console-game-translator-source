package com.abrebostudio.consolegametranslator

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

/** Native dialogs and notifications follow the device language, with English as fallback. */
internal object AppUiLanguage {
    private fun code(context: Context): String =
        if (context.resources.configuration.locales[0].language == "tr") "tr" else "en"

    fun text(context: Context, source: String): String =
        if (code(context) == "tr") source else english[source] ?: source

    fun localizedContext(context: Context): Context {
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(code(context)))
        return context.createConfigurationContext(configuration)
    }

    private val english = mapOf(
        "Güvenli bağlantı" to "Secure connection",
        "İptal" to "Cancel",
        "Ekran kapalıyken çeviri" to "Translate with screen off",
        "Şimdi değil" to "Not now",
        "Ayarları aç" to "Open settings",
        "Durdur" to "Stop",
        "Çeviri durumu" to "Translation status",
        "Remote Play altyazı çevirisi" to "Remote Play subtitle translation",
        "Remote Play karesi bekleniyor" to "Waiting for Remote Play video",
        "Remote Play oturumu" to "Remote Play session",
        "Remote Play bağlı" to "Remote Play connected",
        "Çeviri hazırlanıyor" to "Preparing translation",
        "Çeviri beklemede" to "Translation waiting",
        "Çeviri çalışıyor" to "Translation running",
        "Menüye dönmek için dokun." to "Tap to return to the menu.",
        "İlk video karesi henüz alınmadı. Bildirim açık kalıyor." to
            "Waiting for the first video frame. The notification stays active.",
        "Yeni video karesi yok. Görüntü gelince çeviri sürdürülecek." to
            "No new video frames. Translation will resume when video returns.",
        "PS5 bağlantısı arka planda sürüyor. Menüye dönmek için dokun." to
            "PS5 stays connected in the background. Tap to return to the menu.",
    )
}
