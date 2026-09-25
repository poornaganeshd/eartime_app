package com.eartime.eartime_app.tracking

import android.annotation.SuppressLint
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.media.AudioAttributes
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.AudioPlaybackConfiguration
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log

/**
 * The real-time listening state machine.
 *
 * Every piece of mutable state lives on one dedicated [Looper] (see [AudioTrackingService]), so
 * device callbacks, playback callbacks, volume changes and timers are strictly serialized — no
 * races between the initial scan and callbacks, no duplicate CONNECTED events.
 *
 * Signals and how they are made robust:
 *  - **Devices**: AudioDeviceCallback routes are reference-counted per logical headset and
 *    disconnects are debounced ([DISCONNECT_DEBOUNCE_MS]) so SCO/A2DP/codec route flaps never
 *    create phantom disconnects (Bug A2).
 *  - **Playback**: AudioPlaybackCallback only says *something changed*; its configuration list
 *    also contains paused/idle players, so "list not empty" is NOT "playing" (root cause of the
 *    timer-keeps-running bugs B4/D/E). The truth is AudioManager.isMusicActive(), re-evaluated
 *    after a short settle delay and reconciled by a periodic tick.
 *  - **Routing**: time only counts when media is actually routed to a tracked headset
 *    (getAudioDevicesForAttributes on API 33+, most-recent-headset heuristic before that), so
 *    speaker playback is never attributed to earbuds.
 *  - **Volume**: a Settings ContentObserver samples STREAM_MUSIC and converts it to an estimated
 *    dB(A) level for exposure accounting.
 *  - **Durability**: each transition is appended to the [EventJournal] and a heartbeat is saved,
 *    so a process death closes open sessions at the last known-alive time on the next start.
 */
class TrackingEngine(private val context: Context, looper: Looper) {

    private val handler = Handler(looper)
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val bluetoothAdapter: BluetoothAdapter? =
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
    private val prefs = TrackingPrefs(context)
    private val journal = EventJournal.get(context)
    val alerts = AlertManager(context, prefs)
    private val bleDiscovery = BleDiscoveryManager(context)

    private class TrackedDevice(val info: Map<String, Any?>, val routes: MutableSet<Int>, val connectedAt: Long) {
        val id: String get() = info["id"] as String
        val nativeType: Int get() = (info["nativeType"] as? Number)?.toInt() ?: AudioDeviceInfo.TYPE_UNKNOWN
        val name: String get() = info["friendlyName"] as? String ?: "Headphones"
        val address: String? get() = info["hardwareAddress"] as? String
    }

    /** Logical devices in connection order (most recent last). */
    private val devices = LinkedHashMap<String, TrackedDevice>()
    private val pendingDisconnects = HashMap<String, Runnable>()

    private var started = false
    private var a2dpProxy: BluetoothA2dp? = null
    private var playbackCallback: AudioManager.AudioPlaybackCallback? = null

    // Listening state
    private var musicActive = false
    private var listeningDeviceId: String? = null
    private var listeningSince = 0L
    private var accountedUntil = 0L
    private var volume = ExposureMath.VolumeSample(0, 15, ExposureMath.MUTED_DB)

    // Alert state
    private var continuousSince = 0L
    private var lastListeningEndedAt = 0L
    private var loudSince = 0L
    private var loudAlertSent = false
    private var breakAlertSent = false
    private var lastNotificationUpdate = 0L

    // ---- Lifecycle --------------------------------------------------------------------------

    fun start() = handler.post { startInternal() }

    fun stop() = handler.post { stopInternal() }

    fun requestSync() = handler.post { emitSync("REQUEST") }

    fun reloadSettings() = handler.post {
        accountExposure(now())
        updateNotification(force = true)
        emitSync("SETTINGS")
    }

    fun startBleDiagnostic(address: String?) = handler.post {
        val target = AudioDeviceDetector.normalizeAddress(address)
            ?: devices.values.lastOrNull { it.address != null }?.address
            ?: bestA2dpFallback().second
        if (target == null) {
            TrackingEventBroker.sendEvent(
                mapOf(
                    "type" to "BLE_DIAGNOSTIC_STATE", "deviceId" to "unknown", "state" to "ERROR",
                    "message" to "No Bluetooth headset address available", "timestamp" to now(),
                )
            )
            return@post
        }
        try {
            bluetoothAdapter?.getRemoteDevice(target)?.let { bleDiscovery.discover(it, forceRefresh = true) }
        } catch (e: Exception) {
            Log.e(TAG, "[BLE] diagnostic failed: ${e.message}")
        }
    }

    private fun startInternal() {
        if (started) return
        started = true
        Log.i(TAG, "[ENGINE] starting")
        val startAt = now()
        volume = ExposureMath.sampleVolume(audioManager, null)

        // 1. Enumerate what is connected right now.
        val present = LinkedHashMap<String, Pair<Map<String, Any?>, Int>>()
        audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).forEach { device ->
            if (AudioDeviceDetector.isExternalListeningDevice(device)) {
                val info = extractInfo(device)
                val id = info["id"] as String
                if (!present.containsKey(id)) present[id] = info to device.id
                else Log.d(TAG, "[ENGINE] extra route ${device.id} for $id")
            }
        }

        // 2. Reconcile with the state persisted before the previous process died.
        val recovery = prefs.loadRecovery()
        val recoverable = recovery != null && startAt - recovery.heartbeatAt <= RECOVERY_GAP_MS
        val adopted = HashSet<String>()
        if (recovery != null) {
            val listeningId = recovery.listeningDeviceId
            val stillListening = recoverable && listeningId != null && present.containsKey(listeningId) && isMusicActiveSafe()
            if (listeningId != null && !stillListening) {
                appendAndEmit(playbackEvent("PLAYBACK_PAUSED", listeningId, recovery.devices.findInfo(listeningId), recovery.heartbeatAt, "RECOVERED"))
            }
            recovery.devices.forEach { info ->
                val id = info["id"] as? String ?: return@forEach
                if (recoverable && present.containsKey(id)) {
                    adopted.add(id) // Same session continues; do not split it.
                } else {
                    appendAndEmit(
                        mapOf(
                            "type" to "DEVICE_DISCONNECTED", "deviceId" to id, "device" to info,
                            "timestamp" to recovery.heartbeatAt, "reason" to "RECOVERED",
                        )
                    )
                }
            }
            if (stillListening) {
                listeningDeviceId = listeningId
                listeningSince = recovery.heartbeatAt
                accountedUntil = startAt
                continuousSince = startAt
            }
        }

        // 3. Register present devices.
        val routeRegistry = HashMap<String, MutableSet<Int>>()
        audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).forEach { device ->
            if (AudioDeviceDetector.isExternalListeningDevice(device)) {
                val id = extractInfo(device)["id"] as String
                routeRegistry.getOrPut(id) { HashSet() }.add(device.id)
            }
        }
        present.forEach { (id, pair) ->
            val tracked = TrackedDevice(pair.first, routeRegistry[id] ?: mutableSetOf(pair.second), startAt)
            devices[id] = tracked
            if (!adopted.contains(id)) {
                appendAndEmit(deviceEvent("DEVICE_CONNECTED", tracked, startAt, "INITIAL_SCAN"))
                maybeStartBleDiscovery(tracked)
            }
        }

        // 4. Subscribe to live signals (callbacks are delivered on this engine's looper).
        audioManager.registerAudioDeviceCallback(deviceCallback, handler)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val callback = object : AudioManager.AudioPlaybackCallback() {
                override fun onPlaybackConfigChanged(configs: MutableList<AudioPlaybackConfiguration>?) {
                    schedulePlaybackEvaluation("PLAYBACK_CALLBACK")
                }
            }
            playbackCallback = callback
            audioManager.registerAudioPlaybackCallback(callback, handler)
        }
        context.contentResolver.registerContentObserver(Settings.System.CONTENT_URI, true, volumeObserver)
        registerVolumeReceiver()
        bindA2dpProxy()

        evaluatePlayback("STARTUP")
        saveHeartbeat()
        scheduleTick()
        updateNotification(force = true)
        emitSync("STARTUP")
    }

    private fun stopInternal() {
        if (!started) return
        Log.i(TAG, "[ENGINE] stopping")
        val at = now()
        applyListening(null, at, "MONITORING_STOPPED")
        devices.values.toList().forEach { appendAndEmit(deviceEvent("DEVICE_DISCONNECTED", it, at, "MONITORING_STOPPED")) }
        devices.clear()
        pendingDisconnects.values.forEach { handler.removeCallbacks(it) }
        pendingDisconnects.clear()
        handler.removeCallbacksAndMessages(null)
        try {
            audioManager.unregisterAudioDeviceCallback(deviceCallback)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                playbackCallback?.let { audioManager.unregisterAudioPlaybackCallback(it) }
            }
            context.contentResolver.unregisterContentObserver(volumeObserver)
            a2dpProxy?.let { bluetoothAdapter?.closeProfileProxy(BluetoothProfile.A2DP, it) }
        } catch (e: Exception) {
            Log.w(TAG, "[ENGINE] unregister failed: ${e.message}")
        }
        try {
            context.unregisterReceiver(volumeReceiver)
        } catch (e: IllegalArgumentException) {
            // Receiver was never registered.
        }
        a2dpProxy = null
        bleDiscovery.close()
        prefs.clearRecovery()
        started = false
        emitSync("STOPPED")
    }

    // ---- Devices ----------------------------------------------------------------------------

    private val deviceCallback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) {
            addedDevices?.forEach { onRouteAdded(it) }
        }

        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>?) {
            removedDevices?.forEach { onRouteRemoved(it) }
        }
    }

    private fun onRouteAdded(device: AudioDeviceInfo) {
        if (!AudioDeviceDetector.isExternalListeningDevice(device)) return
        val info = extractInfo(device)
        val id = info["id"] as String
        pendingDisconnects.remove(id)?.let {
            handler.removeCallbacks(it)
            Log.i(TAG, "[ENGINE] route flap absorbed for $id")
        }
        val existing = devices[id]
        if (existing != null) {
            existing.routes.add(device.id)
            return
        }
        val at = now()
        val tracked = TrackedDevice(info, mutableSetOf(device.id), at)
        devices[id] = tracked
        appendAndEmit(deviceEvent("DEVICE_CONNECTED", tracked, at, "ROUTE_ADDED"))
        maybeStartBleDiscovery(tracked)
        saveHeartbeat()
        scheduleTick()
        schedulePlaybackEvaluation("DEVICE_ADDED")
        updateNotification(force = true)
    }

    private fun onRouteRemoved(device: AudioDeviceInfo) {
        // Match by system route id first: extracting info from a removed route can be unreliable.
        val tracked = devices.values.firstOrNull { it.routes.contains(device.id) }
            ?: devices[extractInfo(device)["id"] as String]
            ?: return
        tracked.routes.remove(device.id)
        if (tracked.routes.isNotEmpty()) {
            Log.i(TAG, "[ENGINE] route ${device.id} removed; ${tracked.id} still has ${tracked.routes}")
            return
        }
        if (pendingDisconnects.containsKey(tracked.id)) return
        val removalAt = now()
        val disconnect = Runnable {
            pendingDisconnects.remove(tracked.id)
            if (devices[tracked.id]?.routes?.isEmpty() != true) return@Runnable
            if (listeningDeviceId == tracked.id) applyListening(null, removalAt, "DEVICE_DISCONNECTED")
            devices.remove(tracked.id)
            appendAndEmit(deviceEvent("DEVICE_DISCONNECTED", tracked, removalAt, "ROUTE_REMOVED"))
            saveHeartbeat()
            evaluatePlayback("DEVICE_REMOVED")
            updateNotification(force = true)
        }
        pendingDisconnects[tracked.id] = disconnect
        handler.postDelayed(disconnect, DISCONNECT_DEBOUNCE_MS)
    }

    private fun extractInfo(device: AudioDeviceInfo): Map<String, Any?> {
        val (fallbackName, fallbackAddress) =
            if (AudioDeviceDetector.isBluetoothType(device.type)) bestA2dpFallback() else Pair(null, null)
        return AudioDeviceDetector.extractDeviceInfo(device, bluetoothAdapter, fallbackName, fallbackAddress)
    }

    @SuppressLint("MissingPermission")
    private fun bestA2dpFallback(): Pair<String?, String?> {
        val bd = try { a2dpProxy?.connectedDevices?.firstOrNull() } catch (e: SecurityException) { null } ?: return Pair(null, null)
        val name = try {
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) bd.alias else null) ?: bd.name
        } catch (e: SecurityException) {
            null
        }
        return Pair(name, bd.address)
    }

    private fun bindA2dpProxy() {
        try {
            bluetoothAdapter?.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    handler.post { a2dpProxy = proxy as? BluetoothA2dp }
                }

                override fun onServiceDisconnected(profile: Int) {
                    handler.post { a2dpProxy = null }
                }
            }, BluetoothProfile.A2DP)
        } catch (e: Exception) {
            Log.w(TAG, "[ENGINE] A2DP proxy unavailable: ${e.message}")
        }
    }

    private fun maybeStartBleDiscovery(device: TrackedDevice) {
        val address = device.address ?: return
        if (!AudioDeviceDetector.isBluetoothType(device.nativeType)) return
        try {
            bluetoothAdapter?.getRemoteDevice(address)?.let { bleDiscovery.discover(it) }
        } catch (e: Exception) {
            Log.w(TAG, "[ENGINE] BLE discovery skipped: ${e.message}")
        }
    }

    // ---- Playback ---------------------------------------------------------------------------

    private val evaluateRunnable = Runnable { evaluatePlayback("SETTLED") }
    private val reconcileRunnable = Runnable { evaluatePlayback("RECONCILE") }

    private fun schedulePlaybackEvaluation(reason: String) {
        Log.d(TAG, "[ENGINE] playback evaluation scheduled ($reason)")
        handler.removeCallbacks(evaluateRunnable)
        handler.removeCallbacks(reconcileRunnable)
        // Players report state changes slightly before the mixer output actually starts/stops.
        handler.postDelayed(evaluateRunnable, PLAYBACK_SETTLE_MS)
        handler.postDelayed(reconcileRunnable, PLAYBACK_RECONCILE_MS)
    }

    private fun isMusicActiveSafe(): Boolean = try {
        audioManager.isMusicActive
    } catch (e: Exception) {
        false
    }

    private fun evaluatePlayback(reason: String) {
        musicActive = isMusicActiveSafe()
        val target = if (musicActive) routedDeviceId() else null
        applyListening(target, now(), reason)
    }

    /** The tracked headset that media is routed to right now, or null (speaker, nothing tracked). */
    private fun routedDeviceId(): String? {
        if (devices.isEmpty()) return null
        val candidates = devices.values.filter { it.routes.isNotEmpty() || pendingDisconnects.containsKey(it.id) }
        if (candidates.isEmpty()) return null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                val attrs = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).build()
                val routed = audioManager.getAudioDevicesForAttributes(attrs)
                for (route in routed) {
                    val address = AudioDeviceDetector.normalizeAddress(route.address)
                    candidates.firstOrNull { address != null && it.address == address }?.let { return it.id }
                    candidates.lastOrNull { it.nativeType == route.type }?.let { return it.id }
                    candidates.lastOrNull {
                        AudioDeviceDetector.getConnectionType(it.nativeType) == AudioDeviceDetector.getConnectionType(route.type) &&
                            AudioDeviceDetector.getConnectionType(route.type) != "unknown"
                    }?.let { return it.id }
                }
                if (routed.isNotEmpty()) return null // Media is going somewhere we don't track (speaker, cast…).
            } catch (e: Exception) {
                Log.w(TAG, "[ENGINE] routing query failed: ${e.message}")
            }
        }
        // Heuristic for older releases: Android routes media to the most recently connected headset.
        return candidates.lastOrNull { AudioDeviceDetector.isMediaRouteType(it.nativeType) }?.id ?: candidates.last().id
    }

    private fun applyListening(targetId: String?, at: Long, reason: String) {
        if (targetId == listeningDeviceId) return
        accountExposure(at)
        listeningDeviceId?.let { previous ->
            appendAndEmit(playbackEvent("PLAYBACK_PAUSED", previous, devices[previous]?.info, at, reason))
            lastListeningEndedAt = at
            loudSince = 0L
        }
        listeningDeviceId = targetId
        if (targetId != null) {
            listeningSince = at
            accountedUntil = at
            if (continuousSince == 0L || at - lastListeningEndedAt >= BREAK_RESET_MS) {
                continuousSince = at
                breakAlertSent = false
                loudAlertSent = false
            }
            volume = ExposureMath.sampleVolume(audioManager, devices[targetId]?.nativeType)
            appendAndEmit(playbackEvent("PLAYBACK_STARTED", targetId, devices[targetId]?.info, at, reason))
        }
        saveHeartbeat()
        scheduleTick()
        updateNotification(force = true)
    }

    // ---- Volume & exposure ------------------------------------------------------------------

    private val volumeObserver = object : ContentObserver(handler) {
        override fun onChange(selfChange: Boolean) {
            handler.removeCallbacks(volumeRunnable)
            handler.postDelayed(volumeRunnable, VOLUME_DEBOUNCE_MS)
        }
    }

    private val volumeRunnable = Runnable { onVolumeMaybeChanged() }

    /**
     * Second volume signal. Newer releases persist volume to Settings lazily, so the observer
     * alone can miss changes; the (hidden but long-standing) VOLUME_CHANGED broadcast is immediate.
     */
    private val volumeReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            handler.removeCallbacks(volumeRunnable)
            handler.postDelayed(volumeRunnable, VOLUME_DEBOUNCE_MS)
        }
    }

    private fun registerVolumeReceiver() {
        val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(volumeReceiver, filter, null, handler, Context.RECEIVER_NOT_EXPORTED)
            } else {
                context.registerReceiver(volumeReceiver, filter, null, handler)
            }
        } catch (e: Exception) {
            Log.w(TAG, "[ENGINE] volume receiver unavailable: ${e.message}")
        }
    }

    private fun onVolumeMaybeChanged() {
        val activeType = (listeningDeviceId?.let { devices[it] } ?: devices.values.lastOrNull())?.nativeType
        val sample = ExposureMath.sampleVolume(audioManager, activeType)
        if (sample.index == volume.index && sample.max == volume.max) return
        val at = now()
        accountExposure(at) // Close the exposure slice at the old level first.
        volume = sample
        if (devices.isEmpty()) return
        val deviceId = listeningDeviceId ?: devices.values.last().id
        appendAndEmit(
            mapOf(
                "type" to "VOLUME_CHANGED",
                "deviceId" to deviceId,
                "device" to devices[deviceId]?.info,
                "volume" to volume.toMap(),
                "estimatedDb" to currentDb(),
                "timestamp" to at,
            )
        )
        updateNotification(force = true)
    }

    private fun currentDb(): Double = ExposureMath.estimatedDb(prefs.maxOutputDb, volume.attenuationDb)

    /** Adds listening time and dose for the slice [accountedUntil, at] and runs alert checks. */
    private fun accountExposure(at: Long) {
        if (listeningDeviceId == null) {
            accountedUntil = at
            return
        }
        val slice = at - accountedUntil
        if (slice <= 0) return
        val db = currentDb()
        prefs.addUsage(at, slice, ExposureMath.doseFraction(db, slice))
        accountedUntil = at
        checkAlerts(at, db)
    }

    private fun checkAlerts(at: Long, db: Double) {
        // Sustained loud listening.
        if (db >= prefs.loudThresholdDb) {
            if (loudSince == 0L) loudSince = at
            if (!loudAlertSent && at - loudSince >= LOUD_SUSTAIN_MS) {
                loudAlertSent = true
                val safeMinutes = (ExposureMath.weeklyAllowanceHours(db) * 60 / 7).toInt()
                alerts.alert(
                    "loud", "Your listening level is high",
                    "About ${db.toInt()} dB for the last few minutes. At this level the daily safe limit is roughly " +
                        "$safeMinutes minutes. Lowering the volume a few steps makes a big difference."
                )
            }
        } else {
            loudSince = 0L
        }

        // Break reminder (the "60/60" guideline).
        val breakMinutes = prefs.breakReminderMinutes
        if (breakMinutes > 0 && !breakAlertSent && continuousSince > 0 && at - continuousSince >= breakMinutes * 60_000L) {
            breakAlertSent = true
            alerts.alert(
                "break", "Time for a listening break",
                "You've been listening for $breakMinutes minutes. A 5–10 minute quiet break helps your ears recover."
            )
        }

        // Daily limit.
        val limit = prefs.dailyLimitMinutes
        if (limit > 0 && !prefs.alertSentToday("daily", at) && prefs.todayListenMs(at) >= limit * 60_000L) {
            prefs.markAlertSent("daily", at)
            alerts.alert("daily", "Daily listening goal reached", "You've listened for ${AlertManager.formatDuration(limit * 60_000L)} today.")
        }

        // Weekly sound allowance (WHO/ITU-T H.870).
        if (!prefs.alertSentToday("weekly", at) && prefs.weekDose(at) >= 1.0) {
            prefs.markAlertSent("weekly", at)
            alerts.alert(
                "weekly", "Weekly sound allowance used up",
                "You've reached 100% of the recommended weekly listening dose. Keep the volume lower for the next few days."
            )
        }
    }

    // ---- Tick, heartbeat, notification -------------------------------------------------------

    private val tickRunnable = Runnable { onTick() }

    private fun scheduleTick() {
        handler.removeCallbacks(tickRunnable)
        when {
            listeningDeviceId != null -> handler.postDelayed(tickRunnable, TICK_LISTENING_MS)
            devices.isNotEmpty() -> handler.postDelayed(tickRunnable, TICK_IDLE_MS)
        }
    }

    private fun onTick() {
        val at = now()
        // Reconcile: catches transitions a vendor ROM failed to report through callbacks.
        val active = isMusicActiveSafe()
        if (active != musicActive || (active && listeningDeviceId == null) || (!active && listeningDeviceId != null)) {
            evaluatePlayback("TICK")
        }
        if (listeningDeviceId != null) onVolumeMaybeChanged()
        accountExposure(at)
        saveHeartbeat()
        updateNotification(force = false)
        scheduleTick()
    }

    private fun saveHeartbeat() {
        prefs.saveRecovery(now(), listeningDeviceId, devices.values.map { it.info })
    }

    /** Last status shown in the foreground notification; safe to read from any thread. */
    @Volatile
    var latestStatus: AlertManager.LiveStatus? = null
        private set

    private fun updateNotification(force: Boolean) {
        val at = now()
        if (!force && at - lastNotificationUpdate < NOTIFICATION_INTERVAL_MS) return
        lastNotificationUpdate = at
        val status = liveStatus(at)
        latestStatus = status
        alerts.updateForeground(status)
    }

    private fun liveStatus(at: Long): AlertManager.LiveStatus {
        val device = listeningDeviceId?.let { devices[it] } ?: devices.values.lastOrNull()
        return AlertManager.LiveStatus(
            deviceName = device?.name,
            listening = listeningDeviceId != null,
            estimatedDb = currentDb(),
            todayListenMs = prefs.todayListenMs(at),
            weekDose = prefs.weekDose(at),
        )
    }

    // ---- Events -----------------------------------------------------------------------------

    private fun deviceEvent(type: String, device: TrackedDevice, at: Long, reason: String): Map<String, Any?> = mapOf(
        "type" to type,
        "deviceId" to device.id,
        "device" to device.info,
        "volume" to volume.toMap(),
        "estimatedDb" to currentDb(),
        "timestamp" to at,
        "reason" to reason,
    )

    private fun playbackEvent(type: String, deviceId: String, info: Map<String, Any?>?, at: Long, reason: String): Map<String, Any?> = mapOf(
        "type" to type,
        "deviceId" to deviceId,
        "device" to info,
        "volume" to volume.toMap(),
        "estimatedDb" to currentDb(),
        "timestamp" to at,
        "reason" to reason,
    )

    private fun List<Map<String, Any?>>.findInfo(id: String): Map<String, Any?>? = firstOrNull { it["id"] == id }

    /** Persists the event to the journal (assigning `seq`/`eventId`), then publishes it live. */
    private fun appendAndEmit(event: Map<String, Any?>) {
        val seq = prefs.nextSeq()
        val stamped = LinkedHashMap(event)
        stamped["seq"] = seq
        stamped["eventId"] = "n-$seq-${event["timestamp"]}"
        journal.append(stamped)
        Log.i(TAG, "[ENGINE] ${event["type"]} device=${event["deviceId"]} reason=${event["reason"]}")
        TrackingEventBroker.sendEvent(stamped)
    }

    private fun emitSync(reason: String) {
        val at = now()
        val active = listeningDeviceId?.let { devices[it] }
        TrackingEventBroker.sendEvent(
            mapOf(
                "type" to "SYNC_STATE",
                "reason" to reason,
                "monitoring" to started,
                "connectedDevices" to devices.values.map { it.info },
                "activeDeviceId" to (active?.id ?: devices.values.lastOrNull()?.id),
                "isPlaying" to (listeningDeviceId != null),
                "isMusicActive" to musicActive,
                "playbackStartedAt" to (if (listeningDeviceId != null) listeningSince else null),
                "volume" to volume.toMap(),
                "estimatedDb" to currentDb(),
                "todayListenMs" to prefs.todayListenMs(at),
                "weekDose" to prefs.weekDose(at),
                "settings" to prefs.settingsMap(),
                "timestamp" to at,
            )
        )
    }

    private fun now() = System.currentTimeMillis()

    companion object {
        private const val TAG = "EarTimeDiag"
        const val DISCONNECT_DEBOUNCE_MS = 1_500L
        const val PLAYBACK_SETTLE_MS = 350L
        const val PLAYBACK_RECONCILE_MS = 2_000L
        const val VOLUME_DEBOUNCE_MS = 400L
        const val TICK_LISTENING_MS = 5_000L
        const val TICK_IDLE_MS = 30_000L
        const val NOTIFICATION_INTERVAL_MS = 60_000L
        const val RECOVERY_GAP_MS = 2 * 60_000L
        const val BREAK_RESET_MS = 5 * 60_000L
        const val LOUD_SUSTAIN_MS = 3 * 60_000L
    }
}
