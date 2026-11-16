package com.abrebostudio.consolegametranslator

import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.EntitlementInfo
import com.revenuecat.purchases.EntitlementInfos
import com.revenuecat.purchases.OwnershipType
import com.revenuecat.purchases.PeriodType
import com.revenuecat.purchases.Store
import com.revenuecat.purchases.VerificationResult
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.util.Date

class StoreEntitlementAccessTest {
    private fun entitlement(id: String = "console_game_translator_premium", active: Boolean = true,
                            expiry: Long? = 10_000, verification: VerificationResult = VerificationResult.VERIFIED) =
        EntitlementInfo(
            identifier = id, isActive = active, willRenew = true, periodType = PeriodType.NORMAL,
            latestPurchaseDate = Date(1_000), originalPurchaseDate = Date(1_000),
            expirationDate = expiry?.let { Date(it) }, store = Store.PLAY_STORE,
            productIdentifier = "consolegametranslator_premium", productPlanIdentifier = "monthly",
            isSandbox = true, unsubscribeDetectedAt = null, billingIssueDetectedAt = null,
            ownershipType = OwnershipType.PURCHASED, jsonObject = JSONObject(), verification = verification,
        )

    private fun access(vararg entitlements: EntitlementInfo,
                       verification: VerificationResult = VerificationResult.VERIFIED): SubscriptionAccess {
        val customerInfo = CustomerInfo(
            entitlements = EntitlementInfos(entitlements.associateBy { it.identifier }, verification),
            allExpirationDatesByProduct = emptyMap(), allPurchaseDatesByProduct = emptyMap(),
            requestDate = Date(1_000), schemaVersion = 3, firstSeen = Date(1_000),
            originalAppUserId = "test-user", managementURL = null, originalPurchaseDate = null,
            jsonObject = JSONObject().put("subscriber", JSONObject().put("non_subscriptions", JSONObject())),
        )
        return SubscriptionAccess.fromCustomerInfo(customerInfo, wallNowMs = 1_000, elapsedNowMs = 100)
    }

    @Test fun liveProjectEntitlementUnlocksPremium() {
        val paid = access(entitlement())
        assertEquals("premium", paid.state)
        assertTrue(paid.isActive(100))
        assertFalse(paid.isActive(9_100))
    }

    @Test fun originalEntitlementRemainsCompatible() {
        assertTrue(access(entitlement(id = "premium")).isActive(100))
    }

    @Test fun unrelatedEntitlementsCannotUnlockPremium() {
        assertFalse(access(entitlement(id = "other_feature")).isActive(100))
        assertFalse(access().isActive(100))
    }

    @Test fun inactiveAndExpiredLiveEntitlementsCannotUnlockPremium() {
        assertFalse(access(entitlement(active = false)).isActive(100))
        assertFalse(access(entitlement(expiry = 1_000)).isActive(100))
    }

    @Test fun activeLegacyEntitlementWorksWhenTheLiveEntitlementIsInactive() {
        assertTrue(access(entitlement(active = false), entitlement(id = "premium")).isActive(100))
    }

    @Test fun failedVerificationCannotUnlockEitherIdentifier() {
        for (id in SubscriptionAccess.entitlementIds) {
            val paid = access(entitlement(id = id, verification = VerificationResult.FAILED))
            assertEquals("verification_required", paid.state)
            assertFalse(paid.isActive(100))
        }
        assertFalse(access(entitlement(), verification = VerificationResult.FAILED).isActive(100))
    }

    @Test fun liveLifetimeEntitlementUnlocksLifetimeAccess() {
        val paid = access(entitlement(expiry = null))
        assertEquals("lifetime", paid.state)
        assertTrue(paid.isActive(365L * 86_400_000))
    }
}
