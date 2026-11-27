
import hashlib
from datetime import datetime, timezone, timedelta
import secrets
from typing import Annotated
from uuid import UUID


from fastapi import (
    APIRouter,
    Depends,
    Header,
    HTTPException,
    Query,
    status,
)
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.device import Device, SensorReading, FarmAlert
from app.models.reading import Reading
from app.models.farm import Farm
from app.models.user import User
from app.schemas.device import (
    DeviceCreate,
    DeviceCreated,
    DevicePublic,
    SensorReadingCreate,
    SensorReadingPublic,
    FarmAlertPublic,
    DeviceCreateRequest,
    DeviceResponse,
    DeviceReadingIngestionRequest,
    DeviceReadingIngestionResponse,
)

router = APIRouter(tags=["IoT Devices"])

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]


def hash_device_key(key: str) -> str:
    return hashlib.sha256(key.encode("utf-8")).hexdigest()


@router.post(
    "/farms/{farm_id}/devices",
    response_model=DeviceCreated,
    status_code=status.HTTP_201_CREATED,
)
async def create_device(
    farm_id: UUID,
    payload: DeviceCreate,
    db: DbSession,
    current_user: CurrentUser,
):
    if current_user.role != "farmer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only farmers can register devices.",
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

    device_key = secrets.token_urlsafe(32)

    device = Device(
        farm_id=farm.id,
        name=payload.name,
        is_simulated=payload.is_simulated,
        key_hash=hash_device_key(device_key),
    )

    db.add(device)
    await db.commit()
    await db.refresh(device)

    return {
        "id": device.id,
        "farm_id": device.farm_id,
        "name": device.name,
        "device_key": device_key,
        "is_active": device.is_active,
        "is_simulated": device.is_simulated,
        "created_at": device.created_at,
    }


async def get_authenticated_device(
    device_id: str,
    db: DbSession,
    device_key: Annotated[str | None, Header(alias="X-Device-Key")] = None,
) -> Device:
    if not device_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Device key required.",
        )

    try:
        parsed_device_id = UUID(device_id)
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid device credentials.",
        ) from None

    device = await db.scalar(
        select(Device).where(
            Device.id == parsed_device_id,
            Device.key_hash == hash_device_key(device_key),
            Device.is_active.is_(True),
        )
    )

    if device is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid device credentials.",
        )

    return device


AuthenticatedDevice = Annotated[
    Device,
    Depends(get_authenticated_device),
]


@router.get("/devices", response_model=list[DeviceResponse])
async def list_devices_compat(db: DbSession, current_user: CurrentUser):
    """Main dashboard compatibility route; results remain scoped to owned farms."""
    farm_ids = select(Farm.id).where(Farm.owner_id == current_user.id)
    result = await db.scalars(select(Device).where(Device.farm_id.in_(farm_ids)))
    return list(result.all())


@router.post("/devices", response_model=DeviceResponse, status_code=status.HTTP_201_CREATED)
async def create_device_compat(payload: DeviceCreateRequest, db: DbSession, current_user: CurrentUser):
    """Register through the main dashboard while returning the key only once."""
    if current_user.role != "farmer":
        raise HTTPException(status_code=403, detail="Only farmers can register devices.")
    farm = await db.scalar(
        select(Farm).where(Farm.id == payload.farm_id, Farm.owner_id == current_user.id)
    )
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found.")
    device_key = secrets.token_urlsafe(32)
    device = Device(farm_id=farm.id, name=payload.name, key_hash=hash_device_key(device_key))
    db.add(device)
    await db.commit()
    await db.refresh(device)
    return DeviceResponse(
        id=device.id, farm_id=device.farm_id, name=device.name, device_key=device_key,
        is_active=device.is_active, last_seen_at=device.last_seen_at, created_at=device.created_at,
    )


@router.post(
    "/devices/{device_id}/readings",
    response_model=DeviceReadingIngestionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def receive_sensor_reading(
    payload: DeviceReadingIngestionRequest,
    db: DbSession,
    device: AuthenticatedDevice,
    simulated: Annotated[
        bool,
        Header(alias="X-Simulated"),
    ] = False,
):
    recorded_at = payload.recorded_at or datetime.now(timezone.utc)
    values = {
        "soil_moisture": payload.soil_moisture,
        "temperature": payload.temperature,
        "humidity": payload.humidity,
    }
    values = {metric: value for metric, value in values.items() if value is not None}
    source = "simulated" if simulated or payload.source == "simulated" else "real"
    existing = await db.scalars(
        select(Reading.metric).where(
            Reading.device_id == device.id,
            Reading.recorded_at == recorded_at,
            Reading.metric.in_(list(values)),
        )
    )
    already_stored = set(existing.all())
    new_readings = [
        Reading(device_id=device.id, farm_id=device.farm_id, metric=metric,
                value=value, recorded_at=recorded_at, source=source)
        for metric, value in values.items() if metric not in already_stored
    ]
    db.add_all(new_readings)
    wide_reading = None
    if len(values) == 3:
        wide_reading = await db.scalar(
            select(SensorReading).where(
                SensorReading.device_id == device.id,
                SensorReading.recorded_at == recorded_at,
            ).limit(1)
        )
    if len(values) == 3 and wide_reading is None:
        wide_reading = SensorReading(
            device_id=device.id,
            soil_moisture=values["soil_moisture"],
            temperature=values["temperature"],
            humidity=values["humidity"],
            recorded_at=recorded_at,
            is_simulated=(source == "simulated"),
        )
        db.add(wide_reading)
    # Every authenticated packet proves transport connectivity, including simulator
    # packets. Simulated packets update freshness but do not create field alerts.
    device.last_seen_at = datetime.now(timezone.utc)
    if source == "real" and len(values) == 3:
        # Deterministic agronomic thresholds only; this does not invoke AI/diagnosis.
        alert_specs = []
        if payload.soil_moisture < 20:
            alert_specs.append(("low_soil_moisture", "warning", "Low soil moisture",
                                f"Soil moisture is {payload.soil_moisture:.1f}%. Check the crop's irrigation needs."))
        elif payload.soil_moisture > 85:
            alert_specs.append(("high_soil_moisture", "notable", "High soil moisture",
                                f"Soil moisture is {payload.soil_moisture:.1f}%. Check for overwatering or sensor placement."))
    
        active_moisture_alerts = await db.scalars(
            select(FarmAlert).where(
                FarmAlert.device_id == device.id,
                FarmAlert.alert_type.in_(["low_soil_moisture", "high_soil_moisture"]),
                FarmAlert.acknowledged_at.is_(None),
            )
        )
        active_alerts = list(active_moisture_alerts.all())
        active_types = {spec[0] for spec in alert_specs}
        for active_alert in active_alerts:
            if active_alert.alert_type not in active_types:
                active_alert.acknowledged_at = datetime.now(timezone.utc)
    
        for alert_type, severity, title, detail in alert_specs:
            existing = await db.scalar(
                select(FarmAlert).where(
                    FarmAlert.device_id == device.id,
                    FarmAlert.alert_type == alert_type,
                    FarmAlert.acknowledged_at.is_(None),
                ).limit(1)
            )
            if existing is None:
                db.add(FarmAlert(
                    farm_id=device.farm_id, device_id=device.id,
                    alert_type=alert_type, severity=severity, title=title,
                    detail=detail, source="sensor",
                ))
    
    await db.commit()
    if wide_reading is not None:
        await db.refresh(wide_reading)
    return DeviceReadingIngestionResponse(
        inserted=len(new_readings), skipped=len(values) - len(new_readings),
        recorded_at=recorded_at, device_id=device.id,
        id=wide_reading.id if wide_reading else None,
        reading_id=wide_reading.id if wide_reading else None,
        soil_moisture=values.get("soil_moisture"), temperature=values.get("temperature"),
        humidity=values.get("humidity"), is_simulated=(source == "simulated"),
        received_at=(wide_reading.received_at if wide_reading else datetime.now(timezone.utc)),
    )
@router.get(
    "/farms/{farm_id}/devices/{device_id}/readings/latest",
    response_model=SensorReadingPublic | None,
)
async def get_latest_reading(
    farm_id: UUID,
    device_id: UUID,
    db: DbSession,
    current_user: CurrentUser,
):
    device = await db.scalar(
        select(Device)
        .join(Farm, Device.farm_id == Farm.id)
        .where(
            Device.id == device_id,
            Device.farm_id == farm_id,
            Farm.owner_id == current_user.id,
        )
    )

    if device is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found.",
        )

    return await db.scalar(
        select(SensorReading)
        .where(SensorReading.device_id == device_id)
        .order_by(
            desc(SensorReading.recorded_at),
            desc(SensorReading.received_at),
        )
        .limit(1)
    )


@router.get(
    "/farms/{farm_id}/devices/{device_id}/readings",
    response_model=list[SensorReadingPublic],
)
async def get_reading_history(
    farm_id: UUID,
    device_id: UUID,
    db: DbSession,
    current_user: CurrentUser,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
):
    device = await db.scalar(
        select(Device)
        .join(Farm, Device.farm_id == Farm.id)
        .where(
            Device.id == device_id,
            Device.farm_id == farm_id,
            Farm.owner_id == current_user.id,
        )
    )

    if device is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found.",
        )

    result = await db.scalars(
        select(SensorReading)
        .where(SensorReading.device_id == device_id)
        .order_by(
            desc(SensorReading.recorded_at),
            desc(SensorReading.received_at),
        )
        .limit(limit)
    )

    return list(result.all())
@router.get(
    "/farms/{farm_id}/devices",
    response_model=list[DevicePublic],
)
async def list_farm_devices(
    farm_id: UUID,
    db: DbSession,
    current_user: CurrentUser,
):
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

    result = await db.scalars(
        select(Device).where(Device.farm_id == farm_id).order_by(Device.created_at.desc())
    )
    now = datetime.now(timezone.utc)
    rows = []
    for device in result.all():
        if not device.is_active:
            connection_status = "disabled"
        elif device.last_seen_at is None:
            connection_status = "unknown"
        elif now - device.last_seen_at > timedelta(minutes=10):
            connection_status = "stale"
        else:
            connection_status = "online"
        rows.append({
            "id": device.id, "farm_id": device.farm_id, "name": device.name,
            "is_active": device.is_active, "is_simulated": device.is_simulated, "created_at": device.created_at,
            "last_seen_at": device.last_seen_at, "connection_status": connection_status,
        })
    return rows
@router.patch(
    "/farms/{farm_id}/devices/{device_id}/deactivate",
    response_model=DevicePublic,
)
async def deactivate_device(
    farm_id: UUID,
    device_id: UUID,
    db: DbSession,
    current_user: CurrentUser,
):
    device = await db.scalar(
        select(Device)
        .join(Farm, Device.farm_id == Farm.id)
        .where(
            Device.id == device_id,
            Device.farm_id == farm_id,
            Farm.owner_id == current_user.id,
        )
    )

    if device is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found.",
        )

    device.is_active = False

    await db.commit()
    await db.refresh(device)

    return {
        "id": device.id,
        "farm_id": device.farm_id,
        "name": device.name,
        "is_active": device.is_active,
        "is_simulated": device.is_simulated,
        "created_at": device.created_at,
        "last_seen_at": device.last_seen_at,
        "connection_status": "disabled",
    }

@router.get("/farms/{farm_id}/alerts", response_model=list[FarmAlertPublic])
async def list_farm_alerts(
    farm_id: UUID, db: DbSession, current_user: CurrentUser,
    include_acknowledged: bool = False,
):
    farm = await db.scalar(
        select(Farm).where(Farm.id == farm_id, Farm.owner_id == current_user.id)
    )
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found.")

    query = select(FarmAlert).where(FarmAlert.farm_id == farm_id)
    if not include_acknowledged:
        query = query.where(FarmAlert.acknowledged_at.is_(None))
    result = await db.scalars(query.order_by(FarmAlert.created_at.desc()).limit(100))
    return list(result.all())


@router.patch("/farms/{farm_id}/alerts/{alert_id}/acknowledge", response_model=FarmAlertPublic)
async def acknowledge_farm_alert(
    farm_id: UUID, alert_id: UUID, db: DbSession, current_user: CurrentUser,
):
    alert = await db.scalar(
        select(FarmAlert).join(Farm, FarmAlert.farm_id == Farm.id).where(
            FarmAlert.id == alert_id, FarmAlert.farm_id == farm_id,
            Farm.owner_id == current_user.id,
        )
    )
    if alert is None:
        raise HTTPException(status_code=404, detail="Alert not found.")
    if alert.acknowledged_at is None:
        alert.acknowledged_at = datetime.now(timezone.utc)
        await db.commit()
        await db.refresh(alert)
    return alert
