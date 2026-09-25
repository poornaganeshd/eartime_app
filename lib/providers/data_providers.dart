import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../data/event_ingestor.dart';
import '../data/tracking_platform.dart';
import '../domain/logic/listening_analyzer.dart';
import '../domain/logic/live_session_reducer.dart';
import '../domain/logic/session_manager.dart';
import '../domain/models/eartime_event.dart';
import '../domain/models/listening_session.dart';
import '../domain/models/live_session_state.dart';
import '../domain/models/tracking_event.dart';
import 'settings_provider.dart';

// --- Infrastructure ----------------------------------------------------------------------------

final trackingPlatformProvider = Provider<TrackingPlatform>((ref) => TrackingPlatform());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final eventIngestorProvider = Provider<EventIngestor>((ref) {
  final ingestor = EventIngestor(
    db: ref.watch(databaseProvider),
    platform: ref.watch(trackingPlatformProvider),
  );
  ref.onDispose(ingestor.dispose);
  ingestor.start();
  return ingestor;
});

/// Starts the passive real-time pipeline: live state, journal ingestion and a native state sync.
final trackingPipelineProvider = Provider<void>((ref) {
  ref.watch(eventIngestorProvider);
  ref.watch(liveSessionProvider.notifier);
  ref.watch(settingsProvider.notifier); // Loads preferences and mirrors them to native.
  unawaited(ref.read(trackingPlatformProvider).requestSync());
});

// --- Raw native streams (diagnostics) ----------------------------------------------------------

final bleNotificationProvider = StreamProvider<TrackingEvent>((ref) {
  return ref.watch(trackingPlatformProvider).events.where((event) => event.type == 'BLE_NOTIFICATION');
});

final bleDiagnosticStateProvider = StreamProvider<TrackingEvent>((ref) {
  return ref.watch(trackingPlatformProvider).events.where((event) => event.type == 'BLE_DIAGNOSTIC_STATE');
});

/// The discovered GATT device map (`deviceName`, `deviceAddress`, `services`).
final bleDiscoveryResultProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref
      .watch(trackingPlatformProvider)
      .events
      .where((event) => event.type == 'BLE_DISCOVERY_RESULT')
      .map((event) => event.device ?? const <String, dynamic>{});
});

// --- Live session --------------------------------------------------------------------------------

class LiveSessionNotifier extends Notifier<LiveSessionState> {
  @override
  LiveSessionState build() {
    final subscription = ref.watch(trackingPlatformProvider).events.listen(apply);
    ref.onDispose(subscription.cancel);
    return const LiveSessionState();
  }

  void apply(TrackingEvent event) {
    state = LiveSessionReducer.reduce(state, event);
  }

  void updateState(LiveSessionState newState) {
    state = newState;
  }
}

final liveSessionProvider = NotifierProvider<LiveSessionNotifier, LiveSessionState>(LiveSessionNotifier.new);

/// Wall clock for live figures: ticks every second while listening, every 30 s otherwise
/// (enough to roll over midnight and refresh "x minutes ago" labels).
final clockProvider = StreamProvider<DateTime>((ref) {
  final playing = ref.watch(liveSessionProvider.select((s) => s.isPlaying));
  final period = playing ? const Duration(seconds: 1) : const Duration(seconds: 30);
  final controller = StreamController<DateTime>();
  controller.add(DateTime.now());
  final timer = Timer.periodic(period, (_) => controller.add(DateTime.now()));
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

DateTime currentTime(Ref ref) => ref.watch(clockProvider).value ?? DateTime.now();

// --- History -------------------------------------------------------------------------------------

EarTimeEvent _toDomain(EarTimeEventEntity e) => EarTimeEvent(
      id: e.id,
      canonicalDeviceId: e.canonicalDeviceId,
      deviceName: e.deviceName,
      connectionType: e.connectionType,
      eventType: e.eventType,
      playbackState: e.playbackState,
      timestamp: DateTime.fromMillisecondsSinceEpoch(e.timestamp),
      volumePercent: e.volumePercent,
      attenuationDb: e.attenuationDb,
      reason: e.reason,
    );

/// Events covering [range] (plus two days of lead-in so sessions that started before the range
/// are reconstructed correctly), oldest first.
final eventsProvider = StreamProvider.family<List<EarTimeEvent>, StatsRange>((ref, range) {
  final db = ref.watch(databaseProvider);
  final since = range.startFor(DateTime.now()).subtract(const Duration(days: 2));
  return db.watchEventsSince(since.millisecondsSinceEpoch).map((rows) => rows.map(_toDomain).toList());
});

/// Newest-first events for the last month (activity feeds, diagnostics).
final recentEventsProvider = Provider<AsyncValue<List<EarTimeEvent>>>((ref) {
  return ref.watch(eventsProvider(StatsRange.month)).whenData((events) => events.reversed.toList());
});

/// Kept for the diagnostics screen: chronological events for the last month.
final allEventsProvider = Provider<AsyncValue<List<EarTimeEvent>>>((ref) {
  return ref.watch(eventsProvider(StatsRange.month));
});

final sessionsProvider = Provider.family<AsyncValue<List<ListeningSession>>, StatsRange>((ref, range) {
  final liveDeviceId = ref.watch(liveSessionProvider.select((s) => s.isPlaying ? s.activeDeviceId : null));
  return ref
      .watch(eventsProvider(range))
      .whenData((events) => SessionManager.reconstruct(events, liveDeviceId: liveDeviceId));
});

/// Back-compat alias used by older widgets.
final sessionManagerProvider = Provider<AsyncValue<List<ListeningSession>>>((ref) {
  return ref.watch(sessionsProvider(StatsRange.month));
});

final statsProvider = Provider.family<AsyncValue<ListeningStats>, StatsRange>((ref, range) {
  final now = currentTime(ref);
  final maxOutputDb = ref.watch(preferencesProvider.select((p) => p.maxOutputDb));
  return ref.watch(sessionsProvider(range)).whenData(
        (sessions) => ListeningAnalyzer.compute(
          sessions: sessions,
          range: range,
          now: now,
          maxOutputDb: maxOutputDb,
        ),
      );
});

final hearingInsightProvider = Provider<AsyncValue<HearingInsight>>((ref) {
  final week = ref.watch(statsProvider(StatsRange.week));
  final today = ref.watch(statsProvider(StatsRange.today));
  final limit = ref.watch(preferencesProvider.select((p) => p.dailyLimitMinutes));
  if (week.hasValue && today.hasValue) {
    return AsyncValue.data(ListeningAnalyzer.insight(week: week.value!, today: today.value!, dailyLimitMinutes: limit));
  }
  if (week.hasError) return AsyncValue.error(week.error!, week.stackTrace ?? StackTrace.current);
  return const AsyncValue.loading();
});
