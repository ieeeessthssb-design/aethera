# AETHERA — Phase 2 Navigation Audit

Baseline: `aethera-localization-repair-phase1-2.zip` (25 November 2026).

## Existing structure

- Farmer shell uses an `IndexedStack` with ten destinations: Home, Farms, Irrigation, Assistant, Diagnosis, Weather, Community, Messages, Profile, and Settings.
- Desktop/tablet-wide layout uses a collapsible `NavigationRail` at a 900 px breakpoint.
- Narrow layout uses a four-item bottom navigation bar plus a drawer containing the full destination list.
- Profile and Settings are already distinct shell destinations.

## Issues found and addressed

1. Dashboard tool cards opened Diagnosis and Irrigation as independent routes. This bypassed shell selection and could leave the visible navigation state inconsistent. They now select the corresponding shell destination.
2. Assistant tool tiles opened Weather, Diagnosis, and Irrigation as independent routes. They now select the corresponding shell destination as well. The voice-assistant flow remains a dedicated route.
3. The dashboard callback used a private index-remapping table, making destination indices difficult to reason about. It now uses the shell's destination indices directly.
4. Profile contained a second Settings shortcut, while Settings contained a non-functional Profile row. These duplicated/confusing entries were removed; Profile and Settings remain accessible from the shell navigation.

## Remaining items for the next phase

- The mobile menu control is overlaid at the leading edge of page content; verify it does not overlap page headers at phone widths and in Arabic RTL.
- The mobile bottom bar exposes only Home, Farms, Irrigation, and Assistant. Other destinations remain available in the drawer; verify discoverability and selected-state feedback for drawer-only destinations.
- The dashboard currently focuses on farm selection/summary and tool shortcuts. It does not yet present a consolidated farm-health status, alerts, weather summary, or device freshness overview. These belong to the dashboard redesign phase.
- Profile currently contains placeholder account information and informational dialogs; it is not yet a real editable profile backed by user data.
- Settings currently supports language and theme only.

## Verification status

- ZIP structure and CRC integrity checked.
- Navigation callbacks and destination mappings statically inspected.
- Flutter SDK is not available in this execution environment, so `flutter analyze`, `flutter test`, Chrome, and Android runtime checks were not run. Run these on the development machine before merging.
