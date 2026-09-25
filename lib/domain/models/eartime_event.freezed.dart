// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'eartime_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EarTimeEvent {

 String get id; String get canonicalDeviceId; String get deviceName; String get connectionType; String get eventType;// DEVICE_CONNECTED, DEVICE_DISCONNECTED, PLAYBACK_STARTED, PLAYBACK_PAUSED, VOLUME_CHANGED (+ legacy PLAYBACK_RESUMED/STOPPED)
 String? get playbackState; DateTime get timestamp;// Schema v2: volume at the time of the event (drives exposure estimates).
 int? get volumePercent; double? get attenuationDb; String? get reason;// Phase 5 Optional Fields
 String? get earSide; Map<String, dynamic>? get earState; String? get attributionConfidence; String? get earStateSource;
/// Create a copy of EarTimeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarTimeEventCopyWith<EarTimeEvent> get copyWith => _$EarTimeEventCopyWithImpl<EarTimeEvent>(this as EarTimeEvent, _$identity);

  /// Serializes this EarTimeEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EarTimeEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.canonicalDeviceId, canonicalDeviceId) || other.canonicalDeviceId == canonicalDeviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.connectionType, connectionType) || other.connectionType == connectionType)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.playbackState, playbackState) || other.playbackState == playbackState)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.volumePercent, volumePercent) || other.volumePercent == volumePercent)&&(identical(other.attenuationDb, attenuationDb) || other.attenuationDb == attenuationDb)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.earSide, earSide) || other.earSide == earSide)&&const DeepCollectionEquality().equals(other.earState, earState)&&(identical(other.attributionConfidence, attributionConfidence) || other.attributionConfidence == attributionConfidence)&&(identical(other.earStateSource, earStateSource) || other.earStateSource == earStateSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,canonicalDeviceId,deviceName,connectionType,eventType,playbackState,timestamp,volumePercent,attenuationDb,reason,earSide,const DeepCollectionEquality().hash(earState),attributionConfidence,earStateSource);

@override
String toString() {
  return 'EarTimeEvent(id: $id, canonicalDeviceId: $canonicalDeviceId, deviceName: $deviceName, connectionType: $connectionType, eventType: $eventType, playbackState: $playbackState, timestamp: $timestamp, volumePercent: $volumePercent, attenuationDb: $attenuationDb, reason: $reason, earSide: $earSide, earState: $earState, attributionConfidence: $attributionConfidence, earStateSource: $earStateSource)';
}


}

/// @nodoc
abstract mixin class $EarTimeEventCopyWith<$Res>  {
  factory $EarTimeEventCopyWith(EarTimeEvent value, $Res Function(EarTimeEvent) _then) = _$EarTimeEventCopyWithImpl;
@useResult
$Res call({
 String id, String canonicalDeviceId, String deviceName, String connectionType, String eventType, String? playbackState, DateTime timestamp, int? volumePercent, double? attenuationDb, String? reason, String? earSide, Map<String, dynamic>? earState, String? attributionConfidence, String? earStateSource
});




}
/// @nodoc
class _$EarTimeEventCopyWithImpl<$Res>
    implements $EarTimeEventCopyWith<$Res> {
  _$EarTimeEventCopyWithImpl(this._self, this._then);

  final EarTimeEvent _self;
  final $Res Function(EarTimeEvent) _then;

/// Create a copy of EarTimeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? canonicalDeviceId = null,Object? deviceName = null,Object? connectionType = null,Object? eventType = null,Object? playbackState = freezed,Object? timestamp = null,Object? volumePercent = freezed,Object? attenuationDb = freezed,Object? reason = freezed,Object? earSide = freezed,Object? earState = freezed,Object? attributionConfidence = freezed,Object? earStateSource = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,canonicalDeviceId: null == canonicalDeviceId ? _self.canonicalDeviceId : canonicalDeviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,connectionType: null == connectionType ? _self.connectionType : connectionType // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,playbackState: freezed == playbackState ? _self.playbackState : playbackState // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,volumePercent: freezed == volumePercent ? _self.volumePercent : volumePercent // ignore: cast_nullable_to_non_nullable
as int?,attenuationDb: freezed == attenuationDb ? _self.attenuationDb : attenuationDb // ignore: cast_nullable_to_non_nullable
as double?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,earSide: freezed == earSide ? _self.earSide : earSide // ignore: cast_nullable_to_non_nullable
as String?,earState: freezed == earState ? _self.earState : earState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,attributionConfidence: freezed == attributionConfidence ? _self.attributionConfidence : attributionConfidence // ignore: cast_nullable_to_non_nullable
as String?,earStateSource: freezed == earStateSource ? _self.earStateSource : earStateSource // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EarTimeEvent].
extension EarTimeEventPatterns on EarTimeEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EarTimeEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EarTimeEvent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EarTimeEvent value)  $default,){
final _that = this;
switch (_that) {
case _EarTimeEvent():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EarTimeEvent value)?  $default,){
final _that = this;
switch (_that) {
case _EarTimeEvent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String canonicalDeviceId,  String deviceName,  String connectionType,  String eventType,  String? playbackState,  DateTime timestamp,  int? volumePercent,  double? attenuationDb,  String? reason,  String? earSide,  Map<String, dynamic>? earState,  String? attributionConfidence,  String? earStateSource)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EarTimeEvent() when $default != null:
return $default(_that.id,_that.canonicalDeviceId,_that.deviceName,_that.connectionType,_that.eventType,_that.playbackState,_that.timestamp,_that.volumePercent,_that.attenuationDb,_that.reason,_that.earSide,_that.earState,_that.attributionConfidence,_that.earStateSource);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String canonicalDeviceId,  String deviceName,  String connectionType,  String eventType,  String? playbackState,  DateTime timestamp,  int? volumePercent,  double? attenuationDb,  String? reason,  String? earSide,  Map<String, dynamic>? earState,  String? attributionConfidence,  String? earStateSource)  $default,) {final _that = this;
switch (_that) {
case _EarTimeEvent():
return $default(_that.id,_that.canonicalDeviceId,_that.deviceName,_that.connectionType,_that.eventType,_that.playbackState,_that.timestamp,_that.volumePercent,_that.attenuationDb,_that.reason,_that.earSide,_that.earState,_that.attributionConfidence,_that.earStateSource);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String canonicalDeviceId,  String deviceName,  String connectionType,  String eventType,  String? playbackState,  DateTime timestamp,  int? volumePercent,  double? attenuationDb,  String? reason,  String? earSide,  Map<String, dynamic>? earState,  String? attributionConfidence,  String? earStateSource)?  $default,) {final _that = this;
switch (_that) {
case _EarTimeEvent() when $default != null:
return $default(_that.id,_that.canonicalDeviceId,_that.deviceName,_that.connectionType,_that.eventType,_that.playbackState,_that.timestamp,_that.volumePercent,_that.attenuationDb,_that.reason,_that.earSide,_that.earState,_that.attributionConfidence,_that.earStateSource);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EarTimeEvent implements EarTimeEvent {
  const _EarTimeEvent({required this.id, required this.canonicalDeviceId, this.deviceName = 'Unknown Device', this.connectionType = 'bluetooth', required this.eventType, this.playbackState, required this.timestamp, this.volumePercent, this.attenuationDb, this.reason, this.earSide, final  Map<String, dynamic>? earState, this.attributionConfidence, this.earStateSource}): _earState = earState;
  factory _EarTimeEvent.fromJson(Map<String, dynamic> json) => _$EarTimeEventFromJson(json);

@override final  String id;
@override final  String canonicalDeviceId;
@override@JsonKey() final  String deviceName;
@override@JsonKey() final  String connectionType;
@override final  String eventType;
// DEVICE_CONNECTED, DEVICE_DISCONNECTED, PLAYBACK_STARTED, PLAYBACK_PAUSED, VOLUME_CHANGED (+ legacy PLAYBACK_RESUMED/STOPPED)
@override final  String? playbackState;
@override final  DateTime timestamp;
// Schema v2: volume at the time of the event (drives exposure estimates).
@override final  int? volumePercent;
@override final  double? attenuationDb;
@override final  String? reason;
// Phase 5 Optional Fields
@override final  String? earSide;
 final  Map<String, dynamic>? _earState;
@override Map<String, dynamic>? get earState {
  final value = _earState;
  if (value == null) return null;
  if (_earState is EqualUnmodifiableMapView) return _earState;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? attributionConfidence;
@override final  String? earStateSource;

/// Create a copy of EarTimeEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarTimeEventCopyWith<_EarTimeEvent> get copyWith => __$EarTimeEventCopyWithImpl<_EarTimeEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EarTimeEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EarTimeEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.canonicalDeviceId, canonicalDeviceId) || other.canonicalDeviceId == canonicalDeviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.connectionType, connectionType) || other.connectionType == connectionType)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.playbackState, playbackState) || other.playbackState == playbackState)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.volumePercent, volumePercent) || other.volumePercent == volumePercent)&&(identical(other.attenuationDb, attenuationDb) || other.attenuationDb == attenuationDb)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.earSide, earSide) || other.earSide == earSide)&&const DeepCollectionEquality().equals(other._earState, _earState)&&(identical(other.attributionConfidence, attributionConfidence) || other.attributionConfidence == attributionConfidence)&&(identical(other.earStateSource, earStateSource) || other.earStateSource == earStateSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,canonicalDeviceId,deviceName,connectionType,eventType,playbackState,timestamp,volumePercent,attenuationDb,reason,earSide,const DeepCollectionEquality().hash(_earState),attributionConfidence,earStateSource);

@override
String toString() {
  return 'EarTimeEvent(id: $id, canonicalDeviceId: $canonicalDeviceId, deviceName: $deviceName, connectionType: $connectionType, eventType: $eventType, playbackState: $playbackState, timestamp: $timestamp, volumePercent: $volumePercent, attenuationDb: $attenuationDb, reason: $reason, earSide: $earSide, earState: $earState, attributionConfidence: $attributionConfidence, earStateSource: $earStateSource)';
}


}

/// @nodoc
abstract mixin class _$EarTimeEventCopyWith<$Res> implements $EarTimeEventCopyWith<$Res> {
  factory _$EarTimeEventCopyWith(_EarTimeEvent value, $Res Function(_EarTimeEvent) _then) = __$EarTimeEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String canonicalDeviceId, String deviceName, String connectionType, String eventType, String? playbackState, DateTime timestamp, int? volumePercent, double? attenuationDb, String? reason, String? earSide, Map<String, dynamic>? earState, String? attributionConfidence, String? earStateSource
});




}
/// @nodoc
class __$EarTimeEventCopyWithImpl<$Res>
    implements _$EarTimeEventCopyWith<$Res> {
  __$EarTimeEventCopyWithImpl(this._self, this._then);

  final _EarTimeEvent _self;
  final $Res Function(_EarTimeEvent) _then;

/// Create a copy of EarTimeEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? canonicalDeviceId = null,Object? deviceName = null,Object? connectionType = null,Object? eventType = null,Object? playbackState = freezed,Object? timestamp = null,Object? volumePercent = freezed,Object? attenuationDb = freezed,Object? reason = freezed,Object? earSide = freezed,Object? earState = freezed,Object? attributionConfidence = freezed,Object? earStateSource = freezed,}) {
  return _then(_EarTimeEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,canonicalDeviceId: null == canonicalDeviceId ? _self.canonicalDeviceId : canonicalDeviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,connectionType: null == connectionType ? _self.connectionType : connectionType // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,playbackState: freezed == playbackState ? _self.playbackState : playbackState // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,volumePercent: freezed == volumePercent ? _self.volumePercent : volumePercent // ignore: cast_nullable_to_non_nullable
as int?,attenuationDb: freezed == attenuationDb ? _self.attenuationDb : attenuationDb // ignore: cast_nullable_to_non_nullable
as double?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,earSide: freezed == earSide ? _self.earSide : earSide // ignore: cast_nullable_to_non_nullable
as String?,earState: freezed == earState ? _self._earState : earState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,attributionConfidence: freezed == attributionConfidence ? _self.attributionConfidence : attributionConfidence // ignore: cast_nullable_to_non_nullable
as String?,earStateSource: freezed == earStateSource ? _self.earStateSource : earStateSource // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
