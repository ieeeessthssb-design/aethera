"""Device management and ESP32 reading ingestion router."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone
from typing import List
from app.core.dependencies import get_db, get_current_user, get_device_from_key
from app.models.device import Device
from app.models.reading import Reading
from app.models.user import User
from app.schemas.device import (
    DeviceCreateRequest,
    DeviceResponse,
    DeviceReadingIngestionRequest,
    DeviceReadingIngestionResponse,
)

router = APIRouter(prefix="/devices", tags=["devices"])


@router.get("", response_model=List[DeviceResponse])
async def list_devices(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List all devices owned by the current farmer's farms."""
    # Get all farms for this user
    from app.models.farm import Farm
    farm_result = await db.execute(select(Farm).where(Farm.owner_id == current_user.id))
    farms = farm_result.scalars().all()
    farm_ids = [f.id for f in farms]

    if not farm_ids:
        return []

    result = await db.execute(select(Device).where(Device.farm_id.in_(farm_ids)))
    devices = result.scalars().all()
    return [DeviceResponse.model_validate(d) for d in devices]


@router.post("", response_model=DeviceResponse, status_code=201)
async def create_device(
    request: DeviceCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Register a new IoT device for a farm."""
    # Verify farm ownership
    from app.models.farm import Farm
    result = await db.execute(
        select(Farm).where(Farm.id == request.farm_id, Farm.owner_id == current_user.id)
    )
    farm = result.scalar_one_or_none()
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found or not owned by you")

    device = Device(farm_id=request.farm_id, name=request.name)
    db.add(device)
    await db.commit()
    await db.refresh(device)
    return DeviceResponse.model_validate(device)


@router.post("/{device_id}/readings", response_model=DeviceReadingIngestionResponse, status_code=201)
async def ingest_reading(
    device_id: str,
    request: DeviceReadingIngestionRequest,
    device: Device = Depends(get_device_from_key),
    db: AsyncSession = Depends(get_db),
):
    """Ingest sensor readings from an ESP32 device (uses X-Device-Key auth)."""
    if device.id != device_id:
        raise HTTPException(status_code=401, detail="Device key does not match device ID")

    readings = [
        Reading(
            device_id=device.id,
            farm_id=device.farm_id,
            metric="soil_moisture",
            value=request.soil_moisture,
            recorded_at=request.recorded_at,
            source="real",
        ),
        Reading(
            device_id=device.id,
            farm_id=device.farm_id,
            metric="temperature",
            value=request.temperature,
            recorded_at=request.recorded_at,
            source="real",
        ),
        Reading(
            device_id=device.id,
            farm_id=device.farm_id,
            metric="humidity",
            value=request.humidity,
            recorded_at=request.recorded_at,
            source="real",
        ),
    ]
    db.add_all(readings)
    # Update device last_seen_at
    device.last_seen_at = datetime.now(timezone.utc)
    await db.commit()
    return DeviceReadingIngestionResponse(inserted=3, recorded_at=request.recorded_at)
