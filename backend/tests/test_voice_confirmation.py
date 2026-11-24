from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.routers import assistant
from app.schemas.assistant import VoiceAnswerRequest


@pytest.mark.asyncio
async def test_voice_answer_requires_transcript_confirmation(monkeypatch):
    async def should_not_run(*args, **kwargs):
        pytest.fail("unconfirmed transcript reached the irrigation advisor")

    monkeypatch.setattr(assistant, "_create_irrigation_advice", should_not_run)

    with pytest.raises(HTTPException) as error:
        await assistant.voice_answer(
            VoiceAnswerRequest(farm_id="farm-1", transcript="Should I water?"),
            current_user=SimpleNamespace(id="user-1"),
            db=object(),
        )
    assert error.value.status_code == 400


@pytest.mark.asyncio
async def test_confirmed_voice_transcript_uses_shared_irrigation_pipeline(monkeypatch):
    seen = {}

    async def create_advice(farm_id, question, current_user, db, channel):
        seen.update(farm_id=farm_id, question=question, channel=channel)
        return {"ok": True}

    monkeypatch.setattr(assistant, "_create_irrigation_advice", create_advice)
    result = await assistant.voice_answer(
        VoiceAnswerRequest(farm_id="farm-1", transcript="Quand arroser mes tomates ?", confirmed=True),
        current_user=SimpleNamespace(id="user-1"),
        db=object(),
    )
    assert result == {"ok": True}
    assert seen == {
        "farm_id": "farm-1",
        "question": "Quand arroser mes tomates ?",
        "channel": "voice",
    }


@pytest.mark.asyncio
async def test_voice_transcribe_returns_transcript_for_confirmation(monkeypatch):
    async def get_farm(farm_id, db):
        return SimpleNamespace(owner_id="user-1")

    class STT:
        async def transcribe(self, audio, content_type=None):
            assert audio == b"audio-bytes"
            assert content_type == "audio/wav"
            return "When should I water my tomatoes?"

    class Audio:
        content_type = "audio/wav"

        async def read(self):
            return b"audio-bytes"

    monkeypatch.setattr(assistant, "_get_farm_or_404", get_farm)
    monkeypatch.setattr(assistant, "get_stt_service", lambda: STT())
    result = await assistant.voice_transcribe(
        farm_id="farm-1",
        audio=Audio(),
        current_user=SimpleNamespace(id="user-1"),
        db=object(),
    )
    assert result.transcript == "When should I water my tomatoes?"
    assert result.requires_confirmation is True
