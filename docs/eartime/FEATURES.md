# Features

## Implemented (Phase 7) — automated tests pass, device verification pending
- **Passive real-time tracking** of Bluetooth (A2DP, LE Audio), hearing aids, wired and USB headphones.
- **Accurate play/pause detection** (`isMusicActive` + routing), only counting audio that actually
  reaches the headphones.
- **Crash-safe history**: native journal, idempotent ingestion, recovery after process death,
  restart after reboot.
- **Live dashboard (Now)**: today's ring vs. daily goal, live "playing for" timer, device, volume,
  estimated dB with safety label, weekly allowance, today's sessions/longest/breaks, recent sessions.
- **Insights**: Today / Week / Month / Year totals, daily average, interactive column chart,
  sessions, average and longest stretch, time-of-day, sound exposure (Leq, peak, time ≥ 80 dB, dose),
  per-device breakdown.
- **History**: sessions grouped by day with per-stretch level detail; raw event log.
- **Hearing**: live level gauge, hearing score with the single most useful recommendation,
  7-day WHO sound allowance with daily dose chart, safe-time-per-level table.
- **Background hearing alerts**: sustained loud listening, 60/60 break reminder, daily goal,
  weekly allowance reached. Live foreground notification with today's time, level and allowance.
- **Devices**: connected now + last-30-day device list with listening time.
- **Settings**: monitoring on/off, battery-reliability shortcut, notification permission,
  headphone calibration, alert threshold, break reminder, daily goal, theme, CSV export, clear history.
- **Developer diagnostics**: live pipeline state, audio routing, BLE GATT/OPOv1 observation.

## Planned
- **Phase 5: Per-ear detection** — decode OPOv1 packets (left/right/in-ear).
- Per-headset calibration presets.
