package com.abrebostudio.consolegametranslator

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

/** Native dialogs and notifications follow the saved interface language. */
internal object AppUiLanguage {
    const val preferenceKey = "app_language"
    val preferences = setOf("system", "tr", "en", "ar", "th", "hu")

    fun preference(context: Context): String =
        context.getSharedPreferences("personalization_settings", Context.MODE_PRIVATE)
            .getString(preferenceKey, "system")?.takeIf { it in preferences } ?: "system"

    private fun code(context: Context): String {
        val saved = preference(context)
        if (saved != "system") return saved
        return context.resources.configuration.locales[0].language.let {
            if (it in preferences && it != "system") it else "en"
        }
    }

    fun text(context: Context, source: String): String =
        when (code(context)) {
            "tr" -> source
            "ar" -> arabic[source] ?: source
            "th" -> thai[source] ?: source
            "hu" -> hungarian[source] ?: source
            else -> english[source] ?: source
        }

    fun localizedContext(context: Context): Context {
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(code(context)))
        return context.createConfigurationContext(configuration)
    }

    private val hungarian = mapOf(
        "Güvenli bağlantı" to "Biztonságos kapcsolat",
        "İptal" to "Mégse",
        "Ekran kapalıyken çeviri" to "Fordítás kikapcsolt képernyővel",
        "Şimdi değil" to "Most nem",
        "Ayarları aç" to "Beállítások megnyitása",
        "Durdur" to "Leállítás",
        "Çeviri durumu" to "Fordítás állapota",
        "Remote Play altyazı çevirisi" to "Remote Play feliratfordítás",
        "Remote Play karesi bekleniyor" to "Várakozás a Remote Play képére",
        "Remote Play oturumu" to "Remote Play munkamenet",
        "Remote Play bağlı" to "A Remote Play csatlakoztatva",
        "Çeviri hazırlanıyor" to "Fordítás előkészítése",
        "Çeviri beklemede" to "A fordítás várakozik",
        "Çeviri çalışıyor" to "A fordítás fut",
        "Menüye dönmek için dokun." to "Koppints a menühöz való visszatéréshez.",
        "İlk video karesi henüz alınmadı. Bildirim açık kalıyor." to "Az első videóképkocka még nem érkezett meg. Az értesítés aktív marad.",
        "Yeni video karesi yok. Görüntü gelince çeviri sürdürülecek." to "Nincsenek új videóképkockák. A fordítás folytatódik, amint visszatér a kép.",
        "PS5 bağlantısı arka planda sürüyor. Menüye dönmek için dokun." to "A PS5 a háttérben csatlakoztatva marad. Koppints a menühöz való visszatéréshez.",
    )

    private val thai = mapOf(
        "Güvenli bağlantı" to "การเชื่อมต่อที่ปลอดภัย",
        "İptal" to "ยกเลิก",
        "Ekran kapalıyken çeviri" to "แปลขณะปิดหน้าจอ",
        "Şimdi değil" to "ไว้ภายหลัง",
        "Ayarları aç" to "เปิดการตั้งค่า",
        "Durdur" to "หยุด",
        "Çeviri durumu" to "สถานะการแปล",
        "Remote Play altyazı çevirisi" to "การแปลคำบรรยาย Remote Play",
        "Remote Play karesi bekleniyor" to "กำลังรอภาพ Remote Play",
        "Remote Play oturumu" to "เซสชัน Remote Play",
        "Remote Play bağlı" to "เชื่อมต่อ Remote Play แล้ว",
        "Çeviri hazırlanıyor" to "กำลังเตรียมการแปล",
        "Çeviri beklemede" to "การแปลกำลังรอ",
        "Çeviri çalışıyor" to "กำลังแปล",
        "Menüye dönmek için dokun." to "แตะเพื่อกลับไปที่เมนู",
        "İlk video karesi henüz alınmadı. Bildirim açık kalıyor." to "ยังไม่ได้รับเฟรมวิดีโอแรก การแจ้งเตือนจะยังคงแสดงอยู่",
        "Yeni video karesi yok. Görüntü gelince çeviri sürdürülecek." to "ไม่มีเฟรมวิดีโอใหม่ จะแปลต่อเมื่อภาพกลับมา",
        "PS5 bağlantısı arka planda sürüyor. Menüye dönmek için dokun." to "PS5 ยังเชื่อมต่อในเบื้องหลัง แตะเพื่อกลับไปที่เมนู",
    )

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
