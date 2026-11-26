# AETHERA — Device Management UI

## Added application screens and flows

The farmer navigation now includes **Devices**. The screen is farm-scoped and provides:

- Register physical or simulated devices against a farm.
- Display the generated device ID and one-time device key after registration. The user must store the key securely; it cannot be retrieved later because the backend stores only its SHA-256 hash.
- List devices with online, stale, awaiting-data, or disabled connectivity state and last contact time.
- Show latest soil moisture, temperature, and humidity readings.
- Open recent sensor-reading history (up to 30 records).
- Review active farm alerts and acknowledge them.
- Disable a device after an explicit confirmation. This blocks telemetry ingestion; it is not a valve/actuator command.
- English, French, and Arabic labels for the main device-management workflow.

## Backend and database

- `POST /farms/{farm_id}/devices` accepts `name` and `is_simulated`.
- `GET /farms/{farm_id}/devices` returns `is_simulated` with the existing status fields.
- Alembic revision `e91b8c7d2a40` adds `devices.is_simulated` (default false for existing records).
- Device registration still enforces farmer role and farm ownership.
- Device keys are generated with `secrets.token_urlsafe(32)` and only their SHA-256 hashes are persisted.

## Simulator usage

The firmware simulator accepts command-line credentials or environment variables. Register a simulated device in the app, copy the one-time ID/key, then run from the `firmware` directory:

```powershell
python -m pip install requests
$env:AETHERA_API_URL = "http://localhost:8000"
$env:AETHERA_DEVICE_ID = "<device-id>"
$env:AETHERA_DEVICE_KEY = "<device-key>"
python .\simulator.py
```

To send one sample only, append `--once`. To change the interval, set `AETHERA_SIMULATOR_INTERVAL` (seconds). Each simulator process currently targets one device; for multiple simulated devices, start one process per device with its own credentials. Do not commit device keys or add them to `.env` files tracked by Git.

## Validation status

- Python bytecode compilation: passed.
- Python AST parsing across backend sources: passed.
- English, French, Arabic ARB JSON parsing: passed.
- Simulator CLI help/argument parsing: passed.
- Flutter formatter/analyzer/tests: not run (Flutter/Dart SDK unavailable in build environment).
- Docker/PostgreSQL runtime and authenticated end-to-end API tests: not run.
