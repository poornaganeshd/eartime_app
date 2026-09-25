import 'package:freezed_annotation/freezed_annotation.dart';

part 'eartime_event.freezed.dart';
part 'eartime_event.g.dart';

@freezed
sealed class EarTimeEvent with _$EarTimeEvent {
  const factory EarTimeEvent({
    required String id,
    required String canonicalDeviceId,
    @Default('Unknown Device') String deviceName,
    @Default('bluetooth') String connectionType,
    required String eventType, // DEVICE_CONNECTED, DEVICE_DISCONNECTED, PLAYBACK_STARTED, PLAYBACK_PAUSED, VOLUME_CHANGED (+ legacy PLAYBACK_RESUMED/STOPPED)
    String? playbackState,
    required DateTime timestamp,
    // Schema v2: volume at the time of the event (drives exposure estimates).
    int? volumePercent,
    double? attenuationDb,
    String? reason,
    // Phase 5 Optional Fields
    String? earSide,
    Map<String, dynamic>? earState,
    String? attributionConfidence,
    String? earStateSource,
  }) = _EarTimeEvent;

  factory EarTimeEvent.fromJson(Map<String, dynamic> json) => _$EarTimeEventFromJson(json);
}
