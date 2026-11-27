
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator



class FarmCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    location: str = Field(min_length=2, max_length=255)
    area_hectares: float | None = Field(default=None, gt=0)
    soil_type: str | None = Field(default=None, max_length=100)
    irrigation_type: str | None = Field(default=None, max_length=100)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)

    @model_validator(mode="after")
    def coordinates_must_be_provided_together(self):
        if (self.latitude is None) != (self.longitude is None):
            raise ValueError("Latitude and longitude must be provided together.")
        return self


class FarmPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    owner_id: UUID
    name: str
    location: str
    area_hectares: float | None
    soil_type: str | None
    irrigation_type: str | None
    latitude: float | None
    longitude: float | None
    created_at: datetime


class FarmLocationUpdate(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class FarmUpdateRequest(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    crop: str | None = Field(default=None, max_length=100)
    region: str | None = Field(default=None, max_length=255)
    lat: float | None = Field(default=None, ge=-90, le=90)
    lng: float | None = Field(default=None, ge=-180, le=180)
    area_hectares: float | None = Field(default=None, gt=0)
    soil_type: str | None = Field(default=None, max_length=100)
    irrigation_type: str | None = Field(default=None, max_length=100)
    plant_age_days: int | None = Field(default=None, ge=0)


class FarmResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    owner_id: UUID
    name: str
    crop: str | None = None
    region: str
    lat: float | None = None
    lng: float | None = None
    area_hectares: float | None = None
    soil_type: str | None = None
    irrigation_type: str | None = None
    plant_age_days: int | None = None
    created_at: datetime
