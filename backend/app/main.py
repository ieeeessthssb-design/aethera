from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.core.database import close_database
from app import models  # noqa: F401 - register all ORM models for Alembic
from app.routers import admin, assistant, auth, crops, devices, diagnoses, expert, farms, sensors, social, weather


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Schema changes are managed by Alembic. Optional demo rows are seeded only
    # when explicitly enabled after migrations have been applied.
    if settings.seed_on_start:
        from app.seed import seed
        await seed()
    yield
    await close_database()


app = FastAPI(
    title="AETHERA API",
    description="AI-powered agricultural assistance platform for Tunisian farmers.",
    version="1.0.0",
    lifespan=lifespan,
)

UPLOAD_ROOT = Path(__file__).resolve().parent.parent / "uploads"
(UPLOAD_ROOT / "diagnoses").mkdir(parents=True, exist_ok=True)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

for router in (
    auth.router, admin.router, farms.router, crops.router, devices.router,
    social.router, diagnoses.router, weather.router, assistant.router,
    expert.router, sensors.router,
):
    app.include_router(router)


UPLOAD_ROOT.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_ROOT)), name="uploads")

@app.get("/")
async def root():
    return {
        "project": "AETHERA",
        "message": "Welcome to the AETHERA API!",
        "version": "1.0.0",
        "status": "running",
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "aethera-backend",
    }
