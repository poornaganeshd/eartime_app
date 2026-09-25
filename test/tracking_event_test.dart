import 'package:eartime_app/data/event_ingestor.dart';
import 'package:eartime_app/domain/models/tracking_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackingEvent mapping', () {
    test('Should map DEVICE_CONNECTED correctly', () {
      final json = {
        'type': 'DEVICE_CONNECTED',
        'device': {
          'id': '123',
          'friendlyName': 'My Earbuds',
          'connectionType': 'bluetooth',
        },
        'timestamp': 1600000000000,
      };

      final event = TrackingEvent.fromJson(json);

      expect(event.type, 'DEVICE_CONNECTED');
      expect(event.device?['id'], '123');
      expect(event.device?['friendlyName'], 'My Earbuds');
      expect(event.device?['connectionType'], 'bluetooth');
      expect(event.timestamp, 1600000000000);
    });

    test('Should map PLAYBACK_STARTED correctly', () {
      final json = {
        'type': 'PLAYBACK_STARTED',
        'timestamp': 1600000000000,
      };

      final event = TrackingEvent.fromJson(json);

      expect(event.type, 'PLAYBACK_STARTED');
      expect(event.device, null);
      expect(event.timestamp, 1600000000000);
    });

    test('decodes platform-channel maps (Map<Object?, Object?>) at every level', () {
      final Map<Object?, Object?> raw = {
        'type': 'SYNC_STATE',
        'timestamp': 5,
        'connectedDevices': <Object?>[
          <Object?, Object?>{'id': 'A', 'friendlyName': 'Buds'},
        ],
        'volume': <Object?, Object?>{'index': 9, 'max': 15, 'percent': 60, 'attenuationDb': -17.0},
        'isPlaying': true,
      };
      final event = TrackingEvent.fromJson(TrackingEvent.deepCast(raw));
      final devices = event.raw['connectedDevices'] as List;
      expect((devices.first as Map<String, dynamic>)['friendlyName'], 'Buds');
      expect(event.volume?.percent, 60);
      expect(event.volume?.attenuationDb, -17.0);
      expect(event.raw['isPlaying'], isTrue);
    });

    test('journal identity fields are parsed', () {
      final event = TrackingEvent.fromJson({
        'type': 'PLAYBACK_PAUSED',
        'deviceId': 'A',
        'timestamp': 10,
        'seq': 42,
        'eventId': 'n-42-10',
        'reason': 'RECOVERED',
      });
      expect(event.seq, 42);
      expect(event.eventId, 'n-42-10');
      expect(event.reason, 'RECOVERED');
      expect(event.isPersistable, isTrue);
    });
  });

  group('EventIngestor.toCompanion', () {
    test('maps persistable events with volume', () {
      final row = EventIngestor.toCompanion(TrackingEvent.fromJson({
        'type': 'VOLUME_CHANGED',
        'deviceId': 'A',
        'device': {'id': 'A', 'friendlyName': 'Buds', 'connectionType': 'bluetooth'},
        'volume': {'index': 12, 'max': 15, 'percent': 80, 'attenuationDb': -8.0},
        'timestamp': 99,
        'seq': 3,
        'eventId': 'n-3-99',
      }))!;
      expect(row.id.value, 'n-3-99');
      expect(row.deviceName.value, 'Buds');
      expect(row.volumePercent.value, 80);
      expect(row.attenuationDb.value, -8.0);
      expect(row.seq.value, 3);
    });

    test('skips live-only and device-less events', () {
      expect(EventIngestor.toCompanion(TrackingEvent.fromJson({'type': 'SYNC_STATE', 'timestamp': 1})), isNull);
      expect(EventIngestor.toCompanion(TrackingEvent.fromJson({'type': 'PLAYBACK_STARTED', 'timestamp': 1})), isNull);
    });
  });
}
