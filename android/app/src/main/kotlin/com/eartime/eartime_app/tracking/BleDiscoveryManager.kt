package com.eartime.eartime_app.tracking

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.util.Log

class BleDiscoveryManager(private val context: Context) {

    companion object {
        private const val TAG = "BleDiscoveryManager"
    }

    @Volatile private var currentGatt: BluetoothGatt? = null
    @Volatile private var isConnecting = false
    @Volatile private var isConnected = false

    @SuppressLint("MissingPermission")
    fun discover(device: BluetoothDevice, forceRefresh: Boolean = false) {
        Log.i(TAG, "[BLE_DISCOVERY] Starting discovery for ${device.address}. Force=$forceRefresh")
        
        if (currentGatt != null && currentGatt!!.device.address == device.address) {
            if (!forceRefresh && (isConnecting || isConnected)) {
                Log.i(TAG, "[BLE_DISCOVERY] Already connecting/connected to ${device.address}. Ignoring duplicate request.")
                return
            }
        }
        
        // Clean up previous connection if exists
        currentGatt?.disconnect()
        currentGatt?.close()
        currentGatt = null
        TrackingEventBroker.clearLatestDiscoveryResult()
        isConnecting = true
        isConnected = false

        try {
            TrackingEventBroker.sendEvent(mapOf(
                "type" to "BLE_DIAGNOSTIC_STATE",
                "deviceId" to device.address,
                "state" to "CONNECTING",
                "timestamp" to System.currentTimeMillis()
            ))
            Log.i(TAG, "[BLE-LIFECYCLE] GATT connect requested")
            currentGatt = device.connectGatt(context, false, gattCallback)
        } catch (e: Exception) {
            isConnecting = false
            Log.e(TAG, "[BLE_DISCOVERY] Exception starting GATT: ${e.message}")
            TrackingEventBroker.sendEvent(mapOf(
                "type" to "BLE_DIAGNOSTIC_STATE",
                "deviceId" to device.address,
                "state" to "ERROR",
                "message" to "Exception starting GATT: ${e.message}",
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {

        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val stateStr = when (newState) {
                BluetoothProfile.STATE_CONNECTED -> "CONNECTED"
                BluetoothProfile.STATE_DISCONNECTED -> "DISCONNECTED"
                else -> "UNKNOWN_$newState"
            }
            Log.i(TAG, "[BLE-LIFECYCLE] GATT state changed: $stateStr (status=$status)")

            if (status != BluetoothGatt.GATT_SUCCESS) {
                isConnecting = false
                Log.e(TAG, "[BLE_DISCOVERY] GATT Error status: $status newState: $newState")
                TrackingEventBroker.sendEvent(mapOf(
                    "type" to "BLE_DIAGNOSTIC_STATE",
                    "deviceId" to gatt.device.address,
                    "state" to "ERROR",
                    "status" to status,
                    "newState" to newState,
                    "message" to "GATT Connection Error. Status: $status",
                    "timestamp" to System.currentTimeMillis()
                ))
                gatt.close()
                currentGatt = null
                return
            }

            if (newState == BluetoothProfile.STATE_CONNECTED) {
                isConnecting = false
                isConnected = true
                Log.i(TAG, "[BLE_DISCOVERY] Connected to GATT server.")
                TrackingEventBroker.sendEvent(mapOf(
                    "type" to "BLE_DIAGNOSTIC_STATE",
                    "deviceId" to gatt.device.address,
                    "state" to "CONNECTED",
                    "timestamp" to System.currentTimeMillis()
                ))
                
                // Start service discovery
                Log.i(TAG, "[BLE-LIFECYCLE] Requesting service discovery")
                gatt.discoverServices()
                TrackingEventBroker.sendEvent(mapOf(
                    "type" to "BLE_DIAGNOSTIC_STATE",
                    "deviceId" to gatt.device.address,
                    "state" to "SERVICE_DISCOVERY",
                    "timestamp" to System.currentTimeMillis()
                ))
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                isConnecting = false
                isConnected = false
                Log.i(TAG, "[BLE_DISCOVERY] Disconnected from GATT server.")
                TrackingEventBroker.sendEvent(mapOf(
                    "type" to "BLE_DIAGNOSTIC_STATE",
                    "deviceId" to gatt.device.address,
                    "state" to "DISCONNECTED",
                    "timestamp" to System.currentTimeMillis()
                ))
                gatt.close()
                currentGatt = null
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            Log.i(TAG, "[GATT DISCOVERY] onServicesDiscovered entered")
            Log.i(TAG, "[GATT DISCOVERY] status=$status")
            Log.i(TAG, "[GATT DISCOVERY] serviceCount=${gatt.services.size}")

            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.i(TAG, "[GATT DISCOVERY] SERVICE_DISCOVERY_SUCCESS")
                Log.i(TAG, "[BLE_DISCOVERY] Services discovered!")
                Log.i(TAG, "[BLE-LIFECYCLE] Services discovered")
                
                TrackingEventBroker.sendEvent(mapOf(
                    "type" to "BLE_DIAGNOSTIC_STATE",
                    "deviceId" to gatt.device.address,
                    "state" to "SERVICES_DISCOVERED",
                    "timestamp" to System.currentTimeMillis()
                ))
                
                val servicesList = mutableListOf<Map<String, Any>>()
                
                // Keep track of whether we found OPOv1
                var opoServiceFound = false
                var opoCharFound = false

                for (service in gatt.services) {
                    val characteristicsList = mutableListOf<Map<String, Any>>()
                    
                    val sUuid = service.uuid.toString().uppercase()
                    Log.i(TAG, "[GATT SERVICE] uuid=$sUuid")
                    if (sUuid.contains("0000079A-D102-11E1-9B23-00025B00A5A5")) {
                        Log.i(TAG, "[OPOV1] SERVICE_FOUND")
                        Log.i(TAG, "[OPOV1] uuid=$sUuid")
                        opoServiceFound = true
                    }
                    
                    for (char in service.characteristics) {
                        val properties = mutableListOf<String>()
                        if (char.properties and BluetoothGattCharacteristic.PROPERTY_READ != 0) properties.add("READ")
                        if (char.properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0) properties.add("WRITE")
                        if (char.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0) properties.add("NOTIFY")
                        
                        val cUuid = char.uuid.toString().uppercase()
                        Log.i(TAG, "[GATT CHARACTERISTIC] service=$sUuid uuid=$cUuid properties=$properties")

                        // Subscribe if this is the OPOv1 notification characteristic
                        if (cUuid.contains("0100079A-D102-11E1-9B23-00025B00A5A5")) {
                            Log.i(TAG, "[OPOV1] WRITE_CHARACTERISTIC_FOUND")
                        }
                        if (cUuid.contains("0200079A-D102-11E1-9B23-00025B00A5A5")) {
                            Log.i(TAG, "[OPOV1] NOTIFY_CHARACTERISTIC_FOUND")
                            opoCharFound = true
                            Log.i(TAG, "[BLE-LIFECYCLE] OPOv1 detected")
                            Log.i(TAG, "[BLE_DISCOVERY] Found OPOv1 notification characteristic. Subscribing...")
                            gatt.setCharacteristicNotification(char, true)
                            
                            val cccdUuid = java.util.UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
                            val descriptor = char.getDescriptor(cccdUuid)
                            if (descriptor != null) {
                                descriptor.value = android.bluetooth.BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                                gatt.writeDescriptor(descriptor)
                                Log.i(TAG, "[BLE_DISCOVERY] Wrote CCCD descriptor for OPOv1.")
                                Log.i(TAG, "[BLE-LIFECYCLE] Notifications enabled")
                            } else {
                                Log.e(TAG, "[BLE_DISCOVERY] CCCD descriptor not found for OPOv1.")
                            }
                        }

                        characteristicsList.add(mapOf(
                            "uuid" to cUuid,
                            "properties" to properties
                        ))
                    }
                    
                    servicesList.add(mapOf(
                        "uuid" to sUuid,
                        "type" to if (service.type == BluetoothGattService.SERVICE_TYPE_PRIMARY) "PRIMARY" else "SECONDARY",
                        "characteristics" to characteristicsList
                    ))
                }

                val result = mapOf(
                    "type" to "BLE_DISCOVERY_RESULT",
                    "deviceId" to gatt.device.address,
                    "device" to mapOf(
                        "deviceName" to (gatt.device.name ?: "Unknown"),
                        "deviceAddress" to gatt.device.address,
                        "gattConnected" to true,
                        "services" to servicesList
                    ),
                    "timestamp" to System.currentTimeMillis()
                )

                Log.i(TAG, "[BLE EVENT] Preparing BLE_DISCOVERY_RESULT")
                Log.i(TAG, "[BLE EVENT] Result serviceCount=${servicesList.size}")
                Log.i(TAG, "[BLE EVENT] Sending BLE_DISCOVERY_RESULT")

                // Dispatch to Flutter
                TrackingEventBroker.sendEvent(result)
            } else {
                Log.e(TAG, "[BLE_DISCOVERY] onServicesDiscovered received error: $status")
                TrackingEventBroker.sendEvent(mapOf(
                    "type" to "BLE_DIAGNOSTIC_STATE",
                    "deviceId" to gatt.device.address,
                    "state" to "ERROR",
                    "status" to status,
                    "message" to "onServicesDiscovered received error: $status",
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            val payloadBytes = characteristic.value ?: ByteArray(0)
            val hexPayload = payloadBytes.joinToString("") { "%02X".format(it) }
            
            Log.i(TAG, "[BLE_NOTIFY] Char: ${characteristic.uuid} Payload: $hexPayload")

            val result = mapOf(
                "type" to "BLE_NOTIFICATION",
                "deviceId" to gatt.device.address,
                "serviceUuid" to characteristic.service.uuid.toString(),
                "characteristicUuid" to characteristic.uuid.toString(),
                "payload" to hexPayload,
                "timestamp" to System.currentTimeMillis()
            )

            TrackingEventBroker.sendEvent(result)
        }
    }

    @SuppressLint("MissingPermission")
    fun disconnect() {
        currentGatt?.disconnect()
    }

    /** Releases the GATT client; must be called when the tracking service stops. */
    @SuppressLint("MissingPermission")
    fun close() {
        try {
            currentGatt?.disconnect()
            currentGatt?.close()
        } catch (e: Exception) {
            Log.w(TAG, "[BLE_DISCOVERY] close failed: ${e.message}")
        }
        currentGatt = null
        isConnecting = false
        isConnected = false
    }
}
