// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EarTimeEventsTable extends EarTimeEvents
    with TableInfo<$EarTimeEventsTable, EarTimeEventEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EarTimeEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalDeviceIdMeta = const VerificationMeta(
    'canonicalDeviceId',
  );
  @override
  late final GeneratedColumn<String> canonicalDeviceId =
      GeneratedColumn<String>(
        'canonical_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Unknown Device'),
  );
  static const VerificationMeta _connectionTypeMeta = const VerificationMeta(
    'connectionType',
  );
  @override
  late final GeneratedColumn<String> connectionType = GeneratedColumn<String>(
    'connection_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('bluetooth'),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playbackStateMeta = const VerificationMeta(
    'playbackState',
  );
  @override
  late final GeneratedColumn<String> playbackState = GeneratedColumn<String>(
    'playback_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumePercentMeta = const VerificationMeta(
    'volumePercent',
  );
  @override
  late final GeneratedColumn<int> volumePercent = GeneratedColumn<int>(
    'volume_percent',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attenuationDbMeta = const VerificationMeta(
    'attenuationDb',
  );
  @override
  late final GeneratedColumn<double> attenuationDb = GeneratedColumn<double>(
    'attenuation_db',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    canonicalDeviceId,
    deviceName,
    connectionType,
    eventType,
    playbackState,
    timestamp,
    volumePercent,
    attenuationDb,
    reason,
    seq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ear_time_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EarTimeEventEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('canonical_device_id')) {
      context.handle(
        _canonicalDeviceIdMeta,
        canonicalDeviceId.isAcceptableOrUnknown(
          data['canonical_device_id']!,
          _canonicalDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalDeviceIdMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('connection_type')) {
      context.handle(
        _connectionTypeMeta,
        connectionType.isAcceptableOrUnknown(
          data['connection_type']!,
          _connectionTypeMeta,
        ),
      );
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('playback_state')) {
      context.handle(
        _playbackStateMeta,
        playbackState.isAcceptableOrUnknown(
          data['playback_state']!,
          _playbackStateMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('volume_percent')) {
      context.handle(
        _volumePercentMeta,
        volumePercent.isAcceptableOrUnknown(
          data['volume_percent']!,
          _volumePercentMeta,
        ),
      );
    }
    if (data.containsKey('attenuation_db')) {
      context.handle(
        _attenuationDbMeta,
        attenuationDb.isAcceptableOrUnknown(
          data['attenuation_db']!,
          _attenuationDbMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EarTimeEventEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EarTimeEventEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      canonicalDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_device_id'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      connectionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_type'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      playbackState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playback_state'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      volumePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume_percent'],
      ),
      attenuationDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}attenuation_db'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      ),
    );
  }

  @override
  $EarTimeEventsTable createAlias(String alias) {
    return $EarTimeEventsTable(attachedDatabase, alias);
  }
}

class EarTimeEventEntity extends DataClass
    implements Insertable<EarTimeEventEntity> {
  /// Native journal id (`n-<seq>-<timestamp>`), or `<timestamp>_<device>` for legacy rows.
  final String id;
  final String canonicalDeviceId;
  final String deviceName;
  final String connectionType;

  /// DEVICE_CONNECTED, DEVICE_DISCONNECTED, PLAYBACK_STARTED, PLAYBACK_PAUSED, VOLUME_CHANGED
  /// (legacy rows may also contain PLAYBACK_RESUMED / PLAYBACK_STOPPED).
  final String eventType;
  final String? playbackState;
  final int timestamp;

  /// STREAM_MUSIC volume in percent at the time of the event.
  final int? volumePercent;

  /// Volume-curve attenuation in dB (≤ 0) at the time of the event; drives exposure estimates.
  final double? attenuationDb;

  /// Why the native engine emitted the event (ROUTE_ADDED, RECOVERED, TICK, …).
  final String? reason;

  /// Native journal sequence number.
  final int? seq;
  const EarTimeEventEntity({
    required this.id,
    required this.canonicalDeviceId,
    required this.deviceName,
    required this.connectionType,
    required this.eventType,
    this.playbackState,
    required this.timestamp,
    this.volumePercent,
    this.attenuationDb,
    this.reason,
    this.seq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['canonical_device_id'] = Variable<String>(canonicalDeviceId);
    map['device_name'] = Variable<String>(deviceName);
    map['connection_type'] = Variable<String>(connectionType);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || playbackState != null) {
      map['playback_state'] = Variable<String>(playbackState);
    }
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || volumePercent != null) {
      map['volume_percent'] = Variable<int>(volumePercent);
    }
    if (!nullToAbsent || attenuationDb != null) {
      map['attenuation_db'] = Variable<double>(attenuationDb);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || seq != null) {
      map['seq'] = Variable<int>(seq);
    }
    return map;
  }

  EarTimeEventsCompanion toCompanion(bool nullToAbsent) {
    return EarTimeEventsCompanion(
      id: Value(id),
      canonicalDeviceId: Value(canonicalDeviceId),
      deviceName: Value(deviceName),
      connectionType: Value(connectionType),
      eventType: Value(eventType),
      playbackState: playbackState == null && nullToAbsent
          ? const Value.absent()
          : Value(playbackState),
      timestamp: Value(timestamp),
      volumePercent: volumePercent == null && nullToAbsent
          ? const Value.absent()
          : Value(volumePercent),
      attenuationDb: attenuationDb == null && nullToAbsent
          ? const Value.absent()
          : Value(attenuationDb),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      seq: seq == null && nullToAbsent ? const Value.absent() : Value(seq),
    );
  }

  factory EarTimeEventEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EarTimeEventEntity(
      id: serializer.fromJson<String>(json['id']),
      canonicalDeviceId: serializer.fromJson<String>(json['canonicalDeviceId']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      connectionType: serializer.fromJson<String>(json['connectionType']),
      eventType: serializer.fromJson<String>(json['eventType']),
      playbackState: serializer.fromJson<String?>(json['playbackState']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      volumePercent: serializer.fromJson<int?>(json['volumePercent']),
      attenuationDb: serializer.fromJson<double?>(json['attenuationDb']),
      reason: serializer.fromJson<String?>(json['reason']),
      seq: serializer.fromJson<int?>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'canonicalDeviceId': serializer.toJson<String>(canonicalDeviceId),
      'deviceName': serializer.toJson<String>(deviceName),
      'connectionType': serializer.toJson<String>(connectionType),
      'eventType': serializer.toJson<String>(eventType),
      'playbackState': serializer.toJson<String?>(playbackState),
      'timestamp': serializer.toJson<int>(timestamp),
      'volumePercent': serializer.toJson<int?>(volumePercent),
      'attenuationDb': serializer.toJson<double?>(attenuationDb),
      'reason': serializer.toJson<String?>(reason),
      'seq': serializer.toJson<int?>(seq),
    };
  }

  EarTimeEventEntity copyWith({
    String? id,
    String? canonicalDeviceId,
    String? deviceName,
    String? connectionType,
    String? eventType,
    Value<String?> playbackState = const Value.absent(),
    int? timestamp,
    Value<int?> volumePercent = const Value.absent(),
    Value<double?> attenuationDb = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    Value<int?> seq = const Value.absent(),
  }) => EarTimeEventEntity(
    id: id ?? this.id,
    canonicalDeviceId: canonicalDeviceId ?? this.canonicalDeviceId,
    deviceName: deviceName ?? this.deviceName,
    connectionType: connectionType ?? this.connectionType,
    eventType: eventType ?? this.eventType,
    playbackState: playbackState.present
        ? playbackState.value
        : this.playbackState,
    timestamp: timestamp ?? this.timestamp,
    volumePercent: volumePercent.present
        ? volumePercent.value
        : this.volumePercent,
    attenuationDb: attenuationDb.present
        ? attenuationDb.value
        : this.attenuationDb,
    reason: reason.present ? reason.value : this.reason,
    seq: seq.present ? seq.value : this.seq,
  );
  EarTimeEventEntity copyWithCompanion(EarTimeEventsCompanion data) {
    return EarTimeEventEntity(
      id: data.id.present ? data.id.value : this.id,
      canonicalDeviceId: data.canonicalDeviceId.present
          ? data.canonicalDeviceId.value
          : this.canonicalDeviceId,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      connectionType: data.connectionType.present
          ? data.connectionType.value
          : this.connectionType,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      playbackState: data.playbackState.present
          ? data.playbackState.value
          : this.playbackState,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      volumePercent: data.volumePercent.present
          ? data.volumePercent.value
          : this.volumePercent,
      attenuationDb: data.attenuationDb.present
          ? data.attenuationDb.value
          : this.attenuationDb,
      reason: data.reason.present ? data.reason.value : this.reason,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EarTimeEventEntity(')
          ..write('id: $id, ')
          ..write('canonicalDeviceId: $canonicalDeviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('connectionType: $connectionType, ')
          ..write('eventType: $eventType, ')
          ..write('playbackState: $playbackState, ')
          ..write('timestamp: $timestamp, ')
          ..write('volumePercent: $volumePercent, ')
          ..write('attenuationDb: $attenuationDb, ')
          ..write('reason: $reason, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    canonicalDeviceId,
    deviceName,
    connectionType,
    eventType,
    playbackState,
    timestamp,
    volumePercent,
    attenuationDb,
    reason,
    seq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EarTimeEventEntity &&
          other.id == this.id &&
          other.canonicalDeviceId == this.canonicalDeviceId &&
          other.deviceName == this.deviceName &&
          other.connectionType == this.connectionType &&
          other.eventType == this.eventType &&
          other.playbackState == this.playbackState &&
          other.timestamp == this.timestamp &&
          other.volumePercent == this.volumePercent &&
          other.attenuationDb == this.attenuationDb &&
          other.reason == this.reason &&
          other.seq == this.seq);
}

class EarTimeEventsCompanion extends UpdateCompanion<EarTimeEventEntity> {
  final Value<String> id;
  final Value<String> canonicalDeviceId;
  final Value<String> deviceName;
  final Value<String> connectionType;
  final Value<String> eventType;
  final Value<String?> playbackState;
  final Value<int> timestamp;
  final Value<int?> volumePercent;
  final Value<double?> attenuationDb;
  final Value<String?> reason;
  final Value<int?> seq;
  final Value<int> rowid;
  const EarTimeEventsCompanion({
    this.id = const Value.absent(),
    this.canonicalDeviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.connectionType = const Value.absent(),
    this.eventType = const Value.absent(),
    this.playbackState = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.volumePercent = const Value.absent(),
    this.attenuationDb = const Value.absent(),
    this.reason = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EarTimeEventsCompanion.insert({
    required String id,
    required String canonicalDeviceId,
    this.deviceName = const Value.absent(),
    this.connectionType = const Value.absent(),
    required String eventType,
    this.playbackState = const Value.absent(),
    required int timestamp,
    this.volumePercent = const Value.absent(),
    this.attenuationDb = const Value.absent(),
    this.reason = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       canonicalDeviceId = Value(canonicalDeviceId),
       eventType = Value(eventType),
       timestamp = Value(timestamp);
  static Insertable<EarTimeEventEntity> custom({
    Expression<String>? id,
    Expression<String>? canonicalDeviceId,
    Expression<String>? deviceName,
    Expression<String>? connectionType,
    Expression<String>? eventType,
    Expression<String>? playbackState,
    Expression<int>? timestamp,
    Expression<int>? volumePercent,
    Expression<double>? attenuationDb,
    Expression<String>? reason,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (canonicalDeviceId != null) 'canonical_device_id': canonicalDeviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (connectionType != null) 'connection_type': connectionType,
      if (eventType != null) 'event_type': eventType,
      if (playbackState != null) 'playback_state': playbackState,
      if (timestamp != null) 'timestamp': timestamp,
      if (volumePercent != null) 'volume_percent': volumePercent,
      if (attenuationDb != null) 'attenuation_db': attenuationDb,
      if (reason != null) 'reason': reason,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EarTimeEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? canonicalDeviceId,
    Value<String>? deviceName,
    Value<String>? connectionType,
    Value<String>? eventType,
    Value<String?>? playbackState,
    Value<int>? timestamp,
    Value<int?>? volumePercent,
    Value<double?>? attenuationDb,
    Value<String?>? reason,
    Value<int?>? seq,
    Value<int>? rowid,
  }) {
    return EarTimeEventsCompanion(
      id: id ?? this.id,
      canonicalDeviceId: canonicalDeviceId ?? this.canonicalDeviceId,
      deviceName: deviceName ?? this.deviceName,
      connectionType: connectionType ?? this.connectionType,
      eventType: eventType ?? this.eventType,
      playbackState: playbackState ?? this.playbackState,
      timestamp: timestamp ?? this.timestamp,
      volumePercent: volumePercent ?? this.volumePercent,
      attenuationDb: attenuationDb ?? this.attenuationDb,
      reason: reason ?? this.reason,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (canonicalDeviceId.present) {
      map['canonical_device_id'] = Variable<String>(canonicalDeviceId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (connectionType.present) {
      map['connection_type'] = Variable<String>(connectionType.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (playbackState.present) {
      map['playback_state'] = Variable<String>(playbackState.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (volumePercent.present) {
      map['volume_percent'] = Variable<int>(volumePercent.value);
    }
    if (attenuationDb.present) {
      map['attenuation_db'] = Variable<double>(attenuationDb.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EarTimeEventsCompanion(')
          ..write('id: $id, ')
          ..write('canonicalDeviceId: $canonicalDeviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('connectionType: $connectionType, ')
          ..write('eventType: $eventType, ')
          ..write('playbackState: $playbackState, ')
          ..write('timestamp: $timestamp, ')
          ..write('volumePercent: $volumePercent, ')
          ..write('attenuationDb: $attenuationDb, ')
          ..write('reason: $reason, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingEntity(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingEntity extends DataClass
    implements Insertable<AppSettingEntity> {
  final String key;
  final String value;
  const AppSettingEntity({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingEntity(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingEntity copyWith({String? key, String? value}) =>
      AppSettingEntity(key: key ?? this.key, value: value ?? this.value);
  AppSettingEntity copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingEntity(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingEntity(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingEntity &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingEntity> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingEntity> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EarTimeEventsTable earTimeEvents = $EarTimeEventsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    earTimeEvents,
    appSettings,
  ];
}

typedef $$EarTimeEventsTableCreateCompanionBuilder =
    EarTimeEventsCompanion Function({
      required String id,
      required String canonicalDeviceId,
      Value<String> deviceName,
      Value<String> connectionType,
      required String eventType,
      Value<String?> playbackState,
      required int timestamp,
      Value<int?> volumePercent,
      Value<double?> attenuationDb,
      Value<String?> reason,
      Value<int?> seq,
      Value<int> rowid,
    });
typedef $$EarTimeEventsTableUpdateCompanionBuilder =
    EarTimeEventsCompanion Function({
      Value<String> id,
      Value<String> canonicalDeviceId,
      Value<String> deviceName,
      Value<String> connectionType,
      Value<String> eventType,
      Value<String?> playbackState,
      Value<int> timestamp,
      Value<int?> volumePercent,
      Value<double?> attenuationDb,
      Value<String?> reason,
      Value<int?> seq,
      Value<int> rowid,
    });

class $$EarTimeEventsTableFilterComposer
    extends Composer<_$AppDatabase, $EarTimeEventsTable> {
  $$EarTimeEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalDeviceId => $composableBuilder(
    column: $table.canonicalDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playbackState => $composableBuilder(
    column: $table.playbackState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volumePercent => $composableBuilder(
    column: $table.volumePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get attenuationDb => $composableBuilder(
    column: $table.attenuationDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EarTimeEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EarTimeEventsTable> {
  $$EarTimeEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalDeviceId => $composableBuilder(
    column: $table.canonicalDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playbackState => $composableBuilder(
    column: $table.playbackState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volumePercent => $composableBuilder(
    column: $table.volumePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get attenuationDb => $composableBuilder(
    column: $table.attenuationDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EarTimeEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EarTimeEventsTable> {
  $$EarTimeEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get canonicalDeviceId => $composableBuilder(
    column: $table.canonicalDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get playbackState => $composableBuilder(
    column: $table.playbackState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get volumePercent => $composableBuilder(
    column: $table.volumePercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get attenuationDb => $composableBuilder(
    column: $table.attenuationDb,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$EarTimeEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EarTimeEventsTable,
          EarTimeEventEntity,
          $$EarTimeEventsTableFilterComposer,
          $$EarTimeEventsTableOrderingComposer,
          $$EarTimeEventsTableAnnotationComposer,
          $$EarTimeEventsTableCreateCompanionBuilder,
          $$EarTimeEventsTableUpdateCompanionBuilder,
          (
            EarTimeEventEntity,
            BaseReferences<
              _$AppDatabase,
              $EarTimeEventsTable,
              EarTimeEventEntity
            >,
          ),
          EarTimeEventEntity,
          PrefetchHooks Function()
        > {
  $$EarTimeEventsTableTableManager(_$AppDatabase db, $EarTimeEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EarTimeEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EarTimeEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EarTimeEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> canonicalDeviceId = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> connectionType = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> playbackState = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<int?> volumePercent = const Value.absent(),
                Value<double?> attenuationDb = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int?> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EarTimeEventsCompanion(
                id: id,
                canonicalDeviceId: canonicalDeviceId,
                deviceName: deviceName,
                connectionType: connectionType,
                eventType: eventType,
                playbackState: playbackState,
                timestamp: timestamp,
                volumePercent: volumePercent,
                attenuationDb: attenuationDb,
                reason: reason,
                seq: seq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String canonicalDeviceId,
                Value<String> deviceName = const Value.absent(),
                Value<String> connectionType = const Value.absent(),
                required String eventType,
                Value<String?> playbackState = const Value.absent(),
                required int timestamp,
                Value<int?> volumePercent = const Value.absent(),
                Value<double?> attenuationDb = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int?> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EarTimeEventsCompanion.insert(
                id: id,
                canonicalDeviceId: canonicalDeviceId,
                deviceName: deviceName,
                connectionType: connectionType,
                eventType: eventType,
                playbackState: playbackState,
                timestamp: timestamp,
                volumePercent: volumePercent,
                attenuationDb: attenuationDb,
                reason: reason,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EarTimeEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EarTimeEventsTable,
      EarTimeEventEntity,
      $$EarTimeEventsTableFilterComposer,
      $$EarTimeEventsTableOrderingComposer,
      $$EarTimeEventsTableAnnotationComposer,
      $$EarTimeEventsTableCreateCompanionBuilder,
      $$EarTimeEventsTableUpdateCompanionBuilder,
      (
        EarTimeEventEntity,
        BaseReferences<_$AppDatabase, $EarTimeEventsTable, EarTimeEventEntity>,
      ),
      EarTimeEventEntity,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingEntity,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingEntity,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingEntity>,
          ),
          AppSettingEntity,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingEntity,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingEntity,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingEntity>,
      ),
      AppSettingEntity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EarTimeEventsTableTableManager get earTimeEvents =>
      $$EarTimeEventsTableTableManager(_db, _db.earTimeEvents);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
