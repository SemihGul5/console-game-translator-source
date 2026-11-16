package com.abrebostudio.consolegametranslator

import android.annotation.SuppressLint
import android.app.Activity
import android.app.AlertDialog
import android.graphics.Bitmap
import android.net.http.SslError
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.webkit.CookieManager
import android.webkit.RenderProcessGoneDetail
import android.webkit.SslErrorHandler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import java.io.ByteArrayInputStream

/** Loads only our HTTPS challenge page and Cloudflare resources; no Sony login. */
internal class PsnTurnstileDialog(
    private val activity: Activity,
    private val origin: String,
    private val digest: String,
    private val onComplete: (Result<String>) -> Unit,
) {
    private val handler = Handler(Looper.getMainLooper())
    private var dialog: AlertDialog? = null
    private var webView: WebView? = null
    private var finished = false
    private val page = "$origin/turnstile?cdata=$digest"
    private val policy = PsnTurnstilePolicy(page)
    private var pageLoadRetried = false
    private val retryPage = Runnable { if (!finished) webView?.loadUrl(page) }
    private val timeout = Runnable { fail("Güvenlik doğrulaması zaman aşımına uğradı. Tekrar dene.") }

    @SuppressLint("SetJavaScriptEnabled")
    fun show() {
        check(Looper.myLooper() == Looper.getMainLooper())
        val view = WebView(activity)
        webView = view
        view.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = false
            allowContentAccess = false
            mixedContentMode = android.webkit.WebSettings.MIXED_CONTENT_NEVER_ALLOW
            setSupportMultipleWindows(false)
        }
        CookieManager.getInstance().setAcceptThirdPartyCookies(view, true)
        view.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                val uri = request.url
                if (uri.scheme == "gametranslate-turnstile") {
                    val token = uri.getQueryParameters("token").singleOrNull()
                    if (request.isForMainFrame && view.url == page && uri.host == "complete" &&
                        uri.path.isNullOrEmpty() && uri.fragment == null &&
                        token != null && token.length in 1..2048) {
                        // Defer destruction until WebView has returned from this callback.
                        handler.post { finish(Result.success(token)) }
                    }
                    return true
                }
                return !policy.allowsNavigation(uri.toString(), request.isForMainFrame)
            }

            override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? {
                return if (policy.allowsResource(request.url.toString())) null else WebResourceResponse(
                    "text/plain", "utf-8", ByteArrayInputStream(ByteArray(0)),
                )
            }

            override fun onReceivedSslError(view: WebView, sslHandler: SslErrorHandler, error: SslError) {
                sslHandler.cancel()
                handler.post { fail("Güvenlik doğrulaması için güvenli bağlantı kurulamadı.") }
            }

            override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
                if (!request.isForMainFrame) return
                // Record only the numeric WebView error; URLs can contain proof material.
                val errorCode = error.errorCode
                Log.w("PsnTurnstile", "Challenge page load failed (WebView code $errorCode)")
                handler.post {
                    if (finished) return@post
                    if (!pageLoadRetried && request.url.toString() == page &&
                        errorCode in listOf(ERROR_HOST_LOOKUP, ERROR_CONNECT, ERROR_IO, ERROR_TIMEOUT)) {
                        pageLoadRetried = true
                        handler.postDelayed(retryPage, 1_000)
                    } else {
                        fail("Güvenlik doğrulama sayfası açılamadı. Tekrar dene.")
                    }
                }
            }

            override fun onReceivedHttpError(view: WebView, request: WebResourceRequest, response: WebResourceResponse) {
                if (request.isForMainFrame) handler.post { fail("PSN hesap doğrulama hizmetine ulaşılamadı. Tekrar dene.") }
            }

            override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean {
                handler.post { fail("Güvenlik doğrulaması kesildi. Tekrar deneyebilirsin.") }
                return true
            }

            override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
                if (!policy.allowsNavigation(url, isMainFrame = true)) {
                    view.stopLoading()
                    handler.post { fail("Güvenlik doğrulama adresi geçersiz.") }
                }
            }
        }
        dialog = AlertDialog.Builder(activity, android.R.style.Theme_DeviceDefault_Dialog_Alert)
            .setTitle(AppUiLanguage.text(activity, "Güvenli bağlantı"))
            .setView(view)
            .setNegativeButton(AppUiLanguage.text(activity, "İptal")) { _, _ -> cancel() }
            .setOnCancelListener { cancel() }
            .create().also {
                it.setCanceledOnTouchOutside(false)
                it.show()
                it.window?.setLayout(
                    android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                    (280 * activity.resources.displayMetrics.density).toInt(),
                )
            }
        handler.postDelayed(timeout, 120_000)
        view.loadUrl(page)
    }

    fun cancel() = fail("Güvenlik doğrulaması iptal edildi. Tekrar deneyebilirsin.")

    private fun fail(message: String) = finish(Result.failure(IllegalStateException(message)))

    private fun finish(result: Result<String>) {
        if (finished) return
        finished = true
        handler.removeCallbacks(timeout)
        handler.removeCallbacks(retryPage)
        runCatching { dialog?.dismiss() }
        dialog = null
        webView?.let { view ->
            runCatching {
                view.stopLoading()
                (view.parent as? android.view.ViewGroup)?.removeView(view)
                view.destroy()
            }
        }
        webView = null
        onComplete(result)
    }
}
