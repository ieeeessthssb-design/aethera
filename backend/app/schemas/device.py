"""Pydantic schemas for device management endpoints."""
from pydantic import BaseModel, Field, field_validator, model_validator
from typing import Literal, Optional
from datetime import datetime, timedelta, timezone


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
    """Payload sent by the ESP32 (or the simulator script).

    Each metric is optional: if a sensor fails (e.g. the DHT22), the device sends
    ``null`` for that metric and the others are still stored. At least one metric
    is required. ``recorded_at`` defaults to server time when the ESP32 has no clock.
    """

    soil_moisture: Optional[float] = Field(None, ge=0, le=100, description="Soil moisture, %")
    temperature: Optional[float] = Field(None, ge=-40, le=80, description="Air temperature, °C")
    humidity: Optional[float] = Field(None, ge=0, le=100, description="Air humidity, %")
    recorded_at: Optional[datetime] = None
    # The simulator script must label its data; real devices omit this field.
    source: Literal["real", "simulated"] = "real"

    @field_validator("recorded_at")
    @classmethod
    def _utc_and_not_future(cls, v: Optional[datetime]) -> Optional[datetime]:
        if v is None:
            return v
        if v.tzinfo is None:  # ESP32 firmware often omits the timezone suffix
            v = v.replace(tzinfo=timezone.utc)
        v = v.astimezone(timezone.utc)
        if v > datetime.now(timezone.utc) + timedelta(minutes=5):
            raise ValueError("recorded_at is in the future (check the device clock)")
        return v

    @model_validator(mode="after")
    def _at_least_one_metric(self):
        if self.soil_moisture is None and self.temperature is None and self.humidity is None:
            raise ValueError("at least one of soil_moisture, temperature, humidity is required")
        return self


class DeviceReadingIngestionResponse(BaseModel):
    inserted: int
    recorded_at: datetime
    skipped: int = 0  # duplicates (same device, metric and timestamp) from retries