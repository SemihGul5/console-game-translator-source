package com.abrebostudio.consolegametranslator

import java.util.concurrent.Executor
import java.util.concurrent.RejectedExecutionException

/** One running inference and only the latest pending reading per region. Yields between jobs. */
internal class LatestLocalTranslationQueue(private val executor: Executor) {
    private data class Task(val region: Int, val identity: String, val work: () -> Unit)
    private val pending = linkedMapOf<Int, Task>()
    private var running: Task? = null
    private var scheduled = false

    @Synchronized fun submit(region: Int, identity: String, work: () -> Unit) {
        if (running?.let { it.region == region && it.identity == identity } == true) {
            // Returning to the running line also supersedes a queued OCR variant.
            pending.remove(region)
            return
        }
        if (pending[region]?.identity == identity) return
        pending[region] = Task(region, identity, work)
        if (!scheduled) {
            scheduled = true
            schedule()
        }
    }

    @Synchronized fun clear() { pending.clear() }

    private fun runNext() {
        val task = synchronized(this) {
            val next = pending.keys.firstOrNull()?.let { pending.remove(it) }
            running = next
            next
        }
        try { task?.work?.invoke() }
        finally {
            synchronized(this) {
                running = null
                if (pending.isNotEmpty()) schedule()
                else scheduled = false
            }
        }
    }

    private fun schedule() {
        try { executor.execute(::runNext) }
        catch (_: RejectedExecutionException) {
            pending.clear()
            scheduled = false
        }
    }
}
