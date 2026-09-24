/// A raw event emitted by the native tracking engine over the EventChannel
/// (or replayed from the native journal).
///
/// See docs/eartime/NATIVE_FLUTTER_CONTRACT.md for the full protocol.
class TrackingEvent {
  final String type;
  final Map<String, dynamic>? device;
  final String? deviceId;
  final String? serviceUuid;
  final String? characteristicUuid;
  final String? payload;
  final String? state;
  final String? message;
  final int? status;
  final int timestamp;

  /// Journal identity (persistable events only).
  final String? eventId;
  final int? seq;
  final String? reason;

  /// STREAM_MUSIC volume at the time of the event.
  final VolumeInfo? volume;

  /// The full decoded payload, for event types with extra fields (e.g. SYNC_STATE).
  final Map<String, dynamic> raw;

  TrackingEvent({
    required this.type,
    this.device,
    this.deviceId,
    this.serviceUuid,
    this.characteristicUuid,
    this.payload,
    this.state,
    this.message,
    this.status,
    required this.timestamp,
    this.eventId,
    this.seq,
    this.reason,
    this.volume,
    Map<String, dynamic>? raw,
  }) : raw = raw ?? const {};

  static const persistableTypes = {
    'DEVICE_CONNECTED',
    'DEVICE_DISCONNECTED',
    'PLAYBACK_STARTED',
    'PLAYBACK_RESUMED',
    'PLAYBACK_PAUSED',
    'PLAYBACK_STOPPED',
    'VOLUME_CHANGED',
  };

  bool get isPersistable => persistableTypes.contains(type);

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    final normalized = deepCast(json);
    final deviceRaw = normalized['device'];
    final volumeRaw = normalized['volume'];
    return TrackingEvent(
      type: normalized['type'] as String,
      device: deviceRaw is Map<String, dynamic> ? deviceRaw : null,
      deviceId: normalized['deviceId'] as String?,
      serviceUuid: normalized['serviceUuid'] as String?,
      characteristicUuid: normalized['characteristicUuid'] as String?,
      payload: normalized['payload'] as String?,
      state: normalized['state'] as String?,
      message: normalized['message'] as String?,
      status: (normalized['status'] as num?)?.toInt(),
      timestamp: (normalized['timestamp'] as num).toInt(),
      eventId: normalized['eventId'] as String?,
      seq: (normalized['seq'] as num?)?.toInt(),
      reason: normalized['reason'] as String?,
      volume: volumeRaw is Map<String, dynamic> ? VolumeInfo.fromMap(volumeRaw) : null,
      raw: normalized,
    );
  }

  /// Platform channels deliver `Map<Object?, Object?>` at every nesting level; convert recursively.
  static Map<String, dynamic> deepCast(Map<dynamic, dynamic> map) {
    return map.map((key, value) => MapEntry(key.toString(), _castValue(value)));
  }

  static dynamic _castValue(dynamic value) {
    if (value is Map) return deepCast(value);
    if (value is List) return value.map(_castValue).toList();
    return value;
  }

  @override
  String toString() => 'TrackingEvent($type, device=$deviceId, t=$timestamp, seq=$seq)';
}

/// Snapshot of the media volume.
class VolumeInfo {
  final int index;
  final int max;
  final int percent;

  /// Attenuation applied by Android's volume curve for the active device, in dB (≤ 0).
  final double attenuationDb;

  const VolumeInfo({required this.index, required this.max, required this.percent, required this.attenuationDb});

  factory VolumeInfo.fromMap(Map<String, dynamic> map) => VolumeInfo(
        index: (map['index'] as num?)?.toInt() ?? 0,
        max: (map['max'] as num?)?.toInt() ?? 0,
        percent: (map['percent'] as num?)?.toInt() ?? 0,
        attenuationDb: (map['attenuationDb'] as num?)?.toDouble() ?? -96.0,
      );

  bool get isMuted => index <= 0;

  @override
  bool operator ==(Object other) =>
      other is VolumeInfo && other.index == index && other.max == max && other.attenuationDb == attenuationDb;

  @override
  int get hashCode => Object.hash(index, max, attenuationDb);
}
