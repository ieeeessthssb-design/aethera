
import hashlib
from typing import Annotated
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import InvalidTokenError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.tokens import decode_access_token
from app.models.user import User
from app.models.device import Device

bearer_scheme = HTTPBearer(auto_error=False)

DbSession = Annotated[AsyncSession, Depends(get_db)]


async def get_current_user(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None,
        Depends(bearer_scheme),
    ],
    db: DbSession,
) -> User:
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Authentication required.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if credentials is None or credentials.scheme.lower() != "bearer":
        raise unauthorized

    try:
        claims = decode_access_token(credentials.credentials)

        if claims.get("type") != "access":
            raise unauthorized

        user = await db.scalar(
            select(User).where(User.id == UUID(claims["sub"]))
        )
    except (InvalidTokenError, ValueError, TypeError, KeyError):
        raise unauthorized from None

    if user is None or not user.is_active:
        raise unauthorized

    return user


async def require_expert(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != "expert":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Expert role required")
    if current_user.expert_approval_status not in ("approved", "not_applicable"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Expert account is not approved")
    return current_user


async def get_device_from_key(
    db: DbSession,
    x_device_key: Annotated[str | None, Header(alias="X-Device-Key")] = None,
) -> Device:
    if not x_device_key:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing X-Device-Key header")
    digest = hashlib.sha256(x_device_key.encode("utf-8")).hexdigest()
    device = await db.scalar(select(Device).where(Device.key_hash == digest, Device.is_active.is_(True)))
    if device is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or inactive device key")
    return device
