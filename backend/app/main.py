from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers.admin import router as admin_router
from app.routers.farms import router as farms_router
from app.routers.auth import router as auth_router
from app.routers.crops import router as crops_router
from app.routers.devices import router as devices_router
from app.routers.social import router as social_router
from pathlib import Path
from fastapi.staticfiles import StaticFiles
from app.routers.diagnoses import router as diagnoses_router
from app.routers.weather import router as weather_router
app = FastAPI(
    title="AETHERA API",
    description="AI-powered agricultural assistance platform for Tunisian farmers.",
    version="0.1.0",
)

UPLOAD_ROOT = Path(__file__).resolve().parent.parent / "uploads"
(UPLOAD_ROOT / "diagnoses").mkdir(parents=True, exist_ok=True)

app.mount(
    "/uploads",
    StaticFiles(directory=str(UPLOAD_ROOT)),
    name="uploads",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:8000",
        "http://localhost:8080",
    ],
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(admin_router)
app.include_router(farms_router)
app.include_router(crops_router)
app.include_router(devices_router)
app.include_router(social_router)
app.include_router(diagnoses_router)
app.include_router(weather_router)

@app.get("/")
async def root():
    return {
        "project": "AETHERA",
        "message": "Welcome to the AETHERA API!",
        "version": "0.1.0",
        "status": "running",
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "aethera-backend",
    }
