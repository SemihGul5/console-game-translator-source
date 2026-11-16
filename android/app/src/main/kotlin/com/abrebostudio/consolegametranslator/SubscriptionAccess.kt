package com.abrebostudio.consolegametranslator

import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.PeriodType
import com.revenuecat.purchases.VerificationResult

/** In-memory access derived from RevenueCat; no usage quota or custom permits. */
internal data class SubscriptionAccess(
    val state: String = "inactive",
    val expiresAtMs: Long? = null,
    val deadlineElapsedMs: Long = 0,
    val willRenew: Boolean = false,
) {
    fun isActive(nowElapsedMs: Long): Boolean =
        state in setOf("trial", "premium", "lifetime") && nowElapsedMs < deadlineElapsedMs

    companion object {
        // The live RevenueCat project uses the first ID. Keep the original ID
        // for existing configurations and for compatibility with shipped apps.
        val entitlementIds = listOf("console_game_translator_premium", "premium")

        fun fromCustomerInfo(customerInfo: CustomerInfo, wallNowMs: Long, elapsedNowMs: Long,
                             previous: SubscriptionAccess = SubscriptionAccess()): SubscriptionAccess {
            val active = entitlementIds.mapNotNull { customerInfo.entitlements.active[it] }
            val entitlement = active.firstOrNull()
            return fromEntitlement(
                active = entitlement != null,
                verificationFailed = customerInfo.entitlements.verification == VerificationResult.FAILED ||
                    active.any { it.verification == VerificationResult.FAILED },
                trial = entitlement?.periodType == PeriodType.TRIAL,
                expiresAtMs = entitlement?.expirationDate?.time,
                willRenew = entitlement?.willRenew == true,
                serverNowMs = customerInfo.requestDate.time,
                wallNowMs = wallNowMs, elapsedNowMs = elapsedNowMs, previous = previous,
            )
        }

        fun fromEntitlement(active: Boolean, verificationFailed: Boolean, trial: Boolean,
                            expiresAtMs: Long?, willRenew: Boolean, serverNowMs: Long,
                            wallNowMs: Long, elapsedNowMs: Long,
                            previous: SubscriptionAccess = SubscriptionAccess()): SubscriptionAccess {
            if (verificationFailed) return SubscriptionAccess("verification_required")
            if (!active) return SubscriptionAccess()
            if (expiresAtMs == null) return if (trial) SubscriptionAccess("verification_required")
                else SubscriptionAccess("lifetime", deadlineElapsedMs = Long.MAX_VALUE)
            val remaining = (expiresAtMs - maxOf(serverNowMs, wallNowMs)).coerceAtLeast(0)
            var deadline = elapsedNowMs + remaining
            // Re-reading the same cached purchase cannot extend it after a clock change.
            if (previous.expiresAtMs == expiresAtMs && previous.deadlineElapsedMs > 0) {
                deadline = minOf(deadline, previous.deadlineElapsedMs)
            }
            if (deadline <= elapsedNowMs) return SubscriptionAccess("expired", expiresAtMs)
            return SubscriptionAccess(if (trial) "trial" else "premium", expiresAtMs, deadline, willRenew)
        }
    }
}
