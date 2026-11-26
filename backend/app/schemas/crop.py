
from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class CropCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    variety: str | None = Field(default=None, max_length=100)
    planting_date: date | None = None
    expected_harvest_date: date | None = None
    growth_stage: str = Field(default="planted", max_length=50)


class CropPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    farm_id: UUID
    name: str
    variety: str | None
    planting_date: date | None
    expected_harvest_date: date | None
    growth_stage: str
    created_at: datetime
