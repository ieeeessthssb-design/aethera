"""Irrigation LLM tests: a fake client replaces the network, so no API key is needed."""
import json
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest

from aethera.app.services.irrigation_llm import (
    KBSnippet,
    LLMClient,
    SensorSnapshot,
    assess_data_quality,
    generate_irrigation_advice,
)
from aethera.app.services.weather_service import WeatherSnapshot, parse_open_meteo

NOW = datetime(2026, 11, 20, 12, 0, tzinfo=timezone.utc)
FARM = SimpleNamespace(id="f1", crop="Tomato", region="Sfax", plant_age_days=45,
                       irrigation_type="drip", area_hectares=1.5, lat=34.7, lng=10.7)
KB_WITH_THRESHOLD = [KBSnippet("KB-9", "Tomato: irrigate below 25% soil moisture.", ["Test KB"], True)]
KB_NO_THRESHOLD = [KBSnippet("KB-1", "Irrigate evening or early morning.", ["Test KB"], False)]


def sensor(source="real", age_min=10, sm=18.0):
    return SensorSnapshot(NOW - timedelta(minutes=age_min), sm, 33.0, 40.0, source)


def weather(age_min=10):
    return WeatherSnapshot(NOW - timedelta(minutes=age_min), "Open-Meteo", 34, 36, 6.0, 0, 0, 0, 5, 12)


def llm_json(**over):
    d = {"action": "irrigate_later", "when": "tonight after 19:00", "amount_mm": 5,
         "reasons": [{"point": "Soil is dry", "source": "sensor"}],
         "confidence": "high", "confidence_reason": "all data fresh", "source_label": "sensor",
         "needs_expert": False, "farmer_message": "اسقي الليلة بعد المغرب"}
    d.update(over)
    return json.dumps(d)


class FakeClient(LLMClient):
    def __init__(self, *replies):
        self.replies, self.calls = list(replies), 0

    async def complete(self, system, user):
        self.calls += 1
        r = self.replies.pop(0)
        if isinstance(r, Exception):
            raise r
        return r


def test_quality_full_data_allows_high():
    cap, gaps, usable = assess_data_quality(FARM, sensor(), weather(), KB_WITH_THRESHOLD, NOW)
    assert cap == "high" and gaps == [] and usable is not None


def test_quality_simulated_sensor_caps_medium():
    cap, gaps, _ = assess_data_quality(FARM, sensor(source="simulated"), weather(), KB_WITH_THRESHOLD, NOW)
    assert cap == "medium" and any("simulated" in g for g in gaps)


def test_quality_nothing_usable_is_low():
    cap, _, usable = assess_data_quality(FARM, None, None, KB_WITH_THRESHOLD, NOW)
    assert cap == "low" and usable is None


def test_quality_dead_and_out_of_range_sensor_ignored():
    _, _, u1 = assess_data_quality(FARM, sensor(age_min=25 * 60), weather(), KB_WITH_THRESHOLD, NOW)
    _, _, u2 = assess_data_quality(FARM, sensor(sm=140), weather(), KB_WITH_THRESHOLD, NOW)
    assert u1 is None and u2 is None


@pytest.mark.asyncio
async def test_high_confidence_kept_when_data_is_good():
    a = await generate_irrigation_advice(FakeClient(llm_json()), FARM, sensor(), weather(), KB_WITH_THRESHOLD, now=NOW)
    assert a.confidence == "high" and a.source_label == "sensor" and not a.needs_expert


@pytest.mark.asyncio
async def test_llm_cannot_exceed_data_quality_cap():
    # LLM claims "high" but KB has no threshold -> capped to medium
    a = await generate_irrigation_advice(FakeClient(llm_json()), FARM, sensor(), weather(), KB_NO_THRESHOLD, now=NOW)
    assert a.confidence == "medium"


@pytest.mark.asyncio
async def test_simulated_sensor_label_is_corrected():
    a = await generate_irrigation_advice(FakeClient(llm_json()), FARM, sensor(source="simulated"), weather(),
                                         KB_WITH_THRESHOLD, now=NOW)
    assert a.source_label == "simulated_sensor" and a.reasons[0].source == "simulated_sensor"


@pytest.mark.asyncio
async def test_cannot_claim_sensor_when_sensor_missing():
    a = await generate_irrigation_advice(FakeClient(llm_json()), FARM, None, weather(), KB_WITH_THRESHOLD, now=NOW)
    assert a.source_label == "weather_forecast" and a.confidence == "medium"


@pytest.mark.asyncio
async def test_low_confidence_forces_expert():
    a = await generate_irrigation_advice(FakeClient(llm_json(confidence="low", needs_expert=False)), FARM,
                                         sensor(), weather(), KB_WITH_THRESHOLD, now=NOW)
    assert a.needs_expert is True


@pytest.mark.asyncio
async def test_invalid_json_retries_then_falls_back():
    c = FakeClient("not json", "still not json")
    a = await generate_irrigation_advice(c, FARM, sensor(), weather(), KB_WITH_THRESHOLD, now=NOW)
    assert c.calls == 2 and a.action == "escalate_to_expert" and a.confidence == "low" and a.needs_expert


@pytest.mark.asyncio
async def test_retry_succeeds_on_second_attempt():
    c = FakeClient("```oops", llm_json())
    a = await generate_irrigation_advice(c, FARM, sensor(), weather(), KB_WITH_THRESHOLD, now=NOW)
    assert c.calls == 2 and a.action == "irrigate_later"


@pytest.mark.asyncio
async def test_no_client_falls_back_to_expert():
    a = await generate_irrigation_advice(None, FARM, sensor(), weather(), KB_WITH_THRESHOLD, now=NOW)
    assert a.needs_expert and a.confidence == "low"


def test_parse_open_meteo():
    payload = {
        "current": {"temperature_2m": 31.0, "wind_speed_10m": 14.0},
        "daily": {
            "temperature_2m_max": [30, 36, 35, 34],
            "et0_fao_evapotranspiration": [5.0, 6.2, 6.0, 5.8],
            "precipitation_sum": [0.0, 1.0, 3.0, 4.5],
            "precipitation_probability_max": [0, 10, 60, 40],
        },
    }
    w = parse_open_meteo(payload, now=NOW)
    assert w.temp_max_today_c == 36 and w.et0_today_mm == 6.2
    assert w.rain_today_mm == 1.0 and w.rain_next_2d_mm == 7.5 and w.rain_prob_next_2d_pct == 60
