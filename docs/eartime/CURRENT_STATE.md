# EarTime: Current State & Project Memory

## 1. Project Identity
**EarTime** — "Screen Time for your ears". A Flutter + native Android app that measures, in real
time and in the background, how long and how loud you listen through headphones (Bluetooth,
LE Audio, hearing aids, wired, USB), and turns it into WHO-based hearing-health guidance.

## 2. Current Phase
**Phase 7 — Real-time engine rewrite, hearing health, UI redesign** (branch
`claude/app-audit-realtime-hearing-9du4r4`). All Phase 6 bugs (A2, B, B4, D, E, G) have root-cause
fixes in code and automated regression tests. **Physical re-verification on device is still
required** (see §8).

## 3. Architecture (summary — details in ARCHITECTURE.md)
```
Android OS signals ──► TrackingEngine (HandlerThread, single-threaded state machine)
   AudioDeviceCallback     │  route ref-counting + 1.5 s disconnect debounce
   AudioPlaybackCallback   │  isMusicActive() truth + settle/reconcile + 5 s tick
   Settings observer +     │  volume → estimated dB → exposure dose
   VOLUME_CHANGED bcast    │  heartbeat + crash recovery, alerts, live notification
                           ▼
          EventJournal (jsonl, durable)  ──►  TrackingEventBroker ──► EventChannel
                           │                                            │
                 getJournal/ackJournal                    LiveSessionReducer (live UI)
                           ▼
              EventIngestor ──► Drift SQLite (schema v2) ──► SessionManager ──► ListeningAnalyzer ──► UI
```

## 4. Native Android files
- `MainActivity.kt` — channels, auto-start (if enabled + permitted), journal access, settings.
- `tracking/AudioTrackingService.kt` — foreground service host; owns the engine thread.
- `tracking/TrackingEngine.kt` — all tracking logic (devices, playback, routing, volume, exposure, recovery, alerts).
- `tracking/AudioDeviceDetector.kt` — route classification + logical device model + name resolution.
- `tracking/ExposureMath.kt` — WHO dose model (mirrors Dart).
- `tracking/EventJournal.kt`, `TrackingPrefs.kt`, `JsonUtil.kt` — durability & settings.
- `tracking/AlertManager.kt` — live FGS notification + hearing alerts.
- `tracking/BootReceiver.kt` — restart monitoring after reboot/app update.
- `tracking/TrackingEventBroker.kt` — thread-safe, bounded EventChannel bridge.
- `tracking/BleDiscoveryManager.kt`, `AudioDiagnosticHelper.kt` — diagnostics (BLE logic unchanged except `close()`).

## 5. Flutter files
- `data/tracking_platform.dart` — single shared event stream + method wrappers (injectable).
- `data/event_ingestor.dart` — journal → SQLite.
- `data/database/*` — Drift schema v2 (volume columns, settings table, timestamp index).
- `domain/logic/live_session_reducer.dart` — pure live-state reducer.
- `domain/logic/session_manager.dart` — sessions from events (volume-split intervals).
- `domain/logic/listening_analyzer.dart` — stats, buckets, dose, Leq, breaks, health score.
- `domain/logic/exposure_math.dart` — WHO model.
- `providers/data_providers.dart`, `settings_provider.dart`, `permission_provider.dart`.
- `features/*` — Now, Insights, History, Hearing, Devices, Settings, Permission, diagnostics.
- `core/theme/*` — `EarPalette` design tokens (light + dark), typography; `core/format.dart`.

## 6. Physical Test Matrix — expected after Phase 7 (needs device verification)
| Test | Action | Expected |
|---|---|---|
| A1 | Launch with earbuds disconnected | "No headphones" |
| A2 | Connect earbuds without playback | Device appears and **stays** (SCO flap absorbed) |
| A4 | Disconnect | Device removed after ~1.5 s, session closed |
| B1/B2 | Reopen app while connected/playing | State restored from SYNC_STATE |
| B4/D/E | Pause / resume | Timer stops on pause; resumes from accumulated total |
| F | Midnight crossing | Today's total splits at midnight |
| G | Reopen / swipe from Recents | No FGS crash |
| H (new) | Play on phone speaker with buds connected (API 33+) | Not counted |
| I (new) | Kill app process while playing, reopen later | Session closed at last heartbeat (reason RECOVERED) |
| J (new) | Change volume while playing | Live level updates; exposure recomputed |
| K (new) | Reboot phone | Monitoring resumes without opening the app |

## 7. Known limitations
- Sound levels are **estimates** (volume curve + calibration), not measured SPL.
- `isMusicActive` covers STREAM_MUSIC (media, games, video); calls are not counted.
- Pre-API-33 routing uses "most recently connected headset" (Android's own default).
- OEM battery managers can still kill the FGS; Settings → "Keep tracking reliable" guides the user.
- No Android SDK in the CI/agent environment: Kotlin was type-checked against android-all (API 36)
  + the Flutter embedding jar with androidx stubs, but no APK was built in this session.

## 8. Next steps
1. Build on a device (`flutter run`), run the test matrix in §6, record results in TEST_RESULTS.md.
2. Calibrate `maxOutputDb` defaults per popular headset models (optional per-device calibration).
3. Phase 5 (per-ear BLE decoding) can resume on top of the new engine.

## 9. Constraints still in force
- Tracking must stay passive (no manual start/stop for normal use).
- Never fabricate per-ear data from uninterpreted BLE packets.
- Keep `ExposureMath.kt` and `exposure_math.dart` identical.
- Every change must update these docs (FUTURE ENGINEERING RULE below).

---
**FUTURE ENGINEERING RULE**: Every future feature, bug fix, architectural change, protocol change, state-model change, test, or important engineering discovery MUST update the persistent engineering documentation in the same implementation task. The documentation must contain enough information that the project can be handed to another AI agent after the conversation reaches its chat limit.
