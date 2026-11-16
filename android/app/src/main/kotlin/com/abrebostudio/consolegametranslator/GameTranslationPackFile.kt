package com.abrebostudio.consolegametranslator

import java.io.File
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets
import java.security.MessageDigest

/** Only a bounded, hash-verified pack inside the app cache enters the fast path. */
internal object GameTranslationPackFile {
    fun read(root: File, path: String, sha256: String, expectedBytes: Long): String {
        require(sha256.matches(Regex("[a-f0-9]{64}")) && expectedBytes in 1..25L * 1024 * 1024) {
            "Oyun çeviri dosyası bilgileri geçersiz."
        }
        val file = File(path).canonicalFile
        require(file.path.startsWith(root.canonicalPath + File.separator) &&
            file.name == "pack-$sha256.json" && file.isFile && file.length() == expectedBytes) {
            "Oyun çeviri dosyası bulunamadı veya boyutu değişmiş."
        }
        val bytes = ByteArray(expectedBytes.toInt())
        file.inputStream().buffered().use { input ->
            var offset = 0
            while (offset < bytes.size) {
                val read = input.read(bytes, offset, bytes.size - offset)
                require(read > 0) { "Oyun çeviri dosyası eksik." }
                offset += read
            }
            require(input.read() == -1) { "Oyun çeviri dosyası boyutu değişmiş." }
        }
        val hash = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
        require(hash == sha256) { "Oyun çeviri dosyası doğrulanamadı." }
        return StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
            .onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString()
    }
}
