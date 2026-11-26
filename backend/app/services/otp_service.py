
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone

from app.core.config import settings


def generate_email_otp() -> str:
    """Generate a cryptographically secure six-digit verification code."""
    return f"{secrets.randbelow(1_000_000):06d}"


def hash_email_otp(code: str) -> str:
    """Create a keyed SHA-256 hash of the verification code."""
    pepper = settings.email_otp_pepper

    if not pepper:
        raise RuntimeError("Email OTP pepper is not configured.")

    return hmac.new(
        pepper.encode("utf-8"),
        code.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def verify_email_otp(code: str, stored_hash: str) -> bool:
    """Compare a submitted code with its stored hash safely."""
    if len(code) != 6 or not code.isdigit():
        return False

    try:
        submitted_hash = hash_email_otp(code)
    except RuntimeError:
        return False

    return hmac.compare_digest(submitted_hash, stored_hash)


def email_otp_expiration() -> datetime:
    """Return the expiration time for a new verification code."""
    return datetime.now(timezone.utc) + timedelta(
        minutes=settings.email_otp_expire_minutes
    )
