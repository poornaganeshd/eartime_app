import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:eartime_app/data/database/database.dart';
import 'package:eartime_app/domain/logic/session_manager.dart';
import 'package:eartime_app/domain/models/eartime_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  EarTimeEvent createEvent(String id, String deviceId, String type, DateTime time, {double? attenuationDb}) {
    return EarTimeEvent(
      id: id,
      canonicalDeviceId: deviceId,
      deviceName: 'Test Buds',
      connectionType: 'bluetooth',
      eventType: type,
      timestamp: time,
      attenuationDb: attenuationDb,
    );
  }

  group('SessionManager', () {
    test('handles connected -> playing -> paused -> resumed -> disconnected', () {
      final t0 = DateTime(2026, 8, 1, 10, 0); // connected
      final t1 = DateTime(2026, 8, 1, 10, 5); // playing
      final t2 = DateTime(2026, 8, 1, 10, 20); // paused (15 min active)
      final t3 = DateTime(2026, 8, 1, 10, 30); // resumed
      final t4 = DateTime(2026, 8, 1, 10, 45); // disconnected (15 min active)

      final events = [
        createEvent('1', 'dev1', 'DEVICE_CONNECTED', t0),
        createEvent('2', 'dev1', 'PLAYBACK_STARTED', t1),
        createEvent('3', 'dev1', 'PLAYBACK_PAUSED', t2),
        createEvent('4', 'dev1', 'PLAYBACK_RESUMED', t3),
        createEvent('5', 'dev1', 'DEVICE_DISCONNECTED', t4),
      ];

      final sessions = SessionManager.reconstruct(events);
      expect(sessions.length, 1);

      final session = sessions.first;
      expect(session.isDisconnected, true);
      expect(session.isPlaying, false);
      expect(session.totalActiveDuration.inMinutes, 30); // 15 + 15
    });

    test('media plays through one headset at a time (legacy mis-attribution guard)', () {
      final t0 = DateTime(2026, 8, 1, 10, 0);
      final t1 = DateTime(2026, 8, 1, 10, 10);
      final t2 = DateTime(2026, 8, 1, 10, 20);

      final events = [
        createEvent('1', 'dev1', 'DEVICE_CONNECTED', t0),
        createEvent('2', 'dev2', 'DEVICE_CONNECTED', t0),
        createEvent('3', 'dev1', 'PLAYBACK_STARTED', t0),
        createEvent('4', 'dev2', 'PLAYBACK_STARTED', t1), // closes dev1's interval at t1
        createEvent('5', 'dev1', 'PLAYBACK_PAUSED', t1),
        createEvent('6', 'dev2', 'PLAYBACK_PAUSED', t2),
      ];

      final sessions = SessionManager.reconstruct(events);
      expect(sessions.length, 2);

      final s1 = sessions.firstWhere((s) => s.canonicalDeviceId == 'dev1');
      final s2 = sessions.firstWhere((s) => s.canonicalDeviceId == 'dev2');

      expect(s1.totalActiveDuration.inMinutes, 10);
      expect(s2.totalActiveDuration.inMinutes, 10);
    });

    test('handles midnight crossing correctly', () {
      final t0 = DateTime(2026, 8, 1, 23, 50);
      final t1 = DateTime(2026, 8, 2, 0, 10);

      final events = [
        createEvent('1', 'dev1', 'DEVICE_CONNECTED', t0),
        createEvent('2', 'dev1', 'PLAYBACK_STARTED', t0),
        createEvent('3', 'dev1', 'PLAYBACK_PAUSED', t1),
      ];

      final session = SessionManager.reconstruct(events).first;
      expect(session.totalActiveDuration.inMinutes, 20);
      final todayStart = DateTime(2026, 8, 2, 0, 0);
      expect(session.intervals.first.activeDurationToday(todayStart).inMinutes, 10);
    });

    test('volume changes split intervals so each has a constant level', () {
      final t = DateTime(2026, 8, 1, 10);
      final events = [
        createEvent('1', 'dev1', 'DEVICE_CONNECTED', t, attenuationDb: -20),
        createEvent('2', 'dev1', 'PLAYBACK_STARTED', t.add(const Duration(minutes: 1)), attenuationDb: -20),
        createEvent('3', 'dev1', 'VOLUME_CHANGED', t.add(const Duration(minutes: 11)), attenuationDb: -10),
        createEvent('4', 'dev1', 'PLAYBACK_PAUSED', t.add(const Duration(minutes: 16)), attenuationDb: -10),
      ];
      final session = SessionManager.reconstruct(events).single;
      expect(session.intervals, hasLength(2));
      expect(session.intervals[0].attenuationDb, -20);
      expect(session.intervals[0].staticDuration.inMinutes, 10);
      expect(session.intervals[1].attenuationDb, -10);
      expect(session.intervals[1].staticDuration.inMinutes, 5);
      expect(session.staticTotalActiveDuration.inMinutes, 15);
    });

    test('an open interval stays open only while the live engine says it is playing', () {
      final t = DateTime(2026, 8, 1, 10);
      final events = [
        createEvent('1', 'dev1', 'DEVICE_CONNECTED', t),
        createEvent('2', 'dev1', 'PLAYBACK_STARTED', t.add(const Duration(minutes: 1))),
      ];
      final live = SessionManager.reconstruct(events, liveDeviceId: 'dev1').single;
      expect(live.isPlaying, isTrue);
      expect(live.intervals.single.endTime, isNull);

      // Stale (e.g. a crashed legacy version): never runs forever.
      final stale = SessionManager.reconstruct(events).single;
      expect(stale.isPlaying, isFalse);
      expect(stale.listeningAt(t.add(const Duration(days: 3))), Duration.zero);
    });

    test('same-millisecond events keep log order (stable sort)', () {
      final t = DateTime(2026, 8, 1, 10);
      final t2 = t.add(const Duration(minutes: 5));
      final events = [
        createEvent('1', 'dev1', 'DEVICE_CONNECTED', t),
        createEvent('2', 'dev1', 'PLAYBACK_STARTED', t),
        createEvent('3', 'dev1', 'PLAYBACK_PAUSED', t2),
        createEvent('4', 'dev1', 'PLAYBACK_STARTED', t2),
        createEvent('5', 'dev1', 'DEVICE_DISCONNECTED', t2.add(const Duration(minutes: 5))),
      ];
      final session = SessionManager.reconstruct(events).single;
      expect(session.staticTotalActiveDuration.inMinutes, 10);
    });

    test('DEVICE_CONNECTED while a session is open completes the previous one', () {
      final t = DateTime(2026, 8, 1, 10);
      final events = [
        createEvent('1', 'dev1', 'DEVICE_CONNECTED', t),
        createEvent('2', 'dev1', 'PLAYBACK_STARTED', t),
        createEvent('3', 'dev1', 'DEVICE_CONNECTED', t.add(const Duration(minutes: 30))),
      ];
      final sessions = SessionManager.reconstruct(events);
      expect(sessions, hasLength(2));
      expect(sessions.first.isDisconnected, isTrue);
      expect(sessions.first.staticTotalActiveDuration.inMinutes, 30);
    });
  });

  group('AppDatabase', () {
    EarTimeEventsCompanion row(String id, int ts) => EarTimeEventsCompanion(
          id: drift.Value(id),
          canonicalDeviceId: const drift.Value('dev1'),
          eventType: const drift.Value('DEVICE_CONNECTED'),
          timestamp: drift.Value(ts),
        );

    test('inserts are idempotent on id (journal replays never duplicate)', () async {
      await db.insertEvents([row('a', 1), row('b', 2)]);
      await db.insertEvents([row('a', 1), row('b', 2), row('c', 3)]);
      expect(await db.countEvents(), 3);
    });

    test('two events in the same millisecond no longer collide', () async {
      await db.insertEvent(row('n-1-5', 5));
      await db.insertEvent(row('n-2-5', 5));
      expect(await db.countEvents(), 2);
    });

    test('events since a timestamp are returned oldest first', () async {
      await db.insertEvents([row('c', 30), row('a', 10), row('b', 20)]);
      final rows = await db.getEventsSince(15);
      expect(rows.map((r) => r.id), ['b', 'c']);
    });

    test('settings round-trip', () async {
      await db.setSetting('themeMode', 'dark');
      await db.setSetting('themeMode', 'light');
      expect(await db.getSetting('themeMode'), 'light');
      expect(await db.getAllSettings(), {'themeMode': 'light'});
    });
  });
}
