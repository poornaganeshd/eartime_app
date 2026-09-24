import 'package:eartime_app/domain/logic/exposure_math.dart';
import 'package:eartime_app/domain/logic/listening_analyzer.dart';
import 'package:eartime_app/domain/models/listening_session.dart';
import 'package:flutter_test/flutter_test.dart';

ListeningSession session(String id, List<PlaybackInterval> intervals, {String name = 'Buds'}) => ListeningSession(
      id: id,
      canonicalDeviceId: id,
      deviceName: name,
      connectTime: intervals.first.startTime,
      intervals: intervals,
    );

PlaybackInterval iv(DateTime start, Duration length, {double? attenuationDb}) =>
    PlaybackInterval(startTime: start, endTime: start.add(length), attenuationDb: attenuationDb);

void main() {
  final now = DateTime(2026, 9, 24, 20, 0);
  final today = DateTime(2026, 9, 24);

  test('today totals, hourly buckets and time-of-day', () {
    final stats = ListeningAnalyzer.compute(
      sessions: [
        session('a', [iv(today.add(const Duration(hours: 8)), const Duration(minutes: 30))]),
        session('b', [iv(today.add(const Duration(hours: 18, minutes: 45)), const Duration(minutes: 30))]),
      ],
      range: StatsRange.today,
      now: now,
    );
    expect(stats.total, const Duration(hours: 1));
    expect(stats.sessionCount, 2);
    expect(stats.buckets[8], const Duration(minutes: 30));
    expect(stats.buckets[18], const Duration(minutes: 15));
    expect(stats.buckets[19], const Duration(minutes: 15));
    expect(stats.timeOfDay[DaySlot.morning], const Duration(minutes: 30));
    expect(stats.timeOfDay[DaySlot.evening], const Duration(minutes: 30));
    expect(stats.breaks, 1);
  });

  test('intervals crossing midnight are clipped to the range', () {
    final stats = ListeningAnalyzer.compute(
      sessions: [
        session('a', [iv(today.subtract(const Duration(minutes: 10)), const Duration(minutes: 30))]),
      ],
      range: StatsRange.today,
      now: now,
    );
    expect(stats.total, const Duration(minutes: 20));
  });

  test('open (live) interval counts up to now', () {
    final stats = ListeningAnalyzer.compute(
      sessions: [
        session('a', [PlaybackInterval(startTime: now.subtract(const Duration(minutes: 12)))]),
      ],
      range: StatsRange.today,
      now: now,
    );
    expect(stats.total, const Duration(minutes: 12));
  });

  test('exposure: dose, Leq, peak, loud time and unknown-level time', () {
    // 100 dB max output: -20 dB => 80 dB, -10 dB => 90 dB.
    final stats = ListeningAnalyzer.compute(
      sessions: [
        session('a', [
          iv(today.add(const Duration(hours: 9)), const Duration(hours: 1), attenuationDb: -20),
          iv(today.add(const Duration(hours: 10)), const Duration(hours: 1), attenuationDb: -10),
          iv(today.add(const Duration(hours: 12)), const Duration(minutes: 20)),
        ]),
      ],
      range: StatsRange.today,
      now: now,
    );
    final expectedDose = ExposureMath.doseFraction(80, const Duration(hours: 1)) +
        ExposureMath.doseFraction(90, const Duration(hours: 1));
    expect(stats.dose, closeTo(expectedDose, 1e-9));
    expect(stats.peakDb, 90);
    expect(stats.loudTime, const Duration(hours: 2));
    expect(stats.unknownLevelTime, const Duration(minutes: 20));
    expect(stats.averageDb, closeTo(87.4, 0.1));
  });

  test('breaks: gaps under 5 minutes are part of one continuous block', () {
    final start = today.add(const Duration(hours: 9));
    final stats = ListeningAnalyzer.compute(
      sessions: [
        session('a', [
          iv(start, const Duration(minutes: 40)),
          iv(start.add(const Duration(minutes: 42)), const Duration(minutes: 40)), // 2 min gap
          iv(start.add(const Duration(hours: 3)), const Duration(minutes: 10)), // real break
        ]),
      ],
      range: StatsRange.today,
      now: now,
    );
    expect(stats.longestContinuous, const Duration(minutes: 82));
    expect(stats.breaks, 1);
  });

  test('week buckets and per-device breakdown', () {
    final stats = ListeningAnalyzer.compute(
      sessions: [
        session('buds', [iv(today.subtract(const Duration(days: 2)).add(const Duration(hours: 10)), const Duration(hours: 2))],
            name: 'Buds'),
        session('wired', [iv(today.add(const Duration(hours: 10)), const Duration(hours: 1))], name: 'Wired'),
      ],
      range: StatsRange.week,
      now: now,
    );
    expect(stats.bucketStarts, hasLength(7));
    expect(stats.buckets[4], const Duration(hours: 2));
    expect(stats.buckets[6], const Duration(hours: 1));
    expect(stats.devices.first.name, 'Buds');
    expect(stats.devices.first.listening, const Duration(hours: 2));
  });

  test('year range has 12 monthly buckets ending with the current month', () {
    final buckets = StatsRange.year.bucketStarts(now);
    expect(buckets, hasLength(12));
    expect(buckets.last, DateTime(2026, 9, 1));
    expect(buckets.first, DateTime(2025, 10, 1));
  });

  group('hearing insight', () {
    ListeningStats statsFor(List<PlaybackInterval> intervals, StatsRange range) =>
        ListeningAnalyzer.compute(sessions: [session('a', intervals)], range: range, now: now);

    test('no data -> no score', () {
      final empty = ListeningAnalyzer.compute(sessions: const [], range: StatsRange.week, now: now);
      expect(ListeningAnalyzer.insight(week: empty, today: empty).score, isNull);
    });

    test('moderate listening scores well', () {
      final intervals = [iv(today.add(const Duration(hours: 9)), const Duration(minutes: 45), attenuationDb: -25)];
      final insight = ListeningAnalyzer.insight(
        week: statsFor(intervals, StatsRange.week),
        today: statsFor(intervals, StatsRange.today),
      );
      expect(insight.score, 100);
      expect(insight.headline, 'Healthy listening');
    });

    test('very loud listening is penalised with a dose recommendation', () {
      final intervals = [
        for (var d = 0; d < 5; d++)
          iv(today.subtract(Duration(days: d)).add(const Duration(hours: 8)), const Duration(hours: 1), attenuationDb: -5),
      ];
      final insight = ListeningAnalyzer.insight(
        week: statsFor(intervals, StatsRange.week),
        today: statsFor(intervals, StatsRange.today),
      );
      expect(insight.score, lessThan(60));
      expect(insight.headline, 'High weekly sound dose');
    });
  });
}
