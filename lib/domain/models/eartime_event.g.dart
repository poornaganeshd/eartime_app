// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eartime_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarTimeEvent _$EarTimeEventFromJson(Map<String, dynamic> json) =>
    _EarTimeEvent(
      id: json['id'] as String,
      canonicalDeviceId: json['canonicalDeviceId'] as String,
      deviceName: json['deviceName'] as String? ?? 'Unknown Device',
      connectionType: json['connectionType'] as String? ?? 'bluetooth',
      eventType: json['eventType'] as String,
      playbackState: json['playbackState'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      volumePercent: (json['volumePercent'] as num?)?.toInt(),
      attenuationDb: (json['attenuationDb'] as num?)?.toDouble(),
      reason: json['reason'] as String?,
      earSide: json['earSide'] as String?,
      earState: json['earState'] as Map<String, dynamic>?,
      attributionConfidence: json['attributionConfidence'] as String?,
      earStateSource: json['earStateSource'] as String?,
    );

Map<String, dynamic> _$EarTimeEventToJson(_EarTimeEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'canonicalDeviceId': instance.canonicalDeviceId,
      'deviceName': instance.deviceName,
      'connectionType': instance.connectionType,
      'eventType': instance.eventType,
      'playbackState': instance.playbackState,
      'timestamp': instance.timestamp.toIso8601String(),
      'volumePercent': instance.volumePercent,
      'attenuationDb': instance.attenuationDb,
      'reason': instance.reason,
      'earSide': instance.earSide,
      'earState': instance.earState,
      'attributionConfidence': instance.attributionConfidence,
      'earStateSource': instance.earStateSource,
    };
