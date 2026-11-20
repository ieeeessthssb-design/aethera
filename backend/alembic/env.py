import asyncio
from alembic import context
from sqlalchemy.ext.asyncio import create_async_engine
from app.core.config import settings
from app.core.database import Base
import app.models  # noqa

target = Base.metadata

def _run(conn):
    context.configure(connection=conn, target_metadata=target)
    with context.begin_transaction():
        context.run_migrations()

async def main():
    eng = create_async_engine(settings.async_database_url)
    async with eng.connect() as c:
        await c.run_sync(_run)

asyncio.run(main())
