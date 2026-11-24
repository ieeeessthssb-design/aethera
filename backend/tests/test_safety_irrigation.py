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
async def test_derja_latin_safety_refusal_stays_in_latin_script(monkeypatch):
    calls = _prepare(monkeypatch)
    result = await adv.generate_irrigation_advice(
        _farm(), None, question="kadech mbid n7ot fel tomate?"
    )
    assert calls == []
    assert "Ma najjemch" in result["explanation"]
    assert "khbir" in result["recommended_steps"][0].lower()
    assert not any("\u0600" <= char <= "\u06ff" for char in result["explanation"])


@pytest.mark.asyncio
async def test_dangerous_chemical_mixing_question_is_refused_before_llm(monkeypatch):
    calls = _prepare(monkeypatch)
    result = await adv.generate_irrigation_advice(
        _farm(), None, question="Can I mix these chemicals in one sprayer?"
    )
    assert calls == []
    assert result["expert_review_required"] is True
    assert "safety_rules" in result["source_labels"]


@pytest.mark.asyncio
async def test_normal_question_still_uses_the_llm_path(monkeypatch):
    calls = _prepare(monkeypatch)
    result = await adv.generate_irrigation_advice(_farm(), None, question="When should I water my tomatoes?")
    assert calls == ["llm"]  # Groq only; provider failure uses the deterministic fallback.
    assert "safety_rules" not in result["source_labels"]
    assert "llm_ollama" not in result["source_labels"]


@pytest.mark.asyncio
async def test_retrieved_agronomy_passages_are_added_to_llm_context(monkeypatch):
    _prepare(monkeypatch)
    captured = {}

    async def llm(context, question):
        captured.update(context)
        return {
            "action": "monitor",
            "explanation": "Check the field before irrigating.",
            "recommended_steps": ["Review current soil moisture."],
        }

    monkeypatch.setattr(adv, "retrieve_agronomy_context", lambda question, limit=3: (
        [{"citation": "FAO guide (2025), p. 12", "text": "Relevant irrigation guidance."}],
        ["FAO guide (2025), p. 12"],
    ))
    monkeypatch.setattr(adv, "_ask_groq", llm)
    monkeypatch.setattr(adv.settings, "assistant_provider", "groq", raising=False)

    result = await adv.generate_irrigation_advice(
        _farm(), None, question="When should I irrigate my tomatoes?"
    )

    assert captured["verified_agronomy_references"][0]["citation"] == "FAO guide (2025), p. 12"
    assert "agronomy_rag" in result["source_labels"]
    assert result["knowledge_sources"] == ["FAO guide (2025), p. 12"]


@pytest.mark.asyncio
async def test_safety_refusal_skips_agronomy_retrieval(monkeypatch):
    _prepare(monkeypatch)
    calls = []

    def retrieval(*args, **kwargs):
        calls.append("retrieval")
        return [], []

    monkeypatch.setattr(adv, "retrieve_agronomy_context", retrieval)
    result = await adv.generate_irrigation_advice(
        _farm(), None, question="How many ml of fungicide per liter?"
    )

    assert calls == []
    assert "safety_rules" in result["source_labels"]
    assert "agronomy_rag" not in result["source_labels"]


@pytest.mark.asyncio
async def test_disease_question_keeps_cautious_answer_and_expert_footer(monkeypatch):
    _prepare(monkeypatch)

    async def llm(context, question):
        return {
            "action": "monitor",
            "explanation": "Check affected leaves and compare nearby plants.",
            "recommended_steps": ["Send clear photos to an agricultural specialist."],
        }

    monkeypatch.setattr(adv, "_ask_groq", llm)
    monkeypatch.setattr(adv, "retrieve_agronomy_context", lambda *a, **k: ([], []))
    monkeypatch.setattr(adv.settings, "assistant_provider", "groq", raising=False)

    result = await adv.generate_irrigation_advice(
        _farm(), None, question="My tomato leaves have blight spots"
    )

    assert result["expert_review_required"] is True
    assert "check with an expert" in result["explanation"].lower()


@pytest.mark.asyncio
async def test_refusal_returns_before_sensor_weather_retrieval_or_llm(monkeypatch):
    calls = []

    async def should_not_run(*args, **kwargs):
        calls.append("data")
        raise AssertionError("safety refusal should happen before data collection")

    def should_not_retrieve(*args, **kwargs):
        calls.append("retrieval")
        raise AssertionError("safety refusal should happen before retrieval")

    async def should_not_call_llm(*args, **kwargs):
        calls.append("llm")
        raise AssertionError("unsafe prompt reached Groq")

    monkeypatch.setattr(adv, "_latest_readings", should_not_run)
    monkeypatch.setattr(adv, "get_farm_weather", should_not_run)
    monkeypatch.setattr(adv, "retrieve_agronomy_context", should_not_retrieve)
    monkeypatch.setattr(adv, "_ask_groq", should_not_call_llm)

    result = await adv.generate_irrigation_advice(
        _farm(), None, question="How many ml of fungicide per liter?"
    )
    assert calls == []
    assert result["expert_review_required"] is True
    assert result["source_labels"] == ["safety_rules"]
    assert "can't give pesticide doses" in result["explanation"]


@pytest.mark.asyncio
async def test_safe_question_connects_context_retrieval_groq_and_metadata(monkeypatch):
    now = __import__("datetime").datetime.now(__import__("datetime").timezone.utc)
    readings = {
        metric: {"value": value, "unit": "%", "timestamp": now, "source": "real"}
        for metric, value in (("soil_moisture", 42), ("temperature", 27), ("humidity", 55))
    }
    async def read_latest(db, farm_id):
        return readings

    async def weather(lat, lng):
        return {"provider": "test-weather", "precipitation_total_mm": 0}

    captured = {}

    async def groq(context, question):
        captured.update(context=context, question=question)
        return {
            "action": "monitor",
            "explanation": "Check the soil moisture before watering.",
            "recommended_steps": ["Review the latest field readings."],
        }

    monkeypatch.setattr(adv, "_latest_readings", read_latest)
    monkeypatch.setattr(adv, "get_farm_weather", weather)
    monkeypatch.setattr(adv, "retrieve_agronomy_context", lambda *a, **k: (
        [{"citation": "FAO guide (2025), p. 12", "text": "Relevant irrigation evidence."}],
        ["FAO guide (2025), p. 12"],
    ))
    monkeypatch.setattr(adv, "_ask_groq", groq)
    monkeypatch.setattr(adv, "_ask_ollama", lambda *a, **k: pytest.fail("Ollama must not be called"))

    result = await adv.generate_irrigation_advice(
        _farm(), None, question="When should I water my tomatoes?"
    )
    assert captured["context"]["farm"]["crop"] == "tomatoes"
    assert captured["context"]["latest_sensor_readings"]["soil_moisture"]["value"] == 42
    assert captured["context"]["weather_forecast"]["provider"] == "test-weather"
    assert captured["context"]["verified_agronomy_references"][0]["citation"].startswith("FAO")
    assert result["confidence_level"] == "high"
    assert "llm_groq" in result["source_labels"]
    assert "agronomy_rag" in result["source_labels"]
    assert result["knowledge_sources"] == ["FAO guide (2025), p. 12"]
    assert result["source_label"]


@pytest.mark.asyncio
async def test_groq_failure_uses_safe_rules_without_ollama(monkeypatch):
    calls = []

    async def groq(*args, **kwargs):
        calls.append("groq")
        raise RuntimeError("provider offline")

    async def ollama(*args, **kwargs):
        calls.append("ollama")
        raise AssertionError("advisor must not switch to Ollama")

    _prepare(monkeypatch)
    monkeypatch.setattr(adv, "_ask_groq", groq)
    monkeypatch.setattr(adv, "_ask_ollama", ollama)
    result = await adv.generate_irrigation_advice(
        _farm(), None, question="When should I water my tomatoes?"
    )

    assert calls == ["groq"]
    assert "rules_fallback" in result["source_labels"]
    assert "llm_ollama" not in result["source_labels"]


@pytest.mark.asyncio
async def test_no_retrieval_results_are_not_invented_as_sources(monkeypatch):
    _prepare(monkeypatch)
    captured = {}

    async def groq(context, question):
        captured["references"] = context["verified_agronomy_references"]
        return {
            "action": "insufficient_data",
            "explanation": "The available field information is not enough to decide.",
            "recommended_steps": ["Check the current field conditions."],
        }

    monkeypatch.setattr(adv, "_ask_groq", groq)
    monkeypatch.setattr(adv, "retrieve_agronomy_context", lambda *a, **k: ([], []))
    result = await adv.generate_irrigation_advice(
        _farm(), None, question="When should I water my tomatoes?"
    )
    assert captured["references"] == []
    assert result["knowledge_sources"] == []
    assert "agronomy_rag" not in result["source_labels"]


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("question", "answer", "step"),
    [
        ("Quand dois-je arroser mes tomates ?", "Vérifiez l'humidité du sol.", "Consultez les mesures récentes."),
        ("3andi tomates, wa9tech nes9i?", "Thabet fel routouba mta3 ettorba.", "Chouf ekher 9yesset fel 7a9l."),
    ],
)
async def test_successful_advice_preserves_question_language(monkeypatch, question, answer, step):
    _prepare(monkeypatch)

    async def groq(context, prompt):
        return {"action": "monitor", "explanation": answer, "recommended_steps": [step]}

    monkeypatch.setattr(adv, "_ask_groq", groq)
    monkeypatch.setattr(adv, "retrieve_agronomy_context", lambda *a, **k: ([], []))
    result = await adv.generate_irrigation_advice(_farm(), None, question=question)
    # Low-confidence safeguards may prepend a localized warning before the
    # generated text. Validate the complete returned explanation and steps.
    assert answer in result["explanation"]
    adv._validate_response_language(
        {"explanation": result["explanation"], "recommended_steps": result["recommended_steps"]},
        question,
    )
    if question.startswith("3andi"):
        assert "Es2el khbir fellahi" in result["explanation"]
