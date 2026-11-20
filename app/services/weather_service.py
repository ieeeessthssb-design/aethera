"""Weather client for the irrigation assistant (Open-Meteo: free, no API key).

Never raises: returns None when weather cannot be fetched so the assistant can
lower its confidence instead of failing. A stale cached value is preferred over
nothing; its `fetched_at` stays old so the staleness check in the assistant still
sees it.
"""
from __future__ import annotations

import time
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from typing import Optional

import httpx

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"
CACHE_TTL_S = 30 * 60

_cache: dict[tuple[float, float], tuple[float, "WeatherSnapshot"]] = {}


@dataclass
class WeatherSnapshot:
    fetched_at: datetime
    source: str
    temp_now_c: Optional[float]
    temp_max_today_c: Optional[float]
    et0_today_mm: Optional[float]        # reference evapotranspiration
    rain_yesterday_mm: float
    rain_today_mm: float
    rain_next_2d_mm: float               # tomorrow + day after
    rain_prob_next_2d_pct: Optional[float]
    wind_kmh: Optional[float]
    daily: list = field(default_factory=list)  # yesterday, today, +1, +2

    def as_dict(self) -> dict:
        d = asdict(self)
        d["fetched_at"] = self.fetched_at.isoformat(timespec="minutes")
        return d


def _num(seq, i) -> Optional[float]:
    try:
        v = seq[i]
        return None if v is None else float(v)
    except (IndexError, TypeError, ValueError):
        return None


def parse_open_meteo(payload: dict, now: Optional[datetime] = None) -> WeatherSnapshot:
    """Parse an Open-Meteo response requested with past_days=1, forecast_days=3.

    daily[0] = yesterday, [1] = today, [2] = tomorrow, [3] = day after tomorrow.
    """
    d = payload["daily"]
    cur = payload.get("current", {})
    prob = [p for p in (_num(d.get("precipitation_probability_max", []), i) for i in (2, 3)) if p is not None]
    return WeatherSnapshot(
        fetched_at=now or datetime.now(timezone.utc),
        source="Open-Meteo",
        temp_now_c=cur.get("temperature_2m"),
        temp_max_today_c=_num(d.get("temperature_2m_max", []), 1),
        et0_today_mm=_num(d.get("et0_fao_evapotranspiration", []), 1),
        rain_yesterday_mm=_num(d["precipitation_sum"], 0) or 0.0,
        rain_today_mm=_num(d["precipitation_sum"], 1) or 0.0,
        rain_next_2d_mm=(_num(d["precipitation_sum"], 2) or 0.0) + (_num(d["precipitation_sum"], 3) or 0.0),
        rain_prob_next_2d_pct=max(prob) if prob else None,
        wind_kmh=cur.get("wind_speed_10m"),
        daily=[
            {
                "date": d["time"][i] if i < len(d.get("time", [])) else None,
                "temp_max_c": _num(d.get("temperature_2m_max", []), i),
                "temp_min_c": _num(d.get("temperature_2m_min", []), i),
                "et0_mm": _num(d.get("et0_fao_evapotranspiration", []), i),
                "rain_mm": _num(d["precipitation_sum"], i) or 0.0,
                "rain_prob_pct": _num(d.get("precipitation_probability_max", []), i),
            }
            for i in range(len(d["precipitation_sum"]))
        ],
    )


async def get_weather(lat: Optional[float], lng: Optional[float]) -> Optional[WeatherSnapshot]:
    if lat is None or lng is None:
        return None
    key = (round(lat, 2), round(lng, 2))
    cached = _cache.get(key)
    if cached and time.time() - cached[0] < CACHE_TTL_S:
        return cached[1]

    params = {
        "latitude": lat,
        "longitude": lng,
        "current": "temperature_2m,wind_speed_10m",
        "daily": "temperature_2m_max,temperature_2m_min,et0_fao_evapotranspiration,precipitation_sum,precipitation_probability_max",
        "past_days": 1,
        "forecast_days": 3,
        "timezone": "UTC",
    }
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            r = await client.get(OPEN_METEO_URL, params=params)
            r.raise_for_status()
            snap = parse_open_meteo(r.json())
    except (httpx.HTTPError, KeyError, ValueError, TypeError):
        return cached[1] if cached else None

    _cache[key] = (time.time(), snap)
    return snap
