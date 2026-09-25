import 'dart:async';

import 'package:eartime_app/data/tracking_platform.dart';
import 'package:eartime_app/domain/models/tracking_event.dart';

/// In-memory stand-in for the native engine: a live event stream plus a journal that behaves
/// like `EventJournal.kt` (read returns unacknowledged events, ack trims them).
class FakeTrackingPlatform extends TrackingPlatform {
  FakeTrackingPlatform() : super(isSupported: false);

  final _controller = StreamController<TrackingEvent>.broadcast();
  final List<Map<String, dynamic>> journal = [];
  final List<Map<String, Object?>> nativeSettings = [];
  int _seq = 0;
  int syncRequests = 0;
  int ackCalls = 0;

  @override
  Stream<TrackingEvent> get events => _controller.stream;

  /// Emits a live-only event (e.g. SYNC_STATE).
  void emitLive(Map<String, dynamic> raw) => _controller.add(TrackingEvent.fromJson(raw));

  /// Simulates the engine: journal first, then publish.
  Map<String, dynamic> emitPersisted(Map<String, dynamic> raw) {
    final seq = ++_seq;
    final stamped = {...raw, 'seq': seq, 'eventId': 'n-$seq-${raw['timestamp']}'};
    journal.add(stamped);
    _controller.add(TrackingEvent.fromJson(stamped));
    return stamped;
  }

  /// Simulates an event journaled while Flutter was not listening.
  void journalOnly(Map<String, dynamic> raw) {
    final seq = ++_seq;
    journal.add({...raw, 'seq': seq, 'eventId': 'n-$seq-${raw['timestamp']}'});
  }

  @override
  Future<List<TrackingEvent>> getJournal({required int afterSeq}) async =>
      journal.where((e) => (e['seq'] as int) > afterSeq).map(TrackingEvent.fromJson).toList();

  @override
  Future<void> ackJournal(int upToSeq) async {
    ackCalls++;
    journal.removeWhere((e) => (e['seq'] as int) <= upToSeq);
  }

  @override
  Future<void> requestSync() async => syncRequests++;

  @override
  Future<void> updateNativeSettings(Map<String, Object?> settings) async => nativeSettings.add(settings);

  @override
  Future<bool> startMonitoring() async => true;

  @override
  Future<void> stopMonitoring() async {}

  Future<void> close() => _controller.close();
}

Map<String, dynamic> device(String id, {String name = 'Nord Buds 3 Pro', String type = 'bluetooth'}) => {
      'id': id,
      'friendlyName': name,
      'connectionType': type,
      'hardwareAddress': id.contains(':') ? id : null,
      'nativeType': 8,
    };

Map<String, dynamic> volume(int percent, double attenuationDb) =>
    {'index': (percent * 15 / 100).round(), 'max': 15, 'percent': percent, 'attenuationDb': attenuationDb};
