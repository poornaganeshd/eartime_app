# Architectural & Engineering Decisions

## 1. Deprecating `activeDeviceProvider` for `LiveSessionNotifier`
- **Context**: We previously relied on the SQLite event history (`activeDeviceProvider`) to determine what the Home screen should display.
- **Problem**: If the app was killed while a session was active, and the earbuds were disconnected while the app was dead, reopening the app resulted in it falsely pulling the last historical "PAUSED" state and displaying it as currently active.
- **Decision**: Home screen now completely ignores the DB for its live state. It uses `LiveSessionNotifier`, a purely memory-bound state that is initialized by an explicit `SYNC_STATE` native event upon app startup.

## 2. AudioDeviceDetector Name Resolution
- **Context**: Android `AudioManager` occasionally reports Bluetooth headphones using the phone's hardware model (e.g., `CPH2447`) as the generic route name.
- **Decision**: Modified `AudioDeviceDetector.kt` to prefer the `fallbackName` injected via `BluetoothA2dp` proxy. We prioritize the true Bluetooth identity over the internal AudioManager product name.

## 3. Background Thread Initialization
- **Context**: During startup, attempting to enumerate devices on the main UI thread occasionally caused application freeze/ANR when the user cleared the app from Recents.
- **Decision**: Initial audio state scanning in `AudioTrackingService` is heavily deferred to a background thread.

## 4. (Phase 7) Native engine is the source of truth; Flutter ingests a journal
- **Context**: Flutter wrote history from live events only while its engine was alive; closing the
  UI or a process death lost events and left sessions open forever.
- **Decision**: The native `TrackingEngine` journals every persistable transition before publishing
  it. Flutter's `EventIngestor` drains and acknowledges the journal; inserts are idempotent.
  Supersedes Decision 3 (background thread): all engine work now runs on one HandlerThread.

## 5. (Phase 7) `isMusicActive()` instead of "playback configs not empty"
- **Context**: `AudioPlaybackCallback` delivers every registered player, including paused/idle ones,
  and the player state getter is a hidden API.
- **Decision**: Treat the callback as a *change hint*; truth is `AudioManager.isMusicActive()`
  evaluated after a 350 ms settle, re-checked at 2 s and on a 5 s tick. Count only media routed to a
  tracked headset (`getAudioDevicesForAttributes` on API 33+).

## 6. (Phase 7) Route reference counting + disconnect debounce
- **Decision**: A logical headset (MAC) owns a set of route ids; it disconnects only after the set
  has been empty for 1.5 s. Fixes A2 and absorbs codec/profile reconfiguration flaps.

## 7. (Phase 7) Estimated exposure per WHO/ITU-T H.870
- **Decision**: No microphone. Estimate dB(A) from `getStreamVolumeDb` (device-specific curve) plus a
  user-calibratable headphone maximum (default 100 dB). Dose = hours / (40 h × 10^((80−L)/10)).
  The same maths runs natively (alerts, notification) and in Dart (UI) — keep them identical.

## 8. (Phase 7) Drift schema v2
- Added nullable volume columns, `app_settings` table and a timestamp index with an explicit
  migration. Supersedes the earlier "do not modify the schema" constraint, which was a freeze for
  the Phase 6 investigation.

## 9. (Phase 7) Design system in code
- `EarPalette` ThemeExtension with light and dark tokens; status colours validated for colour-vision
  deficiency and always paired with text. No Figma source file exists for this project; if one is
  created, map its variables onto `EarPalette`.
