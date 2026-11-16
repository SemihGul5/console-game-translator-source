package com.abrebostudio.consolegametranslator

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class BackgroundVideoFrameReaderTest {
    @Test
    fun capturesUprightFramesWithoutAnyActivityOrPreview() {
        BackgroundVideoFrameReader().use { output ->
            assertNull(output.captureLatestBitmap())
            val canvas = output.surface.lockCanvas(null)
            canvas.drawColor(Color.BLUE)
            canvas.drawRect(0f, 0f, canvas.width.toFloat(), canvas.height / 2f,
                Paint().apply { color = Color.RED })
            output.surface.unlockCanvasAndPost(canvas)
            awaitFrame(output, Color.RED).useBitmap { frame ->
                assertColor(Color.RED, frame.getPixel(frame.width / 2, frame.height / 4))
                assertColor(Color.BLUE, frame.getPixel(frame.width / 2, frame.height * 3 / 4))
            }
        }
    }

    @Test
    fun destroyingAndReplacingPreviewKeepsDecoderSurfaceAndNewFramesAlive() {
        val drainThread = HandlerThread("test-preview-drain").apply { start() }
        fun preview() = ImageReader.newInstance(1280, 720, PixelFormat.RGBA_8888, 3).apply {
            setOnImageAvailableListener({ it.acquireLatestImage()?.close() }, Handler(drainThread.looper))
        }
        try {
            BackgroundVideoFrameReader().use { output ->
                val decoderSurface = output.surface
                preview().use { first ->
                    output.setPreviewSurface(first.surface)
                    postColor(output, Color.GREEN)
                    awaitFrame(output, Color.GREEN).recycle()
                    output.setPreviewSurface(null)
                }
                assertSame(decoderSurface, output.surface)
                assertTrue(decoderSurface.isValid)
                postColor(output, Color.BLUE)
                awaitFrame(output, Color.BLUE).recycle()
                preview().use { replacement ->
                    output.setPreviewSurface(replacement.surface)
                    postColor(output, Color.YELLOW)
                    awaitFrame(output, Color.YELLOW).recycle()
                    output.setPreviewSurface(null)
                }
            }
        } finally {
            drainThread.quitSafely()
        }
    }

    private fun postColor(output: BackgroundVideoFrameReader, color: Int) {
        val canvas = output.surface.lockCanvas(null)
        canvas.drawColor(color)
        output.surface.unlockCanvasAndPost(canvas)
    }

    private fun awaitFrame(output: BackgroundVideoFrameReader, topColor: Int): Bitmap {
        val deadline = SystemClock.elapsedRealtime() + 5000
        while (SystemClock.elapsedRealtime() < deadline) {
            val frame = output.captureLatestBitmap()
            if (frame != null) {
                if (colorMatches(topColor, frame.getPixel(frame.width / 2, frame.height / 4))) return frame
                frame.recycle()
            }
            SystemClock.sleep(20)
        }
        throw AssertionError("No fresh decoder frame after preview lifecycle change")
    }

    private fun assertColor(expected: Int, actual: Int) {
        assertTrue("Expected ${Integer.toHexString(expected)}, got ${Integer.toHexString(actual)}",
            colorMatches(expected, actual))
    }

    private fun colorMatches(expected: Int, actual: Int): Boolean =
        kotlin.math.abs(Color.red(expected) - Color.red(actual)) < 12 &&
            kotlin.math.abs(Color.green(expected) - Color.green(actual)) < 12 &&
            kotlin.math.abs(Color.blue(expected) - Color.blue(actual)) < 12

    private inline fun Bitmap.useBitmap(block: (Bitmap) -> Unit) {
        try { block(this) } finally { recycle() }
    }
}
