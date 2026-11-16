package com.abrebostudio.consolegametranslator

internal data class OcrFrameBounds(val left: Int, val top: Int, val right: Int, val bottom: Int) {
    val width get() = right - left
    val height get() = bottom - top
}

internal fun ocrFrameBounds(width: Int, height: Int, value: FloatArray): OcrFrameBounds {
    val left = (value[0].coerceIn(0f, 0.98f) * width).toInt().coerceIn(0, width - 1)
    val top = (value[1].coerceIn(0f, 0.98f) * height).toInt().coerceIn(0, height - 1)
    return OcrFrameBounds(left, top,
        ((value[0] + value[2]).coerceIn(0.02f, 1f) * width).toInt().coerceIn(left + 1, width),
        ((value[1] + value[3]).coerceIn(0.02f, 1f) * height).toInt().coerceIn(top + 1, height))
}

internal fun ocrUnionBounds(width: Int, height: Int, regions: List<FloatArray>): OcrFrameBounds {
    require(width > 0 && height > 0 && regions.isNotEmpty())
    val bounds = regions.map { ocrFrameBounds(width, height, it) }
    return OcrFrameBounds(bounds.minOf { it.left }, bounds.minOf { it.top },
        bounds.maxOf { it.right }, bounds.maxOf { it.bottom })
}

/** Cadence is measured from capture start, with no extra polling delay after OCR. */
internal fun nextOcrSampleDelay(startedAt: Long, finishedAt: Long, interval: Long): Long =
    (interval - (finishedAt - startedAt)).coerceAtLeast(0L)
