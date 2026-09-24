package com.eartime.eartime_app.tracking

import android.Manifest
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.HandlerThread
import android.os.IBinder
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * Foreground service hosting the [TrackingEngine] on its own background thread.
 *
 * startForeground() is called on *every* onStartCommand (Android 12+ requires it after each
 * startForegroundService, even when the service is already running — Bug G), with the correct
 * overload per API level and with every start-restriction exception handled.
 */
class AudioTrackingService : Service() {

    companion object {
        private const val TAG = "EarTimeDiag"
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val ACTION_START_BLE_DIAGNOSTIC = "ACTION_START_BLE_DIAGNOSTIC"
        const val ACTION_SYNC_STATE = "ACTION_SYNC_STATE"

        /** The running engine, if any. Only touched from the main thread. */
        @Volatile
        var engine: TrackingEngine? = null
            private set

        fun hasRequiredPermissions(context: Context): Boolean =
            Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED

        /** Starts monitoring if the user has it enabled and permissions allow it. */
        fun startIfEnabled(context: Context, reason: String): Boolean {
            val prefs = TrackingPrefs(context)
            if (!prefs.monitoringEnabled) {
                Log.i(TAG, "[SERVICE] not starting ($reason): monitoring disabled by user")
                return false
            }
            if (!hasRequiredPermissions(context)) {
                Log.w(TAG, "[SERVICE] not starting ($reason): BLUETOOTH_CONNECT not granted")
                return false
            }
            return try {
                val intent = Intent(context, AudioTrackingService::class.java).setAction(ACTION_START)
                ContextCompat.startForegroundService(context, intent)
                true
            } catch (e: Exception) {
                // ForegroundServiceStartNotAllowedException (Android 12+) or SecurityException.
                Log.e(TAG, "[SERVICE] start failed ($reason): ${e.message}")
                false
            }
        }
    }

    private var thread: HandlerThread? = null

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "[SERVICE] onCreate")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START
        Log.i(TAG, "[SERVICE] onStartCommand action=$action")

        if (action == ACTION_STOP) {
            engine?.stop()
            stopForegroundCompat()
            stopSelf()
            return START_NOT_STICKY
        }

        if (!promoteToForeground()) return START_NOT_STICKY

        val current = engine ?: createEngine()
        when (action) {
            ACTION_START_BLE_DIAGNOSTIC -> current.startBleDiagnostic(intent?.getStringExtra("address"))
            ACTION_SYNC_STATE -> current.requestSync()
        }
        return START_STICKY
    }

    private fun createEngine(): TrackingEngine {
        val handlerThread = HandlerThread("EarTimeEngine").also { it.start() }
        thread = handlerThread
        val created = TrackingEngine(applicationContext, handlerThread.looper)
        engine = created
        created.start()
        return created
    }

    private fun promoteToForeground(): Boolean {
        val alerts = engine?.alerts ?: AlertManager(this, TrackingPrefs(this))
        alerts.ensureChannels()
        val notification = alerts.buildForeground(engine?.latestStatus)
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(AlertManager.FOREGROUND_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
            } else {
                startForeground(AlertManager.FOREGROUND_ID, notification)
            }
            true
        } catch (e: Exception) {
            // SecurityException (missing FGS-type prerequisites on Android 14+) or
            // ForegroundServiceStartNotAllowedException (background start on Android 12+).
            Log.e(TAG, "[SERVICE] startForeground failed: ${e.message}")
            stopSelf()
            false
        }
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    override fun onDestroy() {
        Log.i(TAG, "[SERVICE] onDestroy")
        engine?.stop()
        engine = null
        // Let the engine finish its stop work, then end the thread.
        thread?.quitSafely()
        thread = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent): IBinder? = null
}
