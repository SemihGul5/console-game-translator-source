package com.abrebostudio.consolegametranslator

import android.os.SystemClock
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Source
import java.util.Date

/** One immutable end time per Google account; no heartbeat or usage writes. */
internal class FirestoreTrialStore {
    data class Result(val uid: String, val expiresAtMs: Long?, val serverNowMs: Long,
                      val requestStartedElapsedMs: Long, val durationMinutes: Int?)

    private fun configuration() = FirebaseFirestore.getInstance()
        .collection("appConfig").document("freeTrial")

    fun loadConfiguration(success: (Int) -> Unit, failure: (Exception) -> Unit) {
        configuration().get(Source.SERVER).addOnSuccessListener { snapshot ->
            val minutes = try { FreeTrialPolicy.minutes(snapshot.get("durationMinutes")) }
            catch (error: Exception) { failure(error); return@addOnSuccessListener }
            success(minutes)
        }.addOnFailureListener(failure)
    }

    fun load(startIfMissing: Boolean, success: (Result) -> Unit, failure: (Exception) -> Unit) {
        val user = runCatching { FirebaseAuth.getInstance().currentUser }.getOrNull()
        val subject = user?.providerData?.firstOrNull { it.providerId == "google.com" }?.uid
        if (user == null || subject.isNullOrBlank()) {
            failure(IllegalStateException("Deneme için Google hesabınla giriş yap."))
            return
        }
        val before = SystemClock.elapsedRealtime()
        // Firebase's signed token issuance time gives server UTC without a
        // Firestore clock document/write or dependence on the phone's clock.
        user.getIdToken(true).addOnSuccessListener { token ->
            val issuedAtMs = token.issuedAtTimestamp * 1000L
            if (issuedAtMs <= 0L) { failure(IllegalStateException("Hesap zamanı doğrulanamadı.")); return@addOnSuccessListener }
            val ref = FirebaseFirestore.getInstance().collection("translationTrials").document(subject)
            FirebaseFirestore.getInstance().runTransaction { tx ->
                val snapshot = tx.get(ref)
                if (snapshot.exists()) {
                    Pair(snapshot.getTimestamp("expiresAt")?.toDate()?.time
                        ?: throw IllegalStateException("Deneme kaydı geçersiz."), null)
                } else if (startIfMissing) {
                    // Read inside this transaction too: a changed offer must never
                    // create a deadline from an old cached campaign duration.
                    val minutes = FreeTrialPolicy.minutes(tx.get(configuration()).get("durationMinutes"))
                    val end = issuedAtMs + minutes * 60_000L
                    tx.set(ref, mapOf("expiresAt" to Timestamp(Date(end))))
                    Pair(end, minutes)
                } else Pair(null, null)
            }.addOnSuccessListener { trial ->
                // iat is rounded down to seconds. Round up for checking and
                // anchor before network I/O so access cannot exceed its deadline.
                success(Result(user.uid, trial.first, issuedAtMs + 1000L, before, trial.second))
            }.addOnFailureListener(failure)
        }.addOnFailureListener(failure)
    }
}
