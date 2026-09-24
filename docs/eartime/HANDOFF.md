# EarTime Project Handoff

Start here, then read CURRENT_STATE.md, NATIVE_FLUTTER_CONTRACT.md and BUGS.md.

## 1. What is EarTime?
A passive, real-time headphone listening tracker. A native Android foreground service watches audio
routing, playback and volume; Flutter shows live listening time, sessions, analytics and WHO-based
hearing-exposure guidance. Everything stays on the device.

## 2. What is implemented (Phase 7)
- Single-threaded native `TrackingEngine`: route ref-counting (A2 fix), `isMusicActive` playback
  truth (B4/D/E fix), media-routing attribution, volume → dB estimate, exposure dose, 5 s reconcile
  tick, heartbeat + crash recovery, boot restart, live notification, hearing alerts
  (loud ≥ threshold for 3 min, 60/60 break reminder, daily goal, weekly allowance).
- Durable native journal + idempotent Flutter ingestion (no event loss when the UI is closed).
- Drift schema v2 (volume columns, settings table, index) with a proper migration from v1.
- Pure, tested domain logic: `LiveSessionReducer`, `SessionManager`, `ListeningAnalyzer`, `ExposureMath`.
- Redesigned UI (light + dark): Now, Insights (Today/Week/Month/Year), History (sessions + events),
  Hearing (live gauge, score, weekly dose, safe-time table), Devices, Settings (monitoring, calibration,
  alerts, goal, theme, CSV export, clear data, developer diagnostics).

## 3. How to build & test
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after changing freezed/drift sources
flutter analyze        # must report no issues
flutter test           # 64 tests: reducer, sessions, analyzer, exposure, DB, pipeline, widgets
flutter run            # on an Android device (minSdk = Flutter default, target/compile 36)
```

## 4. What still needs a human
- Physical verification of the test matrix in CURRENT_STATE.md §6 (no device/SDK in the agent
  environment; Kotlin was compile-checked against android-all API 36 only).
- Optional: per-headset calibration presets for `maxOutputDb`.

## 5. Where things live
See CURRENT_STATE.md §4–5. Protocol: NATIVE_FLUTTER_CONTRACT.md. Decisions: DECISIONS.md.

## 6. Rules
- Don't reintroduce a second `receiveBroadcastStream()` — use `trackingPlatformProvider`.
- Don't write history from the live stream — only `EventIngestor` writes events.
- Keep `ExposureMath.kt` and `exposure_math.dart` identical.
- Don't infer per-ear state from uninterpreted BLE packets.

**FUTURE ENGINEERING RULE**: Every future feature, bug fix, architectural change, protocol change, state-model change, test, or important engineering discovery MUST update the persistent engineering documentation (including `CURRENT_STATE.md`, `TEST_RESULTS.md`, `BUGS.md`, and this `HANDOFF.md`) in the same implementation task.
