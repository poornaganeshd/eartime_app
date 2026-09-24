import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/models/tracking_event.dart';

/// Bridge to the native tracking engine.
///
/// IMPORTANT: there is exactly ONE EventChannel subscription for the whole app. Every call to
/// `receiveBroadcastStream()` installs a new platform message handler for the channel name
/// (replacing the previous one) and cancelling any of them tells native to detach the sink —
/// which previously silently killed the live pipeline whenever a diagnostics screen closed.
/// All consumers share [events].
class TrackingPlatform {
  TrackingPlatform({
    MethodChannel methodChannel = const MethodChannel('com.eartime.app/tracking'),
    EventChannel eventChannel = const EventChannel('com.eartime.app/tracking_events'),
    bool? isSupported,
  })  : _methodChannel = methodChannel,
        _eventChannel = eventChannel,
        isSupported = isSupported ?? (!kIsWeb && Platform.isAndroid);

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  /// Background tracking is implemented on Android only.
  final bool isSupported;

  Stream<TrackingEvent>? _events;

  /// Shared, lazily-started broadcast stream of decoded native events. Malformed events are
  /// logged and dropped instead of erroring the stream.
  Stream<TrackingEvent> get events {
    return _events ??= isSupported
        ? _eventChannel
            .receiveBroadcastStream()
            .map(_decode)
            .where((event) => event != null)
            .cast<TrackingEvent>()
            .asBroadcastStream()
        : const Stream<TrackingEvent>.empty();
  }

  static TrackingEvent? _decode(dynamic raw) {
    if (raw is! Map) return null;
    try {
      return TrackingEvent.fromJson(TrackingEvent.deepCast(raw));
    } catch (e) {
      debugPrint('[TRACKING] dropped malformed event: $e\n$raw');
      return null;
    }
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (!isSupported) return null;
    try {
      return await _methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      debugPrint('[TRACKING] $method failed: ${e.code} ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> startMonitoring() async => await _invoke<bool>('startMonitoring') ?? false;

  Future<void> stopMonitoring() => _invoke<void>('stopMonitoring');

  /// Asks native to emit a fresh SYNC_STATE event.
  Future<void> requestSync() => _invoke<void>('requestSync');

  /// Persistable events stored in the native journal with `seq > afterSeq`, oldest first.
  Future<List<TrackingEvent>> getJournal({required int afterSeq}) async {
    final list = await _invoke<List<Object?>>('getJournal', {'afterSeq': afterSeq}) ?? const [];
    return list.map(_decode).whereType<TrackingEvent>().toList();
  }

  Future<void> ackJournal(int upToSeq) => _invoke<void>('ackJournal', {'upToSeq': upToSeq});

  Future<Map<String, dynamic>> getNativeSettings() async {
    final map = await _invoke<Map<Object?, Object?>>('getSettings');
    return map == null ? const {} : TrackingEvent.deepCast(map);
  }

  Future<void> updateNativeSettings(Map<String, Object?> settings) => _invoke<void>('updateSettings', settings);

  Future<bool> startBleDiagnostic(String? hardwareAddress) async =>
      await _invoke<bool>('startBleDiagnostic', {'address': hardwareAddress}) ?? false;

  Future<Map<String, dynamic>> getAudioDiagnostics() async {
    final map = await _invoke<Map<Object?, Object?>>('getAudioDiagnostics');
    return map == null ? const {} : TrackingEvent.deepCast(map);
  }

  Future<void> openBatteryOptimizationSettings() => _invoke<void>('openBatteryOptimizationSettings');
}
