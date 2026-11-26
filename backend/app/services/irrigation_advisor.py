"""Farm-aware irrigation advice using Groq (OpenAI-compatible API) and explicit confidence rules."""
import json
import logging
import re
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

import httpx

from app.core.config import settings
from app.services import safety
from app.services.agronomy_retrieval import retrieve_agronomy_context
from app.models.reading import Reading
from app.services.weather_service import get_farm_weather

logger = logging.getLogger(__name__)


class _LanguageMismatchError(ValueError):
    """Raised when generated advice clearly ignores the farmer's language."""


_FRENCH_MARKERS = {
    "alors", "arroser", "avec", "comment", "des", "dois", "est", "il", "j", "la",
    "le", "les", "mais", "mes", "mon", "ne", "pas", "pour", "quand", "que",
    "quelle", "qui", "sol", "tomates", "une", "votre", "vous",
}
_ENGLISH_MARKERS = {
    "a", "about", "are", "check", "do", "for", "how", "i", "is", "it", "my",
    "need", "of", "soil", "the", "to", "tomatoes", "water", "when", "with", "you",
}
_DERJA_LATIN_MARKERS = {
    "a3tini", "andi", "bech", "chouf", "chnowa", "chneya", "el", "elli", "fama",
    "fel", "fih", "ken", "kifech", "ma", "ma3andich", "najm", "najem", "nheb",
    "n7eb", "9is", "tawa", "thabet", "wa9tech", "walla", "walli", "ya3ni",
}


def _contains_arabizi_marker(text: str) -> bool:
    return bool(re.search(r"(?:^|\W)[237589][a-z]{2,}|\b[a-z]+[237589][a-z]+", text.lower()))


def _language_profile(question: str) -> str:
    """Recognize supported language/script variants without external classifiers."""
    text = question or ""
    if re.search(r"[\u0600-\u06ff\u0750-\u077f\u08a0-\u08ff]", text):
        return "derja_arabic"

    words = set(re.findall(r"[a-z0-9]+", text.lower()))
    if words & _DERJA_LATIN_MARKERS or _contains_arabizi_marker(text):
        return "derja_latin"

    french_score = len(words & _FRENCH_MARKERS)
    english_score = len(words & _ENGLISH_MARKERS)
    if french_score >= 2 and french_score > english_score:
        return "french"
    if english_score >= 2 and english_score > french_score:
        return "english"
    return "other_latin"


def _language_matches(text: str, profile: str) -> bool:
    letters = re.findall(r"[A-Za-z\u0600-\u06ff\u0750-\u077f\u08a0-\u08ff]", text)
    if not letters:
        return False
    arabic_count = sum(bool(re.match(r"[\u0600-\u06ff\u0750-\u077f\u08a0-\u08ff]", c)) for c in letters)
    latin_count = len(letters) - arabic_count
    words = set(re.findall(r"[a-z0-9]+", text.lower()))

    if profile == "derja_arabic":
        return arabic_count / len(letters) >= 0.35
    if profile == "derja_latin":
        return latin_count / len(letters) >= 0.75 and bool(
            words & _DERJA_LATIN_MARKERS or _contains_arabizi_marker(text)
        )
    if profile == "french":
        return latin_count / len(letters) >= 0.75 and not (
            len(words & _ENGLISH_MARKERS) >= 2 and len(words & _ENGLISH_MARKERS) > len(words & _FRENCH_MARKERS)
        )
    if profile == "english":
        return latin_count / len(letters) >= 0.75 and not (
            len(words & _FRENCH_MARKERS) >= 2 and len(words & _FRENCH_MARKERS) > len(words & _ENGLISH_MARKERS)
        )
    # For unsupported Latin-script languages, enforce a matching writing script
    # only when the question itself clearly uses Latin characters.
    return latin_count / len(letters) >= 0.75


def _validate_response_language(advice: dict, question: str) -> None:
    profile = _language_profile(question)
    for field, values in (("explanation", [advice["explanation"]]), ("recommended_steps", advice["recommended_steps"])):
        for value in values:
            if not _language_matches(value, profile):
                raise _LanguageMismatchError(
                    f"LLM {field} does not match the farmer question's language/script ({profile})"
                )


def _localized_safety_prefix(question: str, missing_data: bool) -> str:
    profile = _language_profile(question)
    messages = {
        "french": (
            "Une décision fiable est impossible, car les mesures d’humidité du sol ou les prévisions locales manquent. "
            if missing_data else "Les données disponibles sont peu fiables : ne déclenchez pas l’irrigation automatiquement. "
        ),
        "english": (
            "A reliable decision is not possible because soil-moisture readings or the local forecast are missing. "
            if missing_data else "The available data is low-confidence, so do not use it as an automatic irrigation trigger. "
        ),
        "derja_arabic": (
            "ما ننجموش ناخذو قرار موثوق خاطر قياسات رطوبة التربة ولا نشرة الطقس المحلية ناقصة. "
            if missing_data else "المعطيات المتوفرة موش موثوقة كفاية، ما تعتمدش عليها باش تشعل الري آلياً. "
        ),
        "derja_latin": (
            "Ma najjmouch nakhdhou 9rar mawthou9 khater 9yessat routoubet ettorba walla ta9s el jiha na9es. "
            if missing_data else "El ma3loumet mahech mawthou9a kfeya, ma ta3melch el ri automatique 3la 7sebha. "
        ),
    }
    return messages.get(profile, messages["english"])


def _localized_rules_fallback(question: str, action: str) -> dict:
    profile = _language_profile(question)
    content = {
        "french": (
            "Le service d’IA est indisponible ou les données ne suffisent pas pour décider. Aucun volume d’eau n’est calculé ; vérifiez la parcelle et demandez conseil à un spécialiste agricole local.",
            ["Vérifiez manuellement l’humidité du sol près des racines.", "Confirmez que les dernières mesures viennent d’un capteur réel et sont récentes.", "Consultez les prévisions locales de pluie avant d’irriguer."],
        ),
        "english": (
            "The AI service is unavailable or the available data is insufficient. No watering quantity is calculated; check the field and consult a local agricultural expert.",
            ["Check soil moisture manually near the active root zone.", "Verify that the latest readings are current and come from a real device.", "Review the local rainfall forecast before irrigating."],
        ),
        "derja_arabic": (
            "خدمة الذكاء الاصطناعي موش متوفرة ولا المعطيات ما تكفيش للقرار. ما حسبناش كمية ماء؛ تفقد الحقل واستشر خبير فلاحي من جهتك.",
            ["قيس رطوبة التربة بيدك قريب للجذور.", "تأكد اللي آخر القياسات جديدة وجاية من جهاز حقيقي.", "شوف توقعات الشتا في جهتك قبل ما تسقي."],
        ),
        "derja_latin": (
            "Khedmet el dhka el istena3i mahech mawjouda walla el ma3loumet ma tekfich. Ma 7sebnach 9addech mé; thabet fel 7a9l w es2el khbir fellahi men jihtik.",
            ["9is routoubet ettorba bidek 9rib lel jdhour.", "Thabet elli ekher 9yesset jdod w jeyin men appareil 7a9i9i.", "Chouf ta9s el jiha 9bal ess9i."],
        ),
    }
    explanation, steps = content.get(profile, content["english"])
    return {"action": action, "explanation": explanation, "recommended_steps": steps}


def _localized_safety_reply(question: str, verdict) -> str:
    """Use Latin-script Derja for safety messages when the question is Arabizi."""
    if _language_profile(question) != "derja_latin":
        return verdict.reply or safety.expert_notice(verdict.language)
    if verdict.category == safety.Category.EMERGENCY:
        return (
            "Hedhi tnajem tkoun 7alet tasammom: 3ayet SAMU 190 walla emchi lel sbitar taw. "
            "Ba3ed el personne 3al produit, ma tkhallihach traja3 ken ma 9allekch tbib, "
            "w khoudh etiketa mta3 el produit. Es2el khbir fellahi."
        )
    if verdict.category == safety.Category.PESTICIDE_DOSAGE:
        return (
            "Ma najjemch na3tik dose, nisbet khalet, walla wa9t rch mta3 el mbid. "
            "Es2el khbir fellahi walla technicien CRDA w ettabe3 etiketa mta3 el produit."
        )
    if verdict.category == safety.Category.PESTICIDE_TOPIC:
        return (
            "Ma nans7ekch b produit walla traitement mta3 mbid. Es2el khbir fellahi "
            "w ettabe3 etiketa mta3 el produit."
        )
    if verdict.category == safety.Category.UNCLEAR:
        return "Ma fhemtch sou2alek bch njewbek b aman. 9olli chnowa el mahsoul w chnowa el mochkel."
    return verdict.reply or safety.expert_notice(verdict.language)


def _localized_expert_footer(question: str, escalated: bool, language: str) -> str:
    if _language_profile(question) == "derja_latin":
        return (
            "Es2el khbir fellahi 9bal ma ta3mel ay 7aja." if escalated
            else "Hedhi ma3louma 3amma; es2el khbir 3la 7a9lek."
        )
    return safety.expert_notice(language) if escalated else safety.general_footer(language)


SYSTEM_PROMPT = """You are Aethera, a cautious agricultural irrigation assistant for Tunisian farmers.

LANGUAGE RULES — STRICT AND MANDATORY:
- First identify the language and writing style of the farmer_question.
- If the question is in French, write the entire answer in natural French.
- If the question is in Tunisian Derja written in Arabic script, write the entire answer in natural Tunisian Derja using Arabic script.
- If the question is in Tunisian Derja written in Latin characters or Arabizi, write the entire answer in Tunisian Derja using Latin characters.
- If the question is in another language, answer entirely in that language.
- Never default to English.
- The action value must remain one of the required technical identifiers, but explanation and every recommended_steps item MUST be in the farmer's language.
- Do not mix languages.
- Before returning the JSON, verify that explanation and every recommended step use the same language and writing style as the farmer's question.

AGRONOMY KNOWLEDGE RETRIEVAL — STRICT:
- The farm_context may include verified_agronomy_references retrieved from the local document index.
- Use these excerpts only when relevant; they are supporting references, not farm-specific measurements.
- Never treat a general document passage as a sensor reading, local weather forecast, or validated threshold for this specific farm.
- Do not invent sources, titles, years, pages, facts, or citations. The API separately returns exact retrieved source citations.
- If no relevant passage is supplied, do not claim that a knowledge-base source supports the answer.

AGRICULTURAL SAFETY — STRICT:
- Give irrigation advice only, using facts explicitly present in the supplied farm_context.
- Never invent or assume sensor readings, weather conditions, rainfall, soil type, crop age, crop stage, irrigation equipment, water availability, or farm characteristics.
- A crop name alone does not provide an irrigation threshold.
- Never invent or estimate crop-specific soil-moisture thresholds.
- Never claim that soil moisture is below or above a recommended threshold unless that exact validated threshold is explicitly provided in farm_context.
- Never infer a threshold from crop type, crop age, season, or general agricultural knowledge.
- Never invent irrigation duration, water volume, or millimeters of water.
- Treat readings marked simulated as demonstrations, NOT real field measurements. Never use simulated readings alone to justify an automatic irrigation recommendation.
- Consider the supplied weather forecast before making a recommendation. Never invent forecast information.
- If readings are missing, stale, simulated, or contradictory, prefer monitor or insufficient_data and explain the limitation.
- If reliable information is insufficient to decide whether irrigation is needed, do not guess. Recommend checking the field and collecting reliable measurements.
- Do not diagnose crop diseases or prescribe fertilizers or pesticides.
- Do not claim to be an agronomist.
- Recommend human agricultural expert review when the situation is uncertain or high-risk.

OUTPUT FORMAT — STRICT:
- Return ONLY one valid JSON object.
- Use exactly these three keys: action, explanation, recommended_steps.
- Do not add other keys.
- action must be exactly one of: irrigate_now, wait, monitor, insufficient_data.
- explanation must be a non-empty string written entirely in the farmer's language.
- recommended_steps must be an array containing between 1 and 6 short strings, all written entirely in the farmer's language.
- Do not include Markdown, code fences, comments, or text outside the JSON.
- Do not return the input data or repeat the farm context instead of giving advice.
- Check that the JSON is valid and all required fields are present before responding."""


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


def _parse_llm_response(content: str, question: Optional[str] = None) -> dict:
    parsed = json.loads(content)
    if not isinstance(parsed, dict):
        raise ValueError("LLM returned a non-object irrigation response")
    action = parsed.get("action")

    if action not in {"irrigate_now", "wait", "monitor", "insufficient_data"}:
        raise ValueError("LLM returned an invalid irrigation action")

    explanation = str(parsed.get("explanation", "")).strip()
    steps = parsed.get("recommended_steps", [])

    if not explanation or not isinstance(steps, list) or not 1 <= len(steps) <= 6:
        raise ValueError("LLM returned an incomplete irrigation response")
    if any(not isinstance(step, str) or not step.strip() for step in steps):
        raise ValueError("LLM returned an invalid recommended step")

    advice = {
        "action": action,
        "explanation": explanation[:2000],
        "recommended_steps": [step.strip()[:300] for step in steps],
    }
    if question is not None:
        _validate_response_language(advice, question)
    return advice


async def _ask_groq(farm_context: dict, question: str) -> dict:
    if not settings.groq_api_key:
        raise RuntimeError("GROQ_API_KEY is not configured")
    body = {
        "model": settings.groq_model,
        "temperature": 0.2,
        "max_tokens": 1000,
        "response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": "irrigation_advice",
                "strict": True,
                "schema": {
                    "type": "object",
                    "properties": {
                        "action": {
                            "type": "string",
                            "enum": [
                                "irrigate_now",
                                "wait",
                                "monitor",
                                "insufficient_data"
                            ]
                        },
                        "explanation": {
                            "type": "string"
                        },
                        "recommended_steps": {
                            "type": "array",
                            "items": {"type": "string"}
                        }
                    },
                    "required": [
                        "action",
                        "explanation",
                        "recommended_steps"
                    ],
                    "additionalProperties": False
                }
            }
        },
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": json.dumps({
                    "farmer_question": question,
                    "farm_context": farm_context,
                }, ensure_ascii=False, default=str),
            },
        ],
    }
    async with httpx.AsyncClient(timeout=25.0) as client:
        for attempt in range(2):
            request_body = body
            if attempt:
                request_body = {
                    **body,
                    "messages": [
                        {"role": "system", "content": SYSTEM_PROMPT + (
                            "\n\nCORRECTION: Your previous response used the wrong language or writing script. "
                            "Regenerate every human-readable field in the exact language and script of the farmer_question. "
                            "For Tunisian Arabizi, use Tunisian Derja in Latin characters; for Arabic-script Derja, use Arabic characters."
                        )},
                        body["messages"][1],
                    ],
                }
            response = await client.post(
                settings.groq_base_url.rstrip("/") + "/chat/completions",
                headers={"Authorization": f"Bearer {settings.groq_api_key}"},
                json=request_body,
            )

            if response.is_error:
                logger.error(
                    "Groq HTTP %s",
                    response.status_code,
                )
            response.raise_for_status()
            payload = response.json()
            raw_content = payload["choices"][0]["message"]["content"]
            try:
                return _parse_llm_response(raw_content, question)
            except _LanguageMismatchError:
                if attempt:
                    raise
    raise RuntimeError("Groq response was not accepted")


async def _ask_ollama(farm_context: dict, question: str) -> dict:
    output_instruction = """
You must generate an irrigation recommendation, not repeat the input data.

Return exactly this JSON structure:
{
  "action": "monitor",
  "explanation": "A complete explanation in the farmer's language.",
  "recommended_steps": [
    "A practical step in the farmer's language."
  ]
}

Choose action only from: irrigate_now, wait, monitor, insufficient_data.
Use only the supplied farm context. If reliable information is insufficient,
choose monitor or insufficient_data. Never invent measurements or irrigation quantities.
The example values above are structural examples, not recommendations.
"""

    user_payload = {
        "farmer_question": question,
        "farm_context": farm_context,
        "task": "Give a safe irrigation recommendation for this farmer.",
        "required_output": {
            "action": "monitor",
            "explanation": "string in the farmer's language",
            "recommended_steps": ["string in the farmer's language"]
        }
    }

    body = {
        "model": settings.ollama_model,
        "stream": False,
        "format": "json",
        "think": False,
        "options": {
            "temperature": 0.1,
            "num_predict": 700,
        },
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT + "\n\n" + output_instruction},
            {
                "role": "user",
                "content": json.dumps(user_payload, ensure_ascii=False, default=str),
            },
        ],
    }

    timeout = httpx.Timeout(settings.ollama_timeout_seconds)
    async with httpx.AsyncClient(timeout=timeout) as client:
        response = await client.post(
            settings.ollama_base_url.rstrip("/") + "/api/chat",
            json=body,
        )
        response.raise_for_status()
        payload = response.json()

    raw_content = payload["message"]["content"]
    return _parse_llm_response(raw_content, question)

async def generate_irrigation_advice(farm, db, question: str = "") -> dict:
    # Task 34 runs first: refused questions must not trigger database, retrieval,
    # weather, or model work.
    verdict = safety.evaluate_message(question) if (question or "").strip() else None
    refused = bool(verdict and verdict.refuse)

    if refused:
        labels = ["safety_rules"]
        generated = {
            "action": "insufficient_data",
            "explanation": _localized_safety_reply(question, verdict),
            "recommended_steps": [_localized_expert_footer(question, True, verdict.language)],
        }
        return {
            **generated,
            "action_label": _action_label(generated["action"]),
            "confidence": 0.0,
            "confidence_level": "low",
            "confidence_reasons": ["Question requires safety refusal or clarification"],
            "source_labels": labels,
            "knowledge_sources": [],
            "source_label": "safety_rules",
            "sensor_data": {"soil_moisture": None, "temperature": None, "humidity": None},
            "weather": None,
            "expert_review_required": True,
        }

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

    # Task 33: retrieve only passages from the locally indexed, licence-reviewed
    # agronomy documents. Safety refusals must never reach retrieval or an LLM.
    knowledge_context, knowledge_sources = ([], [])
    try:
        knowledge_context, knowledge_sources = retrieve_agronomy_context(question, limit=3)
    except Exception:
        logger.exception("Agronomy retrieval failed; continuing without retrieved sources")

    context["verified_agronomy_references"] = knowledge_context
    if knowledge_sources:
        labels.append("agronomy_rag")

    generated = None

    try:
        generated = await _ask_groq(context, question)
        labels.append("llm_groq")
    except Exception:
        # Task 32 explicitly uses the hosted Groq API. An unavailable provider
        # produces a localized deterministic fallback; never switch to Ollama.
        logger.exception("Groq irrigation advisor failed; using safe rules fallback")

    if generated is None:
        moisture = readings.get("soil_moisture")

        if not moisture:
            action = "insufficient_data"
        elif moisture["source"] == "simulated":
            action = "monitor"
        elif weather and (weather.get("precipitation_total_mm") or 0) >= 3:
            action = "wait"
        else:
            action = "monitor"

        generated = _localized_rules_fallback(question, action)
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
            _localized_safety_prefix(question, missing_data=True) + generated["explanation"]
        )[:2000]
    elif confidence < 0.60 and generated["action"] == "irrigate_now":
        generated["action"] = "monitor"
        generated["explanation"] = (
            _localized_safety_prefix(question, missing_data=False) + generated["explanation"]
        )[:2000]

    escalated = (
        confidence < 0.60
        or generated["action"] == "insufficient_data"
        or bool(verdict and verdict.escalate)
    )

    # Task 34: apply the same localized expert footer used by the chat assistant.
    # Refusal messages already contain their own purpose-built safety wording.
    if verdict and not refused:
        generated["explanation"] = (
            generated["explanation"] + "\n\n"
            + _localized_expert_footer(question, escalated, verdict.language)
        )[:2000]

    return {
        **generated,
        "action_label": _action_label(generated["action"]),
        "confidence": confidence,
        "confidence_level": level,
        "confidence_reasons": reasons,
        "source_labels": list(dict.fromkeys(labels)),
        "knowledge_sources": knowledge_sources,
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
