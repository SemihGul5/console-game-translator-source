package com.abrebostudio.consolegametranslator

/** Monotonic, local-only cooldown. Reading status never calls a translation API. */
internal class CloudTranslationRetryPolicy(private val now: () -> Long) {
    private data class Failure(val code: String, val message: String, val until: Long)
    @Volatile private var failure: Failure? = null
    private var consecutiveFailures = 0

    val remainingMs: Long get() {
        val current = failure ?: return 0L
        return if (current.until == Long.MAX_VALUE) Long.MAX_VALUE else (current.until - now()).coerceAtLeast(0L)
    }
    val waiting: Boolean get() = remainingMs > 0L
    val allowsGeminiFallback: Boolean get() = waiting && failure?.code in setOf(
        "GEMINI_RATE_LIMIT", "GEMINI_QUOTA", "GEMINI_UNAVAILABLE", "GEMINI_NETWORK",
    )

    fun canRetryLatest(lastConfirmedAt: Long, sampleIntervalMs: Long): Boolean =
        !waiting && isLatestFresh(lastConfirmedAt, sampleIntervalMs)

    fun isLatestFresh(lastConfirmedAt: Long, sampleIntervalMs: Long): Boolean =
        lastConfirmedAt > 0L && now() - lastConfirmedAt in 0L..maxOf(2000L, sampleIntervalMs * 2)

    fun fail(code: String, message: String, suggestedDelayMs: Long): Long {
        consecutiveFailures = (consecutiveFailures + 1).coerceAtMost(5)
        val delay = maxOf(suggestedDelayMs, (5_000L shl (consecutiveFailures - 1)).coerceAtMost(60_000L))
        defer(code, message, delay)
        return delay
    }

    /** Adopt an aggregate key-pool deadline without adding another exponential backoff. */
    fun defer(code: String, message: String, delayMs: Long) {
        failure = Failure(code, message, if (delayMs == Long.MAX_VALUE) Long.MAX_VALUE else now() + delayMs.coerceAtLeast(0))
    }

    fun clear() { failure = null; consecutiveFailures = 0 }

    fun snapshot(): Map<String, Any?> {
        val current = failure ?: return mapOf("state" to "idle", "remainingMs" to 0L)
        val remaining = if (current.until == Long.MAX_VALUE) Long.MAX_VALUE else (current.until - now()).coerceAtLeast(0L)
        if (remaining == 0L) return mapOf("state" to "idle", "remainingMs" to 0L)
        return mapOf("state" to if (remaining == Long.MAX_VALUE) "paused" else "waiting",
            "code" to current.code, "message" to current.message,
            "remainingMs" to if (remaining == Long.MAX_VALUE) 0L else remaining)
    }
}
