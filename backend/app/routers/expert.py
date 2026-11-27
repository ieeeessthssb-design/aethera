"""Expert dashboard router."""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional
from uuid import UUID
from app.core.dependencies import get_db, require_expert
from app.models.expert_case import ExpertCase, ExpertReview
from app.models.user import User
from app.schemas.expert import (
    ExpertCaseListResponse,
    ExpertCaseDetail,
    ExpertCaseListItem,
    ExpertReviewRequest,
)

router = APIRouter(prefix="/expert", tags=["expert"])


@router.get("/cases", response_model=ExpertCaseListResponse)
async def list_cases(
    status: Optional[str] = Query(None, pattern="^(pending|confirmed|rejected)$"),
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    current_user: User = Depends(require_expert),
    db: AsyncSession = Depends(get_db),
):
    """List expert cases, optionally filtered by status."""
    query = select(ExpertCase)
    count_query = select(func.count()).select_from(ExpertCase)

    if status:
        query = query.where(ExpertCase.status == status)
        count_query = count_query.where(ExpertCase.status == status)

    total_result = await db.execute(count_query)
    total = total_result.scalar_one()

    result = await db.execute(
        query.order_by(ExpertCase.created_at.desc()).limit(limit).offset(offset)
    )
    cases = result.scalars().all()

    return ExpertCaseListResponse(
        items=[ExpertCaseListItem.model_validate(c) for c in cases],
        total=total,
    )


@router.get("/cases/{id}", response_model=ExpertCaseDetail)
async def get_case(
    id: UUID,
    current_user: User = Depends(require_expert),
    db: AsyncSession = Depends(get_db),
):
    """Get a single expert case with full detail including review."""
    result = await db.execute(select(ExpertCase).where(ExpertCase.id == id))
    case = result.scalar_one_or_none()
    if case is None:
        raise HTTPException(status_code=404, detail="Case not found")

    review_result = await db.execute(
        select(ExpertReview).where(ExpertReview.case_id == id)
    )
    review = review_result.scalar_one_or_none()

    return ExpertCaseDetail.from_orm_with_review(case, review)


@router.post("/cases/{id}/review", response_model=ExpertCaseDetail)
async def review_case(
    id: UUID,
    request: ExpertReviewRequest,
    current_user: User = Depends(require_expert),
    db: AsyncSession = Depends(get_db),
):
    """Submit a review decision for an expert case."""
    result = await db.execute(select(ExpertCase).where(ExpertCase.id == id))
    case = result.scalar_one_or_none()
    if case is None:
        raise HTTPException(status_code=404, detail="Case not found")
    if case.status != "pending":
        raise HTTPException(status_code=409, detail="This case has already been reviewed")

    # Create review record
    review = ExpertReview(
        case_id=id,
        expert_id=current_user.id,
        expert_name=current_user.name,
        decision=request.decision,
        comment=request.comment,
        corrected_diagnosis=request.corrected_diagnosis,
    )
    db.add(review)

    # Update case status
    case.status = "confirmed" if request.decision == "confirm" else "rejected"
    await db.commit()
    await db.refresh(case)
    await db.refresh(review)

    return ExpertCaseDetail.from_orm_with_review(case, review)
