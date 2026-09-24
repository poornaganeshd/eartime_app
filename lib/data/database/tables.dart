import 'package:drift/drift.dart';

/// Every persisted tracking transition. Sessions, listening time and sound exposure are all
/// *derived* from this append-only log (see SessionManager / ListeningAnalyzer).
@DataClassName('EarTimeEventEntity')
class EarTimeEvents extends Table {
  /// Native journal id (`n-<seq>-<timestamp>`), or `<timestamp>_<device>` for legacy rows.
  TextColumn get id => text()();
  TextColumn get canonicalDeviceId => text()();
  TextColumn get deviceName => text().withDefault(const Constant('Unknown Device'))();
  TextColumn get connectionType => text().withDefault(const Constant('bluetooth'))();

  /// DEVICE_CONNECTED, DEVICE_DISCONNECTED, PLAYBACK_STARTED, PLAYBACK_PAUSED, VOLUME_CHANGED
  /// (legacy rows may also contain PLAYBACK_RESUMED / PLAYBACK_STOPPED).
  TextColumn get eventType => text()();
  TextColumn get playbackState => text().nullable()();
  IntColumn get timestamp => integer()();

  // ---- schema v2 ----
  /// STREAM_MUSIC volume in percent at the time of the event.
  IntColumn get volumePercent => integer().nullable()();

  /// Volume-curve attenuation in dB (≤ 0) at the time of the event; drives exposure estimates.
  RealColumn get attenuationDb => real().nullable()();

  /// Why the native engine emitted the event (ROUTE_ADDED, RECOVERED, TICK, …).
  TextColumn get reason => text().nullable()();

  /// Native journal sequence number.
  IntColumn get seq => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Small key/value store for app preferences (theme, hearing calibration, journal cursor).
@DataClassName('AppSettingEntity')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
