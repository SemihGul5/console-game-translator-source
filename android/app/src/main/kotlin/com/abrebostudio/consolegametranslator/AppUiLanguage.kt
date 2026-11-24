package com.abrebostudio.consolegametranslator

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

/** Native dialogs and notifications follow the saved interface language. */
internal object AppUiLanguage {
    const val preferenceKey = "app_language"
    val preferences = setOf("system", "tr", "en", "ar")

    fun preference(context: Context): String =
        context.getSharedPreferences("personalization_settings", Context.MODE_PRIVATE)
            .getString(preferenceKey, "system")?.takeIf { it in preferences } ?: "system"

    private fun code(context: Context): String {
        val saved = preference(context)
        if (saved != "system") return saved
        return context.resources.configuration.locales[0].language.let {
            if (it == "tr" || it == "ar") it else "en"
        }
    }

    fun text(context: Context, source: String): String =
        when (code(context)) {
            "tr" -> source
            "ar" -> arabic[source] ?: source
            else -> english[source] ?: source
        }

    fun localizedContext(context: Context): Context {
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(code(context)))
        return context.createConfigurationContext(configuration)
    }

    private val arabic = mapOf(
        "Güvenli bağlantı" to "اتصال آمن",
        "İptal" to "إلغاء",
        "Ekran kapalıyken çeviri" to "الترجمة والشاشة مغلقة",
        "Şimdi değil" to "ليس الآن",
        "Ayarları aç" to "فتح الإعدادات",
        "Durdur" to "إيقاف",
        "Çeviri durumu" to "حالة الترجمة",
        "Remote Play altyazı çevirisi" to "ترجمة نصوص Remote Play",
        "Remote Play karesi bekleniyor" to "بانتظار صورة Remote Play",
        "Remote Play oturumu" to "جلسة Remote Play",
        "Remote Play bağlı" to "Remote Play متصل",
        "Çeviri hazırlanıyor" to "جارٍ تجهيز الترجمة",
        "Çeviri beklemede" to "الترجمة قيد الانتظار",
        "Çeviri çalışıyor" to "الترجمة قيد التشغيل",
        "Menüye dönmek için dokun." to "اضغط للعودة إلى القائمة.",
        "İlk video karesi henüz alınmadı. Bildirim açık kalıyor." to
            "لم يصل إطار الفيديو الأول بعد. سيبقى الإشعار نشطًا.",
        "Yeni video karesi yok. Görüntü gelince çeviri sürdürülecek." to
            "لا توجد إطارات فيديو جديدة. ستُستأنف الترجمة عند عودة الصورة.",
        "PS5 bağlantısı arka planda sürüyor. Menüye dönmek için dokun." to
            "اتصال PS5 مستمر في الخلفية. اضغط للعودة إلى القائمة.",
    )

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
