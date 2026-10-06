package com.uomospazio.bisca.voice

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/** Only transports a callback. GDScript validates flow nonce and exchanges PKCE. */
class BiscaAuthCallbackActivity : Activity() {
    companion object {
        private var result = ""
        @Synchronized fun deliver(value: String) { result = value }
        @Synchronized fun clear() { result = "" }
        @Synchronized fun drain(): String { val value = result; result = ""; return value }
    }
    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        val uri = intent?.data
        if (uri?.scheme == "com.bisca.game" && uri.host == "auth" && uri.path == "/callback") {
            deliver(uri.toString())
            packageManager.getLaunchIntentForPackage(packageName)?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                startActivity(it)
            }
        }
        finish()
    }
}
