package com.eartime.eartime_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import com.eartime.eartime_app.tracking.AudioDiagnosticHelper
import com.eartime.eartime_app.tracking.AudioTrackingService
import com.eartime.eartime_app.tracking.EventJournal
import com.eartime.eartime_app.tracking.TrackingEventBroker
import com.eartime.eartime_app.tracking.TrackingPrefs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "com.eartime.app/tracking"
    private val eventChannelName = "com.eartime.app/tracking_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Passive monitoring: (re)start the service whenever the UI opens, if the user wants it.
        AudioTrackingService.startIfEnabled(this, "APP_LAUNCH")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "startMonitoring" -> {
                        TrackingPrefs(this).monitoringEnabled = true
                        result.success(AudioTrackingService.startIfEnabled(this, "USER"))
                    }
                    "stopMonitoring" -> {
                        TrackingPrefs(this).monitoringEnabled = false
                        stopService(Intent(this, AudioTrackingService::class.java))
                        result.success(null)
                    }
                    "requestSync" -> {
                        requestSync()
                        result.success(null)
                    }
                    "getJournal" -> {
                        val after = (call.argument<Number>("afterSeq") ?: 0).toLong()
                        result.success(EventJournal.get(this).read(after))
                    }
                    "ackJournal" -> {
                        val upTo = (call.argument<Number>("upToSeq") ?: 0).toLong()
                        EventJournal.get(this).acknowledge(upTo)
                        result.success(null)
                    }
                    "getSettings" -> result.success(TrackingPrefs(this).settingsMap())
                    "updateSettings" -> {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                        TrackingPrefs(this).applySettings(args)
                        AudioTrackingService.engine?.reloadSettings()
                        result.success(TrackingPrefs(this).settingsMap())
                    }
                    "startBleDiagnostic" -> {
                        val engine = AudioTrackingService.engine
                        if (engine != null) engine.startBleDiagnostic(call.argument<String>("address"))
                        result.success(engine != null)
                    }
                    "getAudioDiagnostics" -> AudioDiagnosticHelper.getDiagnostics(this) { diagInfo -> result.success(diagInfo) }
                    "openBatteryOptimizationSettings" -> {
                        openBatterySettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("EarTimeDiag", "[CHANNEL] ${call.method} failed: ${e.message}")
                result.error("NATIVE_ERROR", e.message, null)
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    TrackingEventBroker.setEventSink(events)
                    requestSync()
                }

                override fun onCancel(arguments: Any?) {
                    TrackingEventBroker.setEventSink(null)
                }
            }
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // The engine is going away (activity destroyed); never deliver to its stale sink again.
        TrackingEventBroker.setEventSink(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /** Emits a SYNC_STATE, even when the service is not running (so the UI never waits forever). */
    private fun requestSync() {
        val engine = AudioTrackingService.engine
        if (engine != null) {
            engine.requestSync()
            return
        }
        val prefs = TrackingPrefs(this)
        // The service may simply not have created its engine yet (it is started in the same
        // launch); report the intended state so the UI doesn't flash "paused". The engine's own
        // STARTUP sync follows within milliseconds with the real device list.
        val expected = prefs.monitoringEnabled && AudioTrackingService.hasRequiredPermissions(this)
        TrackingEventBroker.sendEvent(
            mapOf(
                "type" to "SYNC_STATE",
                "reason" to "SERVICE_NOT_RUNNING",
                "monitoring" to expected,
                "connectedDevices" to emptyList<Any>(),
                "isPlaying" to false,
                "settings" to prefs.settingsMap(),
                "timestamp" to System.currentTimeMillis(),
            )
        )
    }

    private fun openBatterySettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
        try {
            startActivity(intent)
        } catch (e: Exception) {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }
}
