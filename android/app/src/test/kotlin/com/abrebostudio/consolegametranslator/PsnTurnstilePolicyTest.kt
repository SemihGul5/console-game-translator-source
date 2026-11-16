package com.abrebostudio.consolegametranslator

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PsnTurnstilePolicyTest {
    private val page = "https://psn.example.com/turnstile?cdata=${"a".repeat(64)}"
    private val policy = PsnTurnstilePolicy(page)

    @Test fun allowsChallengeAndProbeRequestsSeenInDeviceLogs() {
        listOf(
            page,
            "https://challenges.cloudflare.com/turnstile/v0/api.js",
            "https://hagen.challenges.cloudflare.com/cdn-cgi/challenge-platform/test",
            "https://brunhild.challenges.cloudflare.com/cdn-cgi/challenge-platform/test",
            "https://probe.alg13.dnstest.challenges.cloudflare.com/test",
            "https://probe.mldsa44.dnstest.challenges.cloudflare.com/test",
            "https://ca1.cloudflarecaptcha.com/test",
            "https://ca2.cloudflarecaptcha.com/test",
            "https://dnstest.dev/test",
            "https://HAGEN.challenges.cloudflare.com:443/test",
        ).forEach { url ->
            assertTrue(url, policy.allowsResource(url))
            assertTrue(url, policy.allowsNavigation(url, isMainFrame = false))
        }
    }

    @Test fun allowsInternalFramesRequiredByTurnstile() {
        listOf("about:blank", "about:srcdoc").forEach { url ->
            assertTrue(url, policy.allowsResource(url))
            assertTrue(url, policy.allowsNavigation(url, isMainFrame = false))
            assertFalse(url, policy.allowsNavigation(url, isMainFrame = true))
        }
    }

    @Test fun onlyExactBrokerChallengeCanNavigateTheMainFrame() {
        assertTrue(policy.allowsNavigation(page, isMainFrame = true))
        listOf(
            "https://challenges.cloudflare.com/",
            "https://hagen.challenges.cloudflare.com/test",
            "https://psn.example.com/",
            "$page&extra=true",
            "$page#fragment",
            "gametranslate-turnstile://complete?token=untrusted",
        ).forEach { url -> assertFalse(url, policy.allowsNavigation(url, isMainFrame = true)) }
    }

    @Test fun rejectsLookalikeHostsCredentialsAndNonHttpsResources() {
        listOf(
            "https://challenges.cloudflare.com.attacker.example/test",
            "https://fakechallenges.cloudflare.com/test",
            "https://ca1.cloudflarecaptcha.com.attacker.example/test",
            "https://dnstest.dev.attacker.example/test",
            "https://unrelated.cloudflare.com/test",
            "https://attacker.example@challenges.cloudflare.com/test",
            "https://challenges.cloudflare.com@attacker.example/test",
            "https://challenges.cloudflare.com:8443/test",
            "http://challenges.cloudflare.com/test",
            "file:///sdcard/test.html",
            "content://test/resource",
            "javascript:alert(1)",
            "data:text/html,test",
            "about:config",
            "not a URL",
        ).forEach { url ->
            assertFalse(url, policy.allowsResource(url))
            assertFalse(url, policy.allowsNavigation(url, isMainFrame = false))
        }
    }
}
