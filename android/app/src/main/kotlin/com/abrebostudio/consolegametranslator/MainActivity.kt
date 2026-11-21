package com.abrebostudio.consolegametranslator

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/** UI host only; Remote Play and translation continue after this host detaches. */
class MainActivity : FlutterActivity() {
    companion object {
        const val ACTION_STOP_TRANSLATION = "com.abrebostudio.consolegametranslator.NOTIFICATION_STOP_TRANSLATION"
        const val ACTION_OPEN_HOME_FROM_TRANSLATION_NOTIFICATION =
            "com.abrebostudio.consolegametranslator.OPEN_HOME_FROM_TRANSLATION_NOTIFICATION"
    }

    private val controller get() = RemotePlayController.get(applicationContext)

    override fun provideFlutterEngine(context: Context): FlutterEngine = controller.flutterEngine

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        controller.attach(this)
        controller.configureFlutterEngine(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        controller.handleNotificationStopIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        controller.onResume()
    }

    override fun onStop() {
        controller.onStop()
        super.onStop()
    }

    override fun onPause() {
        controller.onStop()
        super.onPause()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        controller.handleNotificationStopIntent(intent)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        controller.onRequestPermissionsResult(requestCode)
    }

    @Deprecated("System document picker result bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        controller.onCacheDocumentResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        controller.detach(this)
        super.onDestroy()
    }
}
