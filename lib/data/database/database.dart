import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [EarTimeEvents, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  static const _timestampIndex =
      'CREATE INDEX IF NOT EXISTS idx_events_timestamp ON ear_time_events (timestamp)';

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(_timestampIndex);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(earTimeEvents, earTimeEvents.volumePercent);
            await m.addColumn(earTimeEvents, earTimeEvents.attenuationDb);
            await m.addColumn(earTimeEvents, earTimeEvents.reason);
            await m.addColumn(earTimeEvents, earTimeEvents.seq);
            await m.createTable(appSettings);
            await customStatement(_timestampIndex);
          }
        },
      );

  // ---- Events -----------------------------------------------------------------------------

  /// Events at or after [sinceMs], oldest first.
  Stream<List<EarTimeEventEntity>> watchEventsSince(int sinceMs) {
    return (select(earTimeEvents)
          ..where((t) => t.timestamp.isBiggerOrEqualValue(sinceMs))
          ..orderBy([
            (t) => OrderingTerm(expression: t.timestamp),
            (t) => OrderingTerm(expression: t.seq),
          ]))
        .watch();
  }

  Future<List<EarTimeEventEntity>> getEventsSince(int sinceMs) {
    return (select(earTimeEvents)
          ..where((t) => t.timestamp.isBiggerOrEqualValue(sinceMs))
          ..orderBy([
            (t) => OrderingTerm(expression: t.timestamp),
            (t) => OrderingTerm(expression: t.seq),
          ]))
        .get();
  }

  Future<List<EarTimeEventEntity>> getAllEvents() => getEventsSince(0);

  Future<int> insertEvent(EarTimeEventsCompanion event) {
    return into(earTimeEvents).insert(event, mode: InsertMode.insertOrIgnore);
  }

  /// Idempotent bulk insert: rows whose id already exists are skipped, so journal replays are safe.
  Future<void> insertEvents(Iterable<EarTimeEventsCompanion> events) {
    return batch((b) => b.insertAll(earTimeEvents, events, mode: InsertMode.insertOrIgnore));
  }

  Future<int> countEvents() async {
    final count = earTimeEvents.id.count();
    final row = await (selectOnly(earTimeEvents)..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> clearAllEvents() {
    return delete(earTimeEvents).go();
  }

  // ---- Settings ---------------------------------------------------------------------------

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(appSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<void> setSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'eartime_db.sqlite'));

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
