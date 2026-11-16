package com.abrebostudio.consolegametranslator

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.google.firebase.auth.FirebaseAuth
import com.revenuecat.purchases.CacheFetchPolicy
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.interfaces.ReceiveCustomerInfoCallback
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Store subscription access survives Flutter Activity detachment. */
internal class TranslationAccessController private constructor(context: Context) {
    companion object {
        @Volatile private var instance: TranslationAccessController? = null
        fun get(context: Context): TranslationAccessController = instance ?: synchronized(this) {
            instance ?: TranslationAccessController(context.applicationContext).also { instance = it }
        }
    }
    private val main = Handler(Looper.getMainLooper())
    private val appContext = context.applicationContext
    @Volatile private var access = SubscriptionAccess()
    @Volatile private var armed = false
    private var inFlight = false
    private var trialStartInFlight = false
    private var generation = 0
    private var accessOwnerUid: String? = null
    private var accessSource = "store"
    private val trials = FirestoreTrialStore()
    private var freeTrialMinutes: Int? = null
    private val connectionTrial = RemotePlayTrialGate()
    @Volatile private var remotePlayConnected = false
    var onChanged: (() -> Unit)? = null
    var onStatusChanged: (() -> Unit)? = null
    var onDenied: (() -> Unit)? = null
    val isTranslationRequested: Boolean get() = armed
    private fun uid(): String? = runCatching { FirebaseAuth.getInstance().currentUser?.uid }.getOrNull()
    private fun eligible(): Boolean = access.isActive(SystemClock.elapsedRealtime()) &&
        (accessSource != "free_trial" || accessOwnerUid == uid())
    fun hasAccess(): Boolean = armed && eligible()
    private fun unusedTrialVerified(): Boolean = access.state == "available" && accessSource == "free_trial" &&
        accessOwnerUid != null && accessOwnerUid == uid() && freeTrialMinutes != null
    // Commit access on connection, before enabling OCR or sending subtitles to the TV.
    fun canProcessFrames(): Boolean = hasAccess()

    private fun configured(): Boolean = BuildConfig.REVENUECAT_PUBLIC_KEY.let {
        it.startsWith("goog_") && !it.contains("REPLACE", ignoreCase = true)
    }
    private fun status(): Map<String, Any?> = mapOf(
        "state" to if (access.state in setOf("trial", "premium", "lifetime") && !eligible()) "expired" else access.state,
        "expiresAtMs" to access.expiresAtMs, "source" to accessSource,
        "freeTrialMinutes" to freeTrialMinutes,
        "trialRemainingMs" to if (accessSource == "free_trial")
            (access.deadlineElapsedMs - SystemClock.elapsedRealtime()).coerceAtLeast(0L) else 0L,
        "willRenew" to access.willRenew, "translationAllowed" to hasAccess(),
    )
    fun configure(messenger: BinaryMessenger) {
        MethodChannel(messenger, "com.abrebostudio.consolegametranslator/access").setMethodCallHandler { call, result ->
            when (call.method) {
                "configuration" -> result.success(mapOf("configured" to configured(),
                    "googleWebClientId" to run {
                        val id = appContext.resources.getIdentifier("default_web_client_id", "string", appContext.packageName)
                        if (id == 0) "" else appContext.getString(id)
                    },
                    "revenueCatKey" to BuildConfig.REVENUECAT_PUBLIC_KEY,
                    "premiumEntitlementIds" to SubscriptionAccess.entitlementIds,
                    "privacyUrl" to BuildConfig.PRIVACY_POLICY_URL, "termsUrl" to BuildConfig.TERMS_OF_USE_URL))
                "status" -> result.success(status())
                "prepare" -> refresh(force = call.argument<Boolean>("force") == true, result = result)
                "clear" -> {
                    generation++
                    disarm()
                    access = SubscriptionAccess()
                    accessOwnerUid = null
                    accessSource = "store"
                    onChanged?.invoke()
                    onStatusChanged?.invoke()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
    fun arm() {
        check(configured() && (eligible() || unusedTrialVerified())) {
            "Çeviri için aktif deneme veya Premium gerekiyor."
        }
        armed = true
        onChanged?.invoke()
        if (remotePlayConnected) {
            connectionTrial.connected()
            completeConnectionTrial()
        }
    }
    fun disarm() {
        armed = false
        connectionTrial.reset()
        onChanged?.invoke()
        onStatusChanged?.invoke()
    }
    // Frame callbacks never perform eligibility reads or usage writes.
    fun onVideoFrame() = Unit
    fun onRemotePlayConnectionChanged(connected: Boolean) {
        remotePlayConnected = connected
        if (!connected) { connectionTrial.reset(); return }
        connectionTrial.connected()
        completeConnectionTrial()
    }

    private fun completeConnectionTrial() {
        if (!connectionTrial.hasPendingConnection || !remotePlayConnected || !armed) return
        if (hasAccess()) {
            connectionTrial.reset()
        } else if (connectionTrial.takeClaim(armed, unusedTrialVerified(), inFlight)) {
            // Same immutable, one-time transaction. No subtitle or listener is required.
            loadTrial(start = true, result = null)
        }
    }
    fun onResume() {
        if (armed && accessSource == "store" && configured() && Purchases.isConfigured && !inFlight) refresh()
    }

    /** Local expiry check only. Fetch again when the known store period ends. */
    fun tick() {
        if (!armed || hasAccess() || unusedTrialVerified() || inFlight) return
        onChanged?.invoke()
        if (accessSource == "free_trial") {
            access = SubscriptionAccess("expired", access.expiresAtMs)
            disarm()
            onDenied?.invoke()
        } else refresh(force = true)
    }
    private fun refresh(force: Boolean = false, result: MethodChannel.Result? = null) {
        if (inFlight) {
            // Stopping/restarting while the connection's one-time claim completes
            // must not send a verified unused account back to the subscription screen.
            if (trialStartInFlight && unusedTrialVerified()) result?.success(status())
            else result?.error("ACCESS_BUSY", "Satın alma kontrolü devam ediyor.", null)
            return
        }
        if (!configured() || !Purchases.isConfigured) {
            result?.error("ACCESS_UNCONFIGURED", "Satın alma hizmeti henüz kullanıma hazır değil.", null)
            return
        }
        inFlight = true
        val version = generation
        Purchases.sharedInstance.getCustomerInfo(
            if (force) CacheFetchPolicy.FETCH_CURRENT else CacheFetchPolicy.CACHED_OR_FETCHED,
            object : ReceiveCustomerInfoCallback {
                override fun onReceived(customerInfo: CustomerInfo) {
                    main.post {
                        inFlight = false
                        if (version != generation) { result?.error("ACCESS_CHANGED", "Hesap değişti.", null); return@post }
                        val now = SystemClock.elapsedRealtime()
                        val paid = SubscriptionAccess.fromCustomerInfo(
                            customerInfo = customerInfo,
                            wallNowMs = System.currentTimeMillis(), elapsedNowMs = now,
                            previous = if (accessSource == "store") access else SubscriptionAccess(),
                        )
                        if (!paid.isActive(now) && paid.state != "verification_required") {
                            if (accessSource == "free_trial" && accessOwnerUid == uid() && access.state != "available") {
                                result?.success(status())
                                onStatusChanged?.invoke()
                                completeConnectionTrial()
                            } else refreshFreeTrialOffer(version, result)
                            return@post
                        }
                        access = paid
                        accessOwnerUid = null
                        accessSource = "store"
                        onChanged?.invoke()
                        onStatusChanged?.invoke()
                        if (armed && !access.isActive(now)) {
                            disarm()
                            onDenied?.invoke()
                        }
                        result?.success(status())
                        completeConnectionTrial()
                    }
                }
                override fun onError(error: PurchasesError) {
                    main.post {
                        inFlight = false
                        if (armed && !hasAccess()) {
                            access = SubscriptionAccess("verification_required")
                            disarm()
                            onDenied?.invoke()
                        }
                        result?.error("ACCESS_FAILED", "Satın alma durumu alınamadı. İnternete bağlanıp tekrar dene.", null)
                    }
                }
            },
        )
    }

    private fun refreshFreeTrialOffer(version: Int, result: MethodChannel.Result?) {
        inFlight = true
        fun complete(minutes: Int?) { main.post {
            inFlight = false
            if (version != generation) {
                result?.error("ACCESS_CHANGED", "Hesap değişti.", null)
                return@post
            }
            // A failed setting fetch disables new offers. Existing trial
            // deadlines and paid access never depend on this configuration read.
            freeTrialMinutes = minutes
            if (uid() != null) loadTrial(start = false, result = result)
            else {
                access = SubscriptionAccess("signed_out")
                onChanged?.invoke(); onStatusChanged?.invoke()
                result?.success(status())
            }
        } }
        trials.loadConfiguration(success = { complete(it) }, failure = { complete(null) })
    }

    private fun loadTrial(start: Boolean, result: MethodChannel.Result?) {
        if (inFlight) { result?.error("ACCESS_BUSY", "Erişim kontrolü devam ediyor.", null); return }
        val version = generation
        val expectedUid = uid()
        inFlight = true
        trialStartInFlight = start
        trials.load(start, success = { trial -> main.post {
            inFlight = false
            trialStartInFlight = false
            if (generation != version || uid() != expectedUid || uid() != trial.uid) {
                result?.error("ACCESS_CHANGED", "Hesap değişti.", null); return@post
            }
            access = if (trial.expiresAtMs == null) SubscriptionAccess("available")
                else SubscriptionAccess.fromEntitlement(true, false, true, trial.expiresAtMs, false,
                    trial.serverNowMs, trial.serverNowMs, trial.requestStartedElapsedMs,
                    if (accessSource == "free_trial" && accessOwnerUid == trial.uid) access else SubscriptionAccess())
            accessOwnerUid = trial.uid
            accessSource = "free_trial"
            trial.durationMinutes?.let { freeTrialMinutes = it }
            onChanged?.invoke(); onStatusChanged?.invoke()
            result?.success(status())
            completeConnectionTrial()
        } }, failure = { main.post {
            inFlight = false
            trialStartInFlight = false
            result?.error("TRIAL_FAILED", "Deneme durumu alınamadı. Google girişini ve internet bağlantını kontrol et.", null)
            if (generation == version && uid() == expectedUid && connectionTrial.hasPendingConnection) {
                access = SubscriptionAccess("verification_required")
                disarm()
                onDenied?.invoke()
            }
        } })
    }
}
