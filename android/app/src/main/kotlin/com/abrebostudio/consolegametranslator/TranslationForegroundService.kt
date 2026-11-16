package com.abrebostudio.consolegametranslator

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock

internal class TranslationForegroundService : Service() {
    private val notifications = ForegroundNotificationLifecycle()
    private var cpuWakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private val watchdog = Handler(Looper.getMainLooper())
    private var serviceStartedAt = 0L
    private val access by lazy { TranslationAccessController.get(applicationContext) }
    private val accessWatchdog = object : Runnable {
        override fun run() {
            if (!notifications.isRunning) return
            access.tick()
            watchdog.postDelayed(this, 1_000L)
        }
    }
    @Volatile private var lastFrameCopiedAt = 0L
    @Volatile private var staleNoticeShown = false

    private val frameWatchdog = object : Runnable {
        override fun run() {
            if (!notifications.isRunning) return
            val now = SystemClock.elapsedRealtime()
            val lastFrame = lastFrameCopiedAt
            val reference = if (lastFrame == 0L) serviceStartedAt else lastFrame
            val timeout = if (lastFrame == 0L) FIRST_FRAME_TIMEOUT_MS else FRAME_STALE_TIMEOUT_MS
            if (now - reference > timeout) {
                if (!staleNoticeShown) {
                    staleNoticeShown = true
                    val title = if (lastFrame == 0L) "Remote Play karesi bekleniyor" else "Çeviri beklemede"
                    val text = if (lastFrame == 0L) {
                        "İlk video karesi henüz alınmadı. Bildirim açık kalıyor."
                    } else {
                        "Yeni video karesi yok. Görüntü gelince çeviri sürdürülecek."
                    }
                    updateNotification(title, text)
                }
            }
            watchdog.postDelayed(this, WATCHDOG_INTERVAL_MS)
        }
    }

    companion object {
        val isRunning: Boolean get() = instance?.notifications?.isRunning == true
        private const val CHANNEL_ID = "translation_status_v2"
        private const val NOTIFICATION_ID = 81
        private const val WATCHDOG_INTERVAL_MS = 3_000L
        private const val FIRST_FRAME_TIMEOUT_MS = 60_000L
        private const val FRAME_STALE_TIMEOUT_MS = 15_000L
        const val ACTION_STOP = "com.abrebostudio.consolegametranslator.STOP_TRANSLATION"
        @Volatile private var instance: TranslationForegroundService? = null

        fun reportFrameCopied() {
            instance?.onFrameCopied()
        }

        fun refreshAccessNotification() {
            instance?.let { service ->
                service.updateNotification(
                    if (service.access.hasAccess()) "Çeviri çalışıyor" else "Remote Play oturumu",
                    "Menüye dönmek için dokun.",
                )
            }
        }

        fun stop(context: Context) {
            val service = instance
            if (service != null) service.removeForegroundNotification()
            context.stopService(Intent(context, TranslationForegroundService::class.java))
            if (service == null) {
                // Also remove an orphan left behind by an older service build.
                context.getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                AppUiLanguage.text(this, "Çeviri durumu"),
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply { description = AppUiLanguage.text(this@TranslationForegroundService, "Remote Play altyazı çevirisi") }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            removeForegroundNotification()
            stopSelf()
            return START_NOT_STICKY
        }
        val notification = buildNotification(
            if (access.isTranslationRequested) "Çeviri hazırlanıyor" else "Remote Play oturumu",
            "PS5 bağlantısı arka planda sürüyor. Menüye dönmek için dokun.",
        )
        startForeground(NOTIFICATION_ID, notification)
        // A foreground service keeps the process important, but does not by
        // itself prevent the CPU or Wi-Fi radio from suspending with the display off.
        try {
            acquireBackgroundLocks()
            if (!notifications.isRunning) {
                serviceStartedAt = SystemClock.elapsedRealtime()
                lastFrameCopiedAt = 0L
                staleNoticeShown = false
            }
            notifications.start()
            watchdog.removeCallbacks(frameWatchdog)
            watchdog.postDelayed(frameWatchdog, WATCHDOG_INTERVAL_MS)
            watchdog.removeCallbacks(accessWatchdog)
            watchdog.postDelayed(accessWatchdog, 1_000L)
        } catch (_: Exception) {
            removeForegroundNotification()
            stopSelf(startId)
            return START_NOT_STICKY
        }
        // The application controller survives Activity recreation. A process
        // restart still needs a new PS5 session, so never restore an orphan service.
        return START_NOT_STICKY
    }

    private fun onFrameCopied() {
        if (!notifications.isRunning) return
        access.onVideoFrame()
        val wasFirstFrame = lastFrameCopiedAt == 0L
        val recoveredFromStale = staleNoticeShown
        lastFrameCopiedAt = SystemClock.elapsedRealtime()
        staleNoticeShown = false
        if (wasFirstFrame || recoveredFromStale) {
            updateNotification(
                if (access.hasAccess()) "Çeviri çalışıyor" else "Remote Play bağlı",
                "PS5 bağlantısı arka planda sürüyor. Menüye dönmek için dokun.",
            )
        }
    }

    private fun updateNotification(title: String, text: String) {
        notifications.update {
            getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, buildNotification(title, text))
        }
    }

    private fun removeForegroundNotification() {
        notifications.stop {
            stopForeground(STOP_FOREGROUND_REMOVE)
            getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
        }
    }

    private fun buildNotification(title: String, text: String): Notification {
        val openHomeIntent = Intent(this, MainActivity::class.java).apply {
            action = MainActivity.ACTION_OPEN_HOME_FROM_TRANSLATION_NOTIFICATION
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 41, openHomeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        val stopIntent = PendingIntent.getService(
            this, 42, Intent(this, TranslationForegroundService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return builder
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(AppUiLanguage.text(this, title))
            .setContentText(AppUiLanguage.text(this, text))
            .setCategory(Notification.CATEGORY_SERVICE)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .addAction(Notification.Action.Builder(
                android.graphics.drawable.Icon.createWithResource(this, android.R.drawable.ic_media_pause),
                AppUiLanguage.text(this, "Durdur"), stopIntent,
            ).build())
            .build()
    }

    private fun acquireBackgroundLocks() {
        if (cpuWakeLock?.isHeld != true) {
            val power = getSystemService(Context.POWER_SERVICE) as PowerManager
            cpuWakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "$packageName:translation").apply {
                setReferenceCounted(false)
                acquire()
            }
        }
        if (wifiLock?.isHeld != true) {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            @Suppress("DEPRECATION")
            wifiLock = wifi.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "$packageName:translation-wifi").apply {
                setReferenceCounted(false)
                acquire()
            }
        }
    }

    private fun releaseBackgroundLocks() {
        runCatching { cpuWakeLock?.takeIf { it.isHeld }?.release() }
        runCatching { wifiLock?.takeIf { it.isHeld }?.release() }
        cpuWakeLock = null
        wifiLock = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        watchdog.removeCallbacksAndMessages(null)
        removeForegroundNotification()
        if (instance === this) instance = null
        access.disarm()
        releaseBackgroundLocks()
        RemotePlayController.onServiceStopped()
        super.onDestroy()
    }
}
