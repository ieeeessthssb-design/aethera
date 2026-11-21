"""Pydantic schemas for sensor reading endpoints."""
from pydantic import BaseModel
from typing import Literal, Optional
from datetime import datetime

SourceEnum = Literal["real", "simulated"]


class SensorLatestResponse(BaseModel):
    soil_moisture: float
    temperature: float
    humidity: float
    timestamp: datetime
    source: SourceEnum


class SensorReadingResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: int
    timestamp: datetime
    metric: str
    value: float
    source: SourceEnum
