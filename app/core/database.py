"""Async SQLAlchemy engine and session factory."""
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    create_async_engine,
    async_sessionmaker,
)
from sqlalchemy.orm import DeclarativeBase
from app.core.config import settings

# Create async engine
_kw = {} if settings.async_database_url.startswith("sqlite") else {"pool_size": 10, "max_overflow": 20}
engine = create_async_engine(settings.async_database_url, echo=False, pool_pre_ping=True, **_kw)

# Session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """Base class for all ORM models."""
    pass
