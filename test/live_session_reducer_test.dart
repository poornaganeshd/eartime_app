import 'package:eartime_app/domain/logic/live_session_reducer.dart';
import 'package:eartime_app/domain/models/live_session_state.dart';
import 'package:eartime_app/domain/models/playback_state.dart';
import 'package:eartime_app/domain/models/tracking_event.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_tracking_platform.dart';

TrackingEvent ev(Map<String, dynamic> raw) => TrackingEvent.fromJson(raw);

LiveSessionState run(List<Map<String, dynamic>> events, [LiveSessionState start = const LiveSessionState()]) {
  var s = start;
  for (final e in events) {
    s = LiveSessionReducer.reduce(s, ev(e));
  }
  return s;
}

void main() {
  const buds = 'AA:BB:CC:DD:EE:FF';
  const wired = 'wired_Wired_headphones';

  group('SYNC_STATE (Bug B: payload fields live at the root)', () {
    test('empty sync initialises with no device', () {
      final s = run([
        {'type': 'SYNC_STATE', 'timestamp': 1000, 'monitoring': true, 'connectedDevices': [], 'isPlaying': false},
      ]);
      expect(s.isInitialized, isTrue);
      expect(s.monitoring, isTrue);
      expect(s.activeDevice, isNull);
      expect(s.isPlaying, isFalse);
    });

    test('sync with a connected, playing device restores the live session', () {
      final s = run([
        {
          'type': 'SYNC_STATE',
          'timestamp': 5000,
          'monitoring': true,
          'connectedDevices': [device(buds)],
          'activeDeviceId': buds,
          'isPlaying': true,
          'playbackStartedAt': 2000,
          'volume': volume(60, -17),
        },
      ]);
      expect(s.activeDevice?.displayName, 'Nord Buds 3 Pro');
      expect(s.activeDevice?.playbackState, PlaybackState.playing);
      expect(s.isPlaying, isTrue);
      expect(s.playbackStartedAt, DateTime.fromMillisecondsSinceEpoch(2000));
      expect(s.volume?.percent, 60);
    });

    test('service not running reports monitoring=false', () {
      final s = run([
        {'type': 'SYNC_STATE', 'timestamp': 1, 'monitoring': false, 'connectedDevices': [], 'isPlaying': false},
      ]);
      expect(s.monitoring, isFalse);
    });
  });

  group('playback (Bugs B4/D/E: timer must stop on pause)', () {
    test('connect -> play -> pause clears the running interval', () {
      final s = run([
        {'type': 'DEVICE_CONNECTED', 'deviceId': buds, 'device': device(buds), 'timestamp': 1000},
        {'type': 'PLAYBACK_STARTED', 'deviceId': buds, 'device': device(buds), 'timestamp': 2000},
        {'type': 'PLAYBACK_PAUSED', 'deviceId': buds, 'device': device(buds), 'timestamp': 9000},
      ]);
      expect(s.isPlaying, isFalse);
      expect(s.playbackStartedAt, isNull);
      expect(s.currentIntervalAt(DateTime.fromMillisecondsSinceEpoch(20000)), Duration.zero);
      expect(s.activeDevice?.playbackState, PlaybackState.paused);
      expect(s.activeDevice?.currentPlaybackStartTime, isNull);
    });

    test('resume starts a fresh interval', () {
      final s = run([
        {'type': 'DEVICE_CONNECTED', 'deviceId': buds, 'device': device(buds), 'timestamp': 1000},
        {'type': 'PLAYBACK_STARTED', 'deviceId': buds, 'timestamp': 2000},
        {'type': 'PLAYBACK_PAUSED', 'deviceId': buds, 'timestamp': 3000},
        {'type': 'PLAYBACK_STARTED', 'deviceId': buds, 'timestamp': 7000},
      ]);
      expect(s.isPlaying, isTrue);
      expect(s.playbackStartedAt, DateTime.fromMillisecondsSinceEpoch(7000));
      expect(s.currentIntervalAt(DateTime.fromMillisecondsSinceEpoch(10000)), const Duration(seconds: 3));
    });

    test('a duplicate STARTED for the same device keeps the original start', () {
      final s = run([
        {'type': 'PLAYBACK_STARTED', 'deviceId': buds, 'timestamp': 2000},
        {'type': 'PLAYBACK_STARTED', 'deviceId': buds, 'timestamp': 4000},
      ]);
      expect(s.playbackStartedAt, DateTime.fromMillisecondsSinceEpoch(2000));
    });

    test('playback without a routed headset is ignored', () {
      final s = run([
        {'type': 'PLAYBACK_STARTED', 'timestamp': 2000},
      ]);
      expect(s.isPlaying, isFalse);
    });

    test('a stale pause for a non-active device does not stop playback', () {
      final s = run([
        {'type': 'DEVICE_CONNECTED', 'deviceId': buds, 'device': device(buds), 'timestamp': 1000},
        {'type': 'DEVICE_CONNECTED', 'deviceId': wired, 'device': device(wired, name: 'Wired', type: 'wired'), 'timestamp': 1500},
        {'type': 'PLAYBACK_STARTED', 'deviceId': wired, 'timestamp': 2000},
        {'type': 'PLAYBACK_PAUSED', 'deviceId': buds, 'timestamp': 2500},
      ]);
      expect(s.isPlaying, isTrue);
      expect(s.activeDeviceId, wired);
    });
  });

  group('devices', () {
    test('disconnecting one device keeps the other connected', () {
      final s = run([
        {'type': 'DEVICE_CONNECTED', 'deviceId': buds, 'device': device(buds), 'timestamp': 1000},
        {'type': 'DEVICE_CONNECTED', 'deviceId': wired, 'device': device(wired, name: 'Wired', type: 'wired'), 'timestamp': 2000},
        {'type': 'DEVICE_DISCONNECTED', 'deviceId': wired, 'timestamp': 3000},
      ]);
      expect(s.connectedDevices.map((d) => d.canonicalDeviceId), [buds]);
      expect(s.activeDeviceId, buds);
    });

    test('disconnecting the playing device stops playback', () {
      final s = run([
        {'type': 'DEVICE_CONNECTED', 'deviceId': buds, 'device': device(buds), 'timestamp': 1000},
        {'type': 'PLAYBACK_STARTED', 'deviceId': buds, 'timestamp': 2000},
        {'type': 'DEVICE_DISCONNECTED', 'deviceId': buds, 'timestamp': 3000},
      ]);
      expect(s.hasDevice, isFalse);
      expect(s.isPlaying, isFalse);
      expect(s.playbackStartedAt, isNull);
    });

    test('reconnecting the same id does not duplicate it', () {
      final s = run([
        {'type': 'DEVICE_CONNECTED', 'deviceId': buds, 'device': device(buds), 'timestamp': 1000},
        {'type': 'DEVICE_CONNECTED', 'deviceId': buds, 'device': device(buds), 'timestamp': 2000},
      ]);
      expect(s.connectedDevices, hasLength(1));
    });

    test('volume changes update the live volume', () {
      final s = run([
        {'type': 'VOLUME_CHANGED', 'deviceId': buds, 'volume': volume(80, -8), 'timestamp': 1000},
      ]);
      expect(s.volume?.percent, 80);
      expect(s.volume?.attenuationDb, -8);
    });

    test('hearing alerts are surfaced', () {
      final s = run([
        {'type': 'HEARING_ALERT', 'kind': 'loud', 'message': 'Too loud', 'timestamp': 1000},
      ]);
      expect(s.lastAlert, 'Too loud');
    });
  });
}
