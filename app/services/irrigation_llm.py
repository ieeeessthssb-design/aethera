"""Irrigation advice from an LLM: farm profile + latest sensors + weather.

Output carries a confidence level and a source label. Confidence is capped by
deterministic data-quality checks (code has the last word, not the LLM).

Provider-agnostic: any OpenAI-compatible chat endpoint (Groq, OpenAI, OpenRouter...).
"""
from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Literal, Optional

import httpx
from pydantic import BaseModel, Field, ValidationError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.reading import Reading
from app.services.weather_service import WeatherSnapshot

log = logging.getLogger("aethera.irrigation")

# ----------------------------------------------------------------- constants
SENSOR_STALE_MIN = 3 * 60          # older -> confidence capped at medium
SENSOR_DEAD_MIN = 24 * 60          # older -> reading ignored
WEATHER_STALE_MIN = 6 * 60
LEVEL_RANK = {"low": 0, "medium": 1, "high": 2}
LEVEL_TO_FLOAT = {"high": 0.85, "medium": 0.68, "low": 0.40}   # 0.6 = escalation threshold
# Set to "high" if you want simulated demo data to be allowed to reach high confidence.
SIMULATED_SENSOR_CAP = "medium"

Level = Literal["high", "medium", "low"]
SourceLabel = Literal[
    "sensor",            # real ESP32 soil sensor
    "simulated_sensor",  # demo data, no physical device
    "weather_forecast",
    "farm_profile",
    "knowledge_base",    # verified KB passage
    "general_agronomy",  # model's own knowledge, NOT verified locally
]
SOURCE_LABELS = set(SourceLabel.__args__)  # type: ignore[attr-defined]


# ------------------------------------------------------------------- schemas
class Reason(BaseModel):
    point: str
    source: SourceLabel


class IrrigationAdvice(BaseModel):
    action: Literal["irrigate_now", "irrigate_later", "skip", "recheck_later", "escalate_to_expert"]
    when: Optional[str] = None
    amount_mm: Optional[float] = Field(None, ge=0, le=60)
    reasons: list[Reason] = Field(min_length=1, max_length=4)
    confidence: Level
    confidence_reason: str
    source_label: SourceLabel
    needs_expert: bool
    farmer_message: str
    data_gaps: list[str] = []


@dataclass
class SensorSnapshot:
    timestamp: datetime
    soil_moisture: Optional[float]
    temperature: Optional[float]
    humidity: Optional[float]
    source: str  # "real" | "simulated"


@dataclass
class KBSnippet:
    doc_id: str
    text: str
    sources: list[str]
    has_threshold: bool


# -------------------------------------------------------------- data loading
async def load_latest_sensors(db: AsyncSession, farm_id: str) -> Optional[SensorSnapshot]:
    vals, ts, sources = {}, [], []
    for metric in ("soil_moisture", "temperature", "humidity"):
        r = (await db.execute(
            select(Reading).where(Reading.farm_id == farm_id, Reading.metric == metric)
            .order_by(Reading.recorded_at.desc()).limit(1)
        )).scalar_one_or_none()
        vals[metric] = r.value if r else None
        if r:
            ts.append(r.recorded_at)
            sources.append(r.source)
    if not ts:
        return None
    return SensorSnapshot(
        timestamp=max(ts),
        soil_moisture=vals["soil_moisture"], temperature=vals["temperature"], humidity=vals["humidity"],
        source="real" if all(s == "real" for s in sources) else "simulated",
    )


def select_kb(farm) -> list[KBSnippet]:
    """Irrigation entry + entries matching the farm's crop, from the project knowledge base."""
    from app.services.assistant_service import KNOWLEDGE_BASE, _kw_match

    crop = (getattr(farm, "crop", "") or "").lower()
    out = []
    for i, e in enumerate(KNOWLEDGE_BASE):
        is_irrigation = "irrigation" in e["keywords"]
        if is_irrigation or (crop and any(_kw_match(k.lower(), crop) for k in e["keywords"])):
            text = e["answer_en"]
            out.append(KBSnippet(f"KB-{i}", text, e["sources"], bool(re.search(r"\d+\s*%", text))))
    return out


# ------------------------------------------------------------ quality checks
def _aware(ts: datetime) -> datetime:
    return ts if ts.tzinfo else ts.replace(tzinfo=timezone.utc)


def age_min(ts: datetime, now: datetime) -> float:
    return (now - _aware(ts)).total_seconds() / 60


def assess_data_quality(farm, sensor, weather, kb, now) -> tuple[Level, list[str], Optional[SensorSnapshot]]:
    """Returns (max allowed confidence, data gaps, usable sensor or None)."""
    cap: Level = "high"
    gaps: list[str] = []

    def lower(level: Level):
        nonlocal cap
        if LEVEL_RANK[level] < LEVEL_RANK[cap]:
            cap = level

    usable = sensor
    if sensor is None:
        gaps.append("no sensor readings")
        lower("medium")
    else:
        sm = sensor.soil_moisture
        age = age_min(sensor.timestamp, now)
        if sm is None or not (0 <= sm <= 100):
            gaps.append("soil moisture missing or out of range, ignored")
            usable = None
            lower("medium")
        elif age > SENSOR_DEAD_MIN:
            gaps.append("sensor reading older than 24h, ignored")
            usable = None
            lower("medium")
        else:
            if age > SENSOR_STALE_MIN:
                gaps.append(f"sensor reading is {age / 60:.0f}h old")
                lower("medium")
            if sensor.source != "real":
                gaps.append("sensor data is simulated (no physical device)")
                lower(SIMULATED_SENSOR_CAP)

    if weather is None:
        gaps.append("no weather data")
        lower("medium")
    elif age_min(weather.fetched_at, now) > WEATHER_STALE_MIN:
        gaps.append("weather data older than 6h")
        lower("medium")

    if getattr(farm, "plant_age_days", None) is None:
        gaps.append("farm profile missing: plant age / growth stage")
        lower("medium")
    if not any(k.has_threshold for k in kb):
        gaps.append("no verified soil-moisture threshold for this crop in the knowledge base")
        lower("medium")
    if usable is None and weather is None:
        lower("low")
    return cap, gaps, usable


# -------------------------------------------------------------------- prompt
LANG_NAMES = {
    "ar": "Tunisian Derja written in Arabic script (simple, spoken style)",
    "fr": "French (simple)",
    "en": "English (simple)",
}

SYSTEM_PROMPT = """\
You are Aethera's irrigation advisor for Tunisian smallholder farmers.
Decide whether and when to irrigate using ONLY the data provided below.

RULES
1. Never invent sensor values, weather values or crop thresholds.
2. Moisture thresholds and water amounts must come from KNOWLEDGE BASE passages. If none apply you may use
   general agronomy, but label it "general_agronomy" and keep confidence at most "medium".
3. Water is scarce: do not irrigate when meaningful rain is forecast (rain_next_2d_mm >= 5 or high probability)
   unless soil is at critical stress, and say why.
4. Prefer evening or early morning irrigation to reduce evaporation, especially in heat.
5. If signals contradict each other (e.g. very wet soil in a heatwave with no recent rain/irrigation) do not guess:
   confidence "low", action "escalate_to_expert".
6. If irrigation_type is "rainfed", do not recommend irrigating; advise on water conservation instead.
7. Confidence: high = fresh real sensor + fresh weather + KB threshold, signals agree;
   medium = some inputs missing/stale/simulated or thresholds from general knowledge; low = conflicting or too little data.
8. source_label = the PRIMARY basis of the advice. Each reason has its own source label.
   Allowed labels: sensor, simulated_sensor, weather_forecast, farm_profile, knowledge_base, general_agronomy.
   Use "simulated_sensor" instead of "sensor" when the sensor source is "simulated".
9. "reasons": 1-4 short items in English. "farmer_message": max 2 short plain sentences in {language}, read aloud
   by text-to-speech: no symbols, no abbreviations.
10. Output ONLY one JSON object, no markdown.

JSON SHAPE
{{"action": "irrigate_now|irrigate_later|skip|recheck_later|escalate_to_expert",
  "when": "string or null", "amount_mm": number or null,
  "reasons": [{{"point": "...", "source": "<label>"}}],
  "confidence": "high|medium|low", "confidence_reason": "...",
  "source_label": "<label>", "needs_expert": true|false, "farmer_message": "..."}}
"""

USER_TEMPLATE = """\
NOW (UTC): {now}
FARMER QUESTION: {question}

FARM PROFILE
{profile}

LATEST SENSOR READING (age: {sensor_age}; source: {sensor_source})
{sensor}

WEATHER (age: {weather_age})
{weather}

KNOWLEDGE BASE
{kb}

KNOWN DATA GAPS
{gaps}
"""


def build_prompt(farm, sensor, weather, kb, gaps, language, question, now) -> tuple[str, str]:
    profile = {
        "crop": farm.crop, "region": farm.region, "plant_age_days": getattr(farm, "plant_age_days", None),
        "irrigation_type": getattr(farm, "irrigation_type", None), "area_hectares": getattr(farm, "area_hectares", None),
    }
    sensor_d = ({"soil_moisture_pct": sensor.soil_moisture, "air_temp_c": sensor.temperature,
                 "air_humidity_pct": sensor.humidity} if sensor else "NOT AVAILABLE")
    user = USER_TEMPLATE.format(
        now=now.isoformat(timespec="minutes"),
        question=question or "When and how much should I irrigate?",
        profile=json.dumps(profile, ensure_ascii=False),
        sensor=json.dumps(sensor_d), sensor_age=f"{age_min(sensor.timestamp, now):.0f} min" if sensor else "n/a",
        sensor_source=sensor.source if sensor else "n/a",
        weather=json.dumps(weather.as_dict()) if weather else "NOT AVAILABLE",
        weather_age=f"{age_min(weather.fetched_at, now):.0f} min" if weather else "n/a",
        kb="\n".join(f"[{k.doc_id}] {k.text}" for k in kb) or "NONE",
        gaps="\n".join(f"- {g}" for g in gaps) or "none",
    )
    return SYSTEM_PROMPT.format(language=LANG_NAMES.get(language, LANG_NAMES["en"])), user


# --------------------------------------------------------------- LLM client
class LLMClient:
    async def complete(self, system: str, user: str) -> str:  # pragma: no cover - interface
        raise NotImplementedError


DEFAULTS = {
    "groq": ("https://api.groq.com/openai/v1", "llama-3.3-70b-versatile"),
    "openai": ("https://api.openai.com/v1", "gpt-4o-mini"),
}


class OpenAICompatClient(LLMClient):
    def __init__(self, base_url: str, api_key: str, model: str, timeout: float):
        self.base_url, self.api_key, self.model, self.timeout = base_url.rstrip("/"), api_key, model, timeout

    async def complete(self, system: str, user: str) -> str:
        payload = {
            "model": self.model, "temperature": 0.2, "max_tokens": 700,
            "response_format": {"type": "json_object"},
            "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
        }
        headers = {"Authorization": f"Bearer {self.api_key}"}
        async with httpx.AsyncClient(timeout=self.timeout) as c:
            r = await c.post(f"{self.base_url}/chat/completions", headers=headers, json=payload)
            if r.status_code == 400:  # model may not support JSON mode: retry without it
                payload.pop("response_format")
                r = await c.post(f"{self.base_url}/chat/completions", headers=headers, json=payload)
            r.raise_for_status()
            return r.json()["choices"][0]["message"]["content"]


def build_llm_client() -> Optional[LLMClient]:
    provider = settings.assistant_provider.lower()
    if provider not in DEFAULTS:
        return None
    key = settings.groq_api_key if provider == "groq" else settings.openai_api_key
    if not key:
        log.warning("ASSISTANT_PROVIDER=%s but no API key set; falling back to stub", provider)
        return None
    base, default_model = DEFAULTS[provider]
    return OpenAICompatClient(base, key, settings.llm_model or default_model, settings.llm_timeout_s)


# ------------------------------------------------------------ orchestration
def _parse(raw: str) -> IrrigationAdvice:
    raw = raw.strip()
    if raw.startswith("```"):
        raw = re.sub(r"^```(?:json)?|```$", "", raw).strip()
    return IrrigationAdvice.model_validate_json(raw)


FALLBACK_MESSAGES = {
    "ar": "ما نجمش نعطيك نصيحة مؤكدة توا. باش نبعث حالتك لخبير زراعي.",
    "fr": "Je ne peux pas donner un conseil fiable pour le moment. Votre cas est envoyé à un expert.",
    "en": "I can't give a reliable answer right now. Your case is being sent to an expert.",
}


def fallback_advice(gaps: list[str], language: str, why: str) -> IrrigationAdvice:
    return IrrigationAdvice(
        action="escalate_to_expert",
        reasons=[Reason(point="No reliable automatic answer could be produced.", source="general_agronomy")],
        confidence="low", confidence_reason=why, source_label="general_agronomy", needs_expert=True,
        farmer_message=FALLBACK_MESSAGES.get(language, FALLBACK_MESSAGES["en"]), data_gaps=gaps,
    )


def _fix_label(label: str, sensor_usable: Optional[SensorSnapshot], weather) -> str:
    """Never claim a source we did not actually use."""
    if label in ("sensor", "simulated_sensor"):
        if sensor_usable is None:
            return "weather_forecast" if weather else "general_agronomy"
        return "sensor" if sensor_usable.source == "real" else "simulated_sensor"
    if label == "weather_forecast" and weather is None:
        return "general_agronomy"
    return label if label in SOURCE_LABELS else "general_agronomy"


async def generate_irrigation_advice(
    client: Optional[LLMClient], farm, sensor: Optional[SensorSnapshot], weather: Optional[WeatherSnapshot],
    kb: list[KBSnippet], language: str = "ar", question: Optional[str] = None, now: Optional[datetime] = None,
) -> IrrigationAdvice:
    now = now or datetime.now(timezone.utc)
    cap, gaps, usable = assess_data_quality(farm, sensor, weather, kb, now)
    if client is None:
        return fallback_advice(gaps, language, "No LLM provider configured.")

    system, user = build_prompt(farm, usable, weather, kb, gaps, language, question, now)
    advice: Optional[IrrigationAdvice] = None
    for attempt in range(2):
        try:
            advice = _parse(await client.complete(system, user))
            break
        except (ValidationError, ValueError, KeyError, httpx.HTTPError) as e:
            log.warning("irrigation LLM attempt %d failed: %s", attempt + 1, e)
    if advice is None:
        return fallback_advice(gaps, language, "LLM call failed or returned invalid output.")

    # --- guardrails: code has the last word ---
    level = advice.confidence if LEVEL_RANK[advice.confidence] <= LEVEL_RANK[cap] else cap
    advice.source_label = _fix_label(advice.source_label, usable, weather)
    for r in advice.reasons:
        r.source = _fix_label(r.source, usable, weather)
    if advice.source_label == "general_agronomy" and level == "high":
        level = "medium"
    advice.confidence = level
    advice.data_gaps = gaps
    if level == "low" or advice.action == "escalate_to_expert":
        advice.needs_expert = True
    return advice
