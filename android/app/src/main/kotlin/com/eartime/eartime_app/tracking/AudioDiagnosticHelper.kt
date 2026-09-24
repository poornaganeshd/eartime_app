package com.eartime.eartime_app.tracking

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import androidx.core.content.ContextCompat
import android.util.Log

object AudioDiagnosticHelper {
    fun getDiagnostics(context: Context, onCompleteRaw: (Map<String, Any?>) -> Unit) {
        // MethodChannel results may be answered exactly once; guard every completion path.
        val completed = java.util.concurrent.atomic.AtomicBoolean(false)
        val onComplete: (Map<String, Any?>) -> Unit = { if (completed.compareAndSet(false, true)) onCompleteRaw(it) }
        val result = mutableMapOf<String, Any?>()
        result["trackingServiceRunning"] = AudioTrackingService.engine != null
        result["monitoringEnabled"] = TrackingPrefs(context).monitoringEnabled
        result["journalPending"] = EventJournal.get(context).read(0L).size
        val tag = "EarTimeDiag"
        
        Log.i(tag, "[AUDIO] getAudioDiagnostics called")

        // 1. Android / API
        result["androidVersion"] = Build.VERSION.RELEASE
        result["apiLevel"] = Build.VERSION.SDK_INT

        // 2. Permissions
        Log.i(tag, "[PERMISSION] Checking permissions...")
        val hasBtConnect = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else {
            true // implicitly granted
        }
        val hasBtScan = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
        val hasFgServiceConnectedDevice = if (Build.VERSION.SDK_INT >= 34) { // Android 14
            ContextCompat.checkSelfPermission(context, Manifest.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
        
        Log.i(tag, "[PERMISSION] BLUETOOTH_CONNECT: $hasBtConnect")
        Log.i(tag, "[PERMISSION] BLUETOOTH_SCAN: $hasBtScan")
        Log.i(tag, "[PERMISSION] FOREGROUND_SERVICE_CONNECTED_DEVICE: $hasFgServiceConnectedDevice")

        result["hasBluetoothConnect"] = hasBtConnect
        result["hasBluetoothScan"] = hasBtScan
        result["hasFgServiceConnectedDevice"] = hasFgServiceConnectedDevice

        // 3. Bluetooth Adapter
        val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = btManager?.adapter
        val adapterState = if (adapter == null) "null" else if (adapter.isEnabled) "enabled" else "disabled"
        Log.i(tag, "[BLUETOOTH] BluetoothAdapter state: $adapterState")
        result["bluetoothAdapterState"] = adapterState

        // 4. BluetoothA2dp (using getProfileProxy for true A2DP connected devices)
        Log.i(tag, "[BLUETOOTH] Checking BluetoothAdapter.getProfileProxy(A2DP)...")
        if (adapter != null && hasBtConnect) {
            val profileListener = object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    if (profile == BluetoothProfile.A2DP) {
                        try {
                            val a2dp = proxy as android.bluetooth.BluetoothA2dp
                            val a2dpDevices = a2dp.connectedDevices
                            result["a2dpConnectedCount"] = a2dpDevices.size
                            Log.i(tag, "[BLUETOOTH] BluetoothA2dp.connectedDevices count: ${a2dpDevices.size}")
                            
                            val a2dpNames = mutableListOf<String>()
                            val a2dpAddresses = mutableListOf<String>()
                            for (device in a2dpDevices) {
                                val name = try { device.name ?: "null" } catch(e: SecurityException) { "PermissionDenied" }
                                val addr = device.address ?: "null"
                                a2dpNames.add(name)
                                a2dpAddresses.add(addr)
                                Log.i(tag, "[BLUETOOTH] connected Bluetooth device names: $name")
                                Log.i(tag, "[BLUETOOTH] connected Bluetooth device addresses: $addr")
                            }
                            result["a2dpConnectedNames"] = a2dpNames
                        } catch (e: Exception) {
                            Log.e(tag, "[BLUETOOTH] Failed to get A2DP devices: ${e.message}")
                            result["a2dpConnectedCount"] = 0
                            result["a2dpConnectedNames"] = emptyList<String>()
                        } finally {
                            adapter.closeProfileProxy(BluetoothProfile.A2DP, proxy)
                            finishDiagnostics(context, result, onComplete)
                        }
                    }
                }
                override fun onServiceDisconnected(profile: Int) {
                    // Nothing to do
                }
            }
            val bound = try {
                adapter.getProfileProxy(context, profileListener, BluetoothProfile.A2DP)
            } catch (e: Exception) {
                false
            }
            if (!bound) {
                result["a2dpConnectedCount"] = 0
                result["a2dpConnectedNames"] = emptyList<String>()
                finishDiagnostics(context, result, onComplete)
            } else {
                // Never leave the Dart future hanging if the proxy never connects.
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    result.putIfAbsent("a2dpConnectedCount", 0)
                    result.putIfAbsent("a2dpConnectedNames", emptyList<String>())
                    finishDiagnostics(context, result, onComplete)
                }, 3000)
            }
        } else {
            result["a2dpConnectedCount"] = 0
            result["a2dpConnectedNames"] = emptyList<String>()
            finishDiagnostics(context, result, onComplete)
        }
    }

    private fun finishDiagnostics(context: Context, result: MutableMap<String, Any?>, onComplete: (Map<String, Any?>) -> Unit) {
        val tag = "EarTimeDiag"
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        Log.i(tag, "[AUDIO] AudioManager initialized")
        Log.i(tag, "[AUDIO] getDevices(GET_DEVICES_OUTPUTS) called")
        
        val audioDevices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        Log.i(tag, "[AUDIO] number of output devices returned: ${audioDevices.size}")
        result["audioManagerOutputCount"] = audioDevices.size

        val outputDevicesList = mutableListOf<Map<String, Any?>>()
        for (device in audioDevices) {
            val addr = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) device.address else "N/A"
            Log.i(tag, "[AUDIO] complete raw information for EVERY output device:")
            Log.i(tag, "[AUDIO]   type: ${device.type}")
            Log.i(tag, "[AUDIO]   productName: ${device.productName}")
            Log.i(tag, "[AUDIO]   address: $addr")
            Log.i(tag, "[AUDIO]   isSink: ${device.isSink}")
            Log.i(tag, "[AUDIO]   isSource: ${device.isSource}")
            Log.i(tag, "[AUDIO]   id: ${device.id}")
            
            outputDevicesList.add(mapOf(
                "type" to device.type,
                "productName" to device.productName?.toString(),
                "address" to addr,
                "isSink" to device.isSink,
                "isSource" to device.isSource,
                "id" to device.id
            ))
        }
        result["audioManagerDevices"] = outputDevicesList

        onComplete(result)
    }
}
