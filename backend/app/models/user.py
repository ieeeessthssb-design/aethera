
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, synonym

from app.models.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    full_name: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
    )

    # Names used by origin/main's assistant and expert APIs.
    name = synonym("full_name")
    hashed_password = synonym("password_hash")
    phone = synonym("phone_number")

    email: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
        unique=True,
        index=True,
    )

    phone_number: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
        unique=True,
        index=True,
    )

    password_hash: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    auth_provider: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="email",
    )

    firebase_uid: Mapped[str | None] = mapped_column(
        String(128),
        nullable=True,
        unique=True,
    )

    role: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="farmer",
        server_default="farmer",
    )

    expert_approval_status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="not_applicable",
        server_default="not_applicable",
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )

    is_verified: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    preferred_language: Mapped[str] = mapped_column(
        String(5),
        default="en",
        nullable=False,
    )

    region: Mapped[str | None] = mapped_column(String(100), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
