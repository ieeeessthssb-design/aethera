# AETHERA — Operational dashboard (Phase 2)

## Scope

This phase turns the farmer home screen into an operational overview. It does not redesign the dedicated Farms, Irrigation, Diagnosis, Weather, Community, or Assistant screens.

## Dashboard changes

- Reworked the home hierarchy with a compact brand header, welcome section, selected-farm context card, operational status, farm profile, and feature shortcuts.
- Kept farm selection connected to the existing `GET /farms` endpoint through `FarmApiService`.
- Added registered-device totals split by the API's `is_active` flag. These are registration/activation states, not a claim that a device is currently online.
- Added up to three device summary cards using the existing `GET /farms/{farm_id}/devices` and `GET /farms/{farm_id}/devices/{device_id}/readings/latest` endpoints.
- Displays soil-moisture readings and their recorded time only when the API returns a reading. Marks simulated readings explicitly.
- Added loading, error, retry, and no-device states. Pull-to-refresh refreshes farm data and invalidates the selected farm's device list.
- Added navigation shortcuts to Assistant, Diagnosis, Irrigation, Weather, and Community.
- Added EN/FR/AR translations for the new dashboard labels and reading timestamp.
- Preserved directional alignment and arrow direction for RTL layouts.

## Data integrity and limitations

- No weather card is fabricated: the farm model currently has no latitude/longitude fields, and the weather screen requires a separately selected location. Weather remains accessible through its dashboard shortcut.
- No irrigation alerts, online/offline heartbeat, or watering controls are inferred. The current device API exposes `is_active` and sensor readings, but no device last-seen/heartbeat field or alert endpoint.
- The dashboard does not change backend routes, response schemas, database migrations, authentication, or ESP32 firmware.

## Files changed

- `app/lib/features/farmer/presentation/farmer_home_screen.dart`
- `app/lib/l10n/app_en.arb`
- `app/lib/l10n/app_fr.arb`
- `app/lib/l10n/app_ar.arb`
- `app/lib/l10n/generated/app_localizations.dart`
- `app/lib/l10n/generated/app_localizations_en.dart`
- `app/lib/l10n/generated/app_localizations_fr.dart`
- `app/lib/l10n/generated/app_localizations_ar.dart`
- `app/test/widget_test.dart`

## Verification

- ARB JSON parsing: passed.
- Source-level inspection: dashboard uses existing API services/providers and does not fabricate weather or connectivity state.
- Flutter formatting, analyzer, widget tests, and browser/device runtime checks: not run in this environment because the Flutter SDK is unavailable.

## Local validation

From the `app` directory:

```powershell
flutter pub get
flutter gen-l10n
dart format lib test
flutter analyze
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```
