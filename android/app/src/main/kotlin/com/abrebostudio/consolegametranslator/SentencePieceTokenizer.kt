package com.abrebostudio.consolegametranslator

internal class SentencePieceTokenizer private constructor(private val handle: Long) : AutoCloseable {
    fun encode(text: String): Array<String> = nativeEncode(handle, text)
    fun decode(pieces: Array<String>): String = nativeDecode(handle, pieces)
    override fun close() = nativeDestroy(handle)

    companion object {
        init { System.loadLibrary("sentencepiece_jni") }
        fun load(path: String): SentencePieceTokenizer? = nativeCreate(path).takeIf { it != 0L }?.let(::SentencePieceTokenizer)
        @JvmStatic private external fun nativeCreate(path: String): Long
        @JvmStatic private external fun nativeDestroy(handle: Long)
        @JvmStatic private external fun nativeEncode(handle: Long, input: String): Array<String>
        @JvmStatic private external fun nativeDecode(handle: Long, input: Array<String>): String
    }
}
