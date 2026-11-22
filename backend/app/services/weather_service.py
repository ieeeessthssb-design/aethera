"""Open-Meteo weather integration (free, no API key for non-commercial use)."""
from datetime import datetime, timezone
from typing import Optional

import httpx


async def get_farm_weather(lat: Optional[float], lng: Optional[float]) -> Optional[dict]:
    """Return a compact next-24-hour forecast, or None when coordinates/API are unavailable."""
    if lat is None or lng is None:
        return None

    params = {
        "latitude": lat,
        "longitude": lng,
        "hourly": "temperature_2m,precipitation_probability,precipitation",
        "forecast_days": 2,
        "timezone": "UTC",
    }
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.get("https://api.open-meteo.com/v1/forecast", params=params)
            response.raise_for_status()
            payload = response.json()

        hourly = payload.get("hourly", {})
        times = hourly.get("time", [])
        temps = hourly.get("temperature_2m", [])
        probs = hourly.get("precipitation_probability", [])
        rain = hourly.get("precipitation", [])
        if not times:
            return None

        # Open-Meteo returns the forecast from local midnight. Select the next 24 hours.
        now_local = datetime.now(timezone.utc).replace(tzinfo=None)
        start = next((i for i, value in enumerate(times) if datetime.fromisoformat(value) >= now_local), 0)
        indexes = range(start, min(start + 24, len(times)))

        def values(source):
            return [source[i] for i in indexes if i < len(source) and source[i] is not None]

        next_temps = values(temps)
        next_probs = values(probs)
        next_rain = values(rain)
        return {
            "provider": "Open-Meteo",
            "forecast_period": "next_24_hours",
            "temperature_max_c": round(max(next_temps), 1) if next_temps else None,
            "precipitation_probability_max_pct": max(next_probs) if next_probs else None,
            "precipitation_total_mm": round(sum(next_rain), 1) if next_rain else None,
            "timezone": payload.get("timezone"),
            "retrieved_at": datetime.now(timezone.utc).isoformat(),
        }
    except (httpx.HTTPError, ValueError, KeyError, TypeError):
        # A weather outage must not prevent the assistant from returning a cautious result.
        return None
