# Aethera API Contract

## Conventions

### Field Naming
All request and response fields use **snake_case** (e.g., `farm_id`, `soil_moisture`, `created_at`).

### Timestamps
All timestamps are **ISO-8601 UTC** format: `2024-02-01T14:30:00Z`

No timezone offsets in stored values. Clients must convert to local time for display.

### Error Format
All error responses follow this envelope:
```json
{
  "detail": "Human-readable error message"
}
```
Validation errors (422) return:
```json
{
  "detail": [
    {
      "loc": ["body", "field_name"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

### Authentication
- **JWT Bearer** for all farmer/expert endpoints: `Authorization: Bearer <token>`
- **X-Device-Key** header for ESP32 device ingestion endpoints
- Tokens expire in 7 days (configurable via `JWT_EXPIRE_DAYS` env var)

### Pagination
Endpoints returning lists support `limit` and `offset` query params. Responses include a `total` count field.

### Source Enum (Critical)
The `source` field on all sensor readings is **always present**:
- `"real"` — data from a physical ESP32 device
- `"simulated"` — backend-generated data (no real device connected)

**UI rule**: Display a prominent "SIMULATED DATA" badge whenever ANY displayed value has `source != "real"`.

### Roles
- `farmer` — can access `/farms/me`, `/assistant/*`, `/advice/log`, `/devices/*`
- `expert` — can access all farmer endpoints + `/expert/*`

---

## Running the Mock Server

### Prerequisites
- Docker installed
- `contract/openapi.yaml` available

### Option 1: Docker (Recommended)
```bash
docker run --rm -p 4010:4010 \
  -v $(pwd)/contract:/contract \
  stoplight/prism:4 mock \
  /contract/openapi.yaml \
  --host 0.0.0.0
```

### Option 2: npx (Node.js required)
```bash
npx @stoplight/prism-cli mock contract/openapi.yaml
```

### Mock URL
Once running, the mock server is available at: `http://localhost:4010`

### Demo Credentials (Mock)
The mock returns realistic example data for all endpoints.
No auth validation in mock mode — any Bearer token is accepted.

```
Farmer:  demo@aethera.tn  / 123456
Expert:  expert@aethera.tn / 123456
```

### Flutter App — Point to Mock
```bash
flutter run --dart-define=API_URL=http://localhost:4010 --dart-define=DEMO_MODE=true
```

### Test Endpoints with curl
```bash
# Login
curl -X POST http://localhost:4010/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@aethera.tn","password":"123456"}'

# Latest sensor reading
curl http://localhost:4010/farms/660e8400-e29b-41d4-a716-446655440001/sensors/latest \
  -H "Authorization: Bearer mock_token"

# Ask assistant
curl -X POST http://localhost:4010/assistant/chat \
  -H "Authorization: Bearer mock_token" \
  -H "Content-Type: application/json" \
  -d '{"message":"أوراق الطماطم صفراء","farm_id":"660e8400-e29b-41d4-a716-446655440001"}'
```

---

## Endpoint Summary

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /auth/register | None | Register user |
| POST | /auth/login | None | Login → JWT |
| GET | /farms/me | JWT | Get my farm |
| PUT | /farms/me | JWT | Update my farm |
| GET | /farms/{id}/sensors/latest | JWT | Latest sensor snapshot |
| GET | /farms/{id}/sensors/readings | JWT | Time-series readings |
| GET | /devices | JWT | List my devices |
| POST | /devices | JWT | Register device |
| POST | /devices/{id}/readings | Device Key | Ingest ESP32 data |
| POST | /assistant/chat | JWT | Text AI query |
| POST | /assistant/voice | JWT | Voice AI query |
| GET | /advice/log | JWT | My advice history |
| GET | /expert/cases | JWT (expert) | List cases |
| GET | /expert/cases/{id} | JWT (expert) | Case detail |
| POST | /expert/cases/{id}/review | JWT (expert) | Submit review |
