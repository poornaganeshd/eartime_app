// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listening_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaybackInterval {

 DateTime get startTime; DateTime? get endTime;/// Volume-curve attenuation (dB, ≤ 0) during this interval; null for legacy data.
 double? get attenuationDb;
/// Create a copy of PlaybackInterval
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackIntervalCopyWith<PlaybackInterval> get copyWith => _$PlaybackIntervalCopyWithImpl<PlaybackInterval>(this as PlaybackInterval, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackInterval&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.attenuationDb, attenuationDb) || other.attenuationDb == attenuationDb));
}


@override
int get hashCode => Object.hash(runtimeType,startTime,endTime,attenuationDb);

@override
String toString() {
  return 'PlaybackInterval(startTime: $startTime, endTime: $endTime, attenuationDb: $attenuationDb)';
}


}

/// @nodoc
abstract mixin class $PlaybackIntervalCopyWith<$Res>  {
  factory $PlaybackIntervalCopyWith(PlaybackInterval value, $Res Function(PlaybackInterval) _then) = _$PlaybackIntervalCopyWithImpl;
@useResult
$Res call({
 DateTime startTime, DateTime? endTime, double? attenuationDb
});




}
/// @nodoc
class _$PlaybackIntervalCopyWithImpl<$Res>
    implements $PlaybackIntervalCopyWith<$Res> {
  _$PlaybackIntervalCopyWithImpl(this._self, this._then);

  final PlaybackInterval _self;
  final $Res Function(PlaybackInterval) _then;

/// Create a copy of PlaybackInterval
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startTime = null,Object? endTime = freezed,Object? attenuationDb = freezed,}) {
  return _then(_self.copyWith(
startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,attenuationDb: freezed == attenuationDb ? _self.attenuationDb : attenuationDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackInterval].
extension PlaybackIntervalPatterns on PlaybackInterval {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackInterval value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackInterval() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackInterval value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackInterval():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackInterval value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackInterval() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime startTime,  DateTime? endTime,  double? attenuationDb)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackInterval() when $default != null:
return $default(_that.startTime,_that.endTime,_that.attenuationDb);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime startTime,  DateTime? endTime,  double? attenuationDb)  $default,) {final _that = this;
switch (_that) {
case _PlaybackInterval():
return $default(_that.startTime,_that.endTime,_that.attenuationDb);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime startTime,  DateTime? endTime,  double? attenuationDb)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackInterval() when $default != null:
return $default(_that.startTime,_that.endTime,_that.attenuationDb);case _:
  return null;

}
}

}

/// @nodoc


class _PlaybackInterval extends PlaybackInterval {
  const _PlaybackInterval({required this.startTime, this.endTime, this.attenuationDb}): super._();
  

@override final  DateTime startTime;
@override final  DateTime? endTime;
/// Volume-curve attenuation (dB, ≤ 0) during this interval; null for legacy data.
@override final  double? attenuationDb;

/// Create a copy of PlaybackInterval
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackIntervalCopyWith<_PlaybackInterval> get copyWith => __$PlaybackIntervalCopyWithImpl<_PlaybackInterval>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackInterval&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.attenuationDb, attenuationDb) || other.attenuationDb == attenuationDb));
}


@override
int get hashCode => Object.hash(runtimeType,startTime,endTime,attenuationDb);

@override
String toString() {
  return 'PlaybackInterval(startTime: $startTime, endTime: $endTime, attenuationDb: $attenuationDb)';
}


}

/// @nodoc
abstract mixin class _$PlaybackIntervalCopyWith<$Res> implements $PlaybackIntervalCopyWith<$Res> {
  factory _$PlaybackIntervalCopyWith(_PlaybackInterval value, $Res Function(_PlaybackInterval) _then) = __$PlaybackIntervalCopyWithImpl;
@override @useResult
$Res call({
 DateTime startTime, DateTime? endTime, double? attenuationDb
});




}
/// @nodoc
class __$PlaybackIntervalCopyWithImpl<$Res>
    implements _$PlaybackIntervalCopyWith<$Res> {
  __$PlaybackIntervalCopyWithImpl(this._self, this._then);

  final _PlaybackInterval _self;
  final $Res Function(_PlaybackInterval) _then;

/// Create a copy of PlaybackInterval
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startTime = null,Object? endTime = freezed,Object? attenuationDb = freezed,}) {
  return _then(_PlaybackInterval(
startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,attenuationDb: freezed == attenuationDb ? _self.attenuationDb : attenuationDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$ListeningSession {

 String get id; String get canonicalDeviceId; String get deviceName; String get connectionType; DateTime get connectTime; DateTime? get disconnectTime; List<PlaybackInterval> get intervals; bool get isPlaying; bool get isDisconnected;
/// Create a copy of ListeningSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListeningSessionCopyWith<ListeningSession> get copyWith => _$ListeningSessionCopyWithImpl<ListeningSession>(this as ListeningSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListeningSession&&(identical(other.id, id) || other.id == id)&&(identical(other.canonicalDeviceId, canonicalDeviceId) || other.canonicalDeviceId == canonicalDeviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.connectionType, connectionType) || other.connectionType == connectionType)&&(identical(other.connectTime, connectTime) || other.connectTime == connectTime)&&(identical(other.disconnectTime, disconnectTime) || other.disconnectTime == disconnectTime)&&const DeepCollectionEquality().equals(other.intervals, intervals)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isDisconnected, isDisconnected) || other.isDisconnected == isDisconnected));
}


@override
int get hashCode => Object.hash(runtimeType,id,canonicalDeviceId,deviceName,connectionType,connectTime,disconnectTime,const DeepCollectionEquality().hash(intervals),isPlaying,isDisconnected);

@override
String toString() {
  return 'ListeningSession(id: $id, canonicalDeviceId: $canonicalDeviceId, deviceName: $deviceName, connectionType: $connectionType, connectTime: $connectTime, disconnectTime: $disconnectTime, intervals: $intervals, isPlaying: $isPlaying, isDisconnected: $isDisconnected)';
}


}

/// @nodoc
abstract mixin class $ListeningSessionCopyWith<$Res>  {
  factory $ListeningSessionCopyWith(ListeningSession value, $Res Function(ListeningSession) _then) = _$ListeningSessionCopyWithImpl;
@useResult
$Res call({
 String id, String canonicalDeviceId, String deviceName, String connectionType, DateTime connectTime, DateTime? disconnectTime, List<PlaybackInterval> intervals, bool isPlaying, bool isDisconnected
});




}
/// @nodoc
class _$ListeningSessionCopyWithImpl<$Res>
    implements $ListeningSessionCopyWith<$Res> {
  _$ListeningSessionCopyWithImpl(this._self, this._then);

  final ListeningSession _self;
  final $Res Function(ListeningSession) _then;

/// Create a copy of ListeningSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? canonicalDeviceId = null,Object? deviceName = null,Object? connectionType = null,Object? connectTime = null,Object? disconnectTime = freezed,Object? intervals = null,Object? isPlaying = null,Object? isDisconnected = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,canonicalDeviceId: null == canonicalDeviceId ? _self.canonicalDeviceId : canonicalDeviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,connectionType: null == connectionType ? _self.connectionType : connectionType // ignore: cast_nullable_to_non_nullable
as String,connectTime: null == connectTime ? _self.connectTime : connectTime // ignore: cast_nullable_to_non_nullable
as DateTime,disconnectTime: freezed == disconnectTime ? _self.disconnectTime : disconnectTime // ignore: cast_nullable_to_non_nullable
as DateTime?,intervals: null == intervals ? _self.intervals : intervals // ignore: cast_nullable_to_non_nullable
as List<PlaybackInterval>,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isDisconnected: null == isDisconnected ? _self.isDisconnected : isDisconnected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ListeningSession].
extension ListeningSessionPatterns on ListeningSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListeningSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListeningSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListeningSession value)  $default,){
final _that = this;
switch (_that) {
case _ListeningSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListeningSession value)?  $default,){
final _that = this;
switch (_that) {
case _ListeningSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String canonicalDeviceId,  String deviceName,  String connectionType,  DateTime connectTime,  DateTime? disconnectTime,  List<PlaybackInterval> intervals,  bool isPlaying,  bool isDisconnected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListeningSession() when $default != null:
return $default(_that.id,_that.canonicalDeviceId,_that.deviceName,_that.connectionType,_that.connectTime,_that.disconnectTime,_that.intervals,_that.isPlaying,_that.isDisconnected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String canonicalDeviceId,  String deviceName,  String connectionType,  DateTime connectTime,  DateTime? disconnectTime,  List<PlaybackInterval> intervals,  bool isPlaying,  bool isDisconnected)  $default,) {final _that = this;
switch (_that) {
case _ListeningSession():
return $default(_that.id,_that.canonicalDeviceId,_that.deviceName,_that.connectionType,_that.connectTime,_that.disconnectTime,_that.intervals,_that.isPlaying,_that.isDisconnected);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String canonicalDeviceId,  String deviceName,  String connectionType,  DateTime connectTime,  DateTime? disconnectTime,  List<PlaybackInterval> intervals,  bool isPlaying,  bool isDisconnected)?  $default,) {final _that = this;
switch (_that) {
case _ListeningSession() when $default != null:
return $default(_that.id,_that.canonicalDeviceId,_that.deviceName,_that.connectionType,_that.connectTime,_that.disconnectTime,_that.intervals,_that.isPlaying,_that.isDisconnected);case _:
  return null;

}
}

}

/// @nodoc


class _ListeningSession extends ListeningSession {
  const _ListeningSession({required this.id, required this.canonicalDeviceId, required this.deviceName, this.connectionType = 'bluetooth', required this.connectTime, this.disconnectTime, required final  List<PlaybackInterval> intervals, this.isPlaying = false, this.isDisconnected = false}): _intervals = intervals,super._();
  

@override final  String id;
@override final  String canonicalDeviceId;
@override final  String deviceName;
@override@JsonKey() final  String connectionType;
@override final  DateTime connectTime;
@override final  DateTime? disconnectTime;
 final  List<PlaybackInterval> _intervals;
@override List<PlaybackInterval> get intervals {
  if (_intervals is EqualUnmodifiableListView) return _intervals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_intervals);
}

@override@JsonKey() final  bool isPlaying;
@override@JsonKey() final  bool isDisconnected;

/// Create a copy of ListeningSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListeningSessionCopyWith<_ListeningSession> get copyWith => __$ListeningSessionCopyWithImpl<_ListeningSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListeningSession&&(identical(other.id, id) || other.id == id)&&(identical(other.canonicalDeviceId, canonicalDeviceId) || other.canonicalDeviceId == canonicalDeviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.connectionType, connectionType) || other.connectionType == connectionType)&&(identical(other.connectTime, connectTime) || other.connectTime == connectTime)&&(identical(other.disconnectTime, disconnectTime) || other.disconnectTime == disconnectTime)&&const DeepCollectionEquality().equals(other._intervals, _intervals)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isDisconnected, isDisconnected) || other.isDisconnected == isDisconnected));
}


@override
int get hashCode => Object.hash(runtimeType,id,canonicalDeviceId,deviceName,connectionType,connectTime,disconnectTime,const DeepCollectionEquality().hash(_intervals),isPlaying,isDisconnected);

@override
String toString() {
  return 'ListeningSession(id: $id, canonicalDeviceId: $canonicalDeviceId, deviceName: $deviceName, connectionType: $connectionType, connectTime: $connectTime, disconnectTime: $disconnectTime, intervals: $intervals, isPlaying: $isPlaying, isDisconnected: $isDisconnected)';
}


}

/// @nodoc
abstract mixin class _$ListeningSessionCopyWith<$Res> implements $ListeningSessionCopyWith<$Res> {
  factory _$ListeningSessionCopyWith(_ListeningSession value, $Res Function(_ListeningSession) _then) = __$ListeningSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String canonicalDeviceId, String deviceName, String connectionType, DateTime connectTime, DateTime? disconnectTime, List<PlaybackInterval> intervals, bool isPlaying, bool isDisconnected
});




}
/// @nodoc
class __$ListeningSessionCopyWithImpl<$Res>
    implements _$ListeningSessionCopyWith<$Res> {
  __$ListeningSessionCopyWithImpl(this._self, this._then);

  final _ListeningSession _self;
  final $Res Function(_ListeningSession) _then;

/// Create a copy of ListeningSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? canonicalDeviceId = null,Object? deviceName = null,Object? connectionType = null,Object? connectTime = null,Object? disconnectTime = freezed,Object? intervals = null,Object? isPlaying = null,Object? isDisconnected = null,}) {
  return _then(_ListeningSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,canonicalDeviceId: null == canonicalDeviceId ? _self.canonicalDeviceId : canonicalDeviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,connectionType: null == connectionType ? _self.connectionType : connectionType // ignore: cast_nullable_to_non_nullable
as String,connectTime: null == connectTime ? _self.connectTime : connectTime // ignore: cast_nullable_to_non_nullable
as DateTime,disconnectTime: freezed == disconnectTime ? _self.disconnectTime : disconnectTime // ignore: cast_nullable_to_non_nullable
as DateTime?,intervals: null == intervals ? _self._intervals : intervals // ignore: cast_nullable_to_non_nullable
as List<PlaybackInterval>,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isDisconnected: null == isDisconnected ? _self.isDisconnected : isDisconnected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
