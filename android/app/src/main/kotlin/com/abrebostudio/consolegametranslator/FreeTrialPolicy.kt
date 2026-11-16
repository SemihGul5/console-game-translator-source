package com.abrebostudio.consolegametranslator

/** Matches the bounds enforced by Firestore rules; no campaign duration lives in the APK. */
internal object FreeTrialPolicy {
    const val MAX_MINUTES = 1440

    fun minutes(value: Any?): Int {
        require(value is Long && value in 1L..MAX_MINUTES.toLong()) {
            "Deneme süresi sunucuda geçerli bir tam sayı olarak ayarlanmalı."
        }
        return value.toInt()
    }
}
