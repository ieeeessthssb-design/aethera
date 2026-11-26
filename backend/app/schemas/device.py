
from datetime import datetime, timedelta, timezone
from uuid import UUID
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


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


class DeviceCreateRequest(BaseModel):
    farm_id: UUID
    name: str = Field(min_length=2, max_length=100)


class DeviceResponse(BaseModel):
    id: UUID
    farm_id: UUID
    name: str
    device_key: str | None = None
    is_active: bool
    last_seen_at: datetime | None = None
    created_at: datetime


class DeviceReadingIngestionRequest(BaseModel):
    soil_moisture: float | None = Field(default=None, ge=0, le=100)
    temperature: float | None = Field(default=None, ge=-40, le=80)
    humidity: float | None = Field(default=None, ge=0, le=100)
    recorded_at: datetime | None = None
    source: Literal["real", "simulated"] = "real"

    @field_validator("recorded_at")
    @classmethod
    def normalize_recorded_at(cls, value):
        if value is None:
            return value
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        value = value.astimezone(timezone.utc)
        if value > datetime.now(timezone.utc) + timedelta(minutes=5):
            raise ValueError("recorded_at cannot be more than five minutes in the future")
        return value

    @model_validator(mode="after")
    def at_least_one_metric(self):
        if all(getattr(self, metric) is None for metric in ("soil_moisture", "temperature", "humidity")):
            raise ValueError("at least one sensor metric is required")
        return self


class DeviceReadingIngestionResponse(BaseModel):
    inserted: int
    skipped: int = 0
    recorded_at: datetime
    id: UUID | None = None
    device_id: UUID
    reading_id: UUID | None = None
    soil_moisture: float | None = None
    temperature: float | None = None
    humidity: float | None = None
    is_simulated: bool
    received_at: datetime
