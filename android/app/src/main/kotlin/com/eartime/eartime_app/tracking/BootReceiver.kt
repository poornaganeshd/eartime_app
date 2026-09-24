package com.eartime.eartime_app.tracking

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restores background monitoring after a reboot or an app update, so tracking does not silently
 * stop until the user happens to open the app. (connectedDevice FGS may be started from
 * BOOT_COMPLETED on Android 14/15.)
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON" -> AudioTrackingService.startIfEnabled(context, intent.action ?: "BOOT")
        }
    }
}
