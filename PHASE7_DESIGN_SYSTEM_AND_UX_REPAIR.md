# AETHERA Phase 7 — Design System Foundation and UX Repair

## Included
- Home farm overview now displays every farm returned by the farm API as a selectable list, instead of hiding all but the currently selected farm in a dropdown.
- Mobile navigation menu receives a reserved header row; it no longer floats over and obscures the page's own header controls.
- Smart Irrigation is keyed to the current locale so switching language recreates the page and refreshes localized UI state. The screen uses generated localization strings; Arabic strings are present in the ARB and generated localization files.
- Shared Material theme now establishes surface/background/border tokens, app-bar defaults, card shape, input decoration, and button shape for light and dark themes.

## Scope safeguards
No firmware or AI/diagnosis implementation was changed. Backend contracts and irrigation capabilities were not extended. Farm list rendering uses the existing `GET /farms` service response.

## Verification
ZIP integrity and targeted source checks were run. Flutter format/analyze/test and device/browser runtime checks require a local Flutter SDK and were not executed here. Please confirm the farm endpoint returns the full list for the signed-in user; the frontend now renders every farm received.
