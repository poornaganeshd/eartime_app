# Requirements

## Core Constraints
1. **Passive Tracking**: The user MUST NEVER have to manually press a "Start" or "Stop" button to track their listening session. The app must detect connections automatically in the background.
2. **True Time Truth**: The UI Timer must rely on strict epoch timestamps (start time, accumulated pause time) rather than a local ticking state. This ensures resilience to app death.
3. **Zero Data Fabrication**: We must never assume left or right earbud status based on unverified BLE data. If a packet is uninterpreted, it must remain UNKNOWN until a standard or experimental map is created.
4. **Resilience**: The tracking architecture must survive the app being swiped away from the Android Recents screen.
5. **Consistent design system**: UI work goes through `EarPalette` tokens and shared widgets; both light and dark themes must stay readable, and status colours are never the only signal.
6. **Honest measurements**: Sound levels are estimates and must be labelled as such; the exposure model must follow WHO/ITU-T H.870.
