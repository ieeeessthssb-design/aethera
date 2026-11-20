"""Application settings loaded from environment variables."""
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Database
    database_url: str = "postgresql+asyncpg://aethera:aethera_pass@localhost:5432/aethera_db"

    # JWT
    jwt_secret: str = "dev-secret-change-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_days: int = 7

    # CORS
    cors_origins: str = "http://localhost:3000,http://localhost:4200,http://localhost:8080,http://localhost:4010"

    @property
    def async_database_url(self) -> str:
        u = self.database_url
        for a in ("postgres://", "postgresql://"):
            if u.startswith(a):
                return "postgresql+asyncpg://" + u[len(a):]
        return u

    @property
    def cors_origins_list(self) -> List[str]:
        return [o.strip() for o in self.cors_origins.split(",")]

    # Assistant
    assistant_provider: str = "stub"  # stub | openai | groq
    openai_api_key: str = ""
    groq_api_key: str = ""
    llm_model: str = ""          # empty = provider default (see irrigation_llm.DEFAULTS)
    llm_timeout_s: float = 25.0
    weather_enabled: bool = True  # Open-Meteo lookup for irrigation advice

    # STT
    stt_provider: str = "stub"  # stub | whisper

    # Feature flags
    seed_on_start: bool = True
    simulate_sensors: bool = True  # auto-generate simulated data when no device


settings = Settings()
