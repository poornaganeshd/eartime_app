package com.eartime.eartime_app.tracking

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Durable native state: user settings that the background service needs even when Flutter is
 * not running, crash-recovery markers, and per-day listening/exposure accumulators used for the
 * live notification and background hearing alerts.
 */
class TrackingPrefs(context: Context) {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences("eartime_tracking", Context.MODE_PRIVATE)

    // ---- Settings -------------------------------------------------------------------------

    var monitoringEnabled: Boolean
        get() = prefs.getBoolean(KEY_MONITORING, true)
        set(value) = prefs.edit().putBoolean(KEY_MONITORING, value).apply()

    /** Estimated SPL (dBA) the headphones produce at 100% volume. Used to turn volume into dB. */
    var maxOutputDb: Double
        get() = prefs.getFloat(KEY_MAX_OUTPUT_DB, DEFAULT_MAX_OUTPUT_DB.toFloat()).toDouble()
        set(value) = prefs.edit().putFloat(KEY_MAX_OUTPUT_DB, value.toFloat()).apply()

    var loudThresholdDb: Double
        get() = prefs.getFloat(KEY_LOUD_DB, DEFAULT_LOUD_DB.toFloat()).toDouble()
        set(value) = prefs.edit().putFloat(KEY_LOUD_DB, value.toFloat()).apply()

    var alertsEnabled: Boolean
        get() = prefs.getBoolean(KEY_ALERTS, true)
        set(value) = prefs.edit().putBoolean(KEY_ALERTS, value).apply()

    /** Continuous-listening minutes before a break reminder; 0 disables reminders. */
    var breakReminderMinutes: Int
        get() = prefs.getInt(KEY_BREAK_MIN, 60)
        set(value) = prefs.edit().putInt(KEY_BREAK_MIN, value).apply()

    /** Daily listening goal/limit in minutes; 0 disables the daily-limit alert. */
    var dailyLimitMinutes: Int
        get() = prefs.getInt(KEY_DAILY_LIMIT, 180)
        set(value) = prefs.edit().putInt(KEY_DAILY_LIMIT, value).apply()

    fun settingsMap(): Map<String, Any?> = mapOf(
        "monitoringEnabled" to monitoringEnabled,
        "maxOutputDb" to maxOutputDb,
        "loudThresholdDb" to loudThresholdDb,
        "alertsEnabled" to alertsEnabled,
        "breakReminderMinutes" to breakReminderMinutes,
        "dailyLimitMinutes" to dailyLimitMinutes,
    )

    fun applySettings(map: Map<*, *>) {
        (map["maxOutputDb"] as? Number)?.let { maxOutputDb = it.toDouble().coerceIn(70.0, 125.0) }
        (map["loudThresholdDb"] as? Number)?.let { loudThresholdDb = it.toDouble().coerceIn(70.0, 110.0) }
        (map["alertsEnabled"] as? Boolean)?.let { alertsEnabled = it }
        (map["breakReminderMinutes"] as? Number)?.let { breakReminderMinutes = it.toInt().coerceIn(0, 600) }
        (map["dailyLimitMinutes"] as? Number)?.let { dailyLimitMinutes = it.toInt().coerceIn(0, 1440) }
    }

    // ---- Journal sequence -----------------------------------------------------------------

    /**
     * Monotonic journal sequence. Written synchronously (commit): if the process died after an
     * asynchronous apply(), a restarted engine could reuse numbers Flutter already acknowledged,
     * and those new events would be filtered out as "already ingested".
     */
    fun nextSeq(): Long {
        val next = prefs.getLong(KEY_SEQ, 0L) + 1
        prefs.edit().putLong(KEY_SEQ, next).commit()
        return next
    }

    // ---- Crash recovery -------------------------------------------------------------------

    /** Snapshot of what the engine believed right before the last heartbeat. */
    data class RecoveryState(
        val heartbeatAt: Long,
        val listeningDeviceId: String?,
        val devices: List<Map<String, Any?>>,
    )

    fun saveRecovery(heartbeatAt: Long, listeningDeviceId: String?, devices: Collection<Map<String, Any?>>) {
        val array = JSONArray()
        devices.forEach { array.put(JsonUtil.toJson(it)) }
        prefs.edit()
            .putLong(KEY_HEARTBEAT, heartbeatAt)
            .putString(KEY_LISTENING_DEVICE, listeningDeviceId)
            .putString(KEY_DEVICES, array.toString())
            .apply()
    }

    fun loadRecovery(): RecoveryState? {
        val heartbeat = prefs.getLong(KEY_HEARTBEAT, 0L)
        if (heartbeat == 0L) return null
        val devices = try {
            val array = JSONArray(prefs.getString(KEY_DEVICES, "[]"))
            (0 until array.length()).map { JsonUtil.toMap(array.getJSONObject(it)) }
        } catch (e: Exception) {
            emptyList()
        }
        return RecoveryState(heartbeat, prefs.getString(KEY_LISTENING_DEVICE, null), devices)
    }

    fun clearRecovery() {
        prefs.edit().remove(KEY_HEARTBEAT).remove(KEY_LISTENING_DEVICE).remove(KEY_DEVICES).apply()
    }

    // ---- Daily accumulators ---------------------------------------------------------------

    private fun dayKey(timeMs: Long): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(timeMs))

    private fun loadDays(): JSONObject = try {
        JSONObject(prefs.getString(KEY_DAYS, "{}") ?: "{}")
    } catch (e: Exception) {
        JSONObject()
    }

    /** Adds listening time and exposure dose (fraction of the weekly allowance) to the given day. */
    fun addUsage(timeMs: Long, listenMs: Long, doseFraction: Double) {
        if (listenMs <= 0 && doseFraction <= 0.0) return
        val days = loadDays()
        val key = dayKey(timeMs)
        val day = days.optJSONObject(key) ?: JSONObject()
        day.put("ms", day.optLong("ms", 0L) + listenMs)
        day.put("dose", day.optDouble("dose", 0.0) + doseFraction)
        days.put(key, day)

        // Keep only the last 8 days.
        val cutoff = dayKey(timeMs - 8L * 24 * 60 * 60 * 1000)
        val stale = mutableListOf<String>()
        days.keys().forEach { if (it < cutoff) stale.add(it) }
        stale.forEach { days.remove(it) }

        prefs.edit().putString(KEY_DAYS, days.toString()).apply()
    }

    fun todayListenMs(now: Long): Long = loadDays().optJSONObject(dayKey(now))?.optLong("ms", 0L) ?: 0L

    fun todayDose(now: Long): Double = loadDays().optJSONObject(dayKey(now))?.optDouble("dose", 0.0) ?: 0.0

    /** Rolling 7-day dose (today plus the previous six days). */
    fun weekDose(now: Long): Double {
        val days = loadDays()
        var total = 0.0
        for (i in 0 until 7) {
            val key = dayKey(now - i * 24L * 60 * 60 * 1000)
            total += days.optJSONObject(key)?.optDouble("dose", 0.0) ?: 0.0
        }
        return total
    }

    // ---- Once-per-day alert bookkeeping ---------------------------------------------------

    fun alertSentToday(kind: String, now: Long): Boolean = prefs.getString("alert_$kind", null) == dayKey(now)

    fun markAlertSent(kind: String, now: Long) {
        prefs.edit().putString("alert_$kind", dayKey(now)).apply()
    }

    companion object {
        const val DEFAULT_MAX_OUTPUT_DB = 100.0
        const val DEFAULT_LOUD_DB = 90.0

        private const val KEY_MONITORING = "monitoring_enabled"
        private const val KEY_MAX_OUTPUT_DB = "max_output_db"
        private const val KEY_LOUD_DB = "loud_threshold_db"
        private const val KEY_ALERTS = "alerts_enabled"
        private const val KEY_BREAK_MIN = "break_reminder_minutes"
        private const val KEY_DAILY_LIMIT = "daily_limit_minutes"
        private const val KEY_SEQ = "journal_seq"
        private const val KEY_HEARTBEAT = "recovery_heartbeat"
        private const val KEY_LISTENING_DEVICE = "recovery_listening_device"
        private const val KEY_DEVICES = "recovery_devices"
        private const val KEY_DAYS = "daily_usage"
    }
}
