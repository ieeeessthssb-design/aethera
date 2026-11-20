"""Sensor readings router for farm IoT data."""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional, List
from datetime import datetime, timezone, timedelta
import random
from app.core.dependencies import get_db, get_current_user
from app.core.config import settings
from app.models.farm import Farm
from app.models.reading import Reading
from app.models.device import Device
from app.models.user import User
from app.schemas.sensor import SensorLatestResponse, SensorReadingResponse

router = APIRouter(prefix="/farms", tags=["sensors"])


async def _get_farm_or_404(farm_id: str, db: AsyncSession) -> Farm:
    result = await db.execute(select(Farm).where(Farm.id == farm_id))
    farm = result.scalar_one_or_none()
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found")
    return farm


def _generate_simulated_reading(metric: str, farm_id: str) -> Reading:
    """Generate a realistic simulated sensor reading."""
    now = datetime.now(timezone.utc)
    hour = now.hour
    # Simulate diurnal variation
    if metric == "soil_moisture":
        base = 40.0
        variation = random.gauss(0, 3)
        value = max(10.0, min(90.0, base + variation))
    elif metric == "temperature":
        # Warmer during day (Tunisia)
        day_factor = 10 * abs(hour - 12) / 12
        value = max(10.0, min(45.0, 28.0 + day_factor + random.gauss(0, 1)))
    else:  # humidity
        value = max(20.0, min(95.0, 60.0 + random.gauss(0, 5)))
    return Reading(
        device_id=None,
        farm_id=farm_id,
        metric=metric,
        value=round(value, 1),
        recorded_at=now,
        source="simulated",
    )


@router.get("/{id}/sensors/latest", response_model=SensorLatestResponse)
async def get_latest_sensor_reading(
    id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get the latest aggregated sensor reading for a farm."""
    await _get_farm_or_404(id, db)

    readings = {}
    for metric in ("soil_moisture", "temperature", "humidity"):
        result = await db.execute(
            select(Reading)
            .where(Reading.farm_id == id, Reading.metric == metric)
            .order_by(Reading.recorded_at.desc())
            .limit(1)
        )
        readings[metric] = result.scalar_one_or_none()

    if all(r is None for r in readings.values()):
        if not settings.simulate_sensors:
            raise HTTPException(status_code=404, detail="No sensor readings found for this farm")
        # Return simulated data on-the-fly (not persisted for /latest)
        now = datetime.now(timezone.utc)
        return SensorLatestResponse(
            soil_moisture=round(40.0 + random.gauss(0, 3), 1),
            temperature=round(28.3 + random.gauss(0, 1), 1),
            humidity=round(60.0 + random.gauss(0, 5), 1),
            timestamp=now,
            source="simulated",
        )

    # Determine overall source: real only if ALL readings are real
    source = "real" if all(r and r.source == "real" for r in readings.values()) else "simulated"
    latest_ts = max(r.recorded_at for r in readings.values() if r)

    return SensorLatestResponse(
        soil_moisture=readings["soil_moisture"].value if readings["soil_moisture"] else 0,
        temperature=readings["temperature"].value if readings["temperature"] else 0,
        humidity=readings["humidity"].value if readings["humidity"] else 0,
        timestamp=latest_ts,
        source=source,
    )


@router.get("/{id}/sensors/readings", response_model=List[SensorReadingResponse])
async def get_sensor_readings(
    id: str,
    metric: str = Query(..., enum=["soil_moisture", "temperature", "humidity"]),
    from_: Optional[datetime] = Query(None, alias="from"),
    to: Optional[datetime] = Query(None),
    limit: int = Query(200, le=1000),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get time-series sensor readings for a farm."""
    await _get_farm_or_404(id, db)

    query = select(Reading).where(Reading.farm_id == id, Reading.metric == metric)
    if from_:
        query = query.where(Reading.recorded_at >= from_)
    if to:
        query = query.where(Reading.recorded_at <= to)
    query = query.order_by(Reading.recorded_at.desc()).limit(limit)

    result = await db.execute(query)
    readings = result.scalars().all()

    if not readings and settings.simulate_sensors:
        # Return simulated historical data
        now = datetime.now(timezone.utc)
        simulated = []
        for i in range(min(limit, 48)):
            ts = now - timedelta(hours=i)
            if metric == "soil_moisture":
                val = round(40.0 + random.gauss(0, 3), 1)
            elif metric == "temperature":
                val = round(28.3 + random.gauss(0, 2), 1)
            else:
                val = round(60.0 + random.gauss(0, 5), 1)
            simulated.append(
                SensorReadingResponse(
                    id=i + 1,
                    timestamp=ts,
                    metric=metric,
                    value=val,
                    source="simulated",
                )
            )
        return simulated

    return [
        SensorReadingResponse(
            id=r.id,
            timestamp=r.recorded_at,
            metric=r.metric,
            value=r.value,
            source=r.source,
        )
        for r in readings
    ]
