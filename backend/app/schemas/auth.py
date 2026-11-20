"""Pydantic schemas for authentication endpoints."""
from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from datetime import datetime


class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str
    phone: Optional[str] = None
    region: Optional[str] = None

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        if v not in ("farmer", "expert"):
            raise ValueError("role must be 'farmer' or 'expert'")
        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("password must be at least 6 characters")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: str
    name: str
    email: str
    role: str
    phone: Optional[str] = None
    region: Optional[str] = None
    created_at: datetime


class AuthResponse(BaseModel):
    token: str
    user: UserResponse
