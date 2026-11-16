package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test
import java.util.concurrent.Executor
import java.util.concurrent.RejectedExecutionException

class LatestLocalTranslationQueueTest {
    private class Worker : Executor {
        val work = ArrayDeque<Runnable>()
        override fun execute(command: Runnable) { work.add(command) }
        fun drain() { while (work.isNotEmpty()) work.removeFirst().run() }
    }

    @Test fun oneRunningJobRetainsOnlyTheLatestPendingReadForEachRegion() {
        val worker = Worker()
        val queue = LatestLocalTranslationQueue(worker)
        val calls = mutableListOf<String>()
        queue.submit(0, "first") {
            calls.add("first")
            repeat(1000) { index -> queue.submit(0, "variant $index") { calls.add("variant $index") } }
            queue.submit(1, "other region") { calls.add("other region") }
        }
        worker.drain()
        assertEquals(listOf("first", "variant 999", "other region"), calls)
    }

    @Test fun returningToTheRunningReadingDoesNotDuplicateInferenceOrKeepAnObsoleteVariant() {
        val worker = Worker()
        val queue = LatestLocalTranslationQueue(worker)
        var calls = 0
        queue.submit(0, "current") {
            calls++
            queue.submit(0, "noise") { error("Obsolete variant") }
            repeat(1000) { queue.submit(0, "current") { error("Duplicate inference") } }
        }
        worker.drain()
        assertEquals(1, calls)
    }

    @Test fun aLanguageChangeOrModelCloseCanRunBeforeTheNextInference() {
        val worker = Worker()
        val queue = LatestLocalTranslationQueue(worker)
        val calls = mutableListOf<String>()
        queue.submit(0, "old model") {
            calls.add("old model")
            queue.submit(0, "new model") { calls.add("new model") }
            worker.execute { calls.add("close old model") }
        }
        worker.drain()
        assertEquals(listOf("old model", "close old model", "new model"), calls)
    }

    @Test fun stoppingClearsPendingWorkAndAllowsAFreshSessionToStart() {
        val worker = Worker()
        val queue = LatestLocalTranslationQueue(worker)
        queue.submit(0, "stopped") { error("Stopped session") }
        queue.clear()
        var calls = 0
        queue.submit(0, "new session") { calls++ }
        worker.drain()
        assertEquals(1, calls)
    }

    @Test fun closingTheExecutorCannotCrashAQueuedOcrCallback() {
        val queue = LatestLocalTranslationQueue(Executor { throw RejectedExecutionException("closed") })
        repeat(100) { queue.submit(0, "stopped $it") { error("Closed worker must not run") } }
        queue.clear()
    }
}
