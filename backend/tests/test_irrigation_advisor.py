"""Tests for irrigation-advice confidence and safety rules."""
from datetime import datetime, timezone, timedelta
from types import SimpleNamespace

from app.services.irrigation_advisor import calculate_confidence


def farm():
    return SimpleNamespace(
        crop="Tomato",
        irrigation_type="drip",
        area_hectares=1.5,
    )


def test_real_fresh_sensor_and_weather_can_reach_high_data_confidence():
    now = datetime.now(timezone.utc)
    readings = {
        "soil_moisture": {"value": 24, "source": "real", "timestamp": now},
        "temperature": {"value": 30, "source": "real", "timestamp": now},
        "humidity": {"value": 55, "source": "real", "timestamp": now},
    }
    weather = {"provider": "Open-Meteo", "precipitation_total_mm": 0}
    score, level, reasons, labels = calculate_confidence(readings, weather, farm())
    assert score >= 0.8
    assert level == "high"
    assert "sensor" in labels
    assert "weather" in labels


def test_simulated_sensor_is_never_high_confidence():
    now = datetime.now(timezone.utc)
    readings = {
        "soil_moisture": {"value": 40, "source": "simulated", "timestamp": now},
        "temperature": {"value": 28, "source": "simulated", "timestamp": now},
        "humidity": {"value": 60, "source": "simulated", "timestamp": now},
    }
    score, level, reasons, labels = calculate_confidence(
        readings, {"provider": "Open-Meteo"}, farm()
    )
    assert level != "high"
    assert "simulated_data" in labels


def test_missing_moisture_and_weather_produce_low_confidence():
    readings = {"soil_moisture": None, "temperature": None, "humidity": None}
    score, level, reasons, labels = calculate_confidence(readings, None, farm())
    assert score < 0.6
    assert level == "low"
