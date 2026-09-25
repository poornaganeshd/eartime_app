import 'package:drift/native.dart';
import 'package:eartime_app/data/database/database.dart';
import 'package:eartime_app/domain/logic/listening_analyzer.dart';
import 'package:eartime_app/domain/models/listening_session.dart';
import 'package:eartime_app/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_tracking_platform.dart';

/// End-to-end regression tests for the Phase 6 bug matrix, running the real providers,
/// reducer, ingestor, database and session reconstruction against a fake native engine.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const buds = 'AA:BB:CC:DD:EE:FF';
  late FakeTrackingPlatform platform;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    platform = FakeTrackingPlatform();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      trackingPlatformProvider.overrideWithValue(platform),
      databaseProvider.overrideWithValue(db),
    ]);
    container.read(liveSessionProvider); // start listening
    container.read(eventIngestorProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await platform.close();
  });

  Future<void> settle() async {
    // Let the stream deliver, the 250 ms ingest debounce fire, and the drain finish.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await container.read(eventIngestorProvider).drain();
  }

  Map<String, dynamic> connected(int t) =>
      {'type': 'DEVICE_CONNECTED', 'deviceId': buds, 'device': device(buds), 'volume': volume(60, -17), 'timestamp': t};
  Map<String, dynamic> started(int t) =>
      {'type': 'PLAYBACK_STARTED', 'deviceId': buds, 'device': device(buds), 'volume': volume(60, -17), 'timestamp': t};
  Map<String, dynamic> paused(int t) =>
      {'type': 'PLAYBACK_PAUSED', 'deviceId': buds, 'device': device(buds), 'volume': volume(60, -17), 'timestamp': t};

  final base = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;

  test('A1/13. Launch with earbuds disconnected (empty SYNC_STATE)', () async {
    platform.emitLive({'type': 'SYNC_STATE', 'timestamp': base, 'monitoring': true, 'connectedDevices': [], 'isPlaying': false});
    await settle();
    final live = container.read(liveSessionProvider);
    expect(live.isInitialized, isTrue);
    expect(live.activeDevice, isNull);
  });

  test('A2/3/4. DEVICE_CONNECTED without playback: device stays, no timer', () async {
    platform.emitPersisted(connected(base));
    await settle();
    final live = container.read(liveSessionProvider);
    expect(live.activeDevice?.canonicalDeviceId, buds);
    expect(live.isPlaying, isFalse);
    expect(live.playbackStartedAt, isNull);
    expect(await db.countEvents(), 1);
  });

  test('5/6/7. PLAYBACK_STARTED then PAUSED: live timer stops and history closes the interval', () async {
    platform.emitPersisted(connected(base));
    platform.emitPersisted(started(base + 60000));
    await settle();
    expect(container.read(liveSessionProvider).isPlaying, isTrue);
    expect(container.read(liveSessionProvider).playbackStartedAt, DateTime.fromMillisecondsSinceEpoch(base + 60000));

    platform.emitPersisted(paused(base + 60000 + 10 * 60000));
    await settle();
    final live = container.read(liveSessionProvider);
    expect(live.isPlaying, isFalse);
    expect(live.playbackStartedAt, isNull);

    final sessions = await _sessions(container);
    expect(sessions.single.staticTotalActiveDuration, const Duration(minutes: 10));
    expect(sessions.single.intervals.single.attenuationDb, -17);
  });

  test('8/9. Repeated play/pause accumulates without duplicate intervals', () async {
    platform.emitPersisted(connected(base));
    for (var i = 0; i < 5; i++) {
      platform.emitPersisted(started(base + i * 120000));
      platform.emitPersisted(paused(base + i * 120000 + 60000));
    }
    await settle();
    final session = (await _sessions(container)).single;
    expect(session.intervals, hasLength(5));
    expect(session.staticTotalActiveDuration, const Duration(minutes: 5));
    expect(await db.countEvents(), 11);
  });

  test('10. Journal replay is idempotent and the journal is acknowledged', () async {
    platform.emitPersisted(connected(base));
    await settle();
    expect(platform.journal, isEmpty);
    expect(await db.countEvents(), 1);

    // A crash between insert and ack replays the same events: no duplicates.
    platform.journal.add({...connected(base), 'seq': 1, 'eventId': 'n-1-$base'});
    await container.read(eventIngestorProvider).drain();
    expect(await db.countEvents(), 1);
  });

  test('11. Events journaled while Flutter was not running are ingested on the next drain', () async {
    platform.journalOnly(connected(base));
    platform.journalOnly(started(base + 1000));
    platform.journalOnly(paused(base + 1000 + 30 * 60000));
    await container.read(eventIngestorProvider).drain();
    expect(await db.countEvents(), 3);
    final session = (await _sessions(container)).single;
    expect(session.staticTotalActiveDuration, const Duration(minutes: 30));
  });

  test('11b. Service recovery after process death closes the open interval', () async {
    platform.emitPersisted(connected(base));
    platform.emitPersisted(started(base + 1000));
    await settle();
    // Native restarts and journals the recovery pause at the last heartbeat.
    platform.journalOnly({...paused(base + 1000 + 20 * 60000), 'reason': 'RECOVERED'});
    await container.read(eventIngestorProvider).drain();
    final session = (await _sessions(container)).single;
    expect(session.isPlaying, isFalse);
    expect(session.staticTotalActiveDuration, const Duration(minutes: 20));
  });

  test('12. SYNC_STATE with a connected, playing device', () async {
    platform.emitLive({
      'type': 'SYNC_STATE',
      'timestamp': base + 5000,
      'monitoring': true,
      'connectedDevices': [device(buds)],
      'activeDeviceId': buds,
      'isPlaying': true,
      'playbackStartedAt': base,
      'volume': volume(50, -22),
    });
    await settle();
    final live = container.read(liveSessionProvider);
    expect(live.activeDevice?.displayName, 'Nord Buds 3 Pro');
    expect(live.isPlaying, isTrue);
    expect(live.playbackStartedAt, DateTime.fromMillisecondsSinceEpoch(base));
    expect(live.volume?.percent, 50);
  });

  test('14. Home (today stats) and Timeline (sessions) agree', () async {
    platform.emitPersisted(connected(base));
    platform.emitPersisted(started(base + 1000));
    platform.emitPersisted(paused(base + 1000 + 15 * 60000));
    await settle();
    final sessions = await _sessions(container);
    final stats = ListeningAnalyzer.compute(sessions: sessions, range: StatsRange.week, now: DateTime.now());
    expect(stats.total, sessions.single.staticTotalActiveDuration);
  });

  test('Malformed/unknown events never break the pipeline', () async {
    platform.emitLive({'type': 'SOMETHING_NEW', 'timestamp': base});
    platform.emitPersisted(connected(base + 1));
    await settle();
    expect(container.read(liveSessionProvider).hasDevice, isTrue);
  });
}

Future<List<ListeningSession>> _sessions(ProviderContainer c) async {
  final sub = c.listen(sessionsProvider(StatsRange.month), (_, _) {});
  addTearDown(sub.close);
  for (var i = 0; i < 50; i++) {
    final v = c.read(sessionsProvider(StatsRange.month));
    if (v.hasValue) {
      // Wait until the database stream has caught up with the latest inserts.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final latest = c.read(sessionsProvider(StatsRange.month));
      if (latest.hasValue) return latest.value!;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('sessions never loaded');
}
