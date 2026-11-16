package com.abrebostudio.consolegametranslator

import android.os.Bundle
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.google.gson.Gson
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.security.MessageDigest

/** Uses the real, pinned OPUS-MT pack; see docs/android-16kb-validation.tr.md. */
@RunWith(AndroidJUnit4::class)
class MarianInterpreterCompatibilityTest {
    @Test
    fun pinnedOpusModelTranslatesAcrossRepeatedRunsAndInterpreterRecreation() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val modelPath = InstrumentationRegistry.getArguments().getString("opusModelDir")
        assumeTrue("Provision the pinned model and pass -e opusModelDir (see validation guide)", modelPath != null)
        val modelDir = File(requireNotNull(modelPath))
        val pack = requireNotNull(OfflineMarianCatalog.pack("tr"))
        val model = File(modelDir, "model.tflite")
        assertEquals(pack.bytes, model.length())
        val digest = MessageDigest.getInstance("SHA-256")
        model.inputStream().buffered().use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        assertEquals(pack.sha256, digest.digest().joinToString("") { "%02x".format(it) })

        // Recorded with the previous LiteRT 1.0.1 runtime and the same model.
        // Cover encode, prefill, autoregressive decode, cache reuse and speaker preservation.
        val expected = linkedMapOf(
            "Open the door." to "Kapıyı aç.",
            "Where are you?" to "Neredesin sen?",
            "We need to find the key." to "Anahtarı bulmamız gerek.",
            "JOEL: Stay here." to "JOEL: Burada kal.",
        )
        val sources = expected.keys.toList()
        val results = linkedMapOf<String, String>()
        MarianOnDeviceTranslator.load(modelDir).use { translator ->
            sources.forEach { source ->
                val translated = translator.translate(source)
                assertTrue("No translation for $source", translated.isNotBlank())
                assertNotEquals("Source fallback for $source", source, translated)
                assertEquals("Translation changed for $source", expected[source], translated)
                results[source] = translated
                instrumentation.sendStatus(0, Bundle().apply {
                    putString("stream", "OPUS_COMPAT: $source => $translated\n")
                })
            }
            assertEquals(results[sources.first()], translator.translate(sources.first()))
            assertTrue(requireNotNull(results[sources.last()]).startsWith("JOEL: "))
        }
        MarianOnDeviceTranslator.load(modelDir).use { translator ->
            assertEquals(results[sources.first()], translator.translate(sources.first()))
        }
        File(modelDir, "compatibility-results.json").writeText(Gson().toJson(results))
    }
}
