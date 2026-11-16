package com.abrebostudio.consolegametranslator

import android.util.Log
import java.io.File

/** On-device CTranslate2 bridge for the English-to-Turkish HPLT Model C pack. */
internal class HpltCTranslate2 private constructor(
    private var nativeHandle: Long,
    private val sourceTokenizer: SentencePieceTokenizer,
    private val targetTokenizer: SentencePieceTokenizer,
) : AutoCloseable {
    fun translate(text: String): String {
        check(nativeHandle != 0L) { "HPLT modeli kapalı." }
        val input = sourceTokenizer.encode(text.trim().replace(Regex("\\s+"), " "))
            .toMutableList()
        input.add(EOS_TOKEN)
        val output = nativeTranslate(nativeHandle, input.toTypedArray())
        return targetTokenizer.decode(output).trim()
    }

    override fun close() {
        val handle = nativeHandle
        nativeHandle = 0L
        if (handle != 0L) nativeDestroy(handle)
        sourceTokenizer.close()
        targetTokenizer.close()
    }

    companion object {
        private const val EOS_TOKEN = "</s>"
        private const val LOG_TAG = "GameTranslateOCR"

        init {
            System.loadLibrary("hplt_ctranslate2_jni")
        }

        fun load(modelDirectory: File): HpltCTranslate2 {
            require(File(modelDirectory, "model.bin").isFile) {
                "HPLT model.bin bulunamadı."
            }
            val sourceTokenizer = requireNotNull(
                SentencePieceTokenizer.load(File(modelDirectory, "source.spm").absolutePath),
            ) { "HPLT İngilizce sözlüğü açılamadı." }
            val targetTokenizer = try {
                requireNotNull(
                    SentencePieceTokenizer.load(File(modelDirectory, "target.spm").absolutePath),
                ) { "HPLT Türkçe sözlüğü açılamadı." }
            } catch (error: Exception) {
                sourceTokenizer.close()
                throw error
            }
            try {
                // Keep CPU parallelism stable: higher thread counts slowed the
                // tested Android device without changing translation quality.
                val threadCount = minOf(4, Runtime.getRuntime().availableProcessors()).coerceAtLeast(1)
                val handle = nativeCreate(modelDirectory.absolutePath, threadCount)
                check(handle != 0L) { "HPLT modeli yüklenemedi." }
                Log.i(
                    LOG_TAG,
                    "HPLT_RUNTIME_CONFIG model=HPLT-v2-INT8 intraThreads=$threadCount beamSize=4 compute=default",
                )
                return HpltCTranslate2(handle, sourceTokenizer, targetTokenizer)
            } catch (error: Exception) {
                sourceTokenizer.close()
                targetTokenizer.close()
                throw error
            }
        }

        @JvmStatic private external fun nativeCreate(modelDirectory: String, threadCount: Int): Long
        @JvmStatic private external fun nativeTranslate(handle: Long, tokens: Array<String>): Array<String>
        @JvmStatic private external fun nativeDestroy(handle: Long)
    }
}
