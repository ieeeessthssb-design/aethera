"""Create a verified local demo farmer account once, when enabled."""

import asyncio
import os

from sqlalchemy import select

from app.core.database import AsyncSessionLocal, close_database
from app.core.security import hash_password
from app.models.user import User


async def seed_demo_account() -> None:
    enabled = os.getenv("DEMO_ACCOUNT_ENABLED", "true").strip().lower() in {"1", "true", "yes", "on"}
    if not enabled:
        print("Demo account seeding disabled.")
        return

    email = os.getenv("DEMO_ACCOUNT_EMAIL", "demo@example.com").strip().lower()
    # Normalize the previous .local default; EmailStr rejects special-use domains.
    if email.endswith(".local"):
        print("Legacy .local demo email detected; using demo@example.com instead.")
        email = "demo@example.com"
    password = os.getenv("DEMO_ACCOUNT_PASSWORD", "AetheraDemo!2026")
    full_name = os.getenv("DEMO_ACCOUNT_NAME", "AETHERA Demo Farmer").strip()

    if len(password) < 12:
        raise RuntimeError("DEMO_ACCOUNT_PASSWORD must contain at least 12 characters.")

    async with AsyncSessionLocal() as db:
        existing = await db.scalar(select(User).where(User.email == email))
        if existing is None:
            # Migrate the earlier development seed address without resetting its password.
            legacy = await db.scalar(select(User).where(User.email == "demo@aethera.local"))
            if legacy is not None:
                legacy.email = email
                await db.commit()
                print(f"Migrated existing demo account email to: {email}")
                return
        if existing is not None:
            print(f"Demo account already exists ({email}); existing credentials were not changed.")
            return

        user = User(
            full_name=full_name,
            email=email,
            password_hash=hash_password(password),
            auth_provider="email",
            role="farmer",
            expert_approval_status="not_applicable",
            is_active=True,
            is_verified=True,
            preferred_language="en",
        )
        db.add(user)
        await db.commit()
        print(f"Created verified local demo farmer account: {email}")


async def main() -> None:
    try:
        await seed_demo_account()
    finally:
        await close_database()


if __name__ == "__main__":
    asyncio.run(main())
