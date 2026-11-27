"""Interactively reset the password of an existing admin account."""

import asyncio
from getpass import getpass

from sqlalchemy import select

from app.core.database import AsyncSessionLocal, close_database
from app.core.security import hash_password
from app.models.user import User


async def reset_admin_password() -> None:
    email = input("Existing admin email: ").strip().lower()
    if not email or "@" not in email:
        print("Enter a valid admin email.")
        return

    password = getpass("New admin password (minimum 12 characters): ")
    confirmation = getpass("Confirm new password: ")
    if len(password) < 12:
        print("Password must contain at least 12 characters.")
        return
    if password != confirmation:
        print("Passwords do not match.")
        return

    async with AsyncSessionLocal() as db:
        admin = await db.scalar(
            select(User).where(User.email == email, User.role == "admin")
        )
        if admin is None:
            print("No admin account found for that email.")
            return

        admin.password_hash = hash_password(password)
        await db.commit()
        print("Admin password updated. Sign in with the new password.")


async def main() -> None:
    try:
        await reset_admin_password()
    finally:
        await close_database()


if __name__ == "__main__":
    asyncio.run(main())
