package com.eartime.eartime_app.tracking

import android.content.Context
import android.util.Log
import org.json.JSONObject
import java.io.File

/**
 * Append-only, crash-safe journal of persistable tracking events (JSON lines).
 *
 * The background service writes every connection/playback/volume transition here *before*
 * publishing it on the EventChannel. Flutter drains the journal into its SQLite database and
 * acknowledges the highest sequence number it stored. Because database inserts are idempotent on
 * `eventId`, a replay after a crash never duplicates history, and events that happen while the
 * Flutter engine is not running (app swiped away, process restarted) are never lost.
 */
class EventJournal private constructor(context: Context) {

    private val file = File(context.applicationContext.filesDir, "eartime_journal.jsonl")
    private val lock = Any()

    fun append(event: Map<String, Any?>) {
        synchronized(lock) {
            try {
                file.appendText(JsonUtil.toJson(event).toString() + "\n")
            } catch (e: Exception) {
                Log.e(TAG, "[JOURNAL] append failed: ${e.message}")
            }
        }
    }

    /** Returns up to [limit] events with `seq > afterSeq`, oldest first. */
    fun read(afterSeq: Long, limit: Int = 2000): List<Map<String, Any?>> {
        synchronized(lock) {
            if (!file.exists()) return emptyList()
            val result = ArrayList<Map<String, Any?>>()
            try {
                file.forEachLine { line ->
                    if (result.size >= limit || line.isBlank()) return@forEachLine
                    val obj = try { JSONObject(line) } catch (e: Exception) { null } ?: return@forEachLine
                    if (obj.optLong("seq", 0L) > afterSeq) result.add(JsonUtil.toMap(obj))
                }
            } catch (e: Exception) {
                Log.e(TAG, "[JOURNAL] read failed: ${e.message}")
            }
            return result
        }
    }

    /** Drops every event with `seq <= upToSeq` (they are safely stored by Flutter). */
    fun acknowledge(upToSeq: Long) {
        synchronized(lock) {
            if (!file.exists()) return
            try {
                val remaining = file.readLines().filter { line ->
                    if (line.isBlank()) return@filter false
                    val obj = try { JSONObject(line) } catch (e: Exception) { null } ?: return@filter false
                    obj.optLong("seq", 0L) > upToSeq
                }
                val tmp = File(file.parentFile, file.name + ".tmp")
                tmp.writeText(if (remaining.isEmpty()) "" else remaining.joinToString("\n", postfix = "\n"))
                if (!tmp.renameTo(file)) {
                    file.writeText(tmp.readText())
                    tmp.delete()
                }
            } catch (e: Exception) {
                Log.e(TAG, "[JOURNAL] acknowledge failed: ${e.message}")
            }
        }
    }

    companion object {
        private const val TAG = "EarTimeDiag"

        @Volatile
        private var instance: EventJournal? = null

        fun get(context: Context): EventJournal =
            instance ?: synchronized(this) { instance ?: EventJournal(context).also { instance = it } }
    }
}
