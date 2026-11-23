"""Tests for irrigation-advice confidence and safety rules."""
from datetime import datetime, timezone, timedelta
from types import SimpleNamespace
import json

import pytest

from app.services import irrigation_advisor as advisor
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


@pytest.mark.parametrize(
    ("question", "explanation", "step"),
    [
        (
            "J'ai des tomates, comment savoir quand je dois les arroser ?",
            "Vérifiez l'humidité du sol et les prévisions locales avant d'arroser.",
            "Consultez les mesures récentes de votre parcelle.",
        ),
        (
            "عندي طماطم، وقتاش نسقيهم؟",
            "كان قياس رطوبة التربة ناقص، تفقد الحقل قبل السقي.",
            "شوف نشرة الطقس المحلية قبل ما تسقي.",
        ),
        (
            "3andi tomates, wa9tech nes9ihom?",
            "Ken 9yesset routoubet ettorba na9sa, thabet fel 7a9l 9bal ess9i.",
            "Chouf ta9s el jiha 9bal ma tes9i.",
        ),
        (
            "I have tomatoes, how do I know when to water them?",
            "Check the soil moisture and local forecast before watering.",
            "Review the latest readings from your field.",
        ),
    ],
)
def test_response_language_matches_supported_question_styles(question, explanation, step):
    advice = {"explanation": explanation, "recommended_steps": [step]}
    advisor._validate_response_language(advice, question)


@pytest.mark.parametrize(
    ("question", "bad_response"),
    [
        ("J'ai des tomates, comment savoir quand je dois les arroser ?", "Check soil moisture before watering."),
        ("عندي طماطم، وقتاش نسقيهم؟", "Check soil moisture before watering."),
        ("3andi tomates, wa9tech nes9ihom?", "Check soil moisture before watering."),
        ("I have tomatoes, when should I water them?", "Vérifiez l'humidité du sol avant d'arroser."),
    ],
)
def test_clearly_wrong_language_is_rejected(question, bad_response):
    with pytest.raises(advisor._LanguageMismatchError):
        advisor._validate_response_language(
            {"explanation": bad_response, "recommended_steps": ["Check the weather."]}, question
        )


def test_invalid_json_keeps_existing_parse_error_behavior():
    with pytest.raises(json.JSONDecodeError):
        advisor._parse_llm_response("not json", "How should I water tomatoes?")


@pytest.mark.asyncio
async def test_groq_retries_once_when_language_is_wrong(monkeypatch):
    responses = [
        {"action": "insufficient_data", "explanation": "The data is not enough to decide.", "recommended_steps": ["Check the sensor."]},
        {"action": "insufficient_data", "explanation": "Les données ne suffisent pas pour décider.", "recommended_steps": ["Vérifiez les mesures récentes."]},
    ]
    requests = []

    class Response:
        is_error = False

        def __init__(self, value):
            self.value = value

        def raise_for_status(self):
            pass

        def json(self):
            return {"choices": [{"message": {"content": json.dumps(self.value, ensure_ascii=False)}}]}

    class Client:
        def __init__(self, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            pass

        async def post(self, url, headers, json):
            requests.append(json)
            return Response(responses.pop(0))

    monkeypatch.setattr(advisor.httpx, "AsyncClient", Client)
    monkeypatch.setattr(advisor.settings, "groq_api_key", "test-key")
    result = await advisor._ask_groq({}, "J'ai des tomates, comment savoir quand je dois les arroser ?")

    assert result["explanation"].startswith("Les données")
    assert len(requests) == 2
    assert "CORRECTION" in requests[1]["messages"][0]["content"]


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("question", "explanation", "step"),
    [
        ("عندي طماطم، وقتاش نسقيهم؟", "كان قياس رطوبة التربة ناقص، تفقد الحقل قبل السقي.", "شوف نشرة الطقس المحلية قبل ما تسقي."),
        ("3andi tomates, wa9tech nes9ihom?", "Ken 9yesset routoubet ettorba na9sa, thabet fel 7a9l 9bal ess9i.", "Chouf ta9s el jiha 9bal ma tes9i."),
        ("I have tomatoes, how do I know when to water them?", "Check the soil moisture and local forecast before watering.", "Review the latest readings from your field."),
    ],
)
async def test_groq_accepts_valid_arabic_derja_arabizi_and_english(monkeypatch, question, explanation, step):
    response_data = {
        "action": "monitor",
        "explanation": explanation,
        "recommended_steps": [step],
    }

    class Response:
        is_error = False

        def raise_for_status(self):
            pass

        def json(self):
            return {"choices": [{"message": {"content": json.dumps(response_data, ensure_ascii=False)}}]}

    class Client:
        def __init__(self, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            pass

        async def post(self, *args, **kwargs):
            return Response()

    monkeypatch.setattr(advisor.httpx, "AsyncClient", Client)
    monkeypatch.setattr(advisor.settings, "groq_api_key", "test-key")

    result = await advisor._ask_groq({}, question)
    assert result["explanation"] == explanation
    assert result["recommended_steps"] == [step]


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("readings", "expected_action", "question"),
    [
        (
            {"soil_moisture": {"value": 40, "unit": "%", "source": "simulated", "timestamp": datetime.now(timezone.utc)}, "temperature": None, "humidity": None},
            "insufficient_data",
            "J'ai des tomates, comment savoir quand je dois les arroser ?",
        ),
        ({"soil_moisture": None, "temperature": None, "humidity": None}, "insufficient_data", "I have tomatoes, when should I water them?"),
    ],
)
async def test_safe_fallback_for_simulated_or_missing_data(monkeypatch, readings, expected_action, question):
    async def fake_readings(db, farm_id):
        return readings

    async def unavailable(*args):
        raise RuntimeError("provider unavailable")

    monkeypatch.setattr(advisor, "_latest_readings", fake_readings)
    monkeypatch.setattr(advisor, "get_farm_weather", lambda *args: _no_weather())
    monkeypatch.setattr(advisor, "_ask_groq", unavailable)
    monkeypatch.setattr(advisor, "_ask_ollama", unavailable)
    monkeypatch.setattr(advisor.settings, "assistant_provider", "groq")
    farm_data = SimpleNamespace(
        id="farm-1", lat=None, lng=None, crop="Tomato", region=None,
        area_hectares=None, plant_age_days=None, irrigation_type=None,
    )

    result = await advisor.generate_irrigation_advice(farm_data, object(), question)
    all_text = " ".join([result["explanation"], *result["recommended_steps"]]).lower()

    assert result["action"] == expected_action
    assert "mm" not in all_text
    assert "litre" not in all_text and "liter" not in all_text
    if question.startswith("J'"):
        advisor._validate_response_language(
            {"explanation": result["explanation"], "recommended_steps": result["recommended_steps"]}, question
        )


async def _no_weather():
    return None
