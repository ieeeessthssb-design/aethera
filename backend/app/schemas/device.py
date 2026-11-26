
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class DeviceCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    is_simulated: bool = False


class DeviceCreated(BaseModel):
    id: UUID
    farm_id: UUID
    name: str
    device_key: str
    is_active: bool
    is_simulated: bool = False
    created_at: datetime


class DevicePublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    farm_id: UUID
    name: str
    is_active: bool
    is_simulated: bool = False
    created_at: datetime
    last_seen_at: datetime | None = None
    connection_status: str = "unknown"


class SensorReadingCreate(BaseModel):
    soil_moisture: float = Field(ge=0, le=100)
    temperature: float = Field(ge=-50, le=100)
    humidity: float = Field(ge=0, le=100)
    recorded_at: datetime


class SensorReadingPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    device_id: UUID
    soil_moisture: float
    temperature: float
    humidity: float
    recorded_at: datetime
    is_simulated: bool
    received_at: datetime


class FarmAlertPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    farm_id: UUID
    device_id: UUID | None
    alert_type: str
    severity: str
    title: str
    detail: str
    source: str
    created_at: datetime
    acknowledged_at: datetime | None
