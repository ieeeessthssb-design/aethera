
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "AETHERA API"
    app_env: str = "development"

    database_url: str

    # JWT authentication
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_issuer: str = "aethera-api"
    jwt_audience: str = "aethera-mobile"

    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 30

    # Email OTP security
    email_otp_pepper: str | None = None
    email_otp_expire_minutes: int = 10
    email_otp_max_attempts: int = 5
    email_otp_resend_cooldown_seconds: int = 60

    # Gmail SMTP - real email delivery
    smtp_host: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_username: str | None = None
    smtp_password: str | None = None
    smtp_from_email: str | None = None
    smtp_use_tls: bool = True

    # Firebase Phone Authentication
    firebase_project_id: str | None = None
    firebase_credentials_path: str | None = None

    # Assistant, speech, weather and sensor integrations from origin/main.
    cors_origins: str = "http://localhost:3000,http://localhost:4200,http://localhost:8080,http://localhost:4010"
    assistant_provider: str = "stub"
    openai_api_key: str = ""
    groq_api_key: str = ""
    groq_model: str = "openai/gpt-oss-20b"
    groq_base_url: str = "https://api.groq.com/openai/v1"
    stt_provider: str = "stub"
    rag_embedder: str = "hash"
    rag_openai_model: str = "text-embedding-3-small"
    ollama_base_url: str = "http://host.docker.internal:11434"
    ollama_model: str = "qwen3:4b"
    ollama_timeout_seconds: int = 120
    # Startup seeding must be explicitly enabled; local databases use Alembic.
    seed_on_start: bool = False
    simulate_sensors: bool = True

    @property
    def async_database_url(self) -> str:
        url = self.database_url
        if url.startswith("postgres://"):
            return "postgresql+asyncpg://" + url[len("postgres://"):]
        if url.startswith("postgresql://"):
            return "postgresql+asyncpg://" + url[len("postgresql://"):]
        if url.startswith("postgresql+psycopg://"):
            return "postgresql+asyncpg://" + url[len("postgresql+psycopg://"):]
        return url

    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def jwt_secret(self) -> str:
        return self.jwt_secret_key

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
