
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select

from app.core.dependencies import DbSession
from app.core.permissions import require_role
from app.models.user import User
from app.schemas.auth import UserPublic

router = APIRouter(prefix="/admin", tags=["Admin"])

AdminUser = Annotated[User, Depends(require_role("admin"))]


@router.get("/experts/pending", response_model=list[UserPublic])
async def list_pending_experts(
    db: DbSession,
    admin: AdminUser,
):
    result = await db.scalars(
        select(User).where(
            User.role == "expert",
            User.expert_approval_status == "pending",
        )
    )
    return result.all()


@router.patch("/experts/{user_id}/approve", response_model=UserPublic)
async def approve_expert(
    user_id: UUID,
    db: DbSession,
    admin: AdminUser,
):
    expert = await db.scalar(
        select(User).where(
            User.id == user_id,
            User.role == "expert",
        )
    )

    if expert is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expert account not found.",
        )

    if expert.expert_approval_status != "pending":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This expert account is not pending approval.",
        )

    expert.expert_approval_status = "approved"
    await db.commit()
    await db.refresh(expert)

    return expert


@router.patch("/experts/{user_id}/reject", response_model=UserPublic)
async def reject_expert(
    user_id: UUID,
    db: DbSession,
    admin: AdminUser,
):
    expert = await db.scalar(
        select(User).where(
            User.id == user_id,
            User.role == "expert",
        )
    )

    if expert is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expert account not found.",
        )

    if expert.expert_approval_status != "pending":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This expert account is not pending approval.",
        )

    expert.expert_approval_status = "rejected"
    await db.commit()
    await db.refresh(expert)

    return expert
