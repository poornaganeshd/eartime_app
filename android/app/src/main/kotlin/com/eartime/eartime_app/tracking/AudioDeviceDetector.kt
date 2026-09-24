package com.eartime.eartime_app.tracking

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.media.AudioDeviceInfo
import android.os.Build
import android.util.Log

/**
 * Classifies Android audio outputs and builds the stable logical device model sent to Flutter.
 *
 * A single physical headset commonly exposes several routes (A2DP for media, SCO for calls,
 * LE Audio for both). All routes of one headset resolve to the same logical id (its MAC address),
 * and [TrackingEngine] reference-counts those routes so that one route disappearing never
 * disconnects the headset (Bug A2).
 */
object AudioDeviceDetector {

    private const val TAG = "EarTimeDiag"

    // Constants that are not available on every compile/min SDK level.
    const val TYPE_HEARING_AID = 23 // API 28
    const val TYPE_BLE_HEADSET = 26 // API 31
    const val TYPE_BLE_SPEAKER = 27 // API 31
    const val TYPE_BLE_BROADCAST = 30 // API 33

    private val BLUETOOTH_TYPES = setOf(
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
        AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
        TYPE_HEARING_AID,
        TYPE_BLE_HEADSET,
        TYPE_BLE_SPEAKER,
        TYPE_BLE_BROADCAST,
    )

    private val WIRED_TYPES = setOf(
        AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
        AudioDeviceInfo.TYPE_WIRED_HEADSET,
    )

    private val USB_TYPES = setOf(
        AudioDeviceInfo.TYPE_USB_DEVICE,
        AudioDeviceInfo.TYPE_USB_HEADSET,
        AudioDeviceInfo.TYPE_USB_ACCESSORY,
    )

    fun isBluetoothType(type: Int) = type in BLUETOOTH_TYPES

    /** Media-capable routes. SCO is call-only audio and never carries media playback. */
    fun isMediaRouteType(type: Int) = type != AudioDeviceInfo.TYPE_BLUETOOTH_SCO

    /**
     * True when the output is something worn on/in the ear (or a personal listening device).
     * Built-in speakers, earpieces, HDMI, cast routes, etc. are rejected.
     */
    fun isExternalListeningDevice(device: AudioDeviceInfo): Boolean {
        if (!device.isSink) return false
        val type = device.type
        val accepted = type in BLUETOOTH_TYPES || type in WIRED_TYPES || type in USB_TYPES
        Log.d(TAG, "[DETECTOR] name=${device.productName} type=$type id=${device.id} accepted=$accepted")
        return accepted
    }

    fun getConnectionType(type: Int): String = when (type) {
        TYPE_HEARING_AID -> "hearing_aid"
        in BLUETOOTH_TYPES -> "bluetooth"
        in WIRED_TYPES -> "wired"
        in USB_TYPES -> "usb"
        else -> "unknown"
    }

    /** A usable MAC address, or null for empty, zeroed or anonymised ("XX:XX:…") addresses. */
    fun normalizeAddress(raw: String?): String? {
        if (raw.isNullOrBlank()) return null
        val upper = raw.trim().uppercase()
        if (upper == "00:00:00:00:00:00") return null
        if (!BluetoothAdapter.checkBluetoothAddress(upper)) return null
        return upper
    }

    @SuppressLint("MissingPermission")
    private fun resolveBluetoothName(adapter: BluetoothAdapter?, address: String): String? {
        if (adapter == null) return null
        return try {
            val remote = adapter.getRemoteDevice(address)
            val alias = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) remote.alias else null
            (alias ?: remote.name)?.takeIf { it.isNotBlank() }
        } catch (e: SecurityException) {
            null
        } catch (e: IllegalArgumentException) {
            null
        }
    }

    /**
     * Builds the logical device map.
     *
     * Name priority: Bluetooth alias/name resolved from the route's own MAC (the user-visible name),
     * then [fallbackName] (the connected A2DP device, used only when Android hides the MAC),
     * then AudioManager's productName (which on some OEMs is the *phone* model, e.g. "CPH2447").
     */
    fun extractDeviceInfo(
        device: AudioDeviceInfo,
        adapter: BluetoothAdapter?,
        fallbackName: String? = null,
        fallbackAddress: String? = null,
    ): Map<String, Any?> {
        val type = device.type
        val bluetooth = isBluetoothType(type)
        val ownAddress = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) normalizeAddress(device.address) else null
        val address = ownAddress ?: if (bluetooth) normalizeAddress(fallbackAddress) else null

        val productName = device.productName?.toString()?.takeIf { it.isNotBlank() }
        val name = when {
            bluetooth && address != null -> resolveBluetoothName(adapter, address) ?: fallbackName ?: productName
            bluetooth -> fallbackName ?: productName
            else -> productName
        } ?: defaultName(type)

        val connectionType = getConnectionType(type)
        // Wired/USB routes have no MAC; they are keyed by type class so re-plugging keeps the same id.
        val stableId = address ?: "${connectionType}_${name.replace(' ', '_')}"

        return mapOf(
            "id" to stableId,
            "systemId" to device.id.toString(),
            "hardwareAddress" to address,
            "friendlyName" to name,
            "connectionType" to connectionType,
            "nativeType" to type,
        )
    }

    private fun defaultName(type: Int): String = when (getConnectionType(type)) {
        "wired" -> "Wired headphones"
        "usb" -> "USB headphones"
        "hearing_aid" -> "Hearing aid"
        else -> "Bluetooth audio device"
    }
}
