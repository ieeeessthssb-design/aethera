"""Pydantic schemas for farm endpoints."""
from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import datetime


class FarmUpdateRequest(BaseModel):
    name: Optional[str] = None
    crop: Optional[str] = None
    region: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    plant_age_days: Optional[int] = None
    irrigation_type: Optional[str] = None
    area_hectares: Optional[float] = None

    @field_validator("irrigation_type")
    @classmethod
    def validate_irrigation(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ("drip", "sprinkler", "flood", "rainfed"):
            raise ValueError("irrigation_type must be one of: drip, sprinkler, flood, rainfed")
        return v


class FarmResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: str
    owner_id: str
    name: str
    crop: str
    region: str
    lat: Optional[float] = None
    lng: Optional[float] = None
    plant_age_days: Optional[int] = None
    irrigation_type: str
    area_hectares: Optional[float] = None
    created_at: datetime
    updated_at: datetime
