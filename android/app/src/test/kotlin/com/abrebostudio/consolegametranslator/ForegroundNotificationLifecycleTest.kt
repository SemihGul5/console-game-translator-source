package com.abrebostudio.consolegametranslator

import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.junit.Assert.*
import org.junit.Test

class ForegroundNotificationLifecycleTest {
    @Test
    fun disarmCallbackCannotRepostANotificationDuringShutdown() {
        val lifecycle = ForegroundNotificationLifecycle()
        val events = mutableListOf<String>()
        lifecycle.start()
        lifecycle.update { events += "translation" }
        lifecycle.stop {
            // Mirrors the synchronous access-change event when disarm() runs.
            lifecycle.update { events += "remote-play" }
            events += "removed"
        }
        lifecycle.update { events += "late-frame" }
        assertFalse(lifecycle.isRunning)
        assertEquals(listOf("translation", "removed"), events)
    }

    @Test
    fun aDecoderUpdateAlreadyInProgressFinishesBeforeFinalRemoval() {
        val lifecycle = ForegroundNotificationLifecycle()
        val events = CopyOnWriteArrayList<String>()
        val publishing = CountDownLatch(1)
        val finishPublishing = CountDownLatch(1)
        val stopping = CountDownLatch(1)
        val executor = Executors.newFixedThreadPool(2)
        lifecycle.start()
        try {
            val update = executor.submit {
                lifecycle.update {
                    publishing.countDown()
                    check(finishPublishing.await(3, TimeUnit.SECONDS))
                    events += "published"
                }
            }
            assertTrue(publishing.await(3, TimeUnit.SECONDS))
            val stop = executor.submit {
                stopping.countDown()
                lifecycle.stop { events += "removed" }
            }
            assertTrue(stopping.await(3, TimeUnit.SECONDS))
            assertFalse(stop.isDone)
            finishPublishing.countDown()
            update.get(3, TimeUnit.SECONDS)
            stop.get(3, TimeUnit.SECONDS)
            lifecycle.update { events += "late-access-update" }
            assertEquals(listOf("published", "removed"), events.toList())
        } finally {
            finishPublishing.countDown()
            executor.shutdownNow()
        }
    }

    @Test
    fun stoppingAnAlreadyStoppedServiceStillRemovesAnOrphanNotification() {
        val lifecycle = ForegroundNotificationLifecycle()
        var removals = 0
        lifecycle.stop { removals++ }
        lifecycle.stop { removals++ }
        assertEquals(2, removals)
        lifecycle.update { fail("A stopped notification must not be republished") }
    }

    @Test
    fun aNewSessionCanPublishAfterThePreviousSessionWasStopped() {
        val lifecycle = ForegroundNotificationLifecycle()
        val events = mutableListOf<String>()
        lifecycle.update { events += "before-start" }
        lifecycle.start()
        lifecycle.update { events += "first-session" }
        lifecycle.stop { events += "removed" }
        lifecycle.start()
        lifecycle.update { events += "second-session" }
        assertTrue(lifecycle.isRunning)
        assertEquals(listOf("first-session", "removed", "second-session"), events)
    }
}
