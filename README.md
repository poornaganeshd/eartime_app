# EarTime

Screen Time for your ears. EarTime runs in the background on Android and measures, in real time, how
long and how loud you listen through headphones (Bluetooth, LE Audio, hearing aids, wired and USB). It
turns that into WHO-based hearing-health guidance. It needs no microphone and no account, and all data
stays on the device.

## Features
- **Now**: today's listening against your daily goal, a live "playing for" timer, the connected
  device, volume and estimated level, and your weekly sound allowance.
- **Insights**: Today, Week, Month and Year views with an interactive chart, time-of-day breakdown,
  sound exposure (average level (Leq), peak, time above 80 dB, dose) and per-device usage.
- **History**: sessions grouped by day with a level for each playback stretch, plus the raw event log.
- **Hearing**: a live level gauge, a hearing score with advice, the 7-day WHO/ITU-T H.870 allowance,
  and a table of safe listening time at each level.
- **Background alerts** when:
  - the level stays loud for several minutes
  - you have listened for a long stretch (60/60 break reminder)
  - you reach your daily goal
  - you use up your weekly allowance
  
  A live notification shows today's time, the current level and the allowance used.
- **Reliability**: tracking survives the app being closed, the process being killed and the phone
  rebooting. History is journaled natively and then ingested idempotently.

## Development
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after editing drift/freezed sources
flutter analyze
flutter test
flutter run
```

Engineering docs: [`docs/eartime/`](docs/eartime/). Start with `HANDOFF.md`.

> Sound levels are estimates based on your media volume and a headphone calibration that you can
> adjust in Settings. They are not a medical measurement.
