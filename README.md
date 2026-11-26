# AETHERA — Smart Agriculture Platform

AETHERA connects farmers, agricultural experts, farm records, weather information and IoT monitoring through a Flutter client and a FastAPI backend.

## Development architecture

- `app/` — local AETHERA Flutter application, run from VS Code using the Flutter SDK installed on Windows.
- `frontend/aethera_flutter/` — the upstream main Flutter experience; it is retained alongside the local app.
- `backend/` — FastAPI API, run in Docker.
- PostgreSQL — run in Docker with a persistent volume.
- `firmware/` — IoT workspace and configurable sensor simulator.

**The Flutter frontend is intentionally not built inside Docker during development.** This avoids downloading and configuring a large Flutter SDK inside every Docker build and enables Flutter hot reload/debugging in VS Code.

## 1. Requirements

- Docker Desktop with Docker Compose.
- Flutter SDK installed on Windows. Its bundled Dart SDK must satisfy `app/pubspec.yaml` (`^3.13.5` or newer within Dart 3.x).
- VS Code with the Flutter and Dart extensions.

Verify the local SDK in PowerShell:

```powershell
flutter --version
flutter doctor
```

## 2. Configure environment

From the repository root:

```powershell
Copy-Item .env.example .env

# Generate separate, URL-safe random secrets (PowerShell 5.1 compatible).
function New-SecretHex {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return [System.BitConverter]::ToString($bytes).Replace('-', '').ToLowerInvariant()
}
$dbPassword = New-SecretHex
$jwtSecret = New-SecretHex
$content = Get-Content .env -Raw
$content = $content.Replace('replace-with-a-strong-local-database-password', $dbPassword)
$content = $content.Replace('replace-with-at-least-32-random-bytes', $jwtSecret)
Set-Content -Path .env -Value $content -Encoding ASCII
```

The command creates `.env` with independent random secrets. Keep `.env` private and do not commit it. If `.env` already exists, do not overwrite it; inspect and update its values manually if needed.

## 3. Start only PostgreSQL and FastAPI with Docker

From the repository root:

```powershell
docker compose up -d --build db backend
```

Check the services:

```powershell
docker compose ps
docker compose logs -f backend
```

Backend endpoints:

- API: `http://localhost:8000`
- Swagger: `http://localhost:8000/docs`
- Health: `http://localhost:8000/health`

PostgreSQL data is persisted in the `postgres_data` volume. Uploaded files are persisted in `backend_uploads`.

## 4. Run Flutter from VS Code

Open the Flutter app folder:

```powershell
code .\app
```

In the VS Code terminal:

```powershell
flutter pub get
flutter config --enable-web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

The app's API configuration defaults to `http://127.0.0.1:8000`; the explicit define above makes the development endpoint clear. Since Flutter runs on Windows, use `localhost`/`127.0.0.1`, **not** the Docker service hostname `backend`.

For Android emulator, the host is commonly `10.0.2.2` instead of `localhost`:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For a physical device on the same Wi-Fi, use the Windows machine's LAN IPv4 address and ensure the firewall permits the backend port:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8000
```

## 5. Daily workflow

Start backend and database:

```powershell
docker compose up -d db backend
```

Run Flutter in VS Code:

```powershell
cd app
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Stop containers when finished:

```powershell
# From repository root
docker compose down
```

`docker compose down` preserves volumes. Do not add `-v` unless you intentionally want to delete the database and uploaded files.

## 6. Backend without Docker (optional)

Use the Python version required by `backend/` and PostgreSQL. From `backend/`:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
# Configure DATABASE_URL and JWT_SECRET_KEY, then:
alembic upgrade head
uvicorn app.main:app --reload
```

## Firebase note

The Flutter client contains Firebase client configuration. Firebase sign-in requires the matching Firebase project configuration and enabled providers. Backend verification additionally requires Firebase Admin credentials. Never commit service-account JSON files.

## Weather service

Weather data is retrieved from Open-Meteo. The backend exposes:

- `GET /weather/locations?q=Sousse` — place-name lookup.
- `GET /weather/forecast?latitude=35.8256&longitude=10.63699&timezone=auto` — current conditions, hourly data, seven-day data and notable changes.

Forecast responses are cached in-process for 10 minutes. Agricultural notes are informational; verify soil moisture and crop-specific requirements before acting on them.

## Scope and verification

- No AI model weights are bundled. Assistant, safety, retrieval, irrigation, expert review, and voice demo code are included; provider-backed generation requires its optional configuration.
- The main voice pipeline is available at `ai/voice/voice_pipeline.py`; its recorded response clips are demo assets.
- Run `flutter pub get`, `flutter analyze`, and the backend tests locally before deployment. These commands have not been executed as part of packaging this archive.
- Review Firebase restrictions, CORS origins and production secrets before public deployment.

See `docs/PROJECT_STRUCTURE.md` and `DESIGN_SYSTEM.md` for project documentation and visual rules.

## Repository map and team workflow

| Area | Purpose |
|---|---|
| `backend/` | FastAPI API, authentication, database, assistant, farm and device endpoints |
| `app/` | Local integrated Flutter client |
| `frontend/aethera_flutter/` | Upstream Flutter client and screens |
| `firmware/` | ESP32 workspace and sensor simulator |
| `ai/assistant/`, `ai/retrieval/`, `ai/stt/`, `ai/vision/`, `ai/voice/` | Assistant safety, verified retrieval, speech and vision work, and voice demo |
| `docs/` | Architecture and project documentation |

Work on a feature branch and open a pull request. Do not push directly to `main`. Keep API keys, passwords, personal audio and other private data out of Git. Label simulated or manually entered data clearly.

## Local demo account

On the first backend startup, the development configuration creates a verified farmer account if its email does not already exist:

- Email: `demo@example.com`
- Password: `AetheraDemo!2026`
- Role: `farmer`

The seed is idempotent: it does not overwrite an existing account or reset its password. Change the values with `DEMO_ACCOUNT_EMAIL`, `DEMO_ACCOUNT_PASSWORD`, and `DEMO_ACCOUNT_NAME` in the root `.env` before the first startup. Set `DEMO_ACCOUNT_ENABLED=false` before any public deployment. These credentials are for local testing only.
