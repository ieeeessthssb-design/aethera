# AETHERA Phase 9 — Irrigation Connectivity and Monitoring

## Scope
Phase 9 strengthens the existing device telemetry and monitoring workflow. It does not claim actuator control: the current API and device model do not expose a supported irrigation-valve command.

## Backend changes
- Every authenticated sensor packet updates `devices.last_seen_at`, including simulator packets.
- Simulator packets remain marked `is_simulated=true` and do not create physical-field agronomic alerts.
- Existing device list status (`online`, `stale`, `unknown`, `disabled`) remains the connectivity contract.
- Device keys, ownership checks, reading history, and alert acknowledgement contracts are unchanged.

## Flutter changes
- Smart Irrigation refreshes device status and latest readings every 30 seconds while the screen is mounted; the timer is cancelled on disposal.
- Device connectivity now reads the backend `connection_status` field rather than an unrelated `status` field.
- Latest sensor data is presented as soil moisture, temperature, and humidity instead of exposing arbitrary response metadata.
- Reading freshness is displayed using the reading timestamp; readings older than 10 minutes are visibly marked stale.
- Disabling a device requires an explicit confirmation. The confirmation explains that disabling ingestion does not physically switch off an irrigation valve.
- Confirmation, status, and freshness text support English, French, and Arabic.

## Validation
- Backend Python source compilation: run with `python -m compileall -q backend/app`.
- English/French/Arabic ARB JSON parsing: validated.
- ZIP integrity: validated after packaging.
- Flutter formatter/analyzer/tests and runtime API tests require a local Flutter SDK and a running Docker/PostgreSQL environment; they are not represented as passed here.

## Manual verification
1. Start the backend and app.
2. Send authenticated readings to `POST /devices/{device_id}/readings` with `X-Device-Key`.
3. Confirm `GET /farms/{farm_id}/devices` updates `last_seen_at` and reports `online`.
4. Stop the sender and wait more than 10 minutes; confirm the device becomes `stale`.
5. Confirm old readings are labelled stale in Smart Irrigation.
6. Attempt to disable a device and cancel; verify it remains active. Confirm again; verify it becomes disabled and new readings are rejected.
7. Repeat the screen checks in English, French, and Arabic.

## Device Management UI (added after Phase 9 review)
- A farmer-facing Device Management page is available in the main navigation.
- Register a physical or simulated device against one of the farmer's farms.
- The device key is shown once after registration. Copy it to a password manager or secure secret store; the API stores only its SHA-256 hash.
- Review connection state, last contact, and latest soil moisture/temperature/humidity.
- Review farm alerts and acknowledge them.
- Disable a device only after an explicit confirmation.
- The backend stores the simulated/physical device classification via Alembic migration `e91b8c7d2a40`.

### Run one simulated device
After registering a simulated device, run from `firmware/` in PowerShell (replace the values with the one-time credentials shown by the app):

```powershell
python -m pip install requests
$env:AETHERA_API_URL = "http://localhost:8000"
$env:AETHERA_DEVICE_ID = "<device-id>"
$env:AETHERA_DEVICE_KEY = "<device-key>"
python .\simulator.py
```

The simulator sends the `X-Simulated: true` header. Do not commit device keys or put them in source control. This script currently simulates one device per process; start another process with that device's own credentials to simulate another device.
