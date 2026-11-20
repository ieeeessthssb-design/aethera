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

from app.core.config import settings


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
        "answer_ar": "أفضل وقت للسقي هو المساء بعد الغروب أو الصباح الباكر لتجنب التبخر. مع نظام التقطير، اسقِ يومياً لمدة ساعة واحدة في موسم الصيف.",
        "answer_fr": "Le meilleur moment pour irriguer est le soir ou tôt le matin. Avec un système de goutte-à-goutte, une heure par jour en été.",
        "answer_en": "Best time to irrigate is evening or early morning to reduce evaporation. With drip irrigation, 1 hour/day in summer.",
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
        "answer_ar": "استخدم سماداً متوازناً NPK 20-20-20 في مرحلة النمو. قلل الآزوت وزد البوتاسيوم عند الإثمار. لا تبالغ في التسميد لتجنب حرق الجذور.",
        "answer_fr": "Utilisez un engrais équilibré NPK 20-20-20 en phase de croissance.",
        "answer_en": "Use balanced NPK 20-20-20 fertilizer during growth phase. Reduce nitrogen and increase potassium at fruiting stage.",
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
    # Set by LLM-backed providers (None for the rule-based stub)
    confidence_level: Optional[str] = None   # high | medium | low
    source_label: Optional[str] = None       # sensor | simulated_sensor | weather_forecast | ...
    irrigation: Optional[dict] = None        # structured irrigation advice


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

    async def irrigation_advice(self, farm, user, db, message=None, language=None) -> AssistantResult:
        """Irrigation advice for a farm. Default: reuse the text answer (rule-based)."""
        return await self.answer(message=message or "امتى خير وقت نسقي؟", farm=farm, user=user, db=db)


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
        should_escalate = confidence < 0.6 or is_high_risk
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
            answer = answer + "\n\n⚠️ تم إرسال حالتك لمراجعة خبير زراعي متخصص."

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


def get_assistant_service() -> AssistantInterface:
    """Factory function: returns the appropriate assistant implementation."""
    provider = settings.assistant_provider.lower()
    if provider in ("openai", "groq"):
        from app.services.llm_assistant_service import LLMAssistantService  # lazy: avoids import cycle
        return LLMAssistantService()  # falls back to the stub if no API key is set
    return StubAssistantService()
