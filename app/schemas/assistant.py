"""Pydantic schemas for assistant endpoints."""
from pydantic import BaseModel
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
    # LLM providers only (null with the rule-based stub)
    confidence_level: Optional[str] = None
    source_label: Optional[str] = None
    irrigation: Optional[dict] = None


class IrrigationRequest(BaseModel):
    farm_id: str
    language: Optional[str] = None  # ar | fr | en (default ar)


class VoiceResponse(BaseModel):
    transcript: str
    answer: str
    confidence: float
    escalated: bool
    case_id: Optional[str] = None
    confidence_level: Optional[str] = None
    source_label: Optional[str] = None


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
