"""Pydantic schemas for expert dashboard endpoints."""
from pydantic import BaseModel, field_validator
from typing import Optional, List
from datetime import datetime
import json


class ExpertReviewRequest(BaseModel):
    decision: str
    comment: Optional[str] = None
    corrected_diagnosis: Optional[str] = None

    @field_validator("decision")
    @classmethod
    def validate_decision(cls, v: str) -> str:
        if v not in ("confirm", "reject"):
            raise ValueError("decision must be 'confirm' or 'reject'")
        return v


class ExpertReviewResponse(BaseModel):
    decision: str
    comment: Optional[str] = None
    corrected_diagnosis: Optional[str] = None
    reviewed_at: datetime
    expert_name: str


class ExpertCaseListItem(BaseModel):
    model_config = {"from_attributes": True}

    id: str
    farm_id: Optional[str] = None
    farmer_name: str
    crop: str
    region: str
    ai_diagnosis: str
    ai_confidence: float
    symptoms: Optional[str] = None
    photo_url: Optional[str] = None
    status: str
    created_at: datetime


class ExpertCaseDetail(ExpertCaseListItem):
    original_question: Optional[str] = None
    ai_sources: Optional[List[str]] = None
    review: Optional[ExpertReviewResponse] = None

    @classmethod
    def from_orm_with_review(cls, case, review=None):
        """Build ExpertCaseDetail from ORM case + optional review."""
        sources = []
        if case.ai_sources:
            try:
                sources = json.loads(case.ai_sources)
            except (json.JSONDecodeError, TypeError):
                sources = [case.ai_sources]

        review_data = None
        if review:
            review_data = ExpertReviewResponse(
                decision=review.decision,
                comment=review.comment,
                corrected_diagnosis=review.corrected_diagnosis,
                reviewed_at=review.reviewed_at,
                expert_name=review.expert_name,
            )

        return cls(
            id=case.id,
            farm_id=case.farm_id,
            farmer_name=case.farmer_name,
            crop=case.crop,
            region=case.region,
            ai_diagnosis=case.ai_diagnosis,
            ai_confidence=case.ai_confidence,
            symptoms=case.symptoms,
            photo_url=case.photo_url,
            status=case.status,
            created_at=case.created_at,
            original_question=case.original_question,
            ai_sources=sources,
            review=review_data,
        )


class ExpertCaseListResponse(BaseModel):
    items: List[ExpertCaseListItem]
    total: int
