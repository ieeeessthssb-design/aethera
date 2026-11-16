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
