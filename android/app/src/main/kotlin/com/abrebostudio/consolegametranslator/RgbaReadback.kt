package com.abrebostudio.consolegametranslator

import java.nio.IntBuffer

/** Bulk row copies avoid four direct-buffer byte accesses per pixel on Android. */
internal fun rgbaReadbackPixels(buffer: IntBuffer, width: Int, height: Int, littleEndian: Boolean): IntArray {
    val colors = IntArray(width * height)
    for (row in 0 until height) {
        buffer.position((height - 1 - row) * width)
        buffer.get(colors, row * width, width)
    }
    for (i in colors.indices) {
        val value = colors[i]
        colors[i] = if (littleEndian) (0xff shl 24) or ((value and 255) shl 16) or
            (value and 0xff00) or ((value ushr 16) and 255)
        else (0xff shl 24) or (value ushr 8)
    }
    return colors
}
