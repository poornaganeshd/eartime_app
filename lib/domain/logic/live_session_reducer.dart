import '../models/audio_device.dart';
import '../models/live_session_state.dart';
import '../models/playback_state.dart';
import '../models/tracking_event.dart';

/// Pure state transition function for the live session: `(state, event) -> state`.
///
/// Fixes the Phase 6 live-state bugs:
///  * SYNC_STATE fields live at the payload root (`connectedDevices`, `isPlaying`), not in
///    `device` — they were previously ignored, so the app booted with an empty state (Bug B).
///  * PLAYBACK_PAUSED clears `playbackStartedAt`, so the live timer stops (Bugs B4/D/E).
///  * One device disconnecting no longer wipes other connected devices.
class LiveSessionReducer {
  LiveSessionReducer._();

  static LiveSessionState reduce(LiveSessionState state, TrackingEvent event) {
    final at = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
    switch (event.type) {
      case 'SYNC_STATE':
        return _sync(state, event, at);
      case 'DEVICE_CONNECTED':
        return _connected(state, event, at);
      case 'DEVICE_DISCONNECTED':
        return _disconnected(state, event, at);
      case 'PLAYBACK_STARTED':
      case 'PLAYBACK_RESUMED':
        return _playing(state, event, at);
      case 'PLAYBACK_PAUSED':
      case 'PLAYBACK_STOPPED':
        return _paused(state, event, at);
      case 'VOLUME_CHANGED':
        return state.copyWith(volume: () => event.volume ?? state.volume, lastEventAt: at);
      case 'HEARING_ALERT':
        return state.copyWith(lastAlert: () => event.message, lastEventAt: at);
      default:
        return state;
    }
  }

  static LiveSessionState _sync(LiveSessionState state, TrackingEvent event, DateTime at) {
    final raw = event.raw;
    final isPlaying = raw['isPlaying'] == true;
    final activeId = raw['activeDeviceId'] as String?;
    final startedMs = (raw['playbackStartedAt'] as num?)?.toInt();
    final devices = <AudioDevice>[];
    for (final entry in (raw['connectedDevices'] as List?) ?? const []) {
      if (entry is Map<String, dynamic>) {
        final id = entry['id'] as String?;
        devices.add(LiveSessionState.deviceFromMap(
          entry,
          seen: at,
          playback: isPlaying && id == activeId ? PlaybackState.playing : PlaybackState.stopped,
        ));
      }
    }
    final playing = isPlaying && devices.isNotEmpty;
    DateTime? startedAt;
    if (playing) {
      // Keep our own start if we were already tracking this same interval.
      startedAt = startedMs != null
          ? DateTime.fromMillisecondsSinceEpoch(startedMs)
          : (state.isPlaying && state.activeDeviceId == activeId ? state.playbackStartedAt : at);
    }
    return LiveSessionState(
      isInitialized: true,
      monitoring: raw['monitoring'] != false,
      connectedDevices: devices,
      activeDeviceId: activeId ?? (devices.isEmpty ? null : devices.last.canonicalDeviceId),
      isPlaying: playing,
      playbackStartedAt: startedAt,
      volume: event.volume ?? state.volume,
      lastEventAt: at,
      lastAlert: state.lastAlert,
    );
  }

  static LiveSessionState _connected(LiveSessionState state, TrackingEvent event, DateTime at) {
    final map = event.device;
    final id = event.deviceId ?? map?['id'] as String?;
    if (id == null) return state;
    final device = LiveSessionState.deviceFromMap(map ?? {'id': id}, seen: at);
    final devices = [
      for (final d in state.connectedDevices)
        if (d.canonicalDeviceId != id) d,
      device,
    ];
    return state.copyWith(
      isInitialized: true,
      monitoring: true,
      connectedDevices: devices,
      activeDeviceId: state.isPlaying ? null : () => id,
      volume: () => event.volume ?? state.volume,
      lastEventAt: at,
    );
  }

  static LiveSessionState _disconnected(LiveSessionState state, TrackingEvent event, DateTime at) {
    final id = event.deviceId ?? event.device?['id'] as String?;
    final devices = [
      for (final d in state.connectedDevices)
        if (d.canonicalDeviceId != id) d,
    ];
    final wasActive = state.activeDeviceId == id;
    return state.copyWith(
      isInitialized: true,
      connectedDevices: devices,
      activeDeviceId: wasActive ? () => devices.isEmpty ? null : devices.last.canonicalDeviceId : null,
      isPlaying: wasActive ? false : state.isPlaying,
      playbackStartedAt: wasActive ? () => null : null,
      lastEventAt: at,
    );
  }

  static LiveSessionState _playing(LiveSessionState state, TrackingEvent event, DateTime at) {
    final id = event.deviceId ?? event.device?['id'] as String?;
    if (id == null) return state; // Playback not routed to a tracked headset.
    var devices = state.connectedDevices;
    if (!devices.any((d) => d.canonicalDeviceId == id)) {
      devices = [...devices, LiveSessionState.deviceFromMap(event.device ?? {'id': id}, seen: at)];
    }
    devices = [
      for (final d in devices)
        d.copyWith(
          playbackState: d.canonicalDeviceId == id ? PlaybackState.playing : PlaybackState.stopped,
          currentPlaybackStartTime: d.canonicalDeviceId == id ? at : null,
        ),
    ];
    final continuing = state.isPlaying && state.activeDeviceId == id;
    return state.copyWith(
      isInitialized: true,
      monitoring: true,
      connectedDevices: devices,
      activeDeviceId: () => id,
      isPlaying: true,
      playbackStartedAt: () => continuing ? state.playbackStartedAt : at,
      volume: () => event.volume ?? state.volume,
      lastEventAt: at,
    );
  }

  static LiveSessionState _paused(LiveSessionState state, TrackingEvent event, DateTime at) {
    final id = event.deviceId ?? event.device?['id'] as String?;
    if (id != null && state.activeDeviceId != null && id != state.activeDeviceId) {
      return state; // A stale pause for a device that is no longer the active one.
    }
    final devices = [
      for (final d in state.connectedDevices)
        d.canonicalDeviceId == id || id == null
            ? d.copyWith(playbackState: PlaybackState.paused, currentPlaybackStartTime: null)
            : d,
    ];
    return state.copyWith(
      isInitialized: true,
      connectedDevices: devices,
      isPlaying: false,
      playbackStartedAt: () => null,
      volume: () => event.volume ?? state.volume,
      lastEventAt: at,
    );
  }
}
