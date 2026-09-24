import 'audio_device.dart';
import 'connection_state.dart';
import 'playback_state.dart';
import 'tracking_event.dart';

/// Real-time view of what the native engine is doing *right now*.
///
/// Built only from live events (see [LiveSessionReducer]); history is derived separately from the
/// database so the two can never drift apart in how they count time.
class LiveSessionState {
  /// False until the first SYNC_STATE (or any device event) has been received.
  final bool isInitialized;

  /// Whether the native background service is running.
  final bool monitoring;

  /// All connected listening devices, in connection order.
  final List<AudioDevice> connectedDevices;

  /// The device media is routed to (or the most recent connection when idle).
  final String? activeDeviceId;

  /// True only while media is actually playing through a tracked headset.
  final bool isPlaying;

  /// Start of the current listening interval; null whenever [isPlaying] is false.
  final DateTime? playbackStartedAt;

  final VolumeInfo? volume;
  final DateTime? lastEventAt;

  /// Most recent hearing alert raised by the native engine (loud level, break, …).
  final String? lastAlert;

  const LiveSessionState({
    this.isInitialized = false,
    this.monitoring = false,
    this.connectedDevices = const [],
    this.activeDeviceId,
    this.isPlaying = false,
    this.playbackStartedAt,
    this.volume,
    this.lastEventAt,
    this.lastAlert,
  });

  AudioDevice? get activeDevice {
    if (connectedDevices.isEmpty) return null;
    for (final d in connectedDevices) {
      if (d.canonicalDeviceId == activeDeviceId) return d;
    }
    return connectedDevices.last;
  }

  bool get hasDevice => connectedDevices.isNotEmpty;

  /// Length of the current uninterrupted listening interval.
  Duration currentIntervalAt(DateTime now) {
    final start = playbackStartedAt;
    if (!isPlaying || start == null) return Duration.zero;
    final d = now.difference(start);
    return d.isNegative ? Duration.zero : d;
  }

  LiveSessionState copyWith({
    bool? isInitialized,
    bool? monitoring,
    List<AudioDevice>? connectedDevices,
    String? Function()? activeDeviceId,
    bool? isPlaying,
    DateTime? Function()? playbackStartedAt,
    VolumeInfo? Function()? volume,
    DateTime? lastEventAt,
    String? Function()? lastAlert,
  }) {
    return LiveSessionState(
      isInitialized: isInitialized ?? this.isInitialized,
      monitoring: monitoring ?? this.monitoring,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      activeDeviceId: activeDeviceId != null ? activeDeviceId() : this.activeDeviceId,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackStartedAt: playbackStartedAt != null ? playbackStartedAt() : this.playbackStartedAt,
      volume: volume != null ? volume() : this.volume,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      lastAlert: lastAlert != null ? lastAlert() : this.lastAlert,
    );
  }

  /// Legacy helper kept for callers that reset the state.
  LiveSessionState withNoDevice() => LiveSessionState(
        isInitialized: true,
        monitoring: monitoring,
        volume: volume,
        lastEventAt: lastEventAt,
      );

  static AudioDevice deviceFromMap(Map<String, dynamic> map, {required DateTime seen, PlaybackState? playback}) {
    return AudioDevice(
      canonicalDeviceId: map['id'] as String? ?? 'unknown',
      displayName: map['friendlyName'] as String? ?? 'Headphones',
      deviceType: map['connectionType'] as String? ?? 'bluetooth',
      connectionState: ConnectionState.connected,
      playbackState: playback ?? PlaybackState.stopped,
      lastSeen: seen,
    );
  }
}
