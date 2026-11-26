"""Pytest configuration and isolated async database lifecycle."""
import os

import pytest_asyncio

# Never let Compose or a developer's local DATABASE_URL point tests at the
# application database. TEST_DATABASE_URL is an explicit opt-in override.
os.environ["DATABASE_URL"] = os.environ.get(
    "TEST_DATABASE_URL", "sqlite+aiosqlite:///./test.db"
)
# The engine is disposed around every test so async connections never cross loops.
os.environ.setdefault("JWT_SECRET_KEY", "pytest-only-secret-not-for-deployment")
os.environ.setdefault("EMAIL_OTP_PEPPER", "pytest-only-pepper-not-for-deployment")
os.environ.setdefault("SIMULATE_SENSORS", "true")


@pytest_asyncio.fixture(autouse=True)
async def _isolated_database():
    """Create a clean schema on the test's loop and dispose its connections."""
    from app.core.database import Base, engine
    import app.models  # noqa: F401

    await engine.dispose()
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.drop_all)
        await connection.run_sync(Base.metadata.create_all)

    yield

    await engine.dispose()
