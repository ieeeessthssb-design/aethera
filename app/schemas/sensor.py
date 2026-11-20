"""Pydantic schemas for sensor reading endpoints."""
from pydantic import BaseModel
from typing import Literal, Optional
from datetime import datetime

SourceEnum = Literal["real", "simulated"]


class SensorLatestResponse(BaseModel):
    # null = that metric has no reading yet (never a fake 0)
    soil_moisture: Optional[float] = None
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    timestamp: datetime
    source: SourceEnum


class SensorReadingResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: int
    timestamp: datetime
    metric: str
    value: float
    source: SourceEnum
