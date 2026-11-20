"""Pydantic schemas for the weather endpoint."""
from datetime import datetime
from typing import List, Literal, Optional

from pydantic import BaseModel


class WeatherDay(BaseModel):
    date: Optional[str] = None            # YYYY-MM-DD (UTC day)
    temp_max_c: Optional[float] = None
    temp_min_c: Optional[float] = None
    et0_mm: Optional[float] = None        # reference evapotranspiration
    rain_mm: float = 0.0
    rain_prob_pct: Optional[float] = None


class WeatherResponse(BaseModel):
    farm_id: str
    latitude: float
    longitude: float
    location_source: Literal["farm", "region"]  # "region" = governorate centroid (approximate)
    source: str                                  # "Open-Meteo"
    fetched_at: datetime
    temp_now_c: Optional[float] = None
    wind_kmh: Optional[float] = None
    rain_next_2d_mm: float
    rain_prob_next_2d_pct: Optional[float] = None
    daily: List[WeatherDay]                      # yesterday, today, tomorrow, day after
