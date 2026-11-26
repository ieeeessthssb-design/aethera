# AETHERA — Folder guide

This guide describes the folders retained in the cleaned repository and their current contents. It distinguishes implemented code from placeholders.

## Repository root

- `app/` — Flutter mobile application, including Dart source, assets, localization files, and native platform project files.
- `backend/` — Python FastAPI service, database models, API routes, migrations, and runtime upload locations.
- `firmware/` — IoT/ESP32 workspace. It currently has placeholder directories and a Python simulator; actual ESP32 firmware source was not present.
- `docs/` — Project documentation. This folder contains this guide.
- `.gitignore` — Shared exclusions for secrets, generated output, local environments, IDE state, and runtime uploads.
- `README.md` — Project overview and setup instructions.
- `DESIGN_SYSTEM.md` — AETHERA visual tokens, component guidance, accessibility rules, and anti-slop review checklist.

## `app/` — Flutter client

- `app/lib/` — Main Dart application source.
  - `core/` — Shared app infrastructure: API configuration/client and token storage under `network/`, app preferences under `settings/`, and shared styling under `theme/`.
  - `features/` — Feature-oriented application code.
    - `authentication/` — Sign-in / registration UI and authentication API/repository/provider code.
    - `dashboard/` — General home/dashboard screen.
    - `farmer/` — Farmer-facing shell, home screen, farm API access, and Derja voice interface.
    - `expert/` — Expert-facing screens, access flow, and diagnosis queue.
    - `admin/` — Admin home screen.
    - `diagnosis/` — Diagnosis UI and API integration.
    - `community/` — Community feed/messages and social API, models, and providers.
    - `irrigation/` — Irrigation screen and irrigation API/provider code.
    - `assistant/` — Animated assistant-orb presentation component. This is visual UI only; no AI inference is included.
    - `weather/` — Open-Meteo client and weather screen for current conditions, hourly and seven-day forecasts, and notable changes.
  - `l10n/` — Localization source files (`.arb`) for English, French, and Arabic, plus generated localization classes.
  - `main.dart` — Flutter entry point; initializes Firebase, preferences, Riverpod, localization, and the root app widget.
  - `firebase_options.dart` — Firebase client options generated for supported Flutter platforms. These are client-side configuration, not Admin SDK credentials.
- `app/assets/images/` — Image assets used by the mobile application, including `backgrounds/tunisian_farm_landscape.png`, the generated Tunisian landscape used by the dashboard hero.
- `app/Dockerfile` and `app/nginx.conf` — Flutter Web build container and Nginx static hosting configuration.
- `app/android/` — Android host project, Gradle build scripts/wrapper, manifest, and Android Firebase client configuration. `local.properties` and Gradle caches are excluded because they are machine-specific/generated.
- `app/ios/` — iOS host project and Xcode configuration.
- `app/macos/` — macOS host project.
- `app/windows/` — Windows host project.
- `app/linux/` — Linux host project.
- `app/web/` — Web host files, including the web entry page, manifest, and icons.
- `app/test/` — Flutter widget tests.
- `pubspec.yaml` / `pubspec.lock` — Flutter package manifest and resolved dependency versions.
- `analysis_options.yaml` — Dart analyzer/lint configuration.

## `backend/` — FastAPI service

- `backend/app/main.py` — Creates the FastAPI application, configures CORS and static upload serving, and registers API routers.
- `backend/app/core/` — Shared backend infrastructure: settings/environment loading, database connection/session handling, authentication dependencies, password/token security, permissions, Firebase integration, and refresh-token handling.
- `backend/app/models/` — SQLAlchemy database models for users, farms, crops, devices, diagnoses, social entities, authentication identities, pending verification, and refresh sessions.
- `backend/app/schemas/` — Pydantic request/response schemas used to validate API data.
- `backend/app/routers/` — HTTP endpoint groups for authentication, administration, farms, crops, devices, diagnoses, social features, and Open-Meteo weather/geocoding.
- `backend/app/services/` — Business/service logic, including authentication, OTP, and email delivery.
- `backend/migrations/` — Alembic migration environment and migration history. `versions/` contains incremental database schema changes.
- `backend/uploads/` — Runtime directories for diagnosis images, message attachments, and post media. Only `.gitkeep` placeholders are tracked; real uploads must remain out of Git.
- `backend/requirements.txt` — Python backend dependencies.
- `backend/Dockerfile` — Python API image; applies Alembic migrations before starting Uvicorn.
- `backend/.env.example` — Safe configuration template. Copy it to `.env` and set local secrets and database connection details.
- `backend/alembic.ini` — Alembic migration configuration.
- `backend/create_admin.py` — Interactive script to create the first administrator account.

## Root-level runtime files

- `docker-compose.yml` — PostgreSQL, FastAPI, and Flutter Web services with health checks and persistent volumes.
- `.env.example` — Root Docker configuration template; copy to `.env` and replace the required secrets.
- `.dockerignore` — Excludes local environments, generated builds, secrets, and uploads from Docker build contexts.

## `firmware/` — IoT workspace

- `firmware/firmware/src/` — Intended location for ESP32 firmware source; currently contains only a `.gitkeep` placeholder.
- `firmware/firmware/wiring/` — Intended location for wiring diagrams; currently contains only a placeholder.
- `firmware/firmware/simulator/` — Reserved simulator workspace; currently contains only a placeholder.
- `firmware/simulator.py` — Python simulator that generates sample sensor readings and sends them to the backend device-reading endpoint. It is simulation code, not ESP32 firmware.
- `firmware/README.md` — Firmware workspace notes and team workflow guidance from the supplied project.
- `firmware/render.yaml` — Deployment blueprint found in the firmware folder. Review its environment variable names and deployment settings against the current backend configuration before using it; it is retained unchanged.

## Deliberately excluded

- `.git/` directories and Git internals — local repository metadata/history; initialize or connect Git in the destination repository as appropriate.
- `.venv/`, `__pycache__/`, `.pyc` — Python environment and generated bytecode.
- Flutter `build/`, `.dart_tool/`, Android `.gradle/`, and platform `ephemeral/` — generated build/tool state.
- `.idea/`, `*.iml`, and `local.properties` — IDE and machine-specific settings.
- `backend/.env` — real local configuration/secrets; replaced with `.env.example`.
- `backend/uploads/` contents — uploaded user media and runtime data; empty tracked directories are recreated.
- Database dump and old source backups — not required to build the current application and potentially contain data or stale code.
- `backup_before_social_integration/` and `.before-*` source snapshots — historical copies, not active source.
- Empty `ai/` directory — no AI implementation files existed in the supplied archive, so no empty placeholder directory is included.
