
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.crop import Crop
from app.models.farm import Farm
from app.models.user import User
from app.schemas.crop import CropCreate, CropPublic

router = APIRouter(prefix="/farms/{farm_id}/crops", tags=["Crops"])

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]


async def get_owned_farm(
    farm_id: UUID,
    db: AsyncSession,
    current_user: User,
) -> Farm:
    if current_user.role != "farmer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only farmers can manage crops.",
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


@router.post(
    "",
    response_model=CropPublic,
    status_code=status.HTTP_201_CREATED,
)
async def create_crop(
    farm_id: UUID,
    payload: CropCreate,
    db: DbSession,
    current_user: CurrentUser,
):
    await get_owned_farm(farm_id, db, current_user)

    if (
        payload.planting_date
        and payload.expected_harvest_date
        and payload.expected_harvest_date < payload.planting_date
    ):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Harvest date cannot be before planting date.",
        )

    crop = Crop(
        farm_id=farm_id,
        **payload.model_dump(),
    )

    db.add(crop)
    await db.commit()
    await db.refresh(crop)

    return crop


@router.get("", response_model=list[CropPublic])
async def list_farm_crops(
    farm_id: UUID,
    db: DbSession,
    current_user: CurrentUser,
):
    await get_owned_farm(farm_id, db, current_user)

    result = await db.scalars(
        select(Crop).where(Crop.farm_id == farm_id)
    )

    return result.all()


@router.get("/{crop_id}", response_model=CropPublic)
async def get_crop(
    farm_id: UUID,
    crop_id: UUID,
    db: DbSession,
    current_user: CurrentUser,
):
    await get_owned_farm(farm_id, db, current_user)

    crop = await db.scalar(
        select(Crop).where(
            Crop.id == crop_id,
            Crop.farm_id == farm_id,
        )
    )

    if crop is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Crop not found.",
        )

    return crop
