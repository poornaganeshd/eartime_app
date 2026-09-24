import 'package:freezed_annotation/freezed_annotation.dart';

part 'listening_session.freezed.dart';

/// One uninterrupted stretch of playback at a constant volume.
@freezed
sealed class PlaybackInterval with _$PlaybackInterval {
  const PlaybackInterval._();

  const factory PlaybackInterval({
    required DateTime startTime,
    DateTime? endTime,

    /// Volume-curve attenuation (dB, ≤ 0) during this interval; null for legacy data.
    double? attenuationDb,
  }) = _PlaybackInterval;

  bool get isOpen => endTime == null;

  Duration get activeDuration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Duration get staticDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return Duration.zero;
  }

  /// Duration within [from, to), treating an open interval as running until [now].
  Duration overlap(DateTime from, DateTime to, {required DateTime now}) {
    final end = endTime ?? now;
    final s = startTime.isAfter(from) ? startTime : from;
    final e = end.isBefore(to) ? end : to;
    return e.isAfter(s) ? e.difference(s) : Duration.zero;
  }

  Duration activeDurationToday(DateTime startOfDay) {
    var effectiveStart = startTime;
    if (startTime.isBefore(startOfDay)) {
      effectiveStart = startOfDay;
    }
    final end = endTime ?? DateTime.now();
    if (end.isBefore(effectiveStart)) return Duration.zero;
    return end.difference(effectiveStart);
  }
}

@freezed
sealed class ListeningSession with _$ListeningSession {
  const ListeningSession._();

  const factory ListeningSession({
    required String id,
    required String canonicalDeviceId,
    required String deviceName,
    @Default('bluetooth') String connectionType,
    required DateTime connectTime,
    DateTime? disconnectTime,
    required List<PlaybackInterval> intervals,
    @Default(false) bool isPlaying,
    @Default(false) bool isDisconnected,
  }) = _ListeningSession;

  Duration get totalActiveDuration {
    return intervals.fold(
      Duration.zero,
      (total, interval) => total + interval.activeDuration,
    );
  }

  Duration get staticTotalActiveDuration {
    return intervals.fold(
      Duration.zero,
      (total, interval) => total + interval.staticDuration,
    );
  }

  Duration listeningAt(DateTime now) {
    return intervals.fold(
      Duration.zero,
      (total, i) => total + (i.endTime ?? now).difference(i.startTime),
    );
  }

  DateTime? get currentPlaybackStartTime {
    if (isPlaying && intervals.isNotEmpty && intervals.last.endTime == null) {
      return intervals.last.startTime;
    }
    return null;
  }

  /// First playback start in this session (null if nothing was played).
  DateTime? get firstPlayback => intervals.isEmpty ? null : intervals.first.startTime;

  DateTime? lastActivity(DateTime now) {
    if (intervals.isEmpty) return disconnectTime ?? connectTime;
    return intervals.last.endTime ?? now;
  }

  Duration get todayActiveDuration {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return intervals.fold(
      Duration.zero,
      (total, interval) => total + interval.activeDurationToday(startOfDay),
    );
  }
}
