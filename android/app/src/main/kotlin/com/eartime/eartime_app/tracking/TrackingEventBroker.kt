package com.eartime.eartime_app.tracking

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * Thread-safe bridge from native producers to the Flutter EventChannel.
 *
 * Events may be produced on any thread; delivery always happens on the main thread. While no
 * Flutter listener is attached, the most recent events are kept in a *bounded* buffer (persistable
 * events are additionally durable in the [EventJournal], so nothing important depends on it).
 */
object TrackingEventBroker {
    private const val TAG = "EarTimeDiag"
    private const val MAX_PENDING = 200

    private val mainHandler = Handler(Looper.getMainLooper())

    // All fields below are only accessed on the main thread.
    private var eventSink: EventChannel.EventSink? = null
    private val pendingEvents = ArrayDeque<Map<String, Any?>>()
    private var latestDiagnosticState: Map<String, Any?>? = null
    private var latestDiscoveryResult: Map<String, Any?>? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        runOnMain {
            eventSink = sink
            if (sink == null) {
                Log.i(TAG, "[BROKER] EventChannel detached")
                return@runOnMain
            }
            Log.i(TAG, "[BROKER] EventChannel attached; replaying ${pendingEvents.size} buffered events")
            latestDiagnosticState?.let { sink.success(it) }
            latestDiscoveryResult?.let { sink.success(it) }
            while (pendingEvents.isNotEmpty()) sink.success(pendingEvents.removeFirst())
        }
    }

    fun clearLatestDiscoveryResult() {
        runOnMain { latestDiscoveryResult = null }
    }

    fun sendEvent(event: Map<String, Any?>) {
        runOnMain {
            when (event["type"]) {
                "BLE_DIAGNOSTIC_STATE" -> latestDiagnosticState = event
                "BLE_DISCOVERY_RESULT" -> latestDiscoveryResult = event
            }
            val sink = eventSink
            if (sink != null) {
                try {
                    sink.success(event)
                    return@runOnMain
                } catch (e: Exception) {
                    // Engine detached without onCancel (activity destroyed): fall back to buffering.
                    Log.w(TAG, "[BROKER] sink failed, buffering: ${e.message}")
                    eventSink = null
                }
            }
            if (pendingEvents.size >= MAX_PENDING) pendingEvents.removeFirst()
            pendingEvents.addLast(event)
        }
    }

    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
    }
}
