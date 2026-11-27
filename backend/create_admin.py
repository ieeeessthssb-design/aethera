
import asyncio
from getpass import getpass

from sqlalchemy import func, select

from app.core.database import AsyncSessionLocal, close_database
from app.core.security import hash_password
from app.models.user import User


async def create_admin():
    print("\n=== AETHERA: First Admin Setup ===\n")

    full_name = input("Admin full name: ").strip()
    email = input("Admin email: ").strip().lower()

    if len(full_name) < 2 or not email or "@" not in email:
        print("Invalid name or email.")
        return

    password = getpass("Admin password (minimum 12 characters): ")
    confirmation = getpass("Confirm password: ")

    if len(password) < 12:
        print("Password must contain at least 12 characters.")
        return

    if password != confirmation:
        print("Passwords do not match.")
        return

    async with AsyncSessionLocal() as db:
        existing_admins = await db.scalar(
            select(func.count()).select_from(User).where(
                User.role == "admin"
            )
        )

        if existing_admins:
            print("An admin account already exists. Setup cancelled.")
            return

        existing_user = await db.scalar(
            select(User).where(User.email == email)
        )

        if existing_user:
            print("This email already belongs to an account.")
            return

        admin = User(
            full_name=full_name,
            email=email,
            password_hash=hash_password(password),
            auth_provider="email",
            role="admin",
            expert_approval_status="not_applicable",
            is_active=True,
            is_verified=True,
            preferred_language="en",
        )

        db.add(admin)
        await db.commit()

        print("\nAdmin account created successfully!")
        print(f"Name: {full_name}")
        print("Role: admin")
        print("Status: active and verified")


async def main():
    try:
        await create_admin()
    finally:
        await close_database()


if __name__ == "__main__":
    asyncio.run(main())