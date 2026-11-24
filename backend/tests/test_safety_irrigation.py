"""Task 34: the irrigation endpoint applies the same safety rules as the chat (new file, safe to add)."""
from types import SimpleNamespace

import pytest

from app.services import irrigation_advisor as adv


def _farm():
    return SimpleNamespace(id="f1", crop="tomatoes", region="Sfax", area_hectares=1, plant_age_days=40,
                           irrigation_type="drip", lat=None, lng=None)


def _prepare(monkeypatch):
    calls = []

    async def readings(db, farm_id):
        return {"soil_moisture": None, "temperature": None, "humidity": None}

    async def weather(lat, lng):
        return None

    async def fake_llm(*args, **kwargs):
        calls.append("llm")  # recorded, not asserted inside: the advisor swallows exceptions from LLM calls
        raise RuntimeError("llm unavailable in test")

    monkeypatch.setattr(adv, "_latest_readings", readings)
    monkeypatch.setattr(adv, "get_farm_weather", weather)
    monkeypatch.setattr(adv, "_ask_groq", fake_llm)
    monkeypatch.setattr(adv, "_ask_ollama", fake_llm)
    monkeypatch.setattr(adv.settings, "assistant_provider", "groq", raising=False)
    return calls


@pytest.mark.asyncio
async def test_pesticide_dose_question_never_reaches_the_llm(monkeypatch):
    calls = _prepare(monkeypatch)
    result = await adv.generate_irrigation_advice(_farm(), None, question="How many ml of fungicide per liter?")
    assert calls == []
    assert result["expert_review_required"] is True
    assert "can't give pesticide doses" in result["explanation"]
    assert "safety_rules" in result["source_labels"]


@pytest.mark.asyncio
async def test_normal_question_still_uses_the_llm_path(monkeypatch):
    calls = _prepare(monkeypatch)
    result = await adv.generate_irrigation_advice(_farm(), None, question="When should I water my tomatoes?")
    assert calls == ["llm", "llm"]  # Groq then Ollama were tried
    assert "safety_rules" not in result["source_labels"]
