import uuid
from datetime import datetime, timedelta, timezone

import jwt

from app.core.config import settings


def create_access_token(subject: str, extra_claims: dict | None = None) -> str:
    """Create a signed, short-lived JWT access token."""
    now = datetime.now(timezone.utc)

    payload = {
        "sub": subject,
        "iss": settings.jwt_issuer,
        "aud": settings.jwt_audience,
        "iat": now,
        "exp": now + timedelta(minutes=settings.access_token_expire_minutes),
        "jti": str(uuid.uuid4()),
        "type": "access",
    }
    if extra_claims:
        payload.update(extra_claims)
        # Keep the local token contract authoritative if a caller supplies claims.
        payload.update({"sub": subject, "iss": settings.jwt_issuer,
                        "aud": settings.jwt_audience, "type": "access"})

    return jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def decode_access_token(token: str) -> dict:
    """Verify a JWT's signature and required claims."""
    return jwt.decode(
        token,
        settings.jwt_secret_key,
        algorithms=[settings.jwt_algorithm],
        issuer=settings.jwt_issuer,
        audience=settings.jwt_audience,
        options={
            "require": ["sub", "iss", "aud", "iat", "exp", "jti"],
        },
    )
