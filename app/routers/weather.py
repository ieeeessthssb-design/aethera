"""Weather for a farm's location (Open-Meteo)."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_accessible_farm, get_current_user, get_db
from app.models.user import User
from app.schemas.weather import WeatherDay, WeatherResponse
from app.services.locations import resolve_location
from app.services.weather_service import get_weather

router = APIRouter(prefix="/farms", tags=["weather"])


@router.get("/{id}/weather", response_model=WeatherResponse)
async def get_farm_weather(
    id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Current conditions and a short forecast for the farm's location."""
    farm = await get_accessible_farm(id, db, current_user)
    loc = resolve_location(farm)
    if loc is None:
        raise HTTPException(
            status_code=422,
            detail="Farm has no location: set lat/lng or a known governorate in the farm profile",
        )
    lat, lng, loc_source = loc
    w = await get_weather(lat, lng)
    if w is None:
        raise HTTPException(status_code=503, detail="Weather service unavailable, try again later")
    return WeatherResponse(
        farm_id=farm.id, latitude=lat, longitude=lng, location_source=loc_source,
        source=w.source, fetched_at=w.fetched_at, temp_now_c=w.temp_now_c, wind_kmh=w.wind_kmh,
        rain_next_2d_mm=w.rain_next_2d_mm, rain_prob_next_2d_pct=w.rain_prob_next_2d_pct,
        daily=[WeatherDay(**d) for d in w.daily],
    )
