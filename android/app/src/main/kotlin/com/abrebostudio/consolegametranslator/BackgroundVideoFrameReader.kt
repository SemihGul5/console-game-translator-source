package com.abrebostudio.consolegametranslator

import android.graphics.Bitmap
import android.graphics.Rect
import android.graphics.SurfaceTexture
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLSurface
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Log
import android.view.Surface
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.FutureTask
import java.util.concurrent.TimeUnit

internal data class CroppedVideoFrame(val bitmap: Bitmap, val bounds: Rect,
    val sourceWidth: Int, val sourceHeight: Int)

/** One decoder surface for the whole session, independent of the visible preview. */
internal class BackgroundVideoFrameReader : AutoCloseable {
    private val thread = HandlerThread("remote-play-video").apply { start() }
    private val handler = Handler(thread.looper)
    private var display = EGL14.EGL_NO_DISPLAY
    private var context = EGL14.EGL_NO_CONTEXT
    private var offscreen = EGL14.EGL_NO_SURFACE
    private var preview = EGL14.EGL_NO_SURFACE
    private var previewTarget: Surface? = null
    private lateinit var config: EGLConfig
    private lateinit var texture: SurfaceTexture
    private lateinit var decoderSurface: Surface
    private var textureId = 0
    private var program = 0
    private var positionLocation = 0
    private var matrixLocation = 0
    private val transform = FloatArray(16)
    private val vertices = ByteBuffer.allocateDirect(8 * 4).order(ByteOrder.nativeOrder())
        .asFloatBuffer().apply { put(floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f)); position(0) }
    private val pixels = ByteBuffer.allocateDirect(WIDTH * HEIGHT * 4).order(ByteOrder.nativeOrder())
    private var hasFrame = false
    @Volatile private var closed = false

    val surface: Surface get() = decoderSurface

    init {
        try {
            onVideoThread {
                display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
                check(EGL14.eglInitialize(display, IntArray(2), 0, IntArray(2), 0))
                val configs = arrayOfNulls<EGLConfig>(1)
                check(EGL14.eglChooseConfig(display, intArrayOf(
                    EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8,
                    EGL14.EGL_BLUE_SIZE, 8, EGL14.EGL_ALPHA_SIZE, 8,
                    EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                    EGL14.EGL_SURFACE_TYPE, EGL14.EGL_PBUFFER_BIT or EGL14.EGL_WINDOW_BIT,
                    EGL14.EGL_NONE,
                ), 0, configs, 0, 1, IntArray(1), 0))
                config = checkNotNull(configs[0])
                context = EGL14.eglCreateContext(display, config, EGL14.EGL_NO_CONTEXT,
                    intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE), 0)
                check(context != EGL14.EGL_NO_CONTEXT)
                // The pbuffer remains current even when Android destroys SurfaceView.
                offscreen = EGL14.eglCreatePbufferSurface(display, config,
                    intArrayOf(EGL14.EGL_WIDTH, WIDTH, EGL14.EGL_HEIGHT, HEIGHT, EGL14.EGL_NONE), 0)
                check(offscreen != EGL14.EGL_NO_SURFACE)
                makeCurrent(offscreen)
                EGL14.eglSwapInterval(display, 0)
                program = createProgram()
                positionLocation = GLES20.glGetAttribLocation(program, "position")
                matrixLocation = GLES20.glGetUniformLocation(program, "textureMatrix")
                val textures = IntArray(1)
                GLES20.glGenTextures(1, textures, 0)
                textureId = textures[0]
                GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
                GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
                GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
                GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
                GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
                texture = SurfaceTexture(textureId).apply { setDefaultBufferSize(WIDTH, HEIGHT) }
                decoderSurface = Surface(texture)
                texture.setOnFrameAvailableListener({
                    if (!closed) {
                        try {
                            makeCurrent(offscreen)
                            texture.updateTexImage()
                            texture.getTransformMatrix(transform)
                            hasFrame = true
                            TranslationForegroundService.reportFrameCopied()
                            drawPreview()
                        } catch (error: Exception) {
                            Log.w(TAG, "Could not consume video frame", error)
                        }
                    }
                }, handler)
            }
        } catch (error: Exception) {
            runCatching { close() }
            throw error
        }
    }

    fun setPreviewSurface(surface: Surface?) {
        if (closed) return
        // Detach EGL before SurfaceHolder.surfaceDestroyed returns. No codec locks.
        onVideoThread {
            if (previewTarget === surface) return@onVideoThread
            releasePreview()
            if (surface?.isValid == true) {
                preview = EGL14.eglCreateWindowSurface(display, config, surface,
                    intArrayOf(EGL14.EGL_NONE), 0)
                if (preview != EGL14.EGL_NO_SURFACE) previewTarget = surface
                if (hasFrame) drawPreview()
            }
        }
    }

    fun captureLatestBitmap(): Bitmap? {
        if (closed) return null
        return onVideoThread {
            if (!hasFrame) return@onVideoThread null
            readBitmap(Rect(0, 0, WIDTH, HEIGHT))
        }
    }

    /** Read back only the selected union; avoid converting 720p pixels for a subtitle strip. */
    fun captureLatestCrop(regions: List<FloatArray>): CroppedVideoFrame? {
        if (closed || regions.isEmpty()) return null
        return onVideoThread {
            if (!hasFrame) return@onVideoThread null
            val crop = ocrUnionBounds(WIDTH, HEIGHT, regions)
            val bounds = Rect(crop.left, crop.top, crop.right, crop.bottom)
            CroppedVideoFrame(readBitmap(bounds), bounds, WIDTH, HEIGHT)
        }
    }

    private fun readBitmap(bounds: Rect): Bitmap {
        makeCurrent(offscreen)
        draw(WIDTH, HEIGHT)
        pixels.clear()
        val width = bounds.width()
        val height = bounds.height()
        GLES20.glReadPixels(bounds.left, HEIGHT - bounds.bottom, width, height, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, pixels)
        check(GLES20.glGetError() == GLES20.GL_NO_ERROR) { "Video readback failed" }
        val colors = rgbaReadbackPixels(pixels.asIntBuffer(), width, height, ByteOrder.nativeOrder() == ByteOrder.LITTLE_ENDIAN)
        return Bitmap.createBitmap(colors, width, height, Bitmap.Config.ARGB_8888)
    }

    private fun drawPreview() {
        if (preview == EGL14.EGL_NO_SURFACE) return
        if (previewTarget?.isValid != true || !EGL14.eglMakeCurrent(display, preview, preview, context)) {
            releasePreview()
            return
        }
        val size = IntArray(2)
        EGL14.eglQuerySurface(display, preview, EGL14.EGL_WIDTH, size, 0)
        EGL14.eglQuerySurface(display, preview, EGL14.EGL_HEIGHT, size, 1)
        draw(size[0], size[1])
        if (!EGL14.eglSwapBuffers(display, preview)) releasePreview()
        makeCurrent(offscreen)
    }

    private fun draw(width: Int, height: Int) {
        GLES20.glViewport(0, 0, width, height)
        GLES20.glUseProgram(program)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glUniformMatrix4fv(matrixLocation, 1, false, transform, 0)
        vertices.position(0)
        GLES20.glEnableVertexAttribArray(positionLocation)
        GLES20.glVertexAttribPointer(positionLocation, 2, GLES20.GL_FLOAT, false, 0, vertices)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
    }

    private fun makeCurrent(surface: EGLSurface) {
        check(EGL14.eglMakeCurrent(display, surface, surface, context)) { "Cannot bind video EGL context" }
    }

    private fun releasePreview() {
        if (offscreen != EGL14.EGL_NO_SURFACE) makeCurrent(offscreen)
        if (preview != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(display, preview)
        preview = EGL14.EGL_NO_SURFACE
        previewTarget = null
    }

    private fun createProgram(): Int {
        fun shader(type: Int, source: String): Int {
            val id = GLES20.glCreateShader(type)
            GLES20.glShaderSource(id, source)
            GLES20.glCompileShader(id)
            val status = IntArray(1)
            GLES20.glGetShaderiv(id, GLES20.GL_COMPILE_STATUS, status, 0)
            check(status[0] != 0) { GLES20.glGetShaderInfoLog(id) }
            return id
        }
        val vertex = shader(GLES20.GL_VERTEX_SHADER, """
            attribute vec4 position;
            uniform mat4 textureMatrix;
            varying vec2 textureCoordinate;
            void main() {
                gl_Position = position;
                textureCoordinate = (textureMatrix * vec4((position.xy + 1.0) * 0.5, 0.0, 1.0)).xy;
            }
        """.trimIndent())
        val fragment = shader(GLES20.GL_FRAGMENT_SHADER, """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            uniform samplerExternalOES video;
            varying vec2 textureCoordinate;
            void main() { gl_FragColor = texture2D(video, textureCoordinate); }
        """.trimIndent())
        return GLES20.glCreateProgram().also { id ->
            GLES20.glAttachShader(id, vertex)
            GLES20.glAttachShader(id, fragment)
            GLES20.glLinkProgram(id)
            GLES20.glDeleteShader(vertex)
            GLES20.glDeleteShader(fragment)
            val status = IntArray(1)
            GLES20.glGetProgramiv(id, GLES20.GL_LINK_STATUS, status, 0)
            check(status[0] != 0) { GLES20.glGetProgramInfoLog(id) }
        }
    }

    private fun <T> onVideoThread(block: () -> T): T {
        if (Looper.myLooper() == thread.looper) return block()
        val task = FutureTask(block)
        check(handler.post(task)) { "Video thread has stopped" }
        return task.get(5, TimeUnit.SECONDS)
    }

    override fun close() {
        if (closed) return
        closed = true
        try {
            onVideoThread {
                if (::texture.isInitialized) texture.setOnFrameAvailableListener(null)
                releasePreview()
                if (::decoderSurface.isInitialized) decoderSurface.release()
                if (::texture.isInitialized) texture.release()
                if (program != 0) GLES20.glDeleteProgram(program)
                if (textureId != 0) GLES20.glDeleteTextures(1, intArrayOf(textureId), 0)
                EGL14.eglMakeCurrent(display, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
                if (offscreen != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(display, offscreen)
                if (context != EGL14.EGL_NO_CONTEXT) EGL14.eglDestroyContext(display, context)
                if (display != EGL14.EGL_NO_DISPLAY) EGL14.eglTerminate(display)
            }
        } finally {
            handler.removeCallbacksAndMessages(null)
            thread.quitSafely()
        }
    }

    companion object {
        private const val TAG = "GameTranslateBgFrames"
        private const val WIDTH = 1280
        private const val HEIGHT = 720
    }
}
