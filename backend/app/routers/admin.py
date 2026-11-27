
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select

from app.core.dependencies import DbSession
from app.core.permissions import require_role
from app.models.user import User
from app.schemas.auth import UserPublic
from app.schemas.admin import UserStatusUpdate

router = APIRouter(prefix="/admin", tags=["Admin"])

AdminUser = Annotated[User, Depends(require_role("admin"))]


@router.get("/overview")
async def get_overview(db: DbSession, admin: AdminUser):
    async def count_users(*conditions) -> int:
        statement = select(func.count()).select_from(User)
        if conditions:
            statement = statement.where(*conditions)
        return int(await db.scalar(statement) or 0)

    return {
        "total_users": await count_users(),
        "active_users": await count_users(User.is_active.is_(True)),
        "farmers": await count_users(User.role == "farmer"),
        "experts": await count_users(User.role == "expert"),
        "pending_experts": await count_users(
            User.role == "expert", User.expert_approval_status == "pending"
        ),
    }


@router.get("/users", response_model=list[UserPublic])
async def list_users(
    db: DbSession,
    admin: AdminUser,
    limit: int = Query(default=100, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    result = await db.scalars(
        select(User).order_by(User.created_at.desc()).offset(offset).limit(limit)
    )
    return result.all()


@router.patch("/users/{user_id}/status", response_model=UserPublic)
async def update_user_status(
    user_id: UUID,
    payload: UserStatusUpdate,
    db: DbSession,
    admin: AdminUser,
):
    user = await db.scalar(select(User).where(User.id == user_id))
    if user is None:
        raise HTTPException(status_code=404, detail="User account not found.")
    if user.id == admin.id and not payload.is_active:
        raise HTTPException(status_code=409, detail="You cannot deactivate your own account.")
    if user.role == "admin" and user.is_active and not payload.is_active:
        active_admins = await db.scalar(
            select(func.count()).select_from(User).where(
                User.role == "admin", User.is_active.is_(True)
            )
        )
        if int(active_admins or 0) <= 1:
            raise HTTPException(status_code=409, detail="At least one active admin is required.")
    user.is_active = payload.is_active
    await db.commit()
    await db.refresh(user)
    return user


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
