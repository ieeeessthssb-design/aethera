"""AI Assistant service interface and stub implementation.

The interface is designed to be swapped with an LLM+RAG provider by
changing the ASSISTANT_PROVIDER env var.

Stub implementation uses keyword matching to simulate a rule-based assistant
for demo/hackathon purposes.
"""
from abc import ABC, abstractmethod
from typing import Optional, List
from dataclasses import dataclass
import json
import uuid
import logging

from app.core.config import settings
from app.services import safety
import httpx

logger = logging.getLogger(__name__)


# High-risk topics always escalate to an expert regardless of confidence
HIGH_RISK_TOPICS = [
    "pesticide", "herbicide", "fungicide", "insecticide",
    "مبيد", "آفات", "مرض", "disease", "poison", "toxic",
    "wilting", "تذبل", "root rot", "جذر",
    "emergency", "urgent", "طارئ",
]

# Knowledge base for the stub assistant (Tunisian farming context)
KNOWLEDGE_BASE = [
    {
        "keywords": ["أصفر", "صفراء", "يتصفر", "تصفر", "مصفر", "yellow", "jaune", "chlorosis", "كلوروز"],
        "answer_ar": "الاصفرار قد يكون بسبب نقص الحديد أو المغنيسيوم أو الآزوت. أنصح بفحص التربة وإجراء تحليل للعناصر الغذائية. استخدم سماداً متوازناً.",
        "answer_fr": "Le jaunissement peut être dû à une carence en fer, magnésium ou azote. Je recommande une analyse de sol.",
        "answer_en": "Yellowing may indicate iron, magnesium, or nitrogen deficiency. Soil analysis recommended.",
        "confidence": 0.72,
        "sources": ["INAT Tunisia agronomy guide 2023"],
        "high_risk": False,
    },
    {
        "keywords": ["سقي", "السقي", "نسقي", "ري", "irrigation", "water", "arrosage", "رطوبة"],
        "answer_ar": "أفضل وقت للري هو المساء أو الصباح الباكر لتقليل التبخر. عدّل مدة الري حسب رطوبة التربة والمحصول والطقس المحلي.",
        "answer_fr": "Le meilleur moment pour irriguer est le soir ou tôt le matin. Ajustez la durée selon l'humidité du sol, la culture et la météo locale.",
        "answer_en": "Best time to irrigate is evening or early morning to reduce evaporation. Adjust the duration to soil moisture, the crop and local weather.",
        "confidence": 0.88,
        "sources": ["INAT Tunisia irrigation guide", "FAO crop management"],
        "high_risk": False,
    },
    {
        "keywords": ["طماطم", "tomate", "tomato", "بندورة"],
        "answer_ar": "الطماطم تحتاج إلى تسميد منتظم بالنيتروجين في مرحلة النمو والبوتاسيوم في مرحلة الإثمار. تأكد من التهوية الجيدة لمنع الأمراض الفطرية.",
        "answer_fr": "Les tomates nécessitent un engrais riche en azote en phase de croissance et en potassium en phase de fructification.",
        "answer_en": "Tomatoes need nitrogen-rich fertilizer during growth and potassium during fruiting. Ensure good ventilation to prevent fungal diseases.",
        "confidence": 0.80,
        "sources": ["INAT Tunisia vegetable guide 2022"],
        "high_risk": False,
    },
    {
        "keywords": ["زيتون", "olive", "olivier"],
        "answer_ar": "شجرة الزيتون مقاومة للجفاف. الري مهم في مرحلة تكوين الثمار (يونيو-أغسطس). التقليم السنوي ضروري للإنتاجية.",
        "answer_fr": "L'olivier est résistant à la sécheresse. L'irrigation est importante lors de la formation des fruits.",
        "answer_en": "Olive trees are drought-resistant. Irrigation is important during fruit formation (June-August). Annual pruning is essential.",
        "confidence": 0.85,
        "sources": ["Institut de l'Olivier Tunisie 2023"],
        "high_risk": False,
    },
    {
        "keywords": ["سماد", "تسميد", "fertilizer", "engrais", "NPK"],
        "answer_ar": "استخدم سمادًا متوازنًا في مرحلة النمو، وعدّل التركيبة حسب المحصول وحالة التربة. لا تبالغ في التسميد لتجنب حرق الجذور. استشر خبيرًا زراعيًا قبل تحديد الجرعة.",
        "answer_fr": "Utilisez un engrais équilibré en phase de croissance, adapté à la culture et au sol. Évitez l'excès pour ne pas brûler les racines. Demandez l'avis d'un expert avant de fixer une dose.",
        "answer_en": "Use a balanced fertilizer during the growth phase, adapted to the crop and soil. Avoid over-fertilizing to prevent root burn. Check with an expert before choosing a dose.",
        "confidence": 0.78,
        "sources": ["FAO fertilization guidelines"],
        "high_risk": False,
    },
]

DEFAULT_ANSWER_AR = (
    "شكراً على سؤالك. لم أجد معلومات كافية للإجابة بدقة. "
    "أنصح باستشارة مهندس زراعي متخصص أو الاتصال بالإرشاد الزراعي."
)


def _kw_match(kw: str, text: str) -> bool:
    """Short keywords (<=3 chars) must match a whole word, longer ones a substring."""
    if len(kw) <= 3:
        return kw in text.replace("،", " ").replace("?", " ").replace("؟", " ").split()
    return kw in text


@dataclass
class AssistantResult:
    answer: str
    confidence: float
    sources: List[str]
    escalated: bool
    case_id: Optional[str] = None


class AssistantInterface(ABC):
    """Abstract interface for the AI assistant."""

    @abstractmethod
    async def answer(
        self,
        message: str,
        farm,
        user,
        db,
    ) -> AssistantResult:
        ...


class StubAssistantService(AssistantInterface):
    """Rule-based stub assistant for demo/development.

    Escalation rule:
    - Escalate when confidence < 0.6, OR
    - Escalate when the message contains a high-risk topic keyword.
    """

    async def answer(
        self,
        message: str,
        farm,
        user,
        db,
    ) -> AssistantResult:
        message_lower = message.lower()

        # Task 34: safety rules run FIRST. A refused question (pesticide dose, poisoning,
        # unclear text, ...) never reaches the knowledge base, and always creates an expert case.
        verdict = safety.evaluate_message(message)
        if verdict.refuse:
            case_id = await self._create_expert_case(
                message=message, answer=verdict.reply, confidence=0.0, sources=[],
                farm=farm, user=user, db=db,
            )
            return AssistantResult(
                answer=verdict.reply, confidence=0.0, sources=[], escalated=True, case_id=case_id,
            )

        # Check for high-risk topics first
        is_high_risk = any(kw.lower() in message_lower for kw in HIGH_RISK_TOPICS)

        # Find best matching knowledge base entry
        best_match = None
        for entry in KNOWLEDGE_BASE:
            if any(_kw_match(kw.lower(), message_lower) for kw in entry["keywords"]):
                best_match = entry
                break

        if best_match:
            # Detect language from message (simple heuristic: check Arabic chars)
            has_arabic = any("\u0600" <= c <= "\u06FF" for c in message)
            if has_arabic:
                answer = best_match["answer_ar"]
            elif any(c in message_lower for c in ["bonjour", "comment", "le", "la", "les", "je"]):
                answer = best_match["answer_fr"]
            else:
                answer = best_match["answer_en"]
            confidence = best_match["confidence"]
            sources = best_match["sources"]
            is_high_risk = is_high_risk or best_match["high_risk"]
        else:
            answer = DEFAULT_ANSWER_AR
            confidence = 0.35  # Low confidence — will trigger escalation
            sources = []

        # Apply escalation rule
        should_escalate = confidence < 0.6 or is_high_risk or verdict.escalate
        case_id = None

        if should_escalate:
            case_id = await self._create_expert_case(
                message=message,
                answer=answer,
                confidence=confidence,
                sources=sources,
                farm=farm,
                user=user,
                db=db,
            )

        # Mandatory expert wording on every answer, in the language of the question.
        answer = safety.finalize_answer(answer, should_escalate, verdict.language)

        return AssistantResult(
            answer=answer,
            confidence=confidence,
            sources=sources,
            escalated=should_escalate,
            case_id=case_id,
        )

    async def _create_expert_case(
        self,
        message: str,
        answer: str,
        confidence: float,
        sources: List[str],
        farm,
        user,
        db,
    ) -> str:
        """Create an ExpertCase record for escalated questions."""
        from app.models.expert_case import ExpertCase

        case = ExpertCase(
            farm_id=farm.id if farm else None,
            farmer_name=user.name,
            crop=farm.crop if farm else "unknown",
            region=farm.region if farm else (user.region or "Tunisia"),
            ai_diagnosis=answer[:500],
            ai_confidence=confidence,
            original_question=message,
            ai_sources=json.dumps(sources),
            status="pending",
        )
        db.add(case)
        await db.commit()
        await db.refresh(case)
        return case.id


class GroqAssistantService(AssistantInterface):
    """OpenAI-compatible Groq chat provider, guarded by the same offline safety rules."""

    async def answer(self, message: str, farm, user, db) -> AssistantResult:
        # Refusals happen before any request leaves the backend.
        verdict = safety.evaluate_message(message)
        fallback = StubAssistantService()
        if verdict.refuse:
            case_id = await fallback._create_expert_case(
                message, verdict.reply or "", 0.0, [], farm, user, db
            )
            return AssistantResult(
                answer=verdict.reply or "", confidence=0.0, sources=[],
                escalated=True, case_id=case_id,
            )

        context = [
            f"Farm: {farm.name}" if farm else "Farm: not provided",
            f"Location: {farm.location}" if farm else "",
            f"Crop: {farm.crop}" if farm and farm.crop else "",
            f"Soil: {farm.soil_type}" if farm and farm.soil_type else "",
        ]
        system_prompt = (
            "You are AETHERA, an agricultural assistant for farmers in Tunisia. "
            "Answer in the same language as the farmer (Arabic, French, or English). "
            "Be practical, concise, and clear about uncertainty. Never invent farm measurements. "
            "Do not provide pesticide or fertilizer dosages, mixing instructions, or spray schedules. "
            "For disease or pest diagnosis, advise safe observation and recommend expert review. "
            "Farm context:\n" + "\n".join(item for item in context if item)
        )
        try:
            async with httpx.AsyncClient(timeout=35) as client:
                response = await client.post(
                    f"{settings.groq_base_url.rstrip('/')}/chat/completions",
                    headers={"Authorization": f"Bearer {settings.groq_api_key}"},
                    json={
                        "model": settings.groq_model,
                        "temperature": 0.2,
                        "messages": [
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": message},
                        ],
                    },
                )
                response.raise_for_status()
                answer = response.json()["choices"][0]["message"]["content"].strip()
                if not answer:
                    raise ValueError("The assistant returned an empty response.")
        except (httpx.HTTPError, KeyError, IndexError, TypeError, ValueError) as error:
            # Keep the application usable when the optional provider is down.
            logger.warning(
                "Groq assistant request failed (%s); using local stub response.",
                type(error).__name__,
            )
            return await fallback.answer(message, farm, user, db)

        should_escalate = verdict.escalate
        sources = ["Groq AI"]
        case_id = None
        confidence = 0.65
        if should_escalate:
            case_id = await fallback._create_expert_case(
                message, answer, confidence, sources, farm, user, db
            )
        answer = safety.finalize_answer(answer, should_escalate, verdict.language)
        return AssistantResult(
            answer=answer, confidence=confidence, sources=sources,
            escalated=should_escalate, case_id=case_id,
        )


def get_assistant_service() -> AssistantInterface:
    """Factory function: returns the appropriate assistant implementation."""
    provider = settings.assistant_provider.lower()
    if provider == "stub":
        return StubAssistantService()
    if provider == "groq" and settings.groq_api_key.strip():
        return GroqAssistantService()
    return StubAssistantService()  # Fallback
