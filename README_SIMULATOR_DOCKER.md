# AETHERA Docker simulator integration

This is a Docker Compose overlay. It leaves the existing `docker-compose.yml` and firmware source untouched.

## Data flow

`firmware simulator.py` (mounted read-only) -> `simulator` Docker service -> FastAPI `POST /devices/{device_id}/readings` -> PostgreSQL -> existing Flutter irrigation API providers.

The simulator sends the existing contract: `X-Device-Key`, `X-Simulated: true`, and the existing soil-moisture/temperature/humidity/recorded-at JSON payload. The simulator container reaches the API at `http://backend:8000` using the Compose service DNS name, not `localhost`.

## 1. Register a test device

1. Start the normal stack and sign in to the Flutter app.
2. Register a test IoT device under the farm you want to monitor.
3. Copy its UUID and one-time device key. The key is not recoverable later; if it was lost, register a new test device and deactivate the old one.

Do not use a production device's credentials for simulation.

## 2. Configure the root `.env`

Copy the variables from `.env.simulator.example` into the root `.env` file beside `docker-compose.yml` and set the actual test device UUID/key.

The repository contains `firmware/simulator.py`. If your local script is actually named `similator.py`, set `SIMULATOR_SCRIPT_PATH` to its exact path, for example:

```dotenv
SIMULATOR_SCRIPT_PATH=C:/Users/souha/Desktop/Bouzaien Rayen/IEEcs/aethera/firmware/similator.py
```

If the file is named `simulator.py`, use:

```dotenv
SIMULATOR_SCRIPT_PATH=C:/Users/souha/Desktop/Bouzaien Rayen/IEEcs/aethera/firmware/simulator.py
```

The file is mounted read-only into the container. The runner injects configuration at runtime; it does not modify firmware source.

## 3. Start everything

From the project root (the directory containing `docker-compose.yml`):

```powershell
docker compose -f docker-compose.yml -f docker-compose.simulator.yml up -d --build
```

View simulator output:

```powershell
docker compose -f docker-compose.yml -f docker-compose.simulator.yml logs -f simulator
```

Stop only the simulator:

```powershell
docker compose -f docker-compose.yml -f docker-compose.simulator.yml stop simulator
```

Start it again:

```powershell
docker compose -f docker-compose.yml -f docker-compose.simulator.yml start simulator
```

If you change the `.env` device ID/key or script path, recreate the simulator container:

```powershell
docker compose -f docker-compose.yml -f docker-compose.simulator.yml up -d --force-recreate simulator
```

## 4. Verify readings

The simulator logs should show HTTP `201` responses. In Flutter, open Irrigation, select the farm containing the test device, and pull to refresh. The latest reading and history should now be populated from the same backend endpoints used by hardware devices.

The simulator posts every 5 seconds by default. Flutter's existing screen refresh is pull-to-refresh; this patch also includes an optional UI polling patch (see below) if you want the values to refresh while the page remains open.

## Important behavior

- Simulated rows are stored with `is_simulated=true`.
- The backend should update device `last_seen_at` for simulated traffic so the device status can be `online`.
- Existing backend logic deliberately suppresses agronomic alerts for simulated readings. This prevents demo data from creating real-farm alerts.
- This simulator does not operate a physical pump or modify ESP32 firmware.
- Never use the simulator against production data unless the team explicitly approves that setup.

## Flutter automatic refresh

Apply `patches/irrigation_screen_polling.patch` if you want latest values to refresh automatically every 10 seconds while the Irrigation screen is open. Without this optional patch, pull-to-refresh already fetches the latest data.
