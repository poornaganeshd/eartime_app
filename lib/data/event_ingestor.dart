import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../domain/models/tracking_event.dart';
import 'database/database.dart';
import 'tracking_platform.dart';

/// Moves persistable events from the native journal into SQLite.
///
/// This is the *only* write path for history. The native engine journals every transition
/// before publishing it, so events that happen while Flutter isn't running (UI closed, process
/// restarted by Android) are ingested on the next drain. Inserts are idempotent on `eventId`,
/// drains are serialized, and the journal is acknowledged only after the rows are committed —
/// a crash at any point can repeat work but never lose or duplicate history.
class EventIngestor {
  EventIngestor({required this.db, required this.platform, this.debounce = const Duration(milliseconds: 250)});

  final AppDatabase db;
  final TrackingPlatform platform;
  final Duration debounce;

  StreamSubscription<TrackingEvent>? _subscription;
  Timer? _timer;
  Future<void> _chain = Future.value();
  bool _disposed = false;

  void start() {
    _subscription ??= platform.events.listen((event) {
      if (event.isPersistable || event.type == 'SYNC_STATE') scheduleDrain();
    });
    drain();
  }

  void scheduleDrain() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(debounce, drain);
  }

  /// Drains the journal; concurrent calls are queued behind each other.
  Future<void> drain() {
    if (_disposed) return _chain;
    return _chain = _chain.then((_) => _drainOnce()).catchError((Object e, StackTrace s) {
      debugPrint('[INGEST] drain failed: $e\n$s');
    });
  }

  Future<void> _drainOnce() async {
    // The journal only holds unacknowledged events, so it is always read from the start.
    for (var round = 0; round < 50 && !_disposed; round++) {
      final batch = await platform.getJournal(afterSeq: 0);
      if (batch.isEmpty) return;
      final rows = batch.map(toCompanion).whereType<EarTimeEventsCompanion>().toList();
      await db.insertEvents(rows);
      var maxSeq = 0;
      for (final e in batch) {
        if ((e.seq ?? 0) > maxSeq) maxSeq = e.seq!;
      }
      if (maxSeq == 0) return;
      await platform.ackJournal(maxSeq);
      debugPrint('[INGEST] stored ${rows.length} events (acked seq ≤ $maxSeq)');
      if (batch.length < 2000) return;
    }
  }

  /// Maps a native event to a database row; null for events that are not history.
  static EarTimeEventsCompanion? toCompanion(TrackingEvent e) {
    if (!e.isPersistable) return null;
    final deviceId = e.deviceId ?? e.device?['id'] as String?;
    if (deviceId == null) return null;
    final id = e.eventId ?? '${e.timestamp}_${deviceId}_${e.type}';
    return EarTimeEventsCompanion(
      id: drift.Value(id),
      canonicalDeviceId: drift.Value(deviceId),
      deviceName: drift.Value(e.device?['friendlyName'] as String? ?? 'Headphones'),
      connectionType: drift.Value(e.device?['connectionType'] as String? ?? 'bluetooth'),
      eventType: drift.Value(e.type),
      playbackState: const drift.Value(null),
      timestamp: drift.Value(e.timestamp),
      volumePercent: drift.Value(e.volume?.percent),
      attenuationDb: drift.Value(e.volume?.attenuationDb),
      reason: drift.Value(e.reason),
      seq: drift.Value(e.seq),
    );
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _subscription?.cancel();
  }
}
