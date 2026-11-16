package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class OcrRegionSettingsTest {
    @Test fun newRegionsUseDefaultsIndependentlyOfCustomizedRegions() {
        val custom = OcrRegionSettings.fromMap(mapOf(
            "sampleRateHz" to 2.0, "ocrCaptureScale" to 2,
            "ocrPreprocessingMode" to 9, "ocrDialogueFilter" to true,
            "holdSeconds" to 6.0, "autoHideAfterSeconds" to 9.0,
        ))
        assertEquals(500L, custom.sampleIntervalMillis)
        assertEquals(2f, custom.captureScale)
        assertEquals(9, custom.preprocessingMode)
        assertTrue(custom.dialogueFilter)
        assertEquals(6000L, custom.holdMillis)
        assertEquals(9000L, custom.autoHideMillis)
        assertEquals(OcrRegionSettings(), OcrRegionSettings.fromMap(emptyMap<String, Any>()))
    }

    @Test fun slowAndFastRegionsAreOnlyScannedAtTheirOwnIntervals() {
        val schedule = OcrRegionSchedule()
        val settings = listOf(OcrRegionSettings(sampleRateHz = 2.0), OcrRegionSettings(sampleRateHz = 20.0))
        assertEquals(listOf(0, 1), schedule.dueIndices(1000, settings))
        schedule.sampled(listOf(0, 1), 1000)
        assertTrue(schedule.dueIndices(1049, settings).isEmpty())
        assertEquals(listOf(1), schedule.dueIndices(1050, settings))
        schedule.sampled(listOf(1), 1050)
        assertEquals(listOf(1), schedule.dueIndices(1450, settings))
        schedule.sampled(listOf(1), 1450)
        assertEquals(listOf(0, 1), schedule.dueIndices(1500, settings))
    }

    @Test fun malformedSettingsRemainBoundedAndFinite() {
        val settings = OcrRegionSettings.fromMap(mapOf(
            "sampleRateHz" to Double.NaN, "ocrCaptureScale" to Double.POSITIVE_INFINITY,
            "ocrPreprocessingMode" to 50, "holdSeconds" to -5, "autoHideAfterSeconds" to 100,
        ))
        assertEquals(100L, settings.sampleIntervalMillis)
        assertEquals(1f, settings.captureScale)
        assertEquals(9, settings.preprocessingMode)
        assertEquals(0L, settings.holdMillis)
        assertEquals(30000L, settings.autoHideMillis)
    }

    @Test fun mixedRatesScheduleTheEarliestDueRegionWithoutRoundingToTheFastestTick() {
        val schedule = OcrRegionSchedule()
        val settings = listOf(OcrRegionSettings(sampleRateHz = 10.0), OcrRegionSettings(sampleRateHz = 15.0))
        schedule.sampled(listOf(0, 1), 1000)
        assertEquals(67L, schedule.nextDelay(1000, settings))
        schedule.sampled(listOf(1), 1067)
        assertEquals(33L, schedule.nextDelay(1067, settings))
        assertEquals(listOf(0), schedule.dueIndices(1100, settings))
    }
}
