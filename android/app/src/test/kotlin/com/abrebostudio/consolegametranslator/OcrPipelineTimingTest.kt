package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class OcrPipelineTimingTest {
    @Test fun visualReuseCannotHideOneChangedPixelOrExtendItselfIndefinitely() {
        val pixels = IntArray(64) { 0xff202020.toInt() }
        val key = ocrPixelFingerprint(8, 8, pixels)
        val cache = OcrVisualCache<String>()
        cache.remember(key, 1000, "old OCR")
        assertEquals("old OCR", cache.reuse(key, 1050))
        assertEquals("old OCR", cache.reuse(key, 1100))
        assertNull(cache.reuse(key, 1150))
        pixels[31] = 0xffffffff.toInt()
        assertNotEquals(key, ocrPixelFingerprint(8, 8, pixels))
        assertNull(cache.reuse(ocrPixelFingerprint(8, 8, pixels), 1050))
        assertNotEquals(key, ocrPixelFingerprint(4, 16, pixels))
    }
    @Test fun twentyHzHasNoExtraFiftyMillisecondPauseAfterASlowRead() {
        assertEquals(20L, nextOcrSampleDelay(1000, 1030, 50))
        assertEquals(0L, nextOcrSampleDelay(1000, 1060, 50))
        assertEquals(0L, nextOcrSampleDelay(1000, 1120, 50))
    }

    @Test fun subtitleReadbackUsesOnlyTheSelectedPixelsAndKeepsTheSameCoordinates() {
        val bounds = ocrUnionBounds(1280, 720, listOf(floatArrayOf(.10f, .78f, .80f, .22f)))
        assertEquals(128, bounds.left)
        assertEquals(561, bounds.top)
        assertEquals(1152, bounds.right)
        assertEquals(720, bounds.bottom)
        assertTrue(bounds.width * bounds.height < 1280 * 720 / 5)
        val multiple = ocrUnionBounds(1280, 720, listOf(floatArrayOf(.1f, .1f, .2f, .1f), floatArrayOf(.7f, .8f, .2f, .1f)))
        assertEquals(128, multiple.left)
        assertEquals(72, multiple.top)
        assertTrue(multiple.right >= 1151)
        assertTrue(multiple.bottom >= 648)
    }

    @Test fun repeatedLowerConfidenceNewDialogueIsAcceptedInsteadOfStayingOnOldText() {
        val gate = OcrVariantGate()
        assertNull(gate.observe("new", "Open the southern gate.", .72f))
        val next = requireNotNull(gate.observe("new", "Open the southern gate.", .71f))
        assertEquals("Open the southern gate.", next.text)
        assertEquals(.72f, next.confidence)
        gate.clear()
        assertNull(gate.observe("another", "Open the western gate.", .69f))
    }

    @Test fun alternatingOcrNoiseDoesNotAccumulateConfirmationAcrossOldReads() {
        val gate = OcrVariantGate()
        assertNull(gate.observe("variant", "Noisy read", .8f))
        gate.clear()
        assertNull(gate.observe("variant", "Noisy read", .8f))
        assertEquals(1, gate.consecutiveReads)
    }
}
