# Changelog

## [Phase 7: Real-time engine, hearing health, UI redesign] - 2026-09-24
### Fixed
- A2 (route flaps), B (SYNC_STATE parsing), B4/D/E (timer after pause), G (FGS start) — see BUGS.md.
- Shared single EventChannel subscription; durable native journal; crash recovery; speaker playback
  no longer attributed to headphones; same-millisecond primary-key collisions; API 23–27 crash in
  `AudioDeviceInfo.getAddress`; diagnostics MethodChannel hang; permission gate on notifications;
  nav bar Devices tab; unreadable light theme; timer overflow; dead analytics/wellbeing screens.
### Added
- `TrackingEngine` (single-threaded), `EventJournal`, `TrackingPrefs`, `ExposureMath`, `AlertManager`,
  `BootReceiver` (native); `EventIngestor`, `LiveSessionReducer`, `ListeningAnalyzer`,
  `ExposureMath`, `AppPreferences`/settings persistence (Flutter).
- Volume tracking and WHO/ITU-T H.870 exposure dose, Leq, peak, loud time, hearing score.
- Background hearing alerts and a live foreground notification.
- New UI: Now, Insights, History, Hearing, Devices, Settings; `EarPalette` light/dark design tokens.
- 50+ new tests (reducer, sessions, analyzer, exposure, DB, end-to-end pipeline, widgets).
### Changed
- Drift schema v1 → v2 (volume columns, `app_settings` table, timestamp index) with migration.
- Dependency constraints pinned (no more `any`); unused `plugin_platform_interface` removed.
- App label "EarTime"; removed tracked Gradle build report.

## [Phase 6 Investigation] - 2026-08-19
### Identified
- **Bug A**: Transient SCO route removal causes false `DEVICE_DISCONNECTED` event.
- **Bug B**: `SYNC_STATE` JSON payload mismatch prevents Flutter from initializing with connected devices.
- **Bug D & E**: `trackingPipelineProvider` fails to set `currentPlaybackStartTime` to null on pause, causing the Live Timer to tick infinitely.
- **Bug G**: `startForegroundService` called on a restarted background service without subsequent `startForeground`, causing Android 12+ `ForegroundServiceDidNotStartInTimeException`.

### Added
- Created `test/pipeline_regression_test.dart` to simulate and assert event stream behaviors.

### Changed
- Extensive documentation updates mapping root causes.
- **Fix 1 (Test G) Part A**: Relocated `startForeground` in `AudioTrackingService.kt` to safely execute on every `onStartCommand` loop, satisfying Android 12+ foreground requirements without double-initialization.
- **Fix 1 (Test G) Part B**: Fixed `ConcurrentModificationException` during app reopen by converting `connectedDevices` to `ConcurrentHashMap` and simplifying `ACTION_SYNC_STATE` to emit the current state instead of redundantly triggering a concurrent main-thread scan.

## [Phase 6 Fixes Execution] - 2026-08-20
### Fixed
- **Fix 1 (Bug G)**: Removed early returns from `AudioTrackingService.onStartCommand` for intent actions like `ACTION_SYNC_STATE`. This ensures that `startForeground()` is unconditionally executed for any service restart on Android 12+, properly preventing `ForegroundServiceDidNotStartInTimeException` crash loops when the app is cleared from Recents.
- **Fix 1 (Bug G - SecurityException)**: Fixed Android 14+ targetSDK 36 crash (`SecurityException: Starting FGS with type connectedDevice requires permissions: android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE`) by:
  1. Adding a runtime check in `MainActivity.kt` to only automatically start the tracking service if the prerequisite `BLUETOOTH_CONNECT` permission is granted.
  2. Wrapping `startForeground()` in a try-catch block in `AudioTrackingService.kt` to gracefully call `stopSelf()` instead of crashing if the system enforces missing FGS runtime requirements.

## Permission Matrix (updated Phase 7)

| Permission | Purpose | Runtime request | Denial behaviour | Android version |
|---|---|---|---|---|
| BLUETOOTH_CONNECT | Resolve headset names/MACs, A2DP proxy, GATT; prerequisite for `connectedDevice` FGS on 14+ | `Permission.bluetoothConnect` | App gated by PermissionScreen; service not started | API 31+ |
| BLUETOOTH / BLUETOOTH_ADMIN | Legacy Bluetooth access | install-time (`maxSdkVersion=30`) | – | ≤ API 30 |
| POST_NOTIFICATIONS | Live listening notification + hearing alerts | `Permission.notification` (optional) | Tracking still works; notifications hidden | API 33+ |
| FOREGROUND_SERVICE / FOREGROUND_SERVICE_CONNECTED_DEVICE | Background monitoring service | install-time | – | API 28+ / 34+ |
| RECEIVE_BOOT_COMPLETED | Resume monitoring after reboot/update | install-time | – | all |
| BLUETOOTH_SCAN, location, microphone | **Not used** | – | – | – |
