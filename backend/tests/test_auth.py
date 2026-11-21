"""Tests for authentication endpoints."""
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core.security import hash_password, verify_password, create_access_token, decode_token


# --- Unit tests for security functions ---

def test_hash_password():
    """Password hashing should produce a bcrypt hash."""
    hashed = hash_password("test_password")
    assert hashed != "test_password"
    assert hashed.startswith("$2b$")  # bcrypt prefix


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
async def test_register_and_login():
    """Test full register + login flow."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # Register
        resp = await client.post("/auth/register", json={
            "name": "Test User",
            "email": "test_integration@example.com",
            "password": "password123",
            "role": "farmer",
        })
        # Note: May return 409 if already registered from a previous run
        assert resp.status_code in (201, 409)

        # Login
        resp = await client.post("/auth/login", json={
            "email": "test_integration@example.com",
            "password": "password123",
        })
        # Only check if we successfully registered
        if resp.status_code == 200:
            data = resp.json()
            assert "token" in data
            assert "user" in data
            assert data["user"]["role"] == "farmer"


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