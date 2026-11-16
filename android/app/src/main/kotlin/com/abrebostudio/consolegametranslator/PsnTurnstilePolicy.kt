package com.abrebostudio.consolegametranslator

import java.net.URI
import java.util.Locale

/** Keep the broker page fixed while allowing Turnstile's nested challenge resources. */
internal class PsnTurnstilePolicy(private val page: String) {
    fun allowsNavigation(url: String, isMainFrame: Boolean): Boolean =
        url == page || (!isMainFrame && allowsResource(url))

    fun allowsResource(url: String): Boolean {
        if (url == page || url == "about:blank" || url == "about:srcdoc") return true
        val uri = runCatching { URI(url) }.getOrNull() ?: return false
        if (uri.scheme != "https" || uri.rawUserInfo != null || uri.port !in listOf(-1, 443)) return false
        val host = uri.host?.lowercase(Locale.ROOT) ?: return false
        // Turnstile chooses different challenge/probe endpoints per session.
        // These hosts also appear in the Cloudflare iframe's own CSP.
        return host == "challenges.cloudflare.com" || host.endsWith(".challenges.cloudflare.com") ||
            host == "ca1.cloudflarecaptcha.com" || host == "ca2.cloudflarecaptcha.com" ||
            host == "dnstest.dev"
    }
}
