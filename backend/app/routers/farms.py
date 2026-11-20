"""Farm management router."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone
from app.core.dependencies import get_db, get_current_user
from app.models.farm import Farm
from app.models.user import User
from app.schemas.farm import FarmUpdateRequest, FarmResponse

router = APIRouter(prefix="/farms", tags=["farms"])


@router.get("/me", response_model=FarmResponse)
async def get_my_farm(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get the authenticated farmer's farm profile."""
    result = await db.execute(select(Farm).where(Farm.owner_id == current_user.id))
    farm = result.scalar_one_or_none()
    if farm is None:
        raise HTTPException(status_code=404, detail="No farm profile found for this user")
    return FarmResponse.model_validate(farm)


@router.put("/me", response_model=FarmResponse)
async def upsert_my_farm(
    request: FarmUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create or update the authenticated farmer's farm profile."""
    result = await db.execute(select(Farm).where(Farm.owner_id == current_user.id))
    farm = result.scalar_one_or_none()

    if farm is None:
        # Create new farm — name, crop, region, irrigation_type are required for creation
        data = request.model_dump(exclude_none=True)
        if not all(k in data for k in ("name", "crop", "region")):
            raise HTTPException(
                status_code=422,
                detail="name, crop, and region are required when creating a farm profile",
            )
        farm = Farm(
            owner_id=current_user.id,
            name=data.get("name", ""),
            crop=data.get("crop", ""),
            region=data.get("region", current_user.region or "Tunisia"),
            irrigation_type=data.get("irrigation_type", "drip"),
        )
        for field, value in data.items():
            setattr(farm, field, value)
        db.add(farm)
    else:
        # Update existing farm
        for field, value in request.model_dump(exclude_none=True).items():
            setattr(farm, field, value)
        farm.updated_at = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(farm)
    return FarmResponse.model_validate(farm)
