package com.abrebostudio.consolegametranslator

import java.io.BufferedOutputStream
import java.io.DataOutputStream
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.zip.CRC32
import java.util.zip.CheckedOutputStream

/**
 * Prepared game indexes kept on disk, so a downloaded game opens again without
 * re-parsing its JSON after the app restarts. It is derived data: every file is
 * tied to one hash-verified pack version and one app build, and anything that
 * does not match is deleted and rebuilt from the pack.
 */
internal class GameTranslationMemoryIndexStore(
    private val root: File,
    private val buildTag: String,
) {
    private val buildSuffix = "-${shortHash(buildTag)}.idx"
    private val removalEpochs = HashMap<String, Int>()

    /** Only catalog packs identified by their SHA-256 get a disk index. */
    fun supports(key: GameTranslationMemoryKey) = PACK_CONTENT_KEY.matches(key.contentKey)

    fun exists(key: GameTranslationMemoryKey) = supports(key) && file(key).isFile

    fun read(key: GameTranslationMemoryKey): GameTranslationMemory? {
        if (!supports(key)) return null
        val file = file(key)
        val length = file.length()
        if (!file.isFile || length !in 16..MAX_BYTES) return null
        return try {
            // Streamed: a large index never sits in memory twice (file bytes + arrays).
            GameTranslationMemory.readSnapshot(file, key.gameId, key.sourceLanguage,
                key.targetLanguage, key.contentKey, buildTag)
        } catch (_: Exception) {
            file.delete()
            null
        } catch (_: OutOfMemoryError) {
            null
        }
    }

    /** Captured before preparing a pack; a deletion in between cancels the write. */
    @Synchronized fun epoch(gameId: String) = removalEpochs[gameId] ?: 0

    fun write(key: GameTranslationMemoryKey, memory: GameTranslationMemory, epoch: Int) {
        if (!supports(key)) return
        if (!root.isDirectory && !root.mkdirs()) return
        val target = file(key)
        val temporary = File(root, "${target.name}.tmp")
        try {
            val checksum = CRC32()
            DataOutputStream(BufferedOutputStream(CheckedOutputStream(FileOutputStream(temporary), checksum), 1 shl 16)).use { output ->
                memory.writeSnapshot(output, key.contentKey, buildTag)
                output.flush()
                output.writeLong(checksum.value)
            }
            synchronized(this) {
                if (epoch(key.gameId) != epoch || temporary.length() > MAX_BYTES || !temporary.renameTo(target)) {
                    temporary.delete()
                    return
                }
                // An updated pack replaces the index of its older version.
                val prefix = languagePrefix(key.gameId, key.sourceLanguage, key.targetLanguage)
                root.listFiles()?.forEach { if (it.name.startsWith(prefix) && it.name != target.name) it.delete() }
            }
        } catch (_: Exception) {
            temporary.delete()
        } catch (_: OutOfMemoryError) {
            temporary.delete()
        }
    }

    @Synchronized fun removeGame(gameId: String, source: String? = null, target: String? = null) {
        removalEpochs[gameId] = epoch(gameId) + 1
        val prefix = if (source != null && target != null) languagePrefix(gameId, source, target) else "${shortHash(gameId)}-"
        root.listFiles()?.forEach { if (it.name.startsWith(prefix)) it.delete() }
    }

    /** Indexes from older app builds (or interrupted writes) are never read again. */
    @Synchronized fun deleteStale() {
        root.listFiles()?.forEach { if (!it.name.endsWith(buildSuffix)) it.delete() }
    }

    private fun languagePrefix(gameId: String, source: String, target: String) =
        "${shortHash(gameId)}-${shortHash("$source\u0000$target")}-"

    private fun file(key: GameTranslationMemoryKey) = File(root,
        languagePrefix(key.gameId, key.sourceLanguage, key.targetLanguage) + shortHash(key.contentKey) + buildSuffix)

    private companion object {
        val PACK_CONTENT_KEY = Regex(".+:[a-f0-9]{64}")
        const val MAX_BYTES = 256L * 1024 * 1024

        fun shortHash(value: String): String = MessageDigest.getInstance("SHA-256")
            .digest(value.toByteArray(Charsets.UTF_8)).take(10).joinToString("") { "%02x".format(it) }
    }
}
