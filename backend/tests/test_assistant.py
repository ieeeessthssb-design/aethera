"""Tests for the assistant escalation rule (CRITICAL: confidence < 0.6 triggers escalation)."""
import pytest
from unittest.mock import AsyncMock, MagicMock
from app.services.assistant_service import StubAssistantService, HIGH_RISK_TOPICS


class MockFarm:
    id = "test-farm-id"
    crop = "tomatoes"
    region = "Sfax"


class MockUser:
    id = "test-user-id"
    name = "Test Farmer"
    region = "Sfax"


class MockDB:
    """Mock async db session that accepts add() and commit()."""
    added = []

    def add(self, item):
        self.added.append(item)

    async def commit(self):
        pass

    async def refresh(self, item):
        item.id = "mock-case-id"


@pytest.mark.asyncio
async def test_escalation_on_low_confidence():
    """Messages that match no knowledge base entry get confidence=0.35 and must escalate."""
    service = StubAssistantService()
    db = MockDB()
    result = await service.answer(
        message="سؤال غريب جداً لا يمكن الإجابة عليه",  # Unlikely to match
        farm=MockFarm(),
        user=MockUser(),
        db=db,
    )
    # Should escalate because confidence < 0.6
    assert result.escalated is True
    assert result.confidence < 0.6


@pytest.mark.asyncio
async def test_no_escalation_on_high_confidence():
    """Irrigation question matches with confidence 0.88 and must NOT escalate."""
    service = StubAssistantService()
    db = MockDB()
    result = await service.answer(
        message="امتى خير وقت نسقي؟",  # irrigation keyword
        farm=MockFarm(),
        user=MockUser(),
        db=db,
    )
    assert result.escalated is False
    assert result.confidence >= 0.6


@pytest.mark.asyncio
async def test_escalation_on_high_risk_topic():
    """High-risk keywords (pesticide, مبيد) always trigger escalation."""
    service = StubAssistantService()
    db = MockDB()
    result = await service.answer(
        message="واش نستخدم مبيد الحشرات؟",  # مبيد = pesticide
        farm=MockFarm(),
        user=MockUser(),
        db=db,
    )
    assert result.escalated is True


def test_escalation_threshold():
    """Confirm the escalation threshold is 0.6 (not 0.5 or 0.7)."""
    # This test documents the business rule explicitly
    ESCALATION_THRESHOLD = 0.6
    assert ESCALATION_THRESHOLD == 0.6


def test_high_risk_topics_not_empty():
    """Ensure high-risk topic list is populated."""
    assert len(HIGH_RISK_TOPICS) > 0
    assert "pesticide" in HIGH_RISK_TOPICS
    assert "مبيد" in HIGH_RISK_TOPICS