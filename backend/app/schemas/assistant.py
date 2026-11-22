"""Pydantic schemas for assistant endpoints."""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ChatRequest(BaseModel):
    message: str
    farm_id: str


class ChatResponse(BaseModel):
    answer: str
    confidence: float
    sources: List[str]
    escalated: bool
    case_id: Optional[str] = None


class VoiceResponse(BaseModel):
    transcript: str
    answer: str
    confidence: float
    escalated: bool
    case_id: Optional[str] = None


class AdviceLogResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: str
    user_id: str
    farm_id: Optional[str] = None
    question: str
    answer: str
    confidence: float
    escalated: bool
    channel: str
    created_at: datetime


class AdviceLogListResponse(BaseModel):
    items: List[AdviceLogResponse]
    total: int


class IrrigationAdviceResponse(BaseModel):
    """Structured, traceable irrigation advice for a farm."""
    farm_id: str
    action: str
    action_label: str
    explanation: str
    recommended_steps: List[str]
    confidence: float
    confidence_level: str
    confidence_reasons: List[str]
    source_labels: List[str]
    source_label: str
    sensor_data: dict
    weather: Optional[dict] = None
    expert_review_required: bool
    expert_case_id: Optional[str] = None
    generated_at: datetime


class IrrigationAdviceRequest(BaseModel):
    message: Optional[str] = Field(default="Should I irrigate this farm now?", max_length=500)
