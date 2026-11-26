# AETHERA — Dashboard data support

This update adds backend support for farm-specific weather, device freshness, and deterministic sensor alerts. It does not modify the AI/diagnosis implementation or ESP32 firmware.

## Database migration

The new Alembic revision is `c4a9e72b1f30` (down revision `577406604f06`). The backend Docker command already runs `alembic upgrade head` on startup. If running the backend manually, execute from `backend/`:

```bash
alembic upgrade head
```

## Farm coordinates and weather

`farms` now stores nullable `latitude` and `longitude` fields. Existing farms remain valid and are not assigned guessed coordinates.

- `GET /weather/locations?q=Sousse` — location search (Open-Meteo geocoding).
- `PATCH /farms/{farm_id}/location` — save the selected coordinates; requires the farm owner's bearer token.
- `GET /weather/farms/{farm_id}/forecast` — current conditions, hourly forecast, 7-day outlook, and deterministic notable weather changes for that farm. Returns `409` when coordinates have not been configured.

Example location update:

```json
{
  "latitude": 35.8256,
  "longitude": 10.6411
}
```

The existing public coordinate-based `GET /weather/forecast` endpoint remains available for backward compatibility.

## Device freshness

`devices.last_seen_at` is updated whenever the existing authenticated sensor-reading endpoint receives a reading. No firmware change or new firmware message is required.

`GET /farms/{farm_id}/devices` now includes:

- `last_seen_at`
- `connection_status`: `online`, `stale`, `unknown`, or `disabled`

`online` means a reading arrived within the last 10 minutes; `stale` means the last reading is older than 10 minutes; `unknown` means no reading has ever arrived; `disabled` means the device is deactivated. This is a backend freshness classification, not a direct network ping.

## Sensor alerts

- `GET /farms/{farm_id}/alerts` — active alerts for the authenticated farm owner.
- `GET /farms/{farm_id}/alerts?include_acknowledged=true` — include acknowledged alerts.
- `PATCH /farms/{farm_id}/alerts/{alert_id}/acknowledge` — acknowledge an alert.

The current deterministic rules create a low-moisture alert below 20% and a high-moisture alert above 85%. Duplicate active alerts for the same device/type are suppressed. When a subsequent reading returns to the normal range, the corresponding active moisture alert is automatically resolved (acknowledged). These thresholds are conservative defaults, not crop-specific recommendations, and can be calibrated later. They do not invoke or alter AI/diagnosis logic.

## Data boundaries

- Weather data is fetched from Open-Meteo and cached for 10 minutes.
- Weather notable changes are forecast-derived indicators, not official emergency alerts.
- Sensor alerts are generated only from received readings.
- No device status is marked online until the backend receives a real reading.
- No changes were made under firmware or AI/diagnosis directories.

## Flutter integration

The Weather screen now lets the farmer search a place and save the selected coordinates to one of their farms. When a farm already has saved coordinates, the screen loads its farm-scoped forecast automatically. The farmer dashboard now displays persisted active sensor alerts and device freshness labels in EN/FR/AR.

The alert acknowledgement action only acknowledges the alert; it does not control irrigation equipment. The existing irrigation control limitations remain unchanged.
