package com.abrebostudio.consolegametranslator

/** Serializes notification updates with shutdown, including decoder callbacks. */
internal class ForegroundNotificationLifecycle {
    @Volatile var isRunning: Boolean = false
        private set

    @Synchronized fun start() {
        isRunning = true
    }

    @Synchronized fun update(publish: () -> Unit) {
        if (isRunning) publish()
    }

    @Synchronized fun stop(remove: () -> Unit) {
        // Disarming access can synchronously request another notification.
        isRunning = false
        remove()
    }
}
