package com.eartime.eartime_app.tracking

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.eartime.eartime_app.MainActivity
import com.eartime.eartime_app.R
import kotlin.math.roundToInt

/**
 * Owns every notification the tracker shows:
 *  - the ongoing foreground-service notification, updated live with today's listening time,
 *    the estimated level and the weekly sound allowance;
 *  - background hearing-health alerts (loud level, break reminder, daily limit, weekly allowance),
 *    which work even when the Flutter UI is closed.
 */
class AlertManager(private val context: Context, private val prefs: TrackingPrefs) {

    private val manager = NotificationManagerCompat.from(context)

    fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val system = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        system.createNotificationChannel(
            NotificationChannel(CHANNEL_TRACKING, "Listening monitor", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Shows live listening time while EarTime monitors your headphones"
                setShowBadge(false)
            }
        )
        system.createNotificationChannel(
            NotificationChannel(CHANNEL_ALERTS, "Hearing alerts", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Loud listening, break reminders and weekly sound allowance"
            }
        )
    }

    private fun contentIntent(): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        return PendingIntent.getActivity(context, 0, intent, flags)
    }

    data class LiveStatus(
        val deviceName: String?,
        val listening: Boolean,
        val estimatedDb: Double,
        val todayListenMs: Long,
        val weekDose: Double,
    )

    fun buildForeground(status: LiveStatus?): Notification {
        val title: String
        val text: String
        if (status == null || status.deviceName == null) {
            title = "EarTime is monitoring"
            text = if (status != null && status.todayListenMs > 0) {
                "Today ${formatDuration(status.todayListenMs)} · ${percent(status.weekDose)} weekly sound allowance"
            } else {
                "Waiting for headphones"
            }
        } else {
            title = if (status.listening) "Listening · ${status.deviceName}" else "Connected · ${status.deviceName}"
            val parts = mutableListOf("Today ${formatDuration(status.todayListenMs)}")
            if (status.listening && status.estimatedDb > 0) parts.add("~${status.estimatedDb.roundToInt()} dB")
            parts.add("${percent(status.weekDose)} weekly allowance")
            text = parts.joinToString(" · ")
        }
        return NotificationCompat.Builder(context, CHANNEL_TRACKING)
            .setSmallIcon(R.drawable.ic_stat_eartime)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(contentIntent())
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    fun updateForeground(status: LiveStatus) {
        notifySafely(FOREGROUND_ID, buildForeground(status))
    }

    fun alert(kind: String, title: String, text: String) {
        if (!prefs.alertsEnabled) return
        val notification = NotificationCompat.Builder(context, CHANNEL_ALERTS)
            .setSmallIcon(R.drawable.ic_stat_eartime)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setContentIntent(contentIntent())
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
        notifySafely(ALERT_BASE_ID + (kind.hashCode() and 0xFF), notification)
        TrackingEventBroker.sendEvent(
            mapOf("type" to "HEARING_ALERT", "kind" to kind, "message" to text, "timestamp" to System.currentTimeMillis())
        )
    }

    private fun notifySafely(id: Int, notification: Notification) {
        try {
            if (manager.areNotificationsEnabled()) manager.notify(id, notification)
        } catch (e: SecurityException) {
            Log.w("EarTimeDiag", "[ALERT] notification permission missing: ${e.message}")
        }
    }

    companion object {
        const val CHANNEL_TRACKING = "EarTimeTrackingChannel"
        const val CHANNEL_ALERTS = "EarTimeHearingAlerts"
        const val FOREGROUND_ID = 1001
        private const val ALERT_BASE_ID = 2000

        fun formatDuration(ms: Long): String {
            val totalMinutes = ms / 60_000
            val h = totalMinutes / 60
            val m = totalMinutes % 60
            return if (h > 0) "${h}h ${m}m" else "${m}m"
        }

        fun percent(fraction: Double): String = "${(fraction * 100).roundToInt()}%"
    }
}
