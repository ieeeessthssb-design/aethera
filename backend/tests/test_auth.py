"""Tests for authentication endpoints."""
import pytest
from uuid import uuid4
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core.security import hash_password, verify_password, create_access_token, decode_token
from app.services import auth_service


# --- Unit tests for security functions ---

def test_hash_password():
    """Password hashing should produce a bcrypt hash."""
    hashed = hash_password("test_password")
    assert hashed != "test_password"
    assert hashed.startswith("$2b$")  # new hashes use bcrypt; verification also accepts legacy Argon2


def test_verify_password():
    hashed = hash_password("my_password")
    assert verify_password("my_password", hashed)
    assert not verify_password("wrong_password", hashed)


def test_create_and_decode_token():
    token = create_access_token({"sub": "test-user-id", "role": "farmer"})
    payload = decode_token(token)
    assert payload is not None
    assert payload["sub"] == "test-user-id"
    assert payload["role"] == "farmer"


def test_decode_invalid_token():
    result = decode_token("invalid.token.here")
    assert result is None


# --- Integration tests for auth endpoints ---

@pytest.mark.asyncio
async def test_registration_requires_email_verification(monkeypatch):
    """Main's simple registration is adapted to the local verified-email contract."""
    async def send_email(**kwargs):
        return None

    monkeypatch.setattr(auth_service, "send_verification_email", send_email)
    email = f"integration-{uuid4().hex}@example.com"
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # Accept the upstream `name` field but keep the local password policy
        # and OTP verification step.
        resp = await client.post("/auth/register", json={
            "name": "Test User",
            "email": email,
            "password": "password1234",
            "role": "farmer",
        })
        assert resp.status_code == 202
        assert resp.json()["verification_required"] is True

        resp = await client.post("/auth/login", json={
            "email": email,
            "password": "password1234",
        })
        assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_invalid_credentials():
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        resp = await client.post("/auth/login", json={
            "email": "nonexistent@example.com",
            "password": "wrongpassword",
        })
        assert resp.status_code == 401
        assert "detail" in resp.json()
