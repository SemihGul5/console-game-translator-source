package com.abrebostudio.consolegametranslator

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

/** System document picker; no broad storage permission and no cache data crosses to Flutter. */
internal class TranslationCacheDocuments(
    private val context: Context,
    private val activity: () -> MainActivity?,
    private val translating: () -> Boolean,
    private val beforeChange: () -> Unit,
    private val afterChange: () -> Unit,
) {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val manager get() = TranslationCacheManager.get(context)
    private val repository get() = manager.repository
    private val contributions = TranslationCacheContribution(context)
    private var pending: MethodChannel.Result? = null
    private var exporting = false
    @Volatile var isChanging = false; private set
    private var stageToken: String? = null
    private val stageFile get() = File(context.noBackupFilesDir, "translation-cache-import.stage")
    init { worker.execute { stageFile.delete(); contributions.cleanup() } }

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            "getTranslationCacheStatus" -> work(result) { status() }
            "saveTranslationCachePolicy" -> change(result) {
                val policy = TranslationCachePolicy.fromMap(call.arguments as? Map<*, *> ?: error("Invalid policy"))
                manager.updatePolicy(policy); afterChange(); status()
            }
            "resetTranslationCachePolicy" -> change(result) {
                manager.updatePolicy(TranslationCachePolicy()); afterChange(); status()
            }
            "clearTranslationCache" -> change(result) {
                repository.clear(call.arguments as? String ?: ""); afterChange(); status()
            }
            "exportTranslationCache" -> pick(result, export = true)
            "prepareTranslationCacheContribution" -> work(result) { contributions.prepare(repository) }
            "openTranslationCacheContributionDraft" -> openContributionDraft(call, result)
            "discardTranslationCacheContribution" -> work(result) {
                contributions.discard(call.arguments as? String ?: ""); true
            }
            "previewTranslationCacheImport" -> pick(result, export = false)
            "commitTranslationCacheImport" -> change(result) {
                require(stageToken != null && call.arguments == stageToken && stageFile.isFile)
                try { repository.importFile(stageFile); afterChange(); status() }
                finally { stageToken = null; stageFile.delete() }
            }
            "cancelTranslationCacheImport" -> work(result) {
                stageToken = null; stageFile.delete(); true
            }
            else -> return false
        }
        return true
    }

    private fun status(): Map<String, Any> = repository.statistics() + ("translationRunning" to translating())

    private fun change(result: MethodChannel.Result, action: () -> Any?) {
        if (translating()) {
            result.error("CACHE_TRANSLATING", "Önbelleği değiştirmeden önce çeviriyi durdur.", null)
            return
        }
        if (isChanging) { result.error("CACHE_BUSY", "Önbellek işleminin tamamlanmasını bekle.", null); return }
        isChanging = true
        work(result) {
            try {
                check(!translating())
                beforeChange()
                check(!translating())
                action()
            } finally { isChanging = false }
        }
    }

    private fun work(result: MethodChannel.Result, action: () -> Any?) {
        worker.execute {
            try { val value = action(); main.post { result.success(value) } }
            catch (_: Exception) {
                main.post { result.error("CACHE_OPERATION", "Önbellek işlemi tamamlanamadı. Dosyayı ve kullanılabilir alanı kontrol et.", null) }
            }
        }
    }

    private fun openContributionDraft(call: MethodCall, result: MethodChannel.Result) {
        worker.execute {
            try {
                val args = call.arguments as? Map<*, *> ?: error("Missing draft")
                val token = args["token"] as? String ?: error("Missing contribution")
                val intent = contributions.draftIntent(token, args["subject"] as? String ?: "",
                    args["body"] as? String ?: "", args["chooserTitle"] as? String ?: "")
                main.post {
                    try {
                        val host = activity() ?: error("Missing activity")
                        host.startActivity(intent)
                        contributions.markOpened(token)
                        result.success(mapOf("opened" to true))
                    } catch (_: Exception) {
                        result.error("CACHE_EMAIL_OPEN", "E-posta taslağı açılamadı. Önbelleği dışarı aktararak bize gönderebilirsin.", null)
                    }
                }
            } catch (_: TranslationCacheContribution.EmailUnavailable) {
                main.post { result.error("CACHE_NO_EMAIL", "E-posta uygulaması bulunamadı. Önbelleği dışarı aktararak abrebostudio@gmail.com adresine gönderebilirsin.", null) }
            } catch (_: Exception) {
                main.post { result.error("CACHE_EMAIL_OPEN", "E-posta taslağı açılamadı. Önbelleği dışarı aktararak bize gönderebilirsin.", null) }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun pick(result: MethodChannel.Result, export: Boolean) {
        if (pending != null) { result.error("CACHE_PICKER_BUSY", "Önce açık dosya seçimini tamamla.", null); return }
        val host = activity()
        if (host == null) { result.error("CACHE_NO_ACTIVITY", "Dosya seçimi için uygulamayı aç.", null); return }
        pending = result; exporting = export
        try {
            val intent = Intent(if (export) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE).setType(if (export) "application/octet-stream" else "*/*")
            if (export) intent.putExtra(Intent.EXTRA_TITLE, "Oyun Çevirmeni-ceviri-onbellegi.jsonl")
            host.startActivityForResult(intent, REQUEST)
        } catch (_: Exception) {
            pending = null
            result.error("CACHE_NO_PICKER", "Bu cihazda dosya seçici açılamadı.", null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val result = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(mapOf("cancelled" to true)); return true
        }
        val export = exporting
        work(result) {
            if (export) {
                val output = context.contentResolver.openOutputStream(uri, "wt") ?: error("Cannot open document")
                output.use { repository.export(it) }
                mapOf("cancelled" to false)
            } else {
                stageToken = null
                stageFile.delete()
                try {
                    copyImport(uri)
                    val report = repository.preview(stageFile)
                    val token = UUID.randomUUID().toString()
                    stageToken = token
                    report.toMap() + mapOf("cancelled" to false, "token" to token)
                } catch (error: Exception) {
                    stageFile.delete()
                    throw error
                }
            }
        }
        return true
    }

    private fun copyImport(uri: Uri) {
        val input = context.contentResolver.openInputStream(uri) ?: error("Cannot open document")
        input.use { source -> stageFile.outputStream().buffered().use { output ->
            val buffer = ByteArray(8192)
            var bytes = 0L
            while (true) {
                val count = source.read(buffer)
                if (count < 0) break
                bytes += count
                require(bytes <= TranslationCacheBackup.MAX_FILE_BYTES)
                output.write(buffer, 0, count)
            }
        } }
    }

    fun cancelPicker() {
        pending?.success(mapOf("cancelled" to true))
        pending = null
        worker.execute { stageToken = null; stageFile.delete() }
    }

    companion object { private const val REQUEST = 813 }
}
