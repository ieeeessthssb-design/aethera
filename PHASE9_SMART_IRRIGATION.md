# AETHERA Phase 9 — Smart Irrigation Monitoring

## Implemented
- Device connectivity states use backend-provided `connection_status` (online, stale, disabled, unknown) and localized labels.
- Device cards display `last_seen_at` and indicate when no telemetry has been recorded.
- Sensor latest readings remain sourced from the existing readings endpoint; no mock values added.
- Added recent soil-moisture history (up to 12 records fetched, 5 displayed) through the existing history endpoint.
- Active farm alerts are displayed and can be acknowledged using the existing API endpoint.
- Refresh invalidates devices, readings, history and active alerts.
- Added English/French/Arabic labels for the new history and alert-acknowledgement error messages.

## Deliberately not implemented
- No pump/valve activation controls: backend has no supported irrigation-control command.
- No firmware, AI, diagnosis, or threshold logic changes.
- No schema/database migration.

## Validation
- Backend Python compileall passed.
- English, French, and Arabic ARB JSON files parse successfully.
- Flutter SDK is not available in this environment; `flutter gen-l10n`, `dart format`, `flutter analyze`, tests, and runtime/API integration have not been run. Run these locally before treating this phase as runtime-verified.
