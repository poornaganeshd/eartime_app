import '../models/eartime_event.dart';
import '../models/listening_session.dart';

/// Rebuilds listening sessions deterministically from the persisted event log.
///
/// Semantics (shared with the native engine):
///  * A session spans DEVICE_CONNECTED → DEVICE_DISCONNECTED for one device.
///  * Media plays through at most one headset at a time: a PLAYBACK_STARTED on one device closes
///    any interval still open on another (protects against legacy, mis-attributed rows).
///  * Intervals are split at VOLUME_CHANGED so each one has a constant level for exposure maths.
///  * An interval left open by the log is only "live" if the live engine says that device is
///    playing right now ([liveDeviceId]); otherwise it is closed at the device's last known event,
///    so a crash in an old app version can never make a session run forever.
class SessionManager {
  SessionManager._();

  static List<ListeningSession> reconstruct(
    List<EarTimeEvent> events, {
    String? liveDeviceId,
  }) {
    // Stable sort (Dart's List.sort is not stable): same-millisecond events keep log order,
    // e.g. PAUSED(old device) must stay before STARTED(new device).
    final indexed = [for (var i = 0; i < events.length; i++) (i, events[i])]
      ..sort((a, b) {
        final byTime = a.$2.timestamp.compareTo(b.$2.timestamp);
        return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
      });
    final sorted = [for (final e in indexed) e.$2];
    final open = <String, _Builder>{};
    final completed = <ListeningSession>[];
    final lastSeen = <String, DateTime>{};
    double? volumeDb;

    void closeOtherPlayback(String except, DateTime at) {
      for (final b in open.values) {
        if (b.deviceId != except) b.closeInterval(at);
      }
    }

    for (final event in sorted) {
      final deviceId = event.canonicalDeviceId;
      final t = event.timestamp;
      lastSeen[deviceId] = t;
      if (event.attenuationDb != null) volumeDb = event.attenuationDb;

      switch (event.eventType) {
        case 'DEVICE_CONNECTED':
          final previous = open.remove(deviceId);
          if (previous != null) completed.add(previous.build(disconnectAt: t));
          open[deviceId] = _Builder(event);
        case 'DEVICE_DISCONNECTED':
          final session = open.remove(deviceId);
          if (session != null) completed.add(session.build(disconnectAt: t));
        case 'PLAYBACK_STARTED':
        case 'PLAYBACK_RESUMED':
          closeOtherPlayback(deviceId, t);
          // Recover gracefully if the CONNECTED event is missing (e.g. legacy process death).
          final session = open.putIfAbsent(deviceId, () => _Builder(event));
          session.openInterval(t, volumeDb);
        case 'PLAYBACK_PAUSED':
        case 'PLAYBACK_STOPPED':
          open[deviceId]?.closeInterval(t);
        case 'VOLUME_CHANGED':
          for (final b in open.values) {
            if (b.isPlaying) {
              b.closeInterval(t);
              b.openInterval(t, volumeDb);
            }
          }
      }
    }

    for (final b in open.values) {
      if (b.isPlaying && b.deviceId != liveDeviceId) {
        b.closeInterval(lastSeen[b.deviceId] ?? b.connectTime);
      }
    }

    final result = [...completed, ...open.values.map((b) => b.build())];
    result.sort((a, b) => a.connectTime.compareTo(b.connectTime));
    return result;
  }
}

class _Builder {
  _Builder(EarTimeEvent first)
      : id = first.id,
        deviceId = first.canonicalDeviceId,
        deviceName = first.deviceName,
        connectionType = first.connectionType,
        connectTime = first.timestamp;

  final String id;
  final String deviceId;
  final String deviceName;
  final String connectionType;
  final DateTime connectTime;
  final List<PlaybackInterval> intervals = [];

  bool get isPlaying => intervals.isNotEmpty && intervals.last.endTime == null;

  void openInterval(DateTime at, double? attenuationDb) {
    if (isPlaying) {
      if (intervals.last.attenuationDb == attenuationDb) return;
      closeInterval(at);
    }
    intervals.add(PlaybackInterval(startTime: at, attenuationDb: attenuationDb));
  }

  void closeInterval(DateTime at) {
    if (!isPlaying) return;
    final last = intervals.removeLast();
    final end = at.isBefore(last.startTime) ? last.startTime : at;
    if (end.isAfter(last.startTime)) intervals.add(last.copyWith(endTime: end));
  }

  ListeningSession build({DateTime? disconnectAt}) {
    if (disconnectAt != null) closeInterval(disconnectAt);
    return ListeningSession(
      id: id,
      canonicalDeviceId: deviceId,
      deviceName: deviceName,
      connectionType: connectionType,
      connectTime: connectTime,
      disconnectTime: disconnectAt,
      intervals: List.unmodifiable(intervals),
      isPlaying: disconnectAt == null && isPlaying,
      isDisconnected: disconnectAt != null,
    );
  }
}
