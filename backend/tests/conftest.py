"""Pytest configuration and fixtures."""
import pytest
import asyncio
import os

# Use in-memory SQLite for tests
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///./test.db")
os.environ.setdefault("JWT_SECRET", "test-secret-do-not-use-in-production")
os.environ.setdefault("SIMULATE_SENSORS", "true")


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session", autouse=True)
def _create_tables():
    """Create tables in the SQLite test DB once per session."""
    from app.core.database import Base, engine
    import app.models  # noqa

    async def _go():
        async with engine.begin() as c:
            await c.run_sync(Base.metadata.drop_all)
            await c.run_sync(Base.metadata.create_all)

    asyncio.run(_go())