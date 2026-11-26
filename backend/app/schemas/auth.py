
from typing import Literal
from uuid import UUID

from pydantic import AliasChoices, BaseModel, ConfigDict, EmailStr, Field, computed_field


# Shared registration validation
class RegistrationBase(BaseModel):
    full_name: str = Field(
        min_length=2, max_length=150,
        validation_alias=AliasChoices("full_name", "name"),
    )
    password: str = Field(min_length=12, max_length=128)
    preferred_language: str = Field(
        default="en",
        pattern="^(en|fr|ar)$",
    )
    role: Literal["farmer", "expert"] = "farmer"


# Email registration and verification
class EmailRegistrationRequest(RegistrationBase):
    email: EmailStr


class EmailVerificationRequest(BaseModel):
    email: EmailStr
    code: str = Field(pattern=r"^\d{6}$")


class EmailLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


# Phone registration and verification
class PhoneRegistrationRequest(RegistrationBase):
    phone_number: str = Field(
        pattern=r"^\+[1-9]\d{7,14}$",
        description="Phone number in international E.164 format",
    )


class PhoneVerificationRequest(BaseModel):
    phone_number: str = Field(
        pattern=r"^\+[1-9]\d{7,14}$",
        description="Verified phone number in international E.164 format",
    )
    firebase_id_token: str = Field(min_length=1)


class PhoneLoginRequest(BaseModel):
    phone_number: str = Field(pattern=r"^\+[1-9]\d{7,14}$")
    password: str = Field(min_length=1, max_length=128)


# Google authentication
class GoogleSignInRequest(BaseModel):
    id_token: str = Field(min_length=1)


# Verification response
class VerificationPendingResponse(BaseModel):
    message: str
    verification_required: bool = True


# Refresh and logout
class RefreshRequest(BaseModel):
    refresh_token: str | None = None


# Public user information
class UserPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    full_name: str
    name: str | None = None
    email: EmailStr | None = None
    phone_number: str | None = None
    phone: str | None = None
    region: str | None = None
    preferred_language: str
    is_verified: bool
    role: str
    expert_approval_status: str


# Successful authentication response
class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    refresh_token: str | None = None
    user: UserPublic

    @computed_field
    @property
    def token(self) -> str:
        """Alias retained for clients from origin/main; access_token stays canonical."""
        return self.access_token


class EmailResendRequest(BaseModel):
    email: EmailStr
