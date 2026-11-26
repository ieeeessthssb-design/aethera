
from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------
# Profiles
# ---------------------------------------------------------

class ProfileUpdate(BaseModel):
    bio: str | None = None
    location: str | None = Field(default=None, max_length=150)
    photo_url: str | None = Field(default=None, max_length=500)
    specialties: str | None = Field(default=None, max_length=500)
    experience_years: int | None = Field(default=None, ge=0, le=100)
    is_public: bool | None = None
    show_phone: bool | None = None
    show_email: bool | None = None


class ProfilePublic(BaseModel):
    user_id: UUID
    full_name: str
    role: str
    is_verified: bool
    expert_approval_status: str

    email: str | None = None
    phone_number: str | None = None

    bio: str | None = None
    location: str | None = None
    photo_url: str | None = None
    specialties: str | None = None
    experience_years: int | None = None

    is_public: bool
    show_phone: bool
    show_email: bool


# ---------------------------------------------------------
# Community posts
# ---------------------------------------------------------

# ---------------------------------------------------------
# Community posts
# ---------------------------------------------------------

class PostCreate(BaseModel):
    body: str = Field(default="", max_length=5000)


class PostPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    author_id: UUID
    author_name: str
    body: str
    image_url: str | None = None
    created_at: datetime
# ---------------------------------------------------------
# Connections
# ---------------------------------------------------------

class ConnectionCreate(BaseModel):
    recipient_id: UUID


class ConnectionRespond(BaseModel):
    status: Literal["accepted", "declined"]


class ConnectionPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    requester_id: UUID
    recipient_id: UUID
    status: str
    created_at: datetime
    requester_name: str | None = None
    recipient_name: str | None = None


# ---------------------------------------------------------
# Conversations
# ---------------------------------------------------------

class ConversationPublic(BaseModel):
    id: UUID
    other_user_id: UUID
    other_user_name: str
    created_at: datetime



# ---------------------------------------------------------
# Messages
# ---------------------------------------------------------

class MessagePublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    conversation_id: UUID
    sender_id: UUID
    body: str
    image_url: str | None = None
    created_at: datetime

class PersonSearchResult(BaseModel):
    user_id: UUID
    full_name: str
    role: str
    is_verified: bool

