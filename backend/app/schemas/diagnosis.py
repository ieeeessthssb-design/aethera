
from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class DiagnosisReview(BaseModel):
    status: Literal["validated", "rejected"]
    expert_diagnosis: str = Field(min_length=3, max_length=3000)
    expert_advice: str = Field(min_length=3, max_length=5000)


class DiagnosisPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    farmer_id: UUID
    farm_id: UUID
    crop_id: UUID | None
    photo_path: str
    symptoms: str
    status: str
    expert_id: UUID | None
    expert_diagnosis: str | None
    expert_advice: str | None
    reviewed_at: datetime | None
    created_at: datetime
