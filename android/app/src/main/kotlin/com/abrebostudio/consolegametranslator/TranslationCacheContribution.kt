package com.abrebostudio.consolegametranslator

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import java.util.UUID

/** Creates an optional email attachment. Never uploads or sends mail itself. */
internal class TranslationCacheContribution(private val context: Context) {
    private data class Prepared(val file: File, var opened: Boolean = false)
    private val prepared = mutableMapOf<String, Prepared>()
    private val directory get() = File(context.cacheDir, "translation-contributions")

    @Synchronized fun cleanup() {
        val now = System.currentTimeMillis()
        val files = directory.listFiles()?.filter { it.isFile && it.extension == "jsonl" }.orEmpty()
            .sortedByDescending { it.lastModified() }
        files.forEachIndexed { index, file ->
            if (index >= 8 || now - file.lastModified() !in 0..24L * 60 * 60 * 1000) file.delete()
        }
        prepared.entries.removeAll { !it.value.file.isFile }
    }

    @Synchronized fun prepare(repository: TranslationCacheRepository): Map<String, Any> {
        cleanup()
        val token = UUID.randomUUID().toString()
        directory.mkdirs()
        val file = File(directory, "$token.jsonl")
        try {
            val count = file.outputStream().use { repository.contribution(it) }
            prepared[token] = Prepared(file)
            return mapOf("token" to token, "count" to count, "bytes" to file.length(), "recipient" to RECIPIENT)
        } catch (error: Exception) { file.delete(); throw error }
    }

    @Suppress("DEPRECATION")
    @Synchronized fun draftIntent(token: String, subject: String, body: String, title: String): Intent {
        val entry = prepared[token] ?: error("Contribution expired")
        require(entry.file.isFile && subject.length <= 256 && body.length <= 4000 && title.length <= 256)
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.translationcache.fileprovider", entry.file)
        val packages = context.packageManager.queryIntentActivities(
            Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:$RECIPIENT")), 0,
        ).map { it.activityInfo.packageName }.distinct()
        val intents = packages.map { name ->
            Intent(Intent.ACTION_SEND).setPackage(name).setType("application/octet-stream")
                .putExtra(Intent.EXTRA_EMAIL, arrayOf(RECIPIENT))
                .putExtra(Intent.EXTRA_SUBJECT, subject).putExtra(Intent.EXTRA_TEXT, body)
                .putExtra(Intent.EXTRA_STREAM, uri)
                .apply {
                    clipData = ClipData.newUri(context.contentResolver, "Translation cache", uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
        }.filter { it.resolveActivity(context.packageManager) != null }
        if (intents.isEmpty()) throw EmailUnavailable()
        return Intent.createChooser(intents.first(), title)
            .putExtra(Intent.EXTRA_INITIAL_INTENTS, intents.drop(1).toTypedArray())
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            .apply { clipData = intents.first().clipData }
    }

    @Synchronized fun markOpened(token: String) { prepared[token]?.opened = true }

    @Synchronized fun discard(token: String) {
        val entry = prepared.remove(token) ?: return
        // Email clients may read the attachment after our app returns to the foreground.
        if (!entry.opened) entry.file.delete()
    }

    internal class EmailUnavailable : Exception()
    companion object { const val RECIPIENT = "abrebostudio@gmail.com" }
}
