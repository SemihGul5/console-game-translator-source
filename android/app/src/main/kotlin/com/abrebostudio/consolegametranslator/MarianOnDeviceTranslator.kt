package com.abrebostudio.consolegametranslator

import android.util.Log
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.Interpreter.Options
import java.io.File
import kotlin.math.min

/** Small English→Turkish OPUS-MT model. All inference remains on-device. */
internal class MarianOnDeviceTranslator private constructor(
    private val interpreter: Interpreter,
    private val tokenizer: SentencePieceTokenizer,
    private val vocab: Map<String, Int>,
    private val config: MarianConfig,
) : AutoCloseable {
    private val vocabById = vocab.entries.associate { it.value to it.key }
    private val prefillInputs = interpreter.getSignatureInputs("prefill")
    private val selfCacheNames = prefillInputs.filter { it.contains("self_attn_kv_cache") }.sorted()
    private val crossCacheNames = prefillInputs.filter { it.contains("cross_attn_kv_cache") }.sorted()
    private val selfCacheShapes = selfCacheNames.map { interpreter.getInputTensorFromSignature(it, "prefill").shape() }
    private val crossCacheShapes = crossCacheNames.map { interpreter.getInputTensorFromSignature(it, "prefill").shape() }
    private val seqLen = config.maxPositionEmbeddings
    private val vocabSize = config.decoderVocabSize ?: config.vocabSize

    fun translate(text: String): String {
        val cleaned = text.trim().replace(Regex("\\s+"), " ")
        val speakerMatch = SPEAKER_PREFIX.find(cleaned)
        val speaker = speakerMatch?.groupValues?.get(1)?.trim()
        val body = if (speakerMatch != null) cleaned.substring(speakerMatch.range.last + 1).trim() else cleaned
        if (body.isEmpty()) return ""

        val segments = splitForTranslation(body)
        val translatedSegments = segments.map { segment ->
            val translated = translateSingle(segment)
            if (translated.isBlank()) {
                Log.w(LOG_TAG, "OPUS_SEGMENT_FALLBACK" +
                    if (BuildConfig.DEBUG) " source=${segment.take(180)}" else "")
                segment
            } else translated
        }
        val translatedBody = translatedSegments.joinToString(" ").replace(Regex("\\s+"), " ").trim()
        return if (speaker.isNullOrEmpty()) translatedBody else "$speaker: $translatedBody"
    }

    private fun splitForTranslation(text: String): List<String> {
        val sentenceParts = text.split(SENTENCE_BOUNDARY)
            .flatMap { part ->
                if (part.length <= MAX_SEGMENT_CHARS) listOf(part)
                else part.split(CLAUSE_BOUNDARY).flatMap { clause ->
                    if (clause.length <= MAX_SEGMENT_CHARS) listOf(clause)
                    else splitAtWords(clause)
                }
            }
            .map(String::trim)
            .filter(String::isNotEmpty)
        return sentenceParts.ifEmpty { listOf(text) }
    }

    private fun splitAtWords(text: String): List<String> {
        val words = text.split(Regex("\\s+")).filter(String::isNotEmpty)
        val result = mutableListOf<String>()
        var current = StringBuilder()
        words.forEach { word ->
            if (current.isNotEmpty() && current.length + word.length + 1 > MAX_SEGMENT_CHARS) {
                result += current.toString()
                current = StringBuilder()
            }
            if (current.isNotEmpty()) current.append(' ')
            current.append(word)
        }
        if (current.isNotEmpty()) result += current.toString()
        return result
    }

    private fun translateSingle(text: String): String {
        val sourcePieces = tokenizer.encode(text).toList()
        val ids = sourcePieces.map { vocab[it] ?: vocab["<unk>"] ?: 0 } + config.eosTokenId
        val encoderTokens = Array(1) { IntArray(seqLen) }
        ids.take(seqLen).forEachIndexed { i, id -> encoderTokens[0][i] = id }
        val positions = IntArray(seqLen) { it }
        val padMask = FloatArray(seqLen) { if (it < ids.size) 0f else -1e9f }
        val hidden = Array(1) { Array(seqLen) { FloatArray(config.dModel) } }
        interpreter.runSignature(
            mapOf("input_ids" to encoderTokens, "input_pos" to positions, "pad_mask" to padMask),
            mutableMapOf<String, Any>("output_0" to hidden), "encode",
        )

        var selfCaches = mutableCaches(selfCacheShapes)
        var crossCaches = mutableCaches(crossCacheShapes)
        val prefillInputs = mutableMapOf<String, Any>(
            "decoder_input_ids" to arrayOf(intArrayOf(config.decoderStartTokenId)),
            "decoder_input_pos" to intArrayOf(0), "encoder_hidden_states" to hidden, "pad_mask" to padMask,
        )
        addCaches(prefillInputs, selfCaches, crossCaches)
        val prefillLogits = Array(1) { Array(1) { FloatArray(vocabSize) } }
        val nextSelf = mutableCaches(selfCacheShapes); val nextCross = mutableCaches(crossCacheShapes)
        val prefillOutputs = mutableMapOf<String, Any>("logits" to prefillLogits)
        addCaches(prefillOutputs, nextSelf, nextCross)
        interpreter.runSignature(prefillInputs, prefillOutputs, "prefill")
        selfCaches = nextSelf; crossCaches = nextCross

        var next = argmax(prefillLogits[0][0])
        val generated = mutableListOf<Int>()
        var step = 1
        var previousToken = -1
        var repeatedTokenCount = 0
        // Decoder inference is autoregressive, so every token needs the latest
        // KV cache. Keep two cache sets and swap them instead of allocating a
        // fresh set of large nested FloatArrays for every generated token.
        var decodeOutputSelfCaches = mutableCaches(selfCacheShapes)
        var decodeOutputCrossCaches = mutableCaches(crossCacheShapes)
        val decoderToken = arrayOf(intArrayOf(0))
        val decoderPosition = intArrayOf(0)
        val decodeInputs = mutableMapOf<String, Any>(
            "decoder_input_ids" to decoderToken,
            "decoder_input_pos" to decoderPosition,
            "encoder_hidden_states" to hidden,
            "pad_mask" to padMask,
        )
        val logits = Array(1) { Array(1) { FloatArray(vocabSize) } }
        val decodeOutputs = mutableMapOf<String, Any>("logits" to logits)
        while (step < MAX_NEW_TOKENS && next != config.eosTokenId && next != config.padTokenId) {
            if (next == previousToken) repeatedTokenCount++ else repeatedTokenCount = 0
            // A Marian sentence should not emit the same token indefinitely. Treat
            // this as a decoder failure instead of publishing a fabricated subtitle.
            if (repeatedTokenCount >= MAX_CONSECUTIVE_IDENTICAL_TOKENS) {
                // Tokens and token IDs can reconstruct subtitle text. Keep the
                // trace (and its expensive sorting) only for debug diagnostics.
                if (BuildConfig.DEBUG) {
                    val unknownPieces = sourcePieces.filter { it !in vocab }
                    val emitted = generated + next
                    val topPrefillIds = prefillLogits[0][0].indices
                        .sortedByDescending { prefillLogits[0][0][it] }
                        .take(8)
                    Log.w(
                        LOG_TAG,
                        "OPUS_DECODER_TRACE sourcePieces=${sourcePieces.take(64)} " +
                            "unknownPieces=${unknownPieces.take(16)} inputIds=${ids.take(64)} " +
                            "prefillTop=${topPrefillIds.map { "$it:${vocabById[it]}" }} " +
                            "generatedIds=${emitted.take(32)} " +
                            "generatedPieces=${emitted.take(32).map { vocabById[it] ?: "<unk>" }}",
                    )
                } else {
                    Log.w(LOG_TAG, "OPUS_DECODER_OUTPUT_REJECTED reason=repeated-token-loop")
                }
                return ""
            }
            previousToken = next
            generated.add(next)
            decoderToken[0][0] = next
            decoderPosition[0] = step
            addCaches(decodeInputs, selfCaches, crossCaches)
            addCaches(decodeOutputs, decodeOutputSelfCaches, decodeOutputCrossCaches)
            interpreter.runSignature(decodeInputs, decodeOutputs, "decode")
            val oldSelfCaches = selfCaches
            selfCaches = decodeOutputSelfCaches
            decodeOutputSelfCaches = oldSelfCaches
            val oldCrossCaches = crossCaches
            crossCaches = decodeOutputCrossCaches
            decodeOutputCrossCaches = oldCrossCaches
            next = argmax(logits[0][0]); step++
        }
        // Keep decoding aligned with MarianTokenizer: ids map back to vocabulary
        // pieces, then SentencePiece's visible word-boundary marker becomes space.
        return generated.map { vocabById[it] ?: "<unk>" }
            .joinToString("")
            .replace("▁", " ")
            .trim()
    }

    private fun mutableCaches(shapes: List<IntArray>): MutableList<Any> = shapes.map(::newFloatArray).toMutableList()
    private fun addCaches(map: MutableMap<String, Any>, self: List<Any>, cross: List<Any>) {
        selfCacheNames.forEachIndexed { i, name -> map[name] = self[i] }
        crossCacheNames.forEachIndexed { i, name -> map[name] = cross[i] }
    }
    private fun newFloatArray(shape: IntArray): Any = when (shape.size) {
        1 -> FloatArray(shape[0])
        2 -> Array(shape[0]) { FloatArray(shape[1]) }
        3 -> Array(shape[0]) { Array(shape[1]) { FloatArray(shape[2]) } }
        4 -> Array(shape[0]) { Array(shape[1]) { Array(shape[2]) { FloatArray(shape[3]) } } }
        else -> error("Unsupported cache tensor shape")
    }
    private fun argmax(values: FloatArray): Int = values.indices.maxByOrNull { values[it] } ?: config.eosTokenId

    override fun close() { interpreter.close(); tokenizer.close() }

    companion object {
        private const val LOG_TAG = "GameTranslateOCR"
        private const val MAX_NEW_TOKENS = 100
        private const val MAX_CONSECUTIVE_IDENTICAL_TOKENS = 4
        private const val MAX_SEGMENT_CHARS = 100
        private val SPEAKER_PREFIX = Regex("^\\s*([\\p{L}][\\p{L}0-9 _'-]{0,24}):\\s*")
        private val SENTENCE_BOUNDARY = Regex("(?<=[.!?…])\\s+(?=[\\p{L}\"'])")
        private val CLAUSE_BOUNDARY = Regex("(?<=[,;])\\s+")
        fun load(modelDir: File): MarianOnDeviceTranslator {
            val config = Gson().fromJson(File(modelDir, "config.json").readText(), MarianConfig::class.java)
            require(config.dModel == 256 && config.maxPositionEmbeddings == 256 &&
                config.decoderStartTokenId == 32000 && config.eosTokenId == 0 &&
                config.vocabSize == 32001 && config.decoderVocabSize == 32001) {
                "OPUS-MT model configuration does not match the pinned English-Turkish TFLite model"
            }
            val vocab = Gson().fromJson(File(modelDir, "vocab.json").readText(),
                object : com.google.gson.reflect.TypeToken<Map<String, Int>>() {}.type) as Map<String, Int>
            require(vocab.size == config.vocabSize && vocab["</s>"] == config.eosTokenId &&
                vocab["<pad>"] == config.padTokenId && vocab["<unk>"] != null) {
                "OPUS-MT vocabulary does not match the pinned model configuration"
            }
            val tokenizer = requireNotNull(SentencePieceTokenizer.load(File(modelDir, "source.spm").absolutePath)) {
                "OPUS-MT SentencePiece sözlüğü açılamadı"
            }
            try {
                val options = Options().setNumThreads(min(4, Runtime.getRuntime().availableProcessors()).coerceAtLeast(2))
                return MarianOnDeviceTranslator(Interpreter(File(modelDir, "model.tflite"), options), tokenizer, vocab, config)
            } catch (error: Exception) { tokenizer.close(); throw error }
        }
    }
}

internal data class MarianConfig(
    @SerializedName("d_model") val dModel: Int,
    @SerializedName("max_position_embeddings") val maxPositionEmbeddings: Int,
    @SerializedName("vocab_size") val vocabSize: Int,
    @SerializedName("decoder_vocab_size") val decoderVocabSize: Int? = null,
    @SerializedName("pad_token_id") val padTokenId: Int,
    @SerializedName("eos_token_id") val eosTokenId: Int,
    @SerializedName("decoder_start_token_id") val decoderStartTokenId: Int,
)
