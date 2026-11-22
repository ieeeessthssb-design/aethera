"""Farm-aware irrigation advice using Groq (OpenAI-compatible API) and explicit confidence rules."""
import json
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

import httpx

from app.core.config import settings
from app.models.reading import Reading
from app.services.weather_service import get_farm_weather


SYSTEM_PROMPT = """You are Aethera, a cautious agricultural irrigation assistant for Tunisian smallholder farmers.
Your task is ONLY to advise on irrigation using the supplied farm profile, latest sensor readings, and weather forecast.

Rules:
- Use only facts in the supplied JSON. Never invent readings, weather, soil type, crop stage, or water availability.
- Treat sensor readings marked simulated as demonstrations, not real measurements.
- Consider forecast rain before recommending irrigation.
- Do not give a fixed irrigation duration, water volume, or mm amount unless the supplied data contains a validated crop-specific irrigation threshold or irrigation schedule. If not available, say that quantity cannot safely be calculated.
- If readings are missing, stale, simulated, or contradictory, recommend monitoring / collecting data and explain the limitation.
- Do not diagnose crop disease or prescribe fertilizers/pesticides.
- Do not claim to be an agronomist. Escalate uncertain/high-risk situations to a human agricultural expert.
- Answer in the language of the user's question when possible. Keep advice practical and clear.
- Return ONLY valid JSON with keys: action (one of irrigate_now, wait, monitor, insufficient_data), explanation (string), recommended_steps (array of short strings).
"""


def calculate_confidence(
    readings: dict[str, Optional[dict]], weather: Optional[dict], farm: Any
) -> tuple[float, str, list[str], list[str]]:
    """A transparent data-availability score; it is NOT an agronomic probability."""
    score = 0.35
    reasons: list[str] = []
    labels: list[str] = []

    moisture = readings.get("soil_moisture")
    if any(readings.values()):
        labels.append("sensor")
    if moisture:
        if moisture["source"] == "real":
            reading_time = moisture["timestamp"]
            if reading_time.tzinfo is None:
                reading_time = reading_time.replace(tzinfo=timezone.utc)
            age = datetime.now(timezone.utc) - reading_time
            if age <= timedelta(hours=2):
                score += 0.25
                reasons.append("Fresh real soil-moisture reading")
            else:
                score += 0.08
                reasons.append("Soil-moisture reading is older than 2 hours")
        else:
            score += 0.05
            reasons.append("Sensor values are simulated, not field measurements")
            labels.append("simulated_data")
    else:
        reasons.append("No soil-moisture reading is available")

    other_readings = [readings.get("temperature"), readings.get("humidity")]
    if all(other_readings):
        if all(r["source"] == "real" for r in other_readings):
            score += 0.10
            reasons.append("Temperature and humidity readings are available")
        else:
            score += 0.03
            reasons.append("Some environmental sensor readings are simulated")
            if "simulated_data" not in labels:
                labels.append("simulated_data")
    else:
        reasons.append("Temperature or humidity sensor data is missing")

    if weather:
        score += 0.20
        reasons.append("A 24-hour weather forecast is available")
        labels.append("weather")
    else:
        reasons.append("Weather forecast unavailable (farm coordinates may be missing)")

    if getattr(farm, "crop", None) and getattr(farm, "irrigation_type", None):
        score += 0.05
        reasons.append("Crop and irrigation method are known")
        labels.append("farm_profile")
    if getattr(farm, "area_hectares", None):
        score += 0.05
        reasons.append("Farm area is available")

    # Missing weather/moisture, simulated data, or stale moisture cannot support a
    # confident irrigation decision. Keep the score below the expert-review threshold.
    stale_sensor = False
    for reading in readings.values():
        if reading:
            timestamp = reading["timestamp"]
            if timestamp.tzinfo is None:
                timestamp = timestamp.replace(tzinfo=timezone.utc)
            if datetime.now(timezone.utc) - timestamp > timedelta(hours=2):
                stale_sensor = True
    any_simulated = any(
        reading and reading["source"] != "real" for reading in readings.values()
    )
    if stale_sensor and "One or more sensor readings are older than 2 hours" not in reasons:
        reasons.append("One or more sensor readings are older than 2 hours")
    missing_environmental_sensor = not readings.get("temperature") or not readings.get("humidity")
    if not moisture or not weather or stale_sensor or any_simulated:
        score = min(score, 0.59)
    elif missing_environmental_sensor:
        score = min(score, 0.79)

    score = round(min(score, 0.95), 2)
    level = "high" if score >= 0.80 else "medium" if score >= 0.60 else "low"
    return score, level, reasons, list(dict.fromkeys(labels))


async def _latest_readings(db, farm_id: str) -> dict[str, Optional[dict]]:
    result: dict[str, Optional[dict]] = {}
    for metric in ("soil_moisture", "temperature", "humidity"):
        from sqlalchemy import select
        query = (
            select(Reading)
            .where(Reading.farm_id == farm_id, Reading.metric == metric)
            .order_by(Reading.recorded_at.desc())
            .limit(1)
        )
        row = (await db.execute(query)).scalar_one_or_none()
        result[metric] = (
            {
                "value": row.value,
                "unit": "%" if metric in ("soil_moisture", "humidity") else "°C",
                "timestamp": row.recorded_at,
                "source": row.source,
            }
            if row else None
        )
    return result


def _action_label(action: str) -> str:
    return {
        "irrigate_now": "Irrigate now",
        "wait": "Wait before irrigating",
        "monitor": "Monitor conditions",
        "insufficient_data": "Insufficient data",
    }.get(action, "Monitor conditions")


async def _ask_groq(farm_context: dict, question: str) -> dict:
    if not settings.groq_api_key:
        raise RuntimeError("GROQ_API_KEY is not configured")
    body = {
        "model": settings.groq_model,
        "temperature": 0.2,
        "max_tokens": 500,
        "response_format": {"type": "json_object"},
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": json.dumps({
                "farmer_question": question,
                "farm_context": farm_context,
            }, ensure_ascii=False, default=str)},
        ],
    }
    async with httpx.AsyncClient(timeout=25.0) as client:
        response = await client.post(
            settings.groq_base_url.rstrip("/") + "/chat/completions",
            headers={"Authorization": f"Bearer {settings.groq_api_key}"},
            json=body,
        )
        response.raise_for_status()
        payload = response.json()
    content = payload["choices"][0]["message"]["content"]
    parsed = json.loads(content)
    action = parsed.get("action")
    if action not in {"irrigate_now", "wait", "monitor", "insufficient_data"}:
        raise ValueError("LLM returned an invalid irrigation action")
    explanation = str(parsed.get("explanation", "")).strip()
    steps = parsed.get("recommended_steps", [])
    if not explanation or not isinstance(steps, list):
        raise ValueError("LLM returned an incomplete irrigation response")
    return {
        "action": action,
        "explanation": explanation[:2000],
        "recommended_steps": [str(step)[:300] for step in steps[:6]],
    }


async def generate_irrigation_advice(farm, db, question: str = "") -> dict:
    readings = await _latest_readings(db, farm.id)
    weather = await get_farm_weather(farm.lat, farm.lng)
    confidence, level, reasons, labels = calculate_confidence(readings, weather, farm)

    context = {
        "farm": {
            "crop": farm.crop,
            "region": farm.region,
            "area_hectares": farm.area_hectares,
            "plant_age_days": farm.plant_age_days,
            "irrigation_type": farm.irrigation_type,
            "latitude_available": farm.lat is not None,
            "longitude_available": farm.lng is not None,
        },
        "latest_sensor_readings": {
            metric: (
                {**value, "timestamp": value["timestamp"].isoformat()}
                if value else None
            )
            for metric, value in readings.items()
        },
        "weather_forecast": weather,
    }

    provider = settings.assistant_provider.lower()
    try:
        if provider == "groq":
            generated = await _ask_groq(context, question)
            labels.append("llm_groq")
        else:
            raise RuntimeError("LLM provider is not configured; using safe rules fallback")
    except (httpx.HTTPError, RuntimeError, ValueError, KeyError, IndexError, json.JSONDecodeError):
        # A safe deterministic fallback makes local demos work without an API key.
        moisture = readings.get("soil_moisture")
        if not moisture:
            action = "insufficient_data"
        elif moisture["source"] == "simulated":
            action = "monitor"
        elif weather and (weather.get("precipitation_total_mm") or 0) >= 3:
            action = "wait"
        else:
            action = "monitor"
        generated = {
            "action": action,
            "explanation": (
                "The AI service is unavailable or the available data is insufficient. "
                "This fallback does not issue an automatic watering quantity; check the field "
                "and consult a local agronomist before changing the irrigation schedule."
            ),
            "recommended_steps": [
                "Check soil moisture manually near the active root zone.",
                "Verify that the latest sensor readings are current and from a real device.",
                "Review the local rainfall forecast before irrigating.",
            ],
        }
        labels.append("rules_fallback")

    # Never present simulated readings as field evidence or high-confidence advice.
    if any(r and r["source"] == "simulated" for r in readings.values()):
        confidence = min(confidence, 0.59)
        level = "low" if confidence < 0.60 else level
    if not weather or not readings.get("soil_moisture"):
        confidence = min(confidence, 0.59)
        level = "low"

    # Enforce safety in code as well as in the prompt: an LLM must not trigger
    # irrigation when the core moisture or weather input is unavailable.
    if not readings.get("soil_moisture") or not weather:
        generated["action"] = "insufficient_data"
        generated["explanation"] = (
            "A reliable irrigation decision cannot be made because soil-moisture "
            "readings or the local weather forecast are missing. " + generated["explanation"]
        )[:2000]
    elif confidence < 0.60 and generated["action"] == "irrigate_now":
        generated["action"] = "monitor"
        generated["explanation"] = (
            "The available data is low-confidence, so do not use this as an automatic "
            "irrigation trigger. " + generated["explanation"]
        )[:2000]

    escalated = confidence < 0.60 or generated["action"] == "insufficient_data"
    return {
        **generated,
        "action_label": _action_label(generated["action"]),
        "confidence": confidence,
        "confidence_level": level,
        "confidence_reasons": reasons,
        "source_labels": list(dict.fromkeys(labels)),
        "source_label": " + ".join(dict.fromkeys(labels)) or "farm_profile",
        "sensor_data": {
            metric: (
                {
                    "value": value["value"],
                    "unit": value["unit"],
                    "timestamp": value["timestamp"].isoformat(),
                    "source": value["source"],
                } if value else None
            )
            for metric, value in readings.items()
        },
        "weather": weather,
        "expert_review_required": escalated,
    }
