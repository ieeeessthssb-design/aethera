"""Tests for the task-34 safety rules (pesticide dosage, emergencies, unclear, expert wording)."""
import pytest

from app.services import safety
from app.services.assistant_service import StubAssistantService
from app.services.safety import Category, evaluate_message


class MockFarm:
    id = "test-farm-id"
    crop = "tomatoes"
    region = "Sfax"


class MockUser:
    id = "test-user-id"
    name = "Test Farmer"
    region = "Sfax"


class MockDB:
    def __init__(self):
        self.added = []

    def add(self, item):
        self.added.append(item)

    async def commit(self):
        pass

    async def refresh(self, item):
        item.id = "mock-case-id"


@pytest.mark.parametrize("text,expected", [
    ("How many ml of glyphosate per liter for weeds?", Category.PESTICIDE_DOSAGE),
    ("What dose of fungicide should I mix for tomato blight?", Category.PESTICIDE_DOSAGE),
    ("Combien de fongicide par hectare ?", Category.PESTICIDE_DOSAGE),
    ("قداش نحط من مبيد في اللتر", Category.PESTICIDE_DOSAGE),
    ("كم رش نعمل في الاسبوع", Category.PESTICIDE_DOSAGE),
    ("Which pesticide is best for my tomatoes?", Category.PESTICIDE_TOPIC),
    ("شنوة افضل مبيد للطماطم", Category.PESTICIDE_TOPIC),
    ("My child drank insecticide", Category.EMERGENCY),
    ("ولدي شرب مبيد", Category.EMERGENCY),
    ("How much NPK per hectare for tomato?", Category.FERTILIZER_DOSAGE),
    ("My tomato leaves have spots and blight", Category.DISEASE),
    ("اوراق الطماطم فيها بقع صفراء", Category.DISEASE),
    ("???", Category.UNCLEAR),
    ("", Category.UNCLEAR),
])
def test_dangerous_or_unclear_messages_are_classified(text, expected):
    assert evaluate_message(text).category is expected


@pytest.mark.parametrize("text", [
    "When should I irrigate my olive trees?",
    "How often should I water tomatoes?",
    "How much water does a tomato need?",
    "Quand irriguer mes oliviers ?",
    "Combien de fois arroser mes tomates ?",
    "كم مرة نسقي الطماطم",
    "المرشد الزراعي قال كم مرة نسقي",   # مرشد (guide) must not match رش (spray)
    "الشجرة شربت الماء في الموسم",       # موسم (season) must not match سم (poison)
])
def test_normal_irrigation_questions_are_not_blocked(text):
    verdict = evaluate_message(text)
    assert verdict.category is Category.OK
    assert not verdict.refuse and not verdict.escalate


def test_refusals_never_contain_a_dose_and_always_say_check_with_an_expert():
    for text in ["How many ml of glyphosate per liter?", "قداش نحط من مبيد", "Combien de fongicide par litre ?"]:
        verdict = evaluate_message(text)
        assert verdict.refuse and verdict.escalate and verdict.reply
        assert not any(ch.isdigit() for ch in verdict.reply)
        assert any(w in verdict.reply.lower() for w in ("expert", "خبير"))


def test_emergency_reply_gives_the_emergency_number_not_agronomy_advice():
    verdict = evaluate_message("My child drank insecticide")
    assert verdict.category is Category.EMERGENCY and safety.EMERGENCY_NUMBER in verdict.reply


def test_language_is_detected():
    assert evaluate_message("ولدي شرب مبيد").language == "ar"
    assert evaluate_message("Combien de fongicide par hectare ?").language == "fr"
    assert evaluate_message("How many ml of glyphosate per liter?").language == "en"


@pytest.mark.asyncio
async def test_stub_assistant_refuses_pesticide_dosage_and_creates_expert_case():
    db = MockDB()
    result = await StubAssistantService().answer(
        "How many ml of fungicide should I spray per liter?", MockFarm(), MockUser(), db)
    assert result.escalated is True and result.case_id == "mock-case-id"
    assert result.confidence == 0.0
    assert "can't give pesticide doses" in result.answer
    assert len(db.added) == 1


@pytest.mark.asyncio
async def test_stub_assistant_adds_expert_wording_to_every_answer():
    db = MockDB()
    ok = await StubAssistantService().answer("What is the best time for irrigation?", MockFarm(), MockUser(), db)
    assert ok.escalated is False and "Check with an expert" in ok.answer
    unknown = await StubAssistantService().answer("Tell me about the history of the moon landing", MockFarm(), MockUser(), db)
    assert unknown.escalated is True and "Check with an expert before acting" in unknown.answer
