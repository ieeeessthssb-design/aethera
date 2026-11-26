
from functools import lru_cache

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
