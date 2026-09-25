package com.eartime.eartime_app.tracking

import org.json.JSONArray
import org.json.JSONObject

/** Converts between org.json and the plain maps/lists understood by Flutter's StandardMessageCodec. */
object JsonUtil {

    fun toJson(map: Map<*, *>): JSONObject {
        val obj = JSONObject()
        map.forEach { (key, value) -> obj.put(key.toString(), wrap(value)) }
        return obj
    }

    private fun wrap(value: Any?): Any? = when (value) {
        null -> JSONObject.NULL
        is Map<*, *> -> toJson(value)
        is Collection<*> -> JSONArray().also { array -> value.forEach { array.put(wrap(it)) } }
        is Array<*> -> JSONArray().also { array -> value.forEach { array.put(wrap(it)) } }
        else -> value
    }

    fun toMap(obj: JSONObject): Map<String, Any?> {
        val map = LinkedHashMap<String, Any?>()
        obj.keys().forEach { key -> map[key] = unwrap(obj.opt(key)) }
        return map
    }

    private fun unwrap(value: Any?): Any? = when (value) {
        null, JSONObject.NULL -> null
        is JSONObject -> toMap(value)
        is JSONArray -> (0 until value.length()).map { unwrap(value.opt(it)) }
        else -> value
    }
}
