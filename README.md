# AETHERA

AETHERA is a smart-agriculture application for farmers, agricultural experts, and administrators. It brings farm records, weather information, sensor monitoring, agronomy assistance, crop-photo case review, and farmer-to-farmer communication into a Flutter client backed by a FastAPI service and PostgreSQL.

This README describes the code that is present in this repository. Some machine-learning and voice components are research or demo code and are not connected to the production API; see [AI status](#ai-and-machine-learning-status) before interpreting a feature as operational.

## Contents

- [Project at a glance](#project-at-a-glance)
- [Implemented features and status](#implemented-features-and-status)
- [Technology stack](#technology-stack)
- [Architecture](#architecture)
- [Frontend](#frontend)
- [Backend and API reference](#backend-and-api-reference)
- [AI and machine-learning status](#ai-and-machine-learning-status)
- [Database](#database)
- [Installation and local development](#installation-and-local-development)
- [Docker operations](#docker-operations)
- [Configuration reference](#configuration-reference)
- [Testing and verification](#testing-and-verification)
- [Troubleshooting](#troubleshooting)
- [Project structure](#project-structure)
- [Security notes](#security-notes)
- [Roadmap based on repository state](#roadmap-based-on-repository-state)
- [Contributing](#contributing)

## Project at a glance

The project is aimed at small and mid-sized farms, agricultural advisers, and administrators. A farmer can maintain one or more farm profiles, record crops, view weather forecasts, register sensor devices, ask questions about a farm, and submit a crop-photo case for expert review. Experts can review eligible irrigation-assistance cases and crop-photo cases. Administrators manage accounts and expert approval.

The backend is the source of truth for authenticated data. It validates requests, checks user roles and farm ownership, persists records through SQLAlchemy, and serves uploaded media from its uploads directory. The Flutter app calls the API over HTTP. Open-Meteo supplies geocoding and forecast data; optional Firebase, SMTP, and Groq settings enable external integrations.

### Current workflow: farm-specific irrigation advice

1. The farmer signs in and selects a farm in the Flutter app.
2. The app sends the question and farm ID to `POST /farms/{farm_id}/irrigation/advice` with a bearer access token.
3. The API verifies ownership, reads the farm's latest sensor information, obtains weather data, and retrieves relevant passages from the local BM25 agronomy index.
4. Safety checks run before model use. The API calls Groq when configured; otherwise it uses a deterministic rules fallback.
5. The response includes an action, explanation, confidence, data/source labels, and whether expert review is needed. The interaction is recorded; escalated advice also creates an expert case.

## Implemented features and status

| Feature | What the repository implements | Status / limitations |
|---|---|---|
| Accounts and roles | Email registration and verification, phone/Firebase verification, Google identity verification, password login, refresh-token rotation, logout, profile lookup, and Google account linking. | Implemented in the API. Email delivery requires SMTP; phone and Google verification require Firebase Admin credentials. |
| Farm and crop records | Farmer-owned farms, farm profile/location updates, and crops associated with a farm. | Implemented in the API and used by the client. |
| Weather | Location lookup and current/hourly/daily forecast through Open-Meteo, with in-process caching. | Implemented; internet access is needed. Farm forecast requires an authenticated owner. |
| Sensor devices | Device registration, one-time device key response, reading ingestion, history/latest readings, simulated data flags, farm alerts, and alert acknowledgement. | API implemented. Physical ESP32 firmware is not present. `firmware/simulator.py` can send synthetic readings. |
| Text agronomy assistant | Chat with farm context, safety filters, a local keyword-based stub, optional Groq provider, advice history, and expert-case escalation for low confidence/high risk. | Implemented. Default provider is a demo stub; set Groq configuration for hosted model responses. |
| Irrigation advice | Farm-aware advice combines recent readings, Open-Meteo data, BM25 agronomy excerpts, safety rules, Groq where configured, and conservative fallback rules. | Implemented. Missing/stale/simulated inputs lower confidence or prevent an `irrigate_now` result. |
| Voice endpoints | Multipart voice route and separate transcribe/confirm/answer API flow. | API route exists, but backend STT service currently returns a fixed stub transcript. The FarukSTT script is a separate demo. |
| Crop-photo cases | Farmer uploads JPG/PNG/WEBP (up to 8 MiB) with symptoms and an owned farm; the image is stored and a pending case is created. Approved experts can queue and review cases. | Manual expert workflow is implemented. The standalone image model is not called by this API. |
| Expert review | Experts with approved status can read and review irrigation-assistance cases and crop-photo cases. | Implemented in API. Expert accounts require admin approval. |
| Social features | Profiles, profile search, posts and images, connection requests, conversations, and messages. | Implemented in backend routes; inspect client screens for exact integration coverage. |
| Admin | Overview, user list/status, pending expert list, and approve/reject expert applications. | Implemented in backend and the `app/` admin screen. |
| Localization and preferences | The integrated Flutter app supports English, French, and Arabic locale selection and theme preferences. | Implemented, but some labels in screens may remain hard-coded. Arabic/RTL and copy should be reviewed as UI evolves. |
| Plant disease classifier | Training, evaluation, and inference utilities for tomato, potato, and pepper conditions. | Experimental standalone code. No weights are committed and the diagnosis endpoint does not invoke it. |

## Technology stack

| Layer | Technology | Role |
|---|---|---|
| Integrated client | Flutter, Dart SDK constraint `^3.10.0` (`app/pubspec.yaml`) | Cross-platform UI for web, Windows, Android, iOS, and Linux project targets. |
| Client state and preferences | Riverpod 3, SharedPreferences, Flutter Secure Storage | State/dependency management, persisted settings, and platform-secure token storage. |
| Client networking | Dio 5 | JSON and multipart REST requests, bearer headers, and refresh-token retry. |
| Client localization/auth | Flutter localization, ARB files, Firebase Core/Auth, Google Sign-In | English/French/Arabic strings and identity provider integration. |
| API | Python 3.13 in Docker, FastAPI, Pydantic v2 / pydantic-settings | Async REST API, request validation, OpenAPI docs, and environment configuration. |
| Persistence | PostgreSQL 16, SQLAlchemy async, asyncpg, Alembic | Relational storage, async sessions, and schema migrations. SQLite is supported by backend test configuration, not the production Compose database. |
| Auth/security | PyJWT, bcrypt / pwdlib Argon2 support, Firebase Admin | Signed access tokens, password hashing, refresh sessions, and external identity verification. |
| AI and data | HTTPX, Groq-compatible API, local BM25 retrieval, PyTorch/torchvision and Pillow for separate vision work | Assistant and irrigation advice; image model experimentation. The vision weights are not part of the app deployment. |
| Integrations | Open-Meteo, SMTP, optional Groq, optional Ollama configuration | Weather/geocoding, email verification, hosted LLM responses, and currently unused/configured local-model settings. |
| Runtime | Docker Compose, Docker Desktop | Runs PostgreSQL and the FastAPI service with persistent named volumes. |

Exact package versions for the Python service are pinned or constrained in [`backend/requirements.txt`](backend/requirements.txt). Flutter dependencies and SDK constraints are in [`app/pubspec.yaml`](app/pubspec.yaml). The second Flutter project has its own separate manifest.

## Architecture

```mermaid
flowchart LR
    Farmer[Farmer / Expert / Admin]
    Flutter[Flutter client<br/>app/]
    API[FastAPI REST API<br/>backend/app]
    DB[(PostgreSQL<br/>SQLAlchemy + Alembic)]
    Files[(Uploads volume<br/>diagnoses / social media)]
    Weather[Open-Meteo<br/>geocoding + forecast]
    LLM[Optional Groq API]
    RAG[Local BM25 index<br/>ai/retrieval/chunks.json]
    Firebase[Firebase Admin<br/>optional identity verification]
    Sensors[Device / simulator]
    Vision[Standalone vision research<br/>ai/vision; not API-wired]

    Farmer <--> Flutter
    Flutter <-->|REST / JSON / multipart<br/>JWT bearer| API
    API <--> DB
    API --> Files
    API -->|weather requests| Weather
    API -->|configured assistant requests| LLM
    API --> RAG
    API --> Firebase
    Sensors -->|device key + readings| API
    Vision -. no live integration .-> API
```

The client stores access and refresh tokens using `flutter_secure_storage`. `ApiClient` attaches the access token and, after an eligible 401 response, calls `/auth/refresh`, stores the rotated tokens, and retries once. The API keeps only hashes of refresh tokens in `refresh_sessions` and supports either JSON refresh tokens or an HttpOnly cookie transport for callers that opt into it.

### Example: crop-photo case and expert review

```mermaid
sequenceDiagram
    actor Farmer
    participant App as Flutter app
    participant API as FastAPI
    participant DB as PostgreSQL
    participant Disk as Upload volume
    actor Expert

    Farmer->>App: Choose farm, photo, and symptom description
    App->>API: POST /diagnoses (multipart, bearer token)
    API->>API: Check farmer role, farm ownership, image signature and 8 MiB limit
    API->>Disk: Save image under uploads/diagnoses
    API->>DB: Insert pending_review diagnosis case
    API-->>App: 201 case record
    Expert->>API: GET /diagnoses/queue (approved expert token)
    API-->>Expert: Pending cases
    Expert->>API: POST /diagnoses/{case_id}/review
    API->>DB: Save expert decision, diagnosis and advice
    API-->>Expert: Reviewed case
```

Uploaded diagnosis images are not run through the vision model in this flow. The review sequence above represents the implemented API behavior.

## Frontend

### Which Flutter project to run

- **`app/` is the integrated client** used by the repository's root development workflow and recent authentication, farm, assistant, weather, diagnosis, expert, device, and admin integrations.
- **`frontend/aethera_flutter/` is a separate retained Flutter codebase/prototype** with its own manifest, assets, and screens. It is not built or served by the root Compose file. Do not mix its packages or commands with `app/` without deciding which client is the target.

The integrated app starts in [`app/lib/main.dart`](app/lib/main.dart), initializes Firebase and SharedPreferences, creates a Riverpod `ProviderScope`, and opens the authentication screen. User-role screens are opened after authentication. Feature code is organized under `app/lib/features/`; shared HTTP/token configuration is in `app/lib/core/network/`; ARB translations and generated localizations are in `app/lib/l10n/`.

The API base URL is compile-time configured by `String.fromEnvironment('API_BASE_URL')` in `app/lib/core/network/api_config.dart`; its default is `http://127.0.0.1:8000`. Pass `--dart-define=API_BASE_URL=...` when using another host. A browser/desktop host can use `localhost`; the Android emulator normally uses `10.0.2.2`; a physical phone needs the development PC's LAN IP and an allowed firewall port.

### Client feature organization

| Directory | Responsibility |
|---|---|
| `app/lib/features/authentication/` | Email/password and identity-provider sign-in, registration/verification UI, role-based landing. |
| `app/lib/features/dashboard/`, `farmer/` | Farmer shell, overview, farm interaction, settings, and voice demo UI. |
| `app/lib/features/assistant/` | Assistant API adapter and shared assistant UI components. |
| `app/lib/features/diagnosis/` | Crop-photo submission and farmer case history. |
| `app/lib/features/expert/` | Expert access/dashboard and diagnosis queue/review UI. |
| `app/lib/features/admin/` | Admin API adapter and account/expert management screen. |
| `app/lib/features/community/` | Community and messaging screens. |
| `app/lib/features/irrigation/`, `weather/` | Device/irrigation management and farm weather views. |
| `app/lib/core/network/` | Dio client, `API_BASE_URL`, token storage, refresh handling. |
| `app/lib/core/settings/`, `theme/` | Riverpod locale/theme preferences and app theme. |

Build platforms are represented under `app/android`, `app/ios`, `app/web`, `app/windows`, and `app/linux`. Actual build readiness depends on the local Flutter toolchain and per-platform configuration. Firebase options and the Android Google Services client file are configuration artifacts; use credentials belonging to your own Firebase project and follow Firebase's client restrictions.

## Backend and API reference

### Layout and request lifecycle

`backend/app/main.py` creates the FastAPI application, configures CORS, includes routers, mounts `/uploads`, and provides `/` and `/health`. Routes obtain async database sessions through `get_db`; `get_current_user` validates bearer access tokens and loads the user; role dependencies enforce farmer, approved-expert, or admin access. Pydantic schemas validate JSON and multipart form fields. Business logic lives in `backend/app/services/`; ORM entities are in `backend/app/models/`.

The root Docker image runs `alembic upgrade head`, executes the idempotent demo-account seed, then starts Uvicorn on port 8000. For manual local runs, apply migrations before starting the server.

### API conventions

- Base URL in local Docker: `http://localhost:8000`.
- Interactive docs: `http://localhost:8000/docs`; OpenAPI JSON: `http://localhost:8000/openapi.json`.
- Authenticated user routes use `Authorization: Bearer <access_token>` unless noted.
- UUID placeholders represent actual UUID values. Most resource endpoints scope records to the current user/farm owner.
- Validation and permission failures use normal FastAPI HTTP errors (for example, 401/403/404/409/422). See OpenAPI for exact schema fields and response models.

### Endpoint reference

This table is derived from the router decorators in `backend/app/routers/`. `Bearer` means an authenticated user token; role-specific access is stated separately. Device ingestion uses a device key instead of a user bearer token. Weather location and coordinate forecasts are public.

| Method | Endpoint | Description | Authentication |
|---|---|---|---|
| GET | `/` | API identity/status payload. | Public |
| GET | `/health` | Liveness response; does not check database readiness. | Public |
| GET | `/uploads/{path}` | Serve files present under the backend uploads directory (static mount). | Public static file mount; do not store private files here |
| POST | `/auth/register` | Start email registration and send verification code. | Public |
| POST | `/auth/register-phone` | Start phone registration. | Public |
| POST | `/auth/verify-email` | Verify email registration and issue tokens. | Public |
| POST | `/auth/verify-phone` | Verify Firebase phone identity and issue tokens. | Public; Firebase configured |
| POST | `/auth/resend-verification` | Resend email verification code subject to cooldown. | Public |
| POST | `/auth/login` | Email/password login. | Public |
| POST | `/auth/login-phone` | Phone/password login. | Public |
| POST | `/auth/google` | Verify Firebase Google ID token and sign in. | Public; Firebase Admin configured |
| POST | `/auth/refresh` | Rotate a refresh token and issue access/refresh tokens. | Refresh token or configured cookie |
| POST | `/auth/logout` | Revoke refresh session and clear cookie where used. | Refresh token or configured cookie |
| POST | `/auth/link-google` | Link a Google identity to the current account. | Bearer |
| GET | `/auth/me` | Return current user. | Bearer |
| GET | `/admin/overview` | User/account and pending-expert counts. | Admin bearer |
| GET | `/admin/users` | Paginated user list (`limit`, `offset`). | Admin bearer |
| PATCH | `/admin/users/{user_id}/status` | Activate/deactivate a user with last-admin/self protections. | Admin bearer |
| GET | `/admin/experts/pending` | List expert applications awaiting approval. | Admin bearer |
| PATCH | `/admin/experts/{user_id}/approve` | Approve an expert. | Admin bearer |
| PATCH | `/admin/experts/{user_id}/reject` | Reject an expert. | Admin bearer |
| GET | `/farms/me` | Read compatibility single-farm profile. | Farmer bearer |
| PUT | `/farms/me` | Create/update compatibility single-farm profile. | Farmer bearer |
| POST | `/farms` | Create a farm. | Farmer bearer |
| GET | `/farms` | List current farmer's farms. | Farmer bearer |
| GET | `/farms/{farm_id}` | Read an owned farm. | Owner bearer |
| PATCH | `/farms/{farm_id}/location` | Update farm coordinates. | Owner bearer |
| POST | `/farms/{farm_id}/crops` | Create a crop for an owned farm. | Owner bearer |
| GET | `/farms/{farm_id}/crops` | List farm crops. | Owner bearer |
| GET | `/farms/{farm_id}/crops/{crop_id}` | Read a crop. | Owner bearer |
| POST | `/farms/{farm_id}/devices` | Create device for the farm; returns device key once. | Owner bearer |
| GET | `/devices` | List current user's devices (compatibility route). | Bearer |
| POST | `/devices` | Register device through compatibility route. | Farmer bearer |
| POST | `/devices/{device_id}/readings` | Ingest reading from a registered device. | `X-Device-Key` |
| GET | `/farms/{farm_id}/devices` | List farm devices. | Farm owner bearer |
| PATCH | `/farms/{farm_id}/devices/{device_id}/deactivate` | Deactivate farm device. | Farm owner bearer |
| GET | `/farms/{farm_id}/devices/{device_id}/readings/latest` | Latest reading for device. | Farm owner bearer |
| GET | `/farms/{farm_id}/devices/{device_id}/readings` | Reading history for device. | Farm owner bearer |
| GET | `/farms/{farm_id}/alerts` | List farm alerts; `include_acknowledged` optional. | Farm owner bearer |
| PATCH | `/farms/{farm_id}/alerts/{alert_id}/acknowledge` | Acknowledge a farm alert. | Farm owner bearer |
| GET | `/farms/{id}/sensors/latest` | Latest sensor summary (may use configured simulator fallback). | Farm owner bearer |
| GET | `/farms/{id}/sensors/readings` | Readings filtered by metric and optional time range. | Farm owner bearer |
| GET | `/weather/locations` | Search place name (`q`) and return coordinates. | Public |
| GET | `/weather/forecast` | Forecast by required latitude/longitude and optional timezone query. | Public |
| GET | `/weather/farms/{farm_id}/forecast` | Forecast using an owned farm's coordinates. | Owner bearer |
| POST | `/assistant/chat` | Farm-context text assistant; persists advice log. | Bearer + farm owner |
| POST | `/assistant/voice` | Multipart audio assistant route using current STT adapter. | Bearer + farm owner |
| POST | `/assistant/voice/transcribe` | Return transcript for user confirmation. | Bearer |
| POST | `/assistant/voice/answer` | Generate advice from confirmed/edited transcript. | Bearer + farm owner |
| POST | `/farms/{farm_id}/irrigation/advice` | Farm-aware irrigation recommendation, log, optional escalation. | Bearer + farm owner |
| GET | `/advice/log` | Current user's paginated advice history. | Bearer |
| POST | `/diagnoses` | Multipart image/symptom case submission. | Farmer bearer + farm owner |
| GET | `/diagnoses/mine` | Farmer's submitted cases. | Farmer bearer |
| GET | `/diagnoses/queue` | Pending crop-photo cases. | Approved expert bearer |
| GET | `/diagnoses/{case_id}` | Read owned case or case available to approved expert. | Farmer owner or approved expert |
| POST | `/diagnoses/{case_id}/review` | Submit expert diagnosis and advice. | Approved expert bearer |
| GET | `/expert/cases` | List irrigation-advice expert cases; optional `status`, `limit`, `offset`. | Expert bearer (approval enforced by route dependency) |
| GET | `/expert/cases/{id}` | Read an expert case. | Expert bearer |
| POST | `/expert/cases/{id}/review` | Confirm/reject and comment on an expert case. | Expert bearer |
| GET | `/social/profile/me` | Read own social profile. | Bearer |
| PATCH | `/social/profile/me` | Update own social profile. | Bearer |
| GET | `/social/people/search` | Search people. | Bearer |
| GET | `/social/profile/{user_id}` | View a public/available profile. | Bearer |
| POST | `/social/posts` | Create a post, optionally with image. | Bearer |
| GET | `/social/feed` | Read feed. | Bearer |
| GET | `/social/people/{user_id}/posts` | List a person's posts. | Bearer |
| GET | `/social/posts/{post_id}/image` | Retrieve post image. | Bearer |
| POST | `/social/connections` | Send a connection request. | Bearer |
| GET | `/social/connections` | List connection requests/connections. | Bearer |
| PATCH | `/social/connections/{connection_id}` | Respond to a connection request. | Bearer |
| GET | `/social/conversations` | List conversations. | Bearer |
| POST | `/social/conversations/{other_user_id}` | Start/open conversation with a user. | Bearer |
| GET | `/social/conversations/{conversation_id}/messages` | Read conversation messages. | Participant bearer |
| POST | `/social/conversations/{conversation_id}/messages` | Send text/image message. | Participant bearer |
| GET | `/social/messages/{message_id}/image` | Retrieve message image. | Participant bearer |

#### Example: authenticated request

```powershell
$token = '<access-token-from-login>'
Invoke-RestMethod -Headers @{ Authorization = "Bearer $token" } `
  -Uri 'http://localhost:8000/farms' -Method Get
```

#### Example: submit crop-photo case

```powershell
curl.exe -X POST 'http://localhost:8000/diagnoses' `
  -H "Authorization: Bearer <access-token>" `
  -F 'farm_id=<farm-uuid>' `
  -F 'symptoms=Leaves have yellow spots and curling' `
  -F 'photo=@C:\path\to\leaf.jpg;type=image/jpeg'
```

The API's generated OpenAPI document at `/docs` is authoritative for detailed body fields, response schemas, and query parameter constraints.

## AI and machine-learning status

### Operational API behavior

**Text assistant.** `POST /assistant/chat` uses `ASSISTANT_PROVIDER=stub` by default. The stub selects canned answers by keyword and language heuristics; it is a demo fallback, not a trained model. With `ASSISTANT_PROVIDER=groq` and a non-empty `GROQ_API_KEY`, the service calls the configured Groq-compatible chat completion endpoint. It runs safety checks before external model calls, can escalate answers, writes advice history, and creates `expert_cases` when escalation is needed. On provider errors the text assistant falls back to the local stub.

**Irrigation advice.** The irrigation advisor is separate from the general chat provider. It gathers latest readings, a farm weather forecast, and up to three passages from `ai/retrieval/chunks.json` using local BM25; safety checks run first. It calls Groq when configured and otherwise applies conservative rules. Missing weather or soil moisture prevents an actionable irrigation-now recommendation. Simulated sensor data is labelled and lowers confidence. The response includes sources and confidence metadata. The configured Ollama helper/settings are not the active fallback path in this service.

**Retrieval.** This is local keyword/BM25 ranking, not a vector database or embedding model. `ai/retrieval/docs_sources.csv` records sources; `chunks.json` is the packaged index. The API adapter degrades to no retrieved passages if retrieval cannot be loaded.

### Implemented code not integrated into the application

| Component | Verified state |
|---|---|
| Plant condition image model (`ai/vision/`) | Training/evaluation/prediction scripts and safety-oriented decision code are present. The docs describe a ConvNeXt-Tiny probe; another MobileNetV3 pipeline is also present. `data/` and model weight files are git-ignored/not in this checkout. Docker copies vision source and installs runtime dependencies, but no checkpoint or training dataset is bundled. `/diagnoses` does not import or call the predictor. Therefore image inference is **not operational through the API**. |
| Vision performance | The vision README reports a 96-image PlantDoc test result for the final probe (56.2% exact disease accuracy; 64.6% when crop is supplied from farm profile). It also notes overlapping confidence intervals, a small dataset, noisy labels, no in-project real farm photos, and unsupported crops. Treat these as preliminary research metrics, not validated clinical/agronomic performance. |
| Backend speech-to-text | `backend/app/services/stt_service.py` always returns a fixed sample transcript. `STT_PROVIDER` is present in settings but does not currently select an actual backend STT implementation. The `/assistant/voice*` endpoints are consequently demo-only for transcription. |
| FarukSTT / voice pipeline | `ai/voice/voice_pipeline.py` is a separate command-line demo that references `medyas/FarukSTT`, Transformers, PyTorch, and audio decoding; dependencies/model download are not provided by the normal app setup. It calls irrigation advice and plays pre-recorded clips, not generated speech. `ai/stt/README.md` describes a preliminary 20-question evaluation, not production validation. |
| OpenAI configuration | OpenAI key/embedding model settings are declared, but the current irrigation implementation uses local BM25 and Groq; no OpenAI provider path is verified in these routers/services. |

### Vision developer environment (standalone experiments)

The vision tools require Python packages from `ai/vision/requirements-vision.txt` and a CPU or CUDA PyTorch/torchvision build. Training also requires prepared PlantVillage/PlantDoc data and downloads pretrained torchvision backbone weights if not cached. Data/model artifacts are intentionally not checked into Git. Consult [`ai/vision/README.md`](ai/vision/README.md) and each script's `--help` for preparation and training commands. The README documents an example `predict_probe_image` call, but it is a library-level demonstration, not an API endpoint.

## Database

The Compose database is PostgreSQL 16. SQLAlchemy async models are registered in `backend/app/models/__init__.py`; Alembic migrations live in `backend/migrations/versions/`. The container applies migrations at startup. Local backend runs must apply them explicitly.

| Table / entity | Main purpose and links |
|---|---|
| `users` | Account, role, verification and status fields. Parent of farms, identities, refresh sessions, social data, diagnoses, and advice. |
| `auth_identities` | External provider subject linked to a user. |
| `pending_verifications` | Temporary email/phone registration verification state and attempt/expiry data. |
| `refresh_sessions` | Hashed refresh token, family/rotation, expiry and revocation state. |
| `farms` | Owned farm profile, location, crop/soil/irrigation attributes and coordinates. |
| `crops` | Crop records for a farm. |
| `devices` | Farm device, hashed device key, activation/simulation and last-seen state. |
| `sensor_readings` | Timestamped soil-moisture, temperature and humidity samples linked to device. |
| `farm_alerts` | Farm/device alerts and acknowledgement time. |
| `diagnosis_cases` | Uploaded photo path, symptoms, case status, farmer/farm/crop and optional expert response. |
| `advice_log` | User/farm questions and responses, confidence, escalation and text/voice channel. |
| `expert_cases`, `expert_reviews` | Escalated assistant cases and expert review decisions. |
| `user_profiles`, `social_posts`, `social_connections`, `social_conversations`, `social_messages` | Social profile, feed, connection, conversation, and message data. |
| `readings` | Legacy/compatibility reading model retained in the model registry; current device routes primarily use `sensor_readings`. |

```mermaid
erDiagram
    USERS ||--o{ FARMS : owns
    USERS ||--o{ AUTH_IDENTITIES : links
    USERS ||--o{ REFRESH_SESSIONS : has
    USERS ||--o{ PENDING_VERIFICATIONS : verifies
    FARMS ||--o{ CROPS : grows
    FARMS ||--o{ DEVICES : monitors
    DEVICES ||--o{ SENSOR_READINGS : reports
    FARMS ||--o{ FARM_ALERTS : raises
    USERS ||--o{ ADVICE_LOG : asks
    FARMS ||--o{ ADVICE_LOG : concerns
    FARMS ||--o{ EXPERT_CASES : escalates
    ADVICE_LOG ||--o{ EXPERT_CASES : may_create
    USERS ||--o{ DIAGNOSIS_CASES : submits
    FARMS ||--o{ DIAGNOSIS_CASES : concerns
    CROPS o|--o{ DIAGNOSIS_CASES : optionally_identifies
    USERS ||--o{ USER_PROFILES : has
    USERS ||--o{ SOCIAL_POSTS : authors
    USERS ||--o{ SOCIAL_CONNECTIONS : requests
    USERS ||--o{ SOCIAL_CONVERSATIONS : participates
    SOCIAL_CONVERSATIONS ||--o{ SOCIAL_MESSAGES : contains
```

`backend/alembic.ini` points to `backend/migrations`; `backend/migrations/env.py` reads the configured database URL. The repository also contains `backend/alembic/`, an older migration tree not selected by this Alembic configuration. Useful commands from `backend/`:

```powershell
alembic current
alembic history
alembic upgrade head
alembic downgrade -1  # development only; understand data impact first
```

The root Compose database is not published to the host by default; use `docker compose exec db psql -U aethera -d aethera` (replace with configured database/user) to inspect it. Back up before destructive operations. `docker compose down` preserves named volumes. `docker compose down -v` deletes the database and upload data and should be used only when intentionally resetting local development data.

## Installation and local development

### Prerequisites

- Git.
- Docker Desktop with Compose v2 (recommended backend/database workflow).
- Flutter SDK whose Dart version satisfies `^3.10.0` for `app/`; use `flutter doctor` to check platform tooling.
- Windows 10/11 is the documented primary environment. Chrome is needed for web runs; Windows desktop requires Visual Studio C++ desktop workload. Android builds require Android Studio/SDK and an emulator or device.
- Optional: Python 3.13 to match the backend image (the requirements are in `backend/requirements.txt`); a local PostgreSQL instance for running the API outside Docker.

### 1. Get the source and create environment configuration

```powershell
git clone <repository-url> aethera
cd aethera
Copy-Item .env.example .env
```

Edit `.env` and replace `POSTGRES_PASSWORD` and `JWT_SECRET_KEY` with strong, separate random values. Do not use the example demo password for a public environment and do not commit `.env` or secrets. The Compose file requires both database and JWT secrets.

For example, generate a hex secret in PowerShell:

```powershell
$bytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
[System.BitConverter]::ToString($bytes).Replace('-', '').ToLowerInvariant()
```

Repeat for the database password and set each output in `.env`. If `.env` already exists, edit it without overwriting local values.

### 2. Start PostgreSQL and the API

From the repository root:

```powershell
docker compose up -d --build db backend
docker compose ps
Invoke-RestMethod http://localhost:8000/health
```

The backend starts after PostgreSQL is healthy, applies Alembic migrations, creates the configured local demo farmer if absent, then serves the API. Open `http://localhost:8000/docs` to inspect and call endpoints.

### 3. Install and run the integrated Flutter app

```powershell
cd app
flutter doctor
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Other targets, from `app/`:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000
# Android emulator (standard Android Studio emulator networking):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
# Physical Android device on the same network:
flutter run --dart-define=API_BASE_URL=http://<PC-LAN-IP>:8000
```

For a physical device, use the PC's LAN IPv4 address, allow inbound TCP port 8000 through the local firewall, and keep the phone and PC on a reachable network. Firebase authentication additionally requires a matching Firebase app/project and enabled provider configuration. Google/phone backend token verification requires a Firebase Admin service-account JSON outside version control; with the root Compose setup, the expected file is `backend/secrets/firebase-adminsdk.json`.

### 4. Optional backend outside Docker

From `backend/`, create a virtual environment and install requirements:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Edit `backend/.env`: set `DATABASE_URL` to a PostgreSQL database reachable from the host (the root Compose database has no host port published by default), set `JWT_SECRET_KEY`, and add any optional SMTP/Firebase/LLM values. Then:

```powershell
alembic upgrade head
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Local app config reads the backend process environment/`backend/.env`; Docker reads the root `.env` and injects service environment variables. Do not assume `backend/.env` changes affect the Compose container.

### 5. Local demo account

On Compose startup, `backend/app/seed_demo_account.py` creates an already verified farmer only if the configured email does not exist. Root `.env.example` currently supplies the local defaults `demo@example.com` / `AetheraDemo!2026`; treat them as development-only and change them before first startup. The seed does not reset an existing account's password. Disable it with `DEMO_ACCOUNT_ENABLED=false` outside local development.

For an admin account, use the repository's `backend/create_admin.py` setup script or an existing admin. The interactive `backend/reset_admin_password.py` script resets an existing admin by email without echoing the password:

```powershell
docker compose exec -it backend python reset_admin_password.py
```

## Docker operations

The root [`docker-compose.yml`](docker-compose.yml) defines:

| Service | Container/port | Notes |
|---|---|---|
| `db` | PostgreSQL 16, internal port 5432 | Healthy check uses `pg_isready`; data persists in `postgres_data`. No host port is published by default. |
| `backend` | FastAPI, host port `${API_PORT:-8000}` to container 8000 | Waits for healthy DB, migrates and seeds at startup, mounts uploads and Firebase secrets, and has an HTTP health check. |

The root Compose file does **not** build Flutter. Run Flutter locally for hot reload. `docker-compose.simulator.yml` is an optional Compose overlay for the simulator container and requires simulator device settings; see [Sensors](#implemented-features-and-status). `backend/docker-compose.yml` is another configuration and is not the root workflow described here; inspect its services/ports before using it.

```powershell
# Start/rebuild the normal API stack
docker compose up -d --build db backend

# Status and logs
docker compose ps
docker compose logs -f backend
docker compose logs -f db

# Restart after environment/configuration changes
docker compose restart backend

# Apply migrations or open PostgreSQL shell
docker compose exec backend alembic upgrade head
docker compose exec db psql -U aethera -d aethera

# Stop, preserving data
docker compose down
```

Compose service networking uses `db:5432`; from the host Flutter app use `localhost:8000`. Uploaded media and database files persist in named volumes. A service image must be rebuilt after Python dependency or backend image-source changes (`docker compose up -d --build backend`).

## Configuration reference

Variables below are read by backend settings, root Compose interpolation, or its startup seed. A value is required by the root Compose invocation only where marked. Blank optional variables intentionally leave integrations disabled. Never put real keys or passwords in this table or source control.

| Variable | Purpose | Required? | Example / default |
|---|---|---|---|
| `POSTGRES_DB` | Compose database name. | Compose default | `aethera` |
| `POSTGRES_USER` | Compose database user. | Compose default | `aethera` |
| `POSTGRES_PASSWORD` | Compose database password. | Yes for root Compose | `<strong-local-secret>` |
| `DATABASE_URL` | Backend SQLAlchemy connection URL (local backend). Compose constructs it internally for Docker. | Backend required | `postgresql+psycopg://USER:PASSWORD@localhost:5432/aethera` for local process; Compose uses asyncpg at `db:5432`. |
| `JWT_SECRET_KEY` | Signing key for local JWT tokens. | Yes for root Compose/backend | `<random-secret>` |
| `APP_NAME`, `APP_ENV` | Service label and environment; `APP_ENV` affects refresh-cookie `Secure`. | Optional | `AETHERA API`, `development` |
| `JWT_ALGORITHM`, `JWT_ISSUER`, `JWT_AUDIENCE` | JWT validation contract. | Optional | `HS256`, `aethera-api`, `aethera-mobile` |
| `ACCESS_TOKEN_EXPIRE_MINUTES`, `REFRESH_TOKEN_EXPIRE_DAYS` | Token lifetimes. | Optional | `15`, `30` |
| `EMAIL_OTP_PEPPER`, `EMAIL_OTP_EXPIRE_MINUTES`, `EMAIL_OTP_MAX_ATTEMPTS`, `EMAIL_OTP_RESEND_COOLDOWN_SECONDS` | OTP hashing and expiry/abuse controls. | Pepper recommended; others default | `<random-secret>`, `10`, `5`, `60` |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL`, `SMTP_USE_TLS` | Email OTP delivery. Configure valid SMTP credentials for registration verification emails. | Optional for boot; needed for delivery | `smtp.gmail.com`, `587`, `<account>`, `<app-password>`, `<sender>`, `true` |
| `FIREBASE_PROJECT_ID`, `FIREBASE_CREDENTIALS_PATH` | Firebase Admin verification for phone/Google identity. Docker Compose sets the file path to `/run/secrets/firebase-admin/firebase-adminsdk.json`. | Required for Firebase verification only | `<firebase-project-id>`, `/run/secrets/firebase-admin/firebase-adminsdk.json` in Docker |
| `CORS_ORIGINS` | Comma-separated additional origins. Localhost/127.0.0.1 HTTP origins are also allowed by regex. | Optional | `http://localhost:8080` |
| `API_PORT` | Host port mapped to backend 8000. | Optional | `8000` |
| `DEMO_ACCOUNT_ENABLED`, `DEMO_ACCOUNT_EMAIL`, `DEMO_ACCOUNT_PASSWORD`, `DEMO_ACCOUNT_NAME` | Idempotent development farmer seed. | Optional | `true`, `demo@example.com`, `<12+ character password>`, `AETHERA Demo Farmer` |
| `SEED_ON_START` | Optional additional demo seed hook in application lifespan. | Optional | `false` |
| `SIMULATE_SENSORS` | Allow sensor endpoint fallback readings when configured/no real readings exist. | Optional | `true` |
| `ASSISTANT_PROVIDER` | Selects general chat stub or Groq service. | Optional | `stub` or `groq` |
| `GROQ_API_KEY`, `GROQ_MODEL`, `GROQ_BASE_URL` | Groq-compatible chat completion integration used by assistant/advisor. | Key needed for live Groq | `<api-key>`, `openai/gpt-oss-20b`, `https://api.groq.com/openai/v1` |
| `OPENAI_API_KEY`, `RAG_EMBEDDER`, `RAG_OPENAI_MODEL` | Declared configuration for possible OpenAI embedding use. | Not required; no current active OpenAI path verified | `<api-key>`, `hash`, `text-embedding-3-small` |
| `STT_PROVIDER` | Declared voice provider setting; current backend factory still returns stub. | Optional / currently no effect | `stub` |
| `OLLAMA_BASE_URL`, `OLLAMA_MODEL`, `OLLAMA_TIMEOUT_SECONDS` | Ollama settings/helper; not selected by current irrigation advisor fallback. | Optional / not on active path | `http://host.docker.internal:11434`, `qwen3:4b`, `120` |
| `API_BASE_URL` | Flutter compile-time REST API URL (not a backend environment variable). | Optional | `http://localhost:8000` |
| `SIMULATOR_DEVICE_ID`, `SIMULATOR_DEVICE_KEY`, `SIMULATOR_INTERVAL_SECONDS`, `SIMULATOR_SCRIPT_PATH` | Optional simulator Compose overlay settings. | Required only for simulator overlay | `<device-uuid>`, `<one-time-device-key>`, `5`, `./firmware/simulator.py` |

Use root `.env` for Compose. Use `backend/.env` for a locally launched API process. `FIREBASE_CREDENTIALS_PATH` in container must point to a file mounted in the container; the host path alone is not sufficient.

## Testing and verification

### Backend tests

From `backend/` with Python dependencies installed:

```powershell
python -m pytest tests -q
```

The suite covers authentication, safety, irrigation advice, assistant behavior, sensors, device ingestion, and agronomy retrieval. Test fixtures/configuration are in `backend/tests/conftest.py` and `backend/pytest.ini`.

### Flutter checks

From `app/`:

```powershell
flutter pub get
flutter analyze
flutter test
```

The `frontend/aethera_flutter/` folder has its own `flutter pub get` and `flutter test` context; running checks there does not test `app/`.

### API and runtime checks

```powershell
Invoke-RestMethod http://localhost:8000/health
Invoke-WebRequest http://localhost:8000/openapi.json
docker compose ps
docker compose logs --tail 100 backend
```

For a full local integration check, verify the database migration completed, create/login to a farmer, create a farm, check forecast, call advice, and confirm history appears. For sensor integration, register a device, securely retain its one-time key, then submit a device reading. For Google/phone auth, provide valid Firebase client configuration and a mounted Firebase Admin key. For email registration, configure working SMTP and verify code delivery.

The vision unit tests under `ai/vision/tests/` exercise model-independent prediction/decision helpers and audit/training utilities, but they do not prove that inference works without dependencies, data, and a trained checkpoint. Voice quality likewise requires real audio, model dependencies, and separate evaluation.

## Troubleshooting

| Symptom | Likely cause | Checks / resolution |
|---|---|---|
| Flutter cannot reach the API | Wrong `API_BASE_URL`, backend stopped, or device networking mismatch. | Check `docker compose ps` and `http://localhost:8000/health`; rerun with `--dart-define=API_BASE_URL=...`. Android emulator uses `10.0.2.2`; physical devices use host LAN IP. |
| Browser CORS error | Web origin is not allowed. | Add exact origin to comma-separated `CORS_ORIGINS` in root `.env`, restart backend. Local HTTP localhost/127.0.0.1 ports are covered by the app regex; HTTPS/public origins are not. |
| Docker says required variable missing | `.env` absent or `POSTGRES_PASSWORD`/`JWT_SECRET_KEY` still unset/invalid. | Copy `.env.example` once, configure required secrets, retry `docker compose config` and `docker compose up`. |
| Backend unhealthy or exits | DB not healthy, migration failure, invalid config, or port collision. | Inspect `docker compose logs db backend`, `docker compose ps`; check port 8000 and credentials, then rebuild/restart. |
| PostgreSQL connection refused in local API | Root Compose DB is not published to host. | Run API inside Compose or use a separately reachable PostgreSQL and set local `DATABASE_URL`. Do not use hostname `db` from a host-launched process. |
| Missing tables / schema mismatch | Migrations have not been applied or process uses a different database. | `docker compose exec backend alembic current`; apply `alembic upgrade head` against the intended DB. |
| Email registration returns delivery error | SMTP credentials/from address missing or rejected. | Configure SMTP variables in the environment loaded by the backend and inspect backend logs. |
| Google/phone token verification fails | Client Firebase project differs from server project, provider disabled, Admin service account missing/unmounted, or invalid token. | Match Firebase project IDs, enable the provider, mount the private Admin JSON at the configured path, restart backend. Keep the JSON out of Git. |
| Login returns 401 | Incorrect credentials, inactive/unverified account, or wrong login method. | Check email/phone and account state. The demo seed does not reset passwords. Admin password can be reset interactively with the repository script. |
| Refresh/login loop | Stale/expired refresh token or client storage cleared/invalid. | Sign out/clear app token storage and sign in again; inspect `/auth/refresh` response and API logs. |
| Uploaded images return 404 | Upload volume/path mismatch or file not persisted. | Check backend uploads volume and returned `/uploads/...` path; confirm app uses the same API host. |
| Diagnosis does not return model prediction | The diagnosis route creates an expert-review case; vision inference is not wired to it. | Use expert queue workflow. A model checkpoint and explicit service integration are required for automated classification. |
| Voice response repeats sample transcript | Backend `StubSTTService` is always selected. | Treat voice endpoint as a demo; FarukSTT CLI is a separate path with additional dependencies. |
| Vision import/model load fails | PyTorch/torchvision/Pillow missing, incompatible CPU/CUDA build, checkpoint absent, or model data absent. | Install `ai/vision/requirements-vision.txt` plus appropriate PyTorch, prepare datasets/train or provide the expected ignored model artifact; see vision README. |
| Flutter build or plugin error | SDK/platform toolchain mismatch or dependencies not fetched. | Check `flutter --version`, `flutter doctor`, run `flutter pub get` inside `app/`, and use the documented Dart SDK constraint. |
| Simulator cannot post readings | Wrong ID/key/API URL, device inactive, or simulator overlay lacks required env values. | Confirm device key was saved at registration, set simulator variables, inspect API logs, and don't share keys in logs/issues. |

## Project structure

```text
.
├── app/                         # Integrated Flutter application to run
│   ├── lib/core/                # API config/client, token storage, settings, theme
│   ├── lib/features/            # Auth, farmer, assistant, diagnosis, admin, etc.
│   ├── lib/l10n/                # English/French/Arabic ARB and generated localization
│   ├── test/                    # Flutter tests
│   └── web/, android/, ios/     # Platform runners/configuration
├── frontend/aethera_flutter/    # Separate retained Flutter client/prototype
├── backend/
│   ├── app/routers/             # REST endpoints
│   ├── app/services/            # Auth, assistant, irrigation, weather, safety, etc.
│   ├── app/models/              # SQLAlchemy entities
│   ├── app/schemas/             # Pydantic request/response types
│   ├── migrations/              # Alembic revisions
│   ├── tests/                   # FastAPI/backend tests
│   └── uploads/                 # Runtime upload paths (persisted by Docker volume)
├── ai/
│   ├── assistant/               # Assistant safety/prompt notes
│   ├── retrieval/               # BM25 retrieval index and source catalog
│   ├── stt/                     # STT evaluation notes/notebook
│   ├── vision/                  # Experimental image model scripts/tests
│   └── voice/                   # Separate audio -> assistant -> clip demo
├── firmware/                    # Simulator; ESP32 firmware is not present
├── docker/                      # Optional simulator image
├── docs/                        # Architecture/feature notes
├── docker-compose.yml           # Root PostgreSQL + API stack
└── .env.example                 # Root Compose example configuration
```

## Security notes

### Implemented protections

- Passwords are hashed; bcrypt is used for typical passwords and the configured password-hash library supports longer input/legacy Argon2 verification.
- Access tokens are signed and checked for issuer, audience, expiry, and required claims. Refresh tokens are stored hashed, rotated, and revocable; reuse detection is implemented in auth services.
- Role and ownership dependencies protect administrative, expert, farmer, and farm-scoped routes.
- Pydantic schemas validate types and field constraints. Crop-photo upload validates JPG/PNG/WEBP signatures and caps file size at 8 MiB.
- Device keys are returned when a device is created and stored as hashes; reading ingestion authenticates using the device key.
- CORS is configurable. Firebase service-account secrets are expected outside source control; Docker mounts the backend secrets directory read-only and ignores secret JSON in build context.
- Safety rules can refuse or escalate some assistant questions; model prompts alone are not the only enforcement point.

### Before production

Development demo-account seeding is enabled by default in the example Compose configuration. Set a private demo password or disable seeding before public deployment. Supply production secrets through a secret manager, use HTTPS and secure cookie settings (`APP_ENV` must not be `development`), restrict CORS to trusted origins, configure Firebase/SMTP/LLM credentials securely, and review upload access/retention. The `/health` route is liveness-only. No production deployment or cloud-secret-manager setup is established by the root Compose file.

## Roadmap based on repository state

### Implemented in the current source

- FastAPI/PostgreSQL auth, farm/crop, sensor, weather, social, assistant, diagnosis-case, expert, and admin APIs.
- Flutter integrated client in `app/`, with auth/role screens, selected farm workflows, preferences/localization, and API adapters.
- Alembic migration history, local simulator, safety tests, and local BM25 agronomy index.

### Partial or demo-only

- General chat uses a keyword stub unless Groq is configured. Irrigation advice has a Groq call plus rules fallback.
- Voice backend uses a fixed transcript; FarukSTT exists as a standalone experiment/demo and needs integration/dependency management.
- Crop photo diagnosis is manual expert review; standalone classifier lacks committed weights and API wiring.
- Sensor simulator works against a registered device, but physical firmware is absent.
- UI/API integration and localization vary by screen; verify each client workflow against the backend.

### Remaining work evidenced by the code

- Connect a versioned, evaluated vision model to a safe service/API flow and define checkpoint deployment/storage.
- Replace the backend STT stub with a provider implementation and retain explicit transcript confirmation.
- Add real-device firmware/hardware documentation and validate sensor readings in field conditions.
- Run broader agronomist-reviewed evaluation for assistant and crop conditions; clarify commercial rights for dataset/retrieval material.
- Complete a production deployment configuration, secret provisioning, observability, backups, and upload retention policy.
- Audit remaining hard-coded strings and ensure consistent Arabic layout/translation coverage.

## Contributing

1. Create a feature branch from the current integration branch.
2. Keep changes focused and update documentation for API/configuration changes.
3. Run backend tests from `backend/` and Flutter analysis/tests from `app/` for affected areas.
4. Do not commit `.env`, Firebase service-account JSON, API keys, user photos/audio, datasets, generated build folders, or model checkpoints unless the project has explicitly approved and licensed those artifacts.
5. Open a pull request describing behavior, configuration changes, tests, and any known limitations.

```bash
git switch -c feature/short-description
git status --short
git add README.md backend app
git commit -m "Describe the change"
git push -u origin feature/short-description
```

For a documentation-only change, stage only the documentation file. Review `git diff` before committing.
