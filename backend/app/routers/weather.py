"""Weather and agricultural context endpoints backed by Open-Meteo."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
import json
import time
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.farm import Farm
from app.models.user import User

router = APIRouter(prefix="/weather", tags=["Weather"])
_FORECAST_CACHE: dict[tuple[float, float, str], tuple[float, dict]] = {}
_CACHE_TTL_SECONDS = 600


def _get_json(url: str) -> dict:
    request = Request(url, headers={"User-Agent": "AETHERA/1.0 weather-service"})
    try:
        with urlopen(request, timeout=12) as response:
            return json.loads(response.read().decode("utf-8"))
    except Exception as exc:
        raise RuntimeError("Weather provider is temporarily unavailable") from exc


@router.get("/locations")
async def search_locations(q: str = Query(min_length=2, max_length=100)):
    """Resolve a farmer-entered place name to coordinates using Open-Meteo."""
    params = urlencode({"name": q, "count": 5, "language": "en", "format": "json"})
    try:
        data = await asyncio.to_thread(
            _get_json, f"https://geocoding-api.open-meteo.com/v1/search?{params}"
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    return {
        "results": [
            {
                "name": item.get("name"),
                "admin1": item.get("admin1"),
                "country": item.get("country"),
                "latitude": item.get("latitude"),
                "longitude": item.get("longitude"),
                "timezone": item.get("timezone", "auto"),
            }
            for item in data.get("results", [])
        ]
    }


@router.get("/forecast")
async def get_forecast(
    latitude: float = Query(ge=-90, le=90),
    longitude: float = Query(ge=-180, le=180),
    timezone_name: str = Query(default="auto", alias="timezone", max_length=80),
):
    """Return current, hourly and 7-day forecast plus notable weather changes."""
    cache_key = (round(latitude, 3), round(longitude, 3), timezone_name)
    cached = _FORECAST_CACHE.get(cache_key)
    if cached and time.monotonic() - cached[0] < _CACHE_TTL_SECONDS:
        return cached[1]

    params = urlencode(
        {
            "latitude": latitude,
            "longitude": longitude,
            "timezone": timezone_name,
            "forecast_days": 7,
            "current": (
                "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,"
                "precipitation,rain,showers,snowfall,weather_code,cloud_cover,"
                "pressure_msl,wind_speed_10m,wind_direction_10m,wind_gusts_10m"
            ),
            "hourly": (
                "temperature_2m,relative_humidity_2m,precipitation_probability,"
                "precipitation,rain,showers,weather_code,wind_speed_10m,"
                "wind_gusts_10m,uv_index,et0_fao_evapotranspiration"
            ),
            "daily": (
                "weather_code,temperature_2m_max,temperature_2m_min,"
                "sunrise,sunset,uv_index_max,precipitation_sum,"
                "precipitation_probability_max,wind_speed_10m_max"
            ),
        }
    )
    try:
        data = await asyncio.to_thread(
            _get_json, f"https://api.open-meteo.com/v1/forecast?{params}"
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    hourly = data.get("hourly", {})
    times = hourly.get("time", [])
    temps = hourly.get("temperature_2m", [])
    rain_probs = hourly.get("precipitation_probability", [])
    wind = hourly.get("wind_speed_10m", [])
    codes = hourly.get("weather_code", [])
    alerts: list[dict] = []

    for index in range(min(24, len(times))):
        probability = rain_probs[index] if index < len(rain_probs) else None
        temp = temps[index] if index < len(temps) else None
        wind_speed = wind[index] if index < len(wind) else None
        code = codes[index] if index < len(codes) else 0
        when = times[index]
        if probability is not None and probability >= 60:
            alerts.append({"type": "rain", "severity": "notable", "time": when,
                           "title": "Rain likely", "detail": f"Precipitation probability reaches {probability}% ."})
        if temp is not None and temp >= 35:
            alerts.append({"type": "heat", "severity": "warning", "time": when,
                           "title": "High temperature", "detail": f"Forecast temperature is {temp}°C. Check crop heat stress and irrigation needs."})
        if wind_speed is not None and wind_speed >= 35:
            alerts.append({"type": "wind", "severity": "notable", "time": when,
                           "title": "Strong wind", "detail": f"Wind speed may reach {wind_speed} km/h."})
        if code in (56, 57, 66, 67, 71, 73, 75, 77, 85, 86):
            alerts.append({"type": "cold", "severity": "warning", "time": when,
                           "title": "Freezing or wintry conditions", "detail": "Check sensitive crops and local conditions."})

    # Keep alerts deterministic and avoid repeating the same event at every hour.
    deduplicated: dict[tuple[str, str], dict] = {}
    for alert in alerts:
        deduplicated.setdefault((alert["type"], alert["title"]), alert)

    result = {
        "provider": "Open-Meteo",
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "latitude": data.get("latitude"),
        "longitude": data.get("longitude"),
        "timezone": data.get("timezone"),
        "current": data.get("current", {}),
        "hourly": hourly,
        "daily": data.get("daily", {}),
        "notable_changes": list(deduplicated.values()),
        "agricultural_note": (
            "Weather-based guidance is indicative. Confirm soil moisture and crop-specific "
            "needs before changing irrigation or treatment plans."
        ),
    }
    _FORECAST_CACHE[cache_key] = (time.monotonic(), result)
    return result


@router.get("/farms/{farm_id}/forecast")
async def get_farm_forecast(
    farm_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Weather forecast for a farm's saved coordinates (owner-only)."""
    farm = await db.scalar(
        select(Farm).where(Farm.id == farm_id, Farm.owner_id == current_user.id)
    )
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found.")
    if farm.latitude is None or farm.longitude is None:
        raise HTTPException(
            status_code=409,
            detail="Farm coordinates are not configured. Select a location from the weather location search first.",
        )
    return await get_forecast(
        latitude=farm.latitude, longitude=farm.longitude, timezone_name="auto"
    )
