# Architecture

## Layers

### 1. Native Android — real-time engine
- **`AudioTrackingService`** (foreground service, type `connectedDevice`) hosts a dedicated
  `HandlerThread` ("EarTimeEngine"). `startForeground` runs on every `onStartCommand`.
- **`TrackingEngine`** owns *all* mutable tracking state on that one thread:
  - *Devices*: `AudioDeviceCallback` (registered with the engine handler). Each logical headset keeps
    a set of route ids; it disconnects only when the set is empty for 1.5 s.
  - *Playback*: `AudioPlaybackCallback` schedules an evaluation 350 ms and 2 s later; the evaluation
    uses `AudioManager.isMusicActive()` and the media route (`getAudioDevicesForAttributes`, API 33+).
    A 5 s tick (30 s when idle-but-connected) reconciles missed transitions and accounts exposure.
  - *Volume*: Settings ContentObserver + `VOLUME_CHANGED_ACTION` receiver → `ExposureMath.sampleVolume`.
  - *Durability*: every transition → `EventJournal` → broker. Heartbeat saved to `TrackingPrefs`;
    on start, state from a dead process is reconciled (resume if < 2 min gap and still true,
    otherwise close at the last heartbeat with reason `RECOVERED`).
  - *Alerts & notification*: `AlertManager` (live FGS notification, hearing alerts).
- **`BootReceiver`** restarts monitoring after reboot / update if enabled.

### 2. Bridge
- `TrackingEventBroker` (main-thread delivery, bounded 200-event buffer while detached).
- `MainActivity` method channel (see contract).

### 3. Flutter
- **Live state**: `LiveSessionNotifier` applies `LiveSessionReducer` to the shared event stream.
- **History**: `EventIngestor` drains the journal into Drift (`INSERT OR IGNORE`).
- **Derived data** (pure functions, recomputed reactively):
  `eventsProvider(range)` → `SessionManager.reconstruct` (intervals split at volume changes; open
  intervals only stay open for the live device) → `ListeningAnalyzer.compute` (totals, buckets,
  time-of-day, devices, breaks, dose, Leq, peak) → `hearingInsightProvider` (score + advice).
- **Clock**: `clockProvider` ticks 1 s while playing, 30 s otherwise.
- **Settings**: `SettingsNotifier` persists to the `app_settings` table and mirrors hearing values
  to native (`updateSettings`).

## Event flow
```
OS callbacks → TrackingEngine → EventJournal ─┬─► (drain) EventIngestor → SQLite → sessions → stats → UI
                                              └─► Broker → EventChannel → LiveSessionReducer → live UI
```

## UI system
- `EarPalette` ThemeExtension (dark + light tokens); status colours validated for colour-blind
  separation and always paired with a text label.
- Shared components: `TabPage`, `LiquidGlassSurface` (blur opt-in for performance), `ProgressRing`,
  `LevelGauge`, `ColumnChart` (tap/drag inspect, semantics summary), `AllowanceMeter`,
  `StatusIndicator`, `EditorialMetric`, `GlassNavigation`.
