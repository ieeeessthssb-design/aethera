"""Sensor readings router for farm IoT data: latest snapshot and history."""
import hashlib
import math
import random
from datetime import datetime, timedelta, timezone
from typing import List, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.dependencies import get_accessible_farm, get_current_user, get_db
from app.models.reading import Reading
from app.models.user import User
from app.schemas.sensor import SensorLatestResponse, SensorReadingResponse

router = APIRouter(prefix="/farms", tags=["sensors"])

METRICS = ("soil_moisture", "temperature", "humidity")
MAX_SIMULATED_POINTS = 168  # one week, hourly


def _sim_value(metric: str, farm_id: str, ts: datetime) -> float:
    """Deterministic simulated value (same farm + hour -> same value), so charts don't jump on refresh."""
    hour = ts.replace(minute=0, second=0, microsecond=0)
    seed = int(hashlib.md5(f"{farm_id}:{metric}:{int(hour.timestamp())}".encode()).hexdigest()[:8], 16)
    rnd = random.Random(seed)
    x = hour.timestamp() / 3600
    if metric == "soil_moisture":
        v, lo, hi = 40 + 12 * math.sin(x / 7) + rnd.gauss(0, 1), 10.0, 90.0
    elif metric == "temperature":
        v, lo, hi = 26 + 7 * math.sin((x - 9) / 3.82) + rnd.gauss(0, 0.5), 10.0, 45.0
    else:
        v, lo, hi = 58 + 14 * math.cos(x / 4.5) + rnd.gauss(0, 1), 20.0, 95.0
    return round(max(lo, min(hi, v)), 1)


@router.get("/{id}/sensors/latest", response_model=SensorLatestResponse)
async def get_latest_sensor_reading(
    id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Latest value of each metric for a farm. A metric with no reading yet is null, never 0."""
    await get_accessible_farm(id, db, current_user)

    latest = {}
    for metric in METRICS:
        latest[metric] = (await db.execute(
            select(Reading).where(Reading.farm_id == id, Reading.metric == metric)
            .order_by(Reading.recorded_at.desc()).limit(1)
        )).scalar_one_or_none()
    present = [r for r in latest.values() if r is not None]

    if not present:
        if not settings.simulate_sensors:
            raise HTTPException(status_code=404, detail="No sensor readings found for this farm")
        now = datetime.now(timezone.utc)
        return SensorLatestResponse(
            soil_moisture=_sim_value("soil_moisture", id, now),
            temperature=_sim_value("temperature", id, now),
            humidity=_sim_value("humidity", id, now),
            timestamp=now, source="simulated",
        )

    return SensorLatestResponse(
        soil_moisture=latest["soil_moisture"].value if latest["soil_moisture"] else None,
        temperature=latest["temperature"].value if latest["temperature"] else None,
        humidity=latest["humidity"].value if latest["humidity"] else None,
        timestamp=max(r.recorded_at for r in present),
        # "real" only if every reading shown is real (UI shows a SIMULATED badge otherwise)
        source="real" if all(r.source == "real" for r in present) else "simulated",
    )


@router.get("/{id}/sensors/readings", response_model=List[SensorReadingResponse])
async def get_sensor_readings(
    id: str,
    metric: Literal["soil_moisture", "temperature", "humidity"] = Query(...),
    from_: Optional[datetime] = Query(None, alias="from"),
    to: Optional[datetime] = Query(None),
    limit: int = Query(200, ge=1, le=1000),
    order: Literal["asc", "desc"] = Query("desc", description="Sort by time; use asc for charts"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Time-series history for one metric (newest first by default)."""
    await get_accessible_farm(id, db, current_user)
    if from_ and to and from_ > to:
        raise HTTPException(status_code=422, detail="'from' must be earlier than 'to'")

    q = select(Reading).where(Reading.farm_id == id, Reading.metric == metric)
    if from_:
        q = q.where(Reading.recorded_at >= from_)
    if to:
        q = q.where(Reading.recorded_at <= to)
    rows = (await db.execute(q.order_by(Reading.recorded_at.desc()).limit(limit))).scalars().all()

    if rows:
        out = [SensorReadingResponse(id=r.id, timestamp=r.recorded_at, metric=r.metric, value=r.value,
                                     source=r.source) for r in rows]
    else:
        any_real = (await db.execute(
            select(Reading.id).where(Reading.farm_id == id, Reading.metric == metric).limit(1)
        )).first()
        if any_real or not settings.simulate_sensors:
            out = []  # the farm has data, just none in this window (or simulation is off)
        else:
            end = (to or datetime.now(timezone.utc)).astimezone(timezone.utc)
            out = []
            for i in range(min(limit, MAX_SIMULATED_POINTS)):
                ts = end - timedelta(hours=i)
                if from_ and ts < from_:
                    break
                out.append(SensorReadingResponse(id=i + 1, timestamp=ts, metric=metric,
                                                 value=_sim_value(metric, id, ts), source="simulated"))

    out.sort(key=lambda r: r.timestamp, reverse=(order == "desc"))
    return out
