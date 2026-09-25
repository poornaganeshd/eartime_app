# Test Results

## Phase 7 — automated (2026-09-24, agent environment, Flutter 3.41.2 / Dart 3.11.0)
- `flutter analyze`: **No issues found**.
- `flutter test`: **64 passed, 0 failed**.
  - `live_session_reducer_test.dart` — SYNC_STATE root fields (B), pause stops timer (B4/D/E),
    stale pause ignored, multi-device disconnect, volume & alerts.
  - `database_test.dart` — session reconstruction (volume splitting, single-listener rule,
    live-only open intervals, stable ordering, midnight), idempotent inserts, same-ms ids, settings.
  - `listening_analyzer_test.dart` — buckets, time-of-day, midnight clipping, live interval, dose/Leq/
    peak/loud time, breaks, per-device, year buckets, hearing score.
  - `exposure_math_test.dart` — WHO reference points (80 dB/40 h = 100%, 3 dB rule, 1.6 Pa²h).
  - `pipeline_regression_test.dart` — the Phase 6 matrix end-to-end through providers, ingestor
    and in-memory SQLite, incl. journal replay idempotency, offline ingestion and crash recovery.
  - `tracking_event_test.dart`, `domain_model_test.dart`, `diagnostic_test.dart`.
  - `widget_test.dart` — app boot, live events on Home, all tabs at 320×640 without overflow,
    Settings + light theme.
- Kotlin: all native sources compile (kotlinc 2.2.20, JVM 17) against Robolectric android-all
  (API 36) + Flutter embedding 1.0.0-6c0baaeb; androidx.core/lifecycle were stubbed because
  Google Maven is unreachable from the agent environment. Only pre-existing BLE deprecation warnings.
- UI rendered headlessly with real fonts (dark + light) and reviewed.

## Phase 7 — physical
- **Pending.** Run CURRENT_STATE.md §6 on the OnePlus CPH2447 / Nord Buds 3 Pro setup.

## Phase 6 Core Sync Fixes (historical)
- Environment: OnePlus CPH2447, Android 16 (API 36), OnePlus Nord Buds 3 Pro
- A: FAIL (SCO route removal) · B: FAIL (SYNC_STATE mismatch) · C: PASS · D/E: FAIL (timer) ·
  F: PASS · G: FAIL (FGS crash). All addressed in Phase 7 — see BUGS.md.

## Phase 5 BLE Discovery (historical)
- `connectGatt` / `discoverServices` succeed; OPOv1 payloads stream to the diagnostics UI.
