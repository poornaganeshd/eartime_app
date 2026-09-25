# Known Bugs & Resolutions

## Resolved in Phase 7 (code + automated tests; awaiting physical re-verification)

| ID | Symptom | Root cause | Fix |
|---|---|---|---|
| A2 | Earbuds appear then vanish | SCO and A2DP routes share one logical id; removing SCO evicted the headset | Routes are reference-counted per logical device; last-route removal is debounced 1.5 s (`TrackingEngine.onRouteRemoved`) |
| B1/B2 | App opens with empty state while connected | `SYNC_STATE` fields are at the payload root but Flutter read `event.device`; also the pipeline dropped SYNC_STATE because it had no `deviceId` | `LiveSessionReducer._sync` reads root fields; SYNC is never filtered |
| B4/D/E | Timer keeps running after pause | (1) `AudioPlaybackCallback` configs include paused/idle players, so "list not empty" was treated as playing; (2) PAUSED kept `currentPlaybackStartTime` | Playback truth is `AudioManager.isMusicActive()` with settle + reconcile; reducer clears `playbackStartedAt` on pause |
| G | FGS crash on reopen | `startForeground` skipped on re-entry; 3-arg overload on API < 29; unhandled `ForegroundServiceStartNotAllowedException` | `promoteToForeground()` on every start with per-API overload and full exception handling |
| P1 | Live pipeline silently died after opening diagnostics | Each `TrackingPlatform.eventStream` call created a new `receiveBroadcastStream()`; cancelling one detached the native sink | One shared broadcast stream (`TrackingPlatform.events`) |
| P2 | Events lost when the UI was closed / process died | Only Flutter persisted events, and only while its engine was alive; broker buffer was unbounded & in-memory | Native `EventJournal` + idempotent `EventIngestor`; bounded broker buffer |
| P3 | Sessions never closed after process death | No recovery | Heartbeat + `RECOVERED` pause/disconnect at last heartbeat on restart |
| P4 | Speaker playback counted as earbud listening | Playback events fell back to the last known device, even after disconnect | Only media routed to a tracked headset counts (`routedDeviceId`) |
| P5 | Duplicate-key crash when two events share a millisecond | Row id was `<timestamp>_<device>` with plain INSERT | Journal ids `n-<seq>-<ts>` + `INSERT OR IGNORE` |
| P6 | Race / duplicate DEVICE_CONNECTED on startup | Initial scan on a background thread raced callbacks on main thread | Single engine HandlerThread; callbacks registered with that handler |
| P7 | `NoSuchMethodError` on Android 7–8 | `AudioDeviceInfo.getAddress()` (API 28) called behind an API 23 check | Guarded with API 28 |
| P8 | App locked if notifications disabled | Permission gate required POST_NOTIFICATIONS | Only BLUETOOTH_CONNECT gates; notifications optional |
| P9 | Diagnostics result could hang forever | `getProfileProxy` failure never completed the MethodChannel result | Guarded single completion + 3 s timeout |
| P10 | Nav "Devices" tab opened Settings | Hard-coded index 4 redirect | Five real tabs; settings in top bar |
| P11 | Light theme unreadable | Hard-coded dark colours everywhere | `EarPalette` ThemeExtension with light & dark tokens |
| P12 | Timer text overflowed on phones | 96 px display font | Type scale revised, FittedBox, tabular figures |
| P13 | Analytics/Wellbeing always empty/zero | Providers returned placeholders | `ListeningAnalyzer` computes real stats |
| P14 | "Latest event" diagnostic showed the oldest event | Wrong sort assumption | Uses newest-first provider, shows 50 rows |
| P15 | Developer diagnostics never listed GATT services | Read `result['device']['services']` from an already-unwrapped map | Reads `result['services']` |
| P17 | New source files silently never committed | Root `.gitignore` had lines appended in UTF-16; git read the first as a bare `*` pattern, ignoring every untracked file | Rewrote those patterns as UTF-8 |
| P16 | Stale sink after activity destroy | `onCancel` not always called | `cleanUpFlutterEngine` detaches sink; sink failures fall back to buffering |

## Resolved earlier
- **[Phase 6] Stale Home State After Process Death** — separated live state from DB history + SYNC_STATE.
- **[Phase 6] CPH2447 Misidentification** — names resolved from the Bluetooth device (now via the route's own MAC first).
- **[Phase 4] Splash Screen Freeze** — startup scan off the main thread (now: engine thread).
- **[Phase 4] Unreliable GATT Service Discovery** — `discoverServices` in `onConnectionStateChange`.

## Open
- None known in code. Physical verification of the Phase 7 matrix (CURRENT_STATE.md §6) pending.
- BLE code still uses pre-API-33 GATT APIs (deprecation warnings only).
