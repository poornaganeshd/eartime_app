package com.eartime.eartime_app.tracking

import android.media.AudioManager
import android.os.Build
import kotlin.math.pow

/**
 * Headphone sound-exposure model (mirrored 1:1 in lib/domain/logic/exposure_math.dart).
 *
 * Follows WHO/ITU-T H.870 "Safe listening devices": the reference weekly allowance for adults is
 * 1.6 Pa²h, i.e. 80 dB(A) for 40 hours per week, with the equal-energy (3 dB exchange) rule —
 * every +3 dB halves the safe listening time.
 *
 * Without calibrated hardware the level is an *estimate*: the headphones' output at full volume
 * (user-calibratable, default 100 dB(A), typical for earbuds with pop music) plus the attenuation
 * Android applies for the current volume step on the active device's volume curve.
 */
object ExposureMath {

    const val REFERENCE_DB = 80.0
    const val REFERENCE_WEEKLY_HOURS = 40.0
    const val MUTED_DB = -96.0

    /** Android's default media volume curve (AudioPolicy DEFAULT_MEDIA_VOLUME_CURVE), percent -> dB. */
    private val DEFAULT_CURVE = listOf(0.01 to -58.0, 0.20 to -40.0, 0.60 to -17.0, 1.00 to 0.0)

    fun curveAttenuationDb(fraction: Double): Double {
        if (fraction <= 0.0) return MUTED_DB
        if (fraction <= DEFAULT_CURVE.first().first) return DEFAULT_CURVE.first().second
        for (i in 1 until DEFAULT_CURVE.size) {
            val (x0, y0) = DEFAULT_CURVE[i - 1]
            val (x1, y1) = DEFAULT_CURVE[i]
            if (fraction <= x1) return y0 + (y1 - y0) * (fraction - x0) / (x1 - x0)
        }
        return 0.0
    }

    /** Estimated sound pressure level in dB(A); 0 when muted. */
    fun estimatedDb(maxOutputDb: Double, attenuationDb: Double?): Double {
        if (attenuationDb == null || attenuationDb <= MUTED_DB) return 0.0
        return (maxOutputDb + attenuationDb).coerceAtLeast(0.0)
    }

    /** Safe listening hours per week at [db] under the equal-energy rule. */
    fun weeklyAllowanceHours(db: Double): Double =
        REFERENCE_WEEKLY_HOURS * 10.0.pow((REFERENCE_DB - db) / 10.0)

    /** Fraction of the weekly allowance consumed by listening [durationMs] at [db]. */
    fun doseFraction(db: Double, durationMs: Long): Double {
        if (db <= 0.0 || durationMs <= 0) return 0.0
        val hours = durationMs / 3_600_000.0
        return hours / weeklyAllowanceHours(db)
    }

    data class VolumeSample(val index: Int, val max: Int, val attenuationDb: Double) {
        val percent: Int get() = if (max <= 0) 0 else ((index * 100.0) / max).toInt()

        fun toMap(): Map<String, Any?> = mapOf(
            "index" to index,
            "max" to max,
            "percent" to percent,
            "attenuationDb" to attenuationDb,
        )
    }

    fun sampleVolume(audioManager: AudioManager, outputDeviceType: Int?): VolumeSample {
        val index = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        if (index <= 0) return VolumeSample(index, max, MUTED_DB)

        var attenuation: Double? = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && outputDeviceType != null) {
            attenuation = try {
                val db = audioManager.getStreamVolumeDb(AudioManager.STREAM_MUSIC, index, outputDeviceType).toDouble()
                if (db.isFinite() && db > MUTED_DB && db <= 0.0) db else null
            } catch (e: Exception) {
                null // Not every device type is accepted by getStreamVolumeDb.
            }
        }
        val fraction = if (max <= 0) 0.0 else index.toDouble() / max
        return VolumeSample(index, max, attenuation ?: curveAttenuationDb(fraction))
    }
}
