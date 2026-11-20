"""Pydantic schemas for device management endpoints."""
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class DeviceCreateRequest(BaseModel):
    farm_id: str
    name: str


class DeviceResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: str
    farm_id: str
    name: str
    device_key: str
    is_active: bool
    last_seen_at: Optional[datetime] = None
    created_at: datetime


class DeviceReadingIngestionRequest(BaseModel):
    soil_moisture: float
    temperature: float
    humidity: float
    recorded_at: datetime


class DeviceReadingIngestionResponse(BaseModel):
    inserted: int
    recorded_at: datetime
