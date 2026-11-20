"""LLM assistant: irrigation questions go to the LLM with live farm context;
every other question keeps using the rule-based knowledge base (stub)."""
from __future__ import annotations

from typing import Optional

from app.core.config import settings
from app.services.assistant_service import (
    KNOWLEDGE_BASE,
    AssistantResult,
    StubAssistantService,
    _kw_match,
)
from app.services.irrigation_llm import (
    LEVEL_TO_FLOAT,
    LLMClient,
    build_llm_client,
    generate_irrigation_advice,
    load_latest_sensors,
    select_kb,
)
from app.services.locations import resolve_location
from app.services.weather_service import get_weather

_IRRIGATION_KEYWORDS = next(e["keywords"] for e in KNOWLEDGE_BASE if "irrigation" in e["keywords"]) + [
    "نسقيو", "السقية", "سقية", "irriguer", "arroser", "irrigate", "watering",
]

ESCALATION_NOTE = "\n\n⚠️ تم إرسال حالتك لمراجعة خبير زراعي متخصص."


def is_irrigation_question(message: str) -> bool:
    m = message.lower()
    return any(_kw_match(k.lower(), m) for k in _IRRIGATION_KEYWORDS)


def detect_language(message: Optional[str]) -> str:
    if not message or any("\u0600" <= c <= "\u06FF" for c in message):
        return "ar"
    m = message.lower()
    if any(w in m.split() for w in ("bonjour", "comment", "quand", "je", "arroser", "irriguer", "mon", "ma")):
        return "fr"
    return "en"


class LLMAssistantService(StubAssistantService):
    def __init__(self, client: Optional[LLMClient] = None):
        self.client = client or build_llm_client()

    async def answer(self, message, farm, user, db) -> AssistantResult:
        if self.client is None or not is_irrigation_question(message):
            return await super().answer(message, farm, user, db)
        return await self.irrigation_advice(farm, user, db, message=message)

    async def irrigation_advice(self, farm, user, db, message: Optional[str] = None,
                                language: Optional[str] = None) -> AssistantResult:
        if self.client is None:  # no provider/key configured: rule-based answer
            return await super().irrigation_advice(farm, user, db, language=language)

        language = language or detect_language(message)
        sensor = await load_latest_sensors(db, farm.id)
        weather = None
        loc = resolve_location(farm)
        if settings.weather_enabled and loc:
            weather = await get_weather(loc[0], loc[1])
        kb = select_kb(farm)

        advice = await generate_irrigation_advice(self.client, farm, sensor, weather, kb, language, message)

        confidence = LEVEL_TO_FLOAT[advice.confidence]
        escalated = advice.needs_expert or confidence < 0.6
        sources = _human_sources(advice, sensor, weather, kb)
        answer = advice.farmer_message
        case_id = None
        if escalated:
            case_id = await self._create_expert_case(
                message=message or "Irrigation advice request",
                answer=f"[{advice.action}] {advice.farmer_message}",
                confidence=confidence, sources=sources, farm=farm, user=user, db=db,
            )
            answer += ESCALATION_NOTE

        return AssistantResult(
            answer=answer, confidence=confidence, sources=sources, escalated=escalated, case_id=case_id,
            confidence_level=advice.confidence, source_label=advice.source_label,
            irrigation=advice.model_dump(),
        )


def _human_sources(advice, sensor, weather, kb) -> list[str]:
    """Readable source list for the UI, derived from the labels actually used."""
    used = {advice.source_label, *(r.source for r in advice.reasons)}
    out: list[str] = []
    if "sensor" in used:
        out.append("Aethera soil sensor")
    if "simulated_sensor" in used:
        out.append("Simulated sensor data (demo)")
    if "weather_forecast" in used and weather:
        out.append(weather.source)
    if "knowledge_base" in used:
        for k in kb:
            out.extend(s for s in k.sources if s not in out)
    if "general_agronomy" in used:
        out.append("General agronomy (not locally verified)")
    return out
