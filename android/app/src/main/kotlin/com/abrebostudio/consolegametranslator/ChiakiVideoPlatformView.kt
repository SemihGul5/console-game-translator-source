package com.abrebostudio.consolegametranslator

import android.content.Context
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.graphics.Bitmap
import android.os.Handler
import android.os.HandlerThread
import java.io.ByteArrayOutputStream
import io.flutter.plugin.platform.PlatformView

internal class ChiakiVideoPlatformView(
    context: Context,
    private val backgroundFrameProvider: () -> Bitmap?,
    private val onSurfaceChanged: (Surface?) -> Unit,
    private val onDisposed: () -> Unit,
) : PlatformView, SurfaceHolder.Callback {
    private val surfaceView = SurfaceView(context).apply {
        holder.addCallback(this@ChiakiVideoPlatformView)
    }
    private val snapshotThread = HandlerThread("subtitle-snapshot").apply { start() }
    private val snapshotHandler = Handler(snapshotThread.looper)
    override fun getView(): View = surfaceView

    override fun dispose() {
        surfaceView.holder.removeCallback(this)
        snapshotHandler.removeCallbacksAndMessages(null)
        snapshotThread.quitSafely()
        onSurfaceChanged(null)
        onDisposed()
    }

    fun captureSnapshot(completion: (ByteArray?) -> Unit) {
        snapshotHandler.post {
            val frame = runCatching { backgroundFrameProvider() }.getOrNull()
            if (frame == null) {
                completion(null)
                return@post
            }
            try {
                val output = ByteArrayOutputStream()
                frame.compress(Bitmap.CompressFormat.JPEG, 68, output)
                completion(output.toByteArray())
            } finally {
                frame.recycle()
            }
        }
    }


    override fun surfaceCreated(holder: SurfaceHolder) {
        onSurfaceChanged(holder.surface)
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        // EGL reads the current preview dimensions on each frame.
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        onSurfaceChanged(null)
    }
}
