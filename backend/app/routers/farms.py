
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.core.database import get_db
from app.models.farm import Farm
from app.models.user import User
from app.schemas.farm import FarmCreate, FarmPublic, FarmLocationUpdate

router = APIRouter(prefix="/farms", tags=["Farms"])

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]


@router.post(
    "",
    response_model=FarmPublic,
    status_code=status.HTTP_201_CREATED,
)
async def create_farm(
    payload: FarmCreate,
    db: DbSession,
    current_user: CurrentUser,
):
    if current_user.role != "farmer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only farmers can create farms.",
        )

    farm = Farm(
        owner_id=current_user.id,
        **payload.model_dump(),
    )

    db.add(farm)
    await db.commit()
    await db.refresh(farm)

    return farm


@router.get("", response_model=list[FarmPublic])
async def list_my_farms(
    db: DbSession,
    current_user: CurrentUser,
):
    if current_user.role != "farmer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only farmers can access farmer farms.",
        )

    result = await db.scalars(
        select(Farm).where(Farm.owner_id == current_user.id)
    )

    return result.all()


@router.get("/{farm_id}", response_model=FarmPublic)
async def get_my_farm(
    farm_id: UUID,
    db: DbSession,
    current_user: CurrentUser,
):
    if current_user.role != "farmer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only farmers can access farmer farms.",
        )

    farm = await db.scalar(
        select(Farm).where(
            Farm.id == farm_id,
            Farm.owner_id == current_user.id,
        )
    )

    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Farm not found.",
        )

    return farm


@router.patch("/{farm_id}/location", response_model=FarmPublic)
async def update_farm_coordinates(
    farm_id: UUID,
    payload: FarmLocationUpdate,
    db: DbSession,
    current_user: CurrentUser,
):
    if current_user.role != "farmer":
        raise HTTPException(status_code=403, detail="Only farmers can update farm locations.")

    farm = await db.scalar(
        select(Farm).where(Farm.id == farm_id, Farm.owner_id == current_user.id)
    )
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found.")

    farm.latitude = payload.latitude
    farm.longitude = payload.longitude
    await db.commit()
    await db.refresh(farm)
    return farm
