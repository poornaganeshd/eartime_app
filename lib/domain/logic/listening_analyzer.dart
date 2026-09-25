import 'dart:math' as math;

import '../models/listening_session.dart';
import 'exposure_math.dart';

enum StatsRange { today, week, month, year }

extension StatsRangeX on StatsRange {
  String get label => switch (this) {
        StatsRange.today => 'Today',
        StatsRange.week => 'Week',
        StatsRange.month => 'Month',
        StatsRange.year => 'Year',
      };

  /// Inclusive start of the range (local midnight based).
  DateTime startFor(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      StatsRange.today => today,
      StatsRange.week => DateTime(today.year, today.month, today.day - 6),
      StatsRange.month => DateTime(today.year, today.month, today.day - 29),
      StatsRange.year => DateTime(today.year - 1, today.month + 1, 1),
    };
  }

  /// Chart bucket starts: hours for today, days for week/month, months for year.
  List<DateTime> bucketStarts(DateTime now) {
    final start = startFor(now);
    return switch (this) {
      StatsRange.today => [for (var h = 0; h < 24; h++) DateTime(start.year, start.month, start.day, h)],
      StatsRange.week => [for (var d = 0; d < 7; d++) DateTime(start.year, start.month, start.day + d)],
      StatsRange.month => [for (var d = 0; d < 30; d++) DateTime(start.year, start.month, start.day + d)],
      StatsRange.year => [for (var m = 0; m < 12; m++) DateTime(start.year, start.month + m, 1)],
    };
  }

  DateTime bucketEnd(DateTime bucketStart) => switch (this) {
        StatsRange.today => bucketStart.add(const Duration(hours: 1)),
        StatsRange.week || StatsRange.month =>
          DateTime(bucketStart.year, bucketStart.month, bucketStart.day + 1),
        StatsRange.year => DateTime(bucketStart.year, bucketStart.month + 1, 1),
      };
}

enum DaySlot { morning, afternoon, evening, night }

extension DaySlotX on DaySlot {
  String get label => switch (this) {
        DaySlot.morning => 'Morning',
        DaySlot.afternoon => 'Afternoon',
        DaySlot.evening => 'Evening',
        DaySlot.night => 'Night',
      };

  String get hours => switch (this) {
        DaySlot.morning => '5–12',
        DaySlot.afternoon => '12–17',
        DaySlot.evening => '17–22',
        DaySlot.night => '22–5',
      };

  static DaySlot forHour(int hour) {
    if (hour >= 5 && hour < 12) return DaySlot.morning;
    if (hour >= 12 && hour < 17) return DaySlot.afternoon;
    if (hour >= 17 && hour < 22) return DaySlot.evening;
    return DaySlot.night;
  }
}

class DeviceUsage {
  final String id;
  final String name;
  final String connectionType;
  final Duration listening;
  final DateTime lastUsed;

  const DeviceUsage({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.listening,
    required this.lastUsed,
  });
}

class ListeningStats {
  final DateTime from;
  final DateTime to;
  final Duration total;
  final int sessionCount;
  final Duration averageSession;
  final Duration longestSession;

  /// Longest stretch of listening without a ≥5 minute break.
  final Duration longestContinuous;

  /// Number of ≥5 minute breaks between listening blocks.
  final int breaks;
  final Map<DaySlot, Duration> timeOfDay;
  final List<DeviceUsage> devices;
  final List<DateTime> bucketStarts;
  final List<Duration> buckets;

  /// Exposure dose (fraction of the weekly allowance) per chart bucket.
  final List<double> bucketDose;

  /// Fraction of the WHO weekly allowance consumed within the range.
  final double dose;

  /// Time-weighted equivalent level (Leq) over time with known volume; null without data.
  final double? averageDb;
  final double? peakDb;

  /// Listening time at or above the caution level (80 dB).
  final Duration loudTime;

  /// Listening time recorded before volume tracking existed (legacy rows).
  final Duration unknownLevelTime;

  const ListeningStats({
    required this.from,
    required this.to,
    required this.total,
    required this.sessionCount,
    required this.averageSession,
    required this.longestSession,
    required this.longestContinuous,
    required this.breaks,
    required this.timeOfDay,
    required this.devices,
    required this.bucketStarts,
    required this.buckets,
    required this.bucketDose,
    required this.dose,
    required this.averageDb,
    required this.peakDb,
    required this.loudTime,
    required this.unknownLevelTime,
  });

  bool get isEmpty => total == Duration.zero;
}

class HearingInsight {
  /// 0–100, higher is healthier; null when there's no listening data in the last 7 days.
  final int? score;
  final String headline;
  final String recommendation;

  const HearingInsight({required this.score, required this.headline, required this.recommendation});
}

/// Turns reconstructed sessions into statistics. Pure and deterministic given `now`.
class ListeningAnalyzer {
  ListeningAnalyzer._();

  static const breakThreshold = Duration(minutes: 5);

  static ListeningStats compute({
    required List<ListeningSession> sessions,
    required StatsRange range,
    required DateTime now,
    double maxOutputDb = ExposureMath.defaultMaxOutputDb,
  }) {
    final from = range.startFor(now);
    final to = now;
    final bucketStarts = range.bucketStarts(now);
    final buckets = List<Duration>.filled(bucketStarts.length, Duration.zero);
    final bucketDose = List<double>.filled(bucketStarts.length, 0);
    final timeOfDay = {for (final s in DaySlot.values) s: Duration.zero};
    final deviceTotals = <String, Duration>{};
    final deviceMeta = <String, ListeningSession>{};
    final deviceLast = <String, DateTime>{};
    final ranges = <(DateTime, DateTime)>[];

    var total = Duration.zero;
    var sessionCount = 0;
    var longestSession = Duration.zero;
    var dose = 0.0;
    var energy = 0.0;
    var knownTime = Duration.zero;
    var loudTime = Duration.zero;
    var unknownTime = Duration.zero;
    double? peak;

    for (final session in sessions) {
      var sessionTotal = Duration.zero;
      for (final interval in session.intervals) {
        final d = interval.overlap(from, to, now: now);
        if (d == Duration.zero) continue;
        final start = interval.startTime.isBefore(from) ? from : interval.startTime;
        final rawEnd = interval.endTime ?? now;
        final end = rawEnd.isAfter(to) ? to : rawEnd;
        ranges.add((start, end));
        sessionTotal += d;

        final db = interval.attenuationDb == null
            ? null
            : ExposureMath.estimatedDb(maxOutputDb, interval.attenuationDb);

        // Chart buckets.
        for (var i = 0; i < bucketStarts.length; i++) {
          final bs = bucketStarts[i];
          final be = range.bucketEnd(bs);
          final part = interval.overlap(bs, be, now: now);
          if (part == Duration.zero) continue;
          buckets[i] += part;
          if (db != null) bucketDose[i] += ExposureMath.doseFraction(db, part);
        }

        _splitByHour(start, end, (hourStart, part) {
          final slot = DaySlotX.forHour(hourStart.hour);
          timeOfDay[slot] = timeOfDay[slot]! + part;
        });

        // Exposure.
        if (db == null) {
          unknownTime += d;
        } else {
          knownTime += d;
          if (db > 0) {
            dose += ExposureMath.doseFraction(db, d);
            energy += ExposureMath.energy(db, d);
            peak = peak == null ? db : math.max(peak, db);
            if (db >= ExposureMath.cautionDb) loudTime += d;
          }
        }
      }
      if (sessionTotal > Duration.zero) {
        sessionCount++;
        total += sessionTotal;
        if (sessionTotal > longestSession) longestSession = sessionTotal;
        final id = session.canonicalDeviceId;
        deviceTotals[id] = (deviceTotals[id] ?? Duration.zero) + sessionTotal;
        deviceMeta[id] = session;
        final last = session.lastActivity(now) ?? session.connectTime;
        if (deviceLast[id] == null || last.isAfter(deviceLast[id]!)) deviceLast[id] = last;
      }
    }

    // Continuous listening blocks.
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    var longestContinuous = Duration.zero;
    var breaks = 0;
    DateTime? blockStart;
    DateTime? blockEnd;
    for (final (s, e) in ranges) {
      if (blockEnd == null || s.difference(blockEnd) >= breakThreshold) {
        if (blockStart != null) {
          longestContinuous = _max(longestContinuous, blockEnd!.difference(blockStart));
          breaks++;
        }
        blockStart = s;
        blockEnd = e;
      } else if (e.isAfter(blockEnd)) {
        blockEnd = e;
      }
    }
    if (blockStart != null) longestContinuous = _max(longestContinuous, blockEnd!.difference(blockStart));

    final devices = deviceTotals.entries
        .map((e) => DeviceUsage(
              id: e.key,
              name: deviceMeta[e.key]!.deviceName,
              connectionType: deviceMeta[e.key]!.connectionType,
              listening: e.value,
              lastUsed: deviceLast[e.key]!,
            ))
        .toList()
      ..sort((a, b) => b.listening.compareTo(a.listening));

    final energyTime = knownTime;
    return ListeningStats(
      from: from,
      to: to,
      total: total,
      sessionCount: sessionCount,
      averageSession: sessionCount == 0 ? Duration.zero : total ~/ sessionCount,
      longestSession: longestSession,
      longestContinuous: longestContinuous,
      breaks: breaks,
      timeOfDay: timeOfDay,
      devices: devices,
      bucketStarts: bucketStarts,
      buckets: buckets,
      bucketDose: bucketDose,
      dose: dose,
      averageDb: energy > 0 ? ExposureMath.leq(energy, energyTime) : null,
      peakDb: peak,
      loudTime: loudTime,
      unknownLevelTime: unknownTime,
    );
  }

  /// Hearing health score from the rolling week plus today, with the most useful next step.
  static HearingInsight insight({
    required ListeningStats week,
    required ListeningStats today,
    int dailyLimitMinutes = 180,
  }) {
    if (week.isEmpty) {
      return const HearingInsight(
        score: null,
        headline: 'No listening data yet',
        recommendation: 'Put on your headphones and play something — EarTime will start measuring automatically.',
      );
    }

    final penalties = <String, double>{};
    if (week.dose > 0.5) penalties['dose'] = math.min(40, (week.dose - 0.5) * 60);
    final loudShare = week.total.inSeconds == 0 ? 0.0 : week.loudTime.inSeconds / week.total.inSeconds;
    if (loudShare > 0.2) penalties['loud'] = math.min(25, (loudShare - 0.2) * 50);
    final longestMin = week.longestContinuous.inMinutes;
    if (longestMin > 90) penalties['breaks'] = math.min(15, (longestMin - 90) / 6);
    if (dailyLimitMinutes > 0) {
      final over = today.total.inMinutes / dailyLimitMinutes - 1;
      if (over > 0) penalties['limit'] = math.min(20, over * 20);
    }
    final score = (100 - penalties.values.fold(0.0, (a, b) => a + b)).clamp(0, 100).round();

    if (penalties.isEmpty) {
      return HearingInsight(
        score: score,
        headline: 'Healthy listening',
        recommendation: week.averageDb == null
            ? 'Your listening time is well balanced. Keep taking regular breaks.'
            : 'Average level ~${week.averageDb!.round()} dB with regular breaks. Your ears are in a good place.',
      );
    }
    final worst = penalties.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final (headline, recommendation) = switch (worst) {
      'dose' => (
          'High weekly sound dose',
          "You've used ${(week.dose * 100).round()}% of the weekly safe allowance. Lowering the volume by "
              '3 dB (one or two steps) doubles how long you can safely listen.'
        ),
      'loud' => (
          'Loud listening',
          '${(loudShare * 100).round()}% of your listening this week was above 80 dB. Try noise-cancelling '
              'or keeping the volume under 60%.'
        ),
      'breaks' => (
          'Long sessions without breaks',
          'Your longest stretch was ${longestMin ~/ 60}h ${longestMin % 60}m. Follow the 60/60 rule: '
              'after an hour, give your ears 5–10 minutes of quiet.'
        ),
      _ => (
          'Over your daily goal',
          "You've listened ${today.total.inMinutes} minutes today against a goal of $dailyLimitMinutes."
        ),
    };
    return HearingInsight(score: score, headline: headline, recommendation: recommendation);
  }

  static void _splitByHour(DateTime start, DateTime end, void Function(DateTime hourStart, Duration part) visit) {
    var cursor = start;
    while (cursor.isBefore(end)) {
      final hourStart = DateTime(cursor.year, cursor.month, cursor.day, cursor.hour);
      final next = DateTime(cursor.year, cursor.month, cursor.day, cursor.hour + 1);
      final segmentEnd = next.isBefore(end) ? next : end;
      visit(hourStart, segmentEnd.difference(cursor));
      cursor = segmentEnd;
    }
  }

  static Duration _max(Duration a, Duration b) => a > b ? a : b;
}
