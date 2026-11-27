# AETHERA Phase 10 — IoT Device Management & Reliability

## Scope

Phase 10 adds practical device lifecycle management on top of the existing authenticated farmer/farm APIs. It reuses the current device credential and sensor-reading contracts and does not introduce firmware, irrigation actuation, or diagnosis/AI changes.

## Flutter changes

- Register an IoT device from the selected farm's Smart Irrigation screen.
- Device name is entered by the farmer and validated before submission.
- After registration, the generated `device_key` is displayed in a one-time credential dialog with copy-to-clipboard. It is not stored by the Flutter app. The user must save it securely; the backend stores only its hash.
- Rename an active device from the device-card action menu.
- Deactivate an active device only after a confirmation prompt.
- Device list refreshes after successful registration, rename, and deactivation.
- Management strings are translated in English, French, and Arabic ARB files and the checked-in localization source files.

## Backend changes

- Added `DeviceUpdate` request schema with a trimmed 2–100 character device name.
- Added `PATCH /farms/{farm_id}/devices/{device_id}` for farmer-owned device renaming.
- Ownership is verified through the farm relationship; inactive devices cannot be renamed (409).
- Existing create endpoint remains `POST /farms/{farm_id}/devices`, which returns the device credential once.
- Existing deactivate endpoint remains `PATCH /farms/{farm_id}/devices/{device_id}/deactivate`.
- Existing reading submission, listing, and alert APIs are unchanged.

## Device onboarding contract

1. Farmer registers a device for a selected farm in the app.
2. API returns `device_key` once; copy/save it securely.
3. Device firmware/client submits readings using `X-Device-Key` and the device ID, as already defined by the API.
4. If credentials are lost, the current API does not provide key rotation/recovery. Do not reuse or expose the key in screenshots or logs.
5. Deactivation disables device-key authenticated reading submission. It is not a physical shutdown command.

## Validation performed

- Python backend modules compile via `python -m compileall -q backend/app`.
- English, French, and Arabic ARB files parse as JSON.
- ZIP archive integrity check passes.
- Flutter/Dart SDK is unavailable in the build environment; Flutter code formatting, static analysis, tests, generated localization rebuild, and app runtime validation remain pending locally.

## API endpoints used/added

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/farms/{farm_id}/devices` | Register a device and return one-time device key |
| GET | `/farms/{farm_id}/devices` | List farm devices and connection state |
| PATCH | `/farms/{farm_id}/devices/{device_id}` | Rename active device (new) |
| PATCH | `/farms/{farm_id}/devices/{device_id}/deactivate` | Deactivate device |
| GET | `/farms/{farm_id}/devices/{device_id}/readings/latest` | Fetch latest reading |
| GET | `/farms/{farm_id}/devices/{device_id}/readings` | Fetch readings history |

## Not included

- Device credential rotation/recovery.
- Device transfer between farms.
- Firmware/OTA updates or configuration push.
- Physical pump/valve control.
- Changes to firmware, AI, or crop diagnosis.
