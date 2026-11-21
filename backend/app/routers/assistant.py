"""AI assistant router for text and voice queries."""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List
from app.core.dependencies import get_db, get_current_user
from app.models.farm import Farm
from app.models.user import User
from app.models.advice_log import AdviceLog
from app.schemas.assistant import (
    ChatRequest,
    ChatResponse,
    VoiceResponse,
    AdviceLogResponse,
    AdviceLogListResponse,
)
from app.services.assistant_service import get_assistant_service
from app.services.stt_service import get_stt_service

router = APIRouter(tags=["assistant"])


async def _get_farm_or_404(farm_id: str, db: AsyncSession) -> Farm:
    result = await db.execute(select(Farm).where(Farm.id == farm_id))
    farm = result.scalar_one_or_none()
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found")
    return farm


@router.post("/assistant/chat", response_model=ChatResponse)
async def chat(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Send a text message to the AI assistant."""
    farm = await _get_farm_or_404(request.farm_id, db)
    assistant = get_assistant_service()
    result = await assistant.answer(
        message=request.message,
        farm=farm,
        user=current_user,
        db=db,
    )
    # Persist to advice log
    log_entry = AdviceLog(
        user_id=current_user.id,
        farm_id=request.farm_id,
        question=request.message,
        answer=result.answer,
        confidence=result.confidence,
        escalated=result.escalated,
        channel="text",
    )
    db.add(log_entry)
    await db.commit()
    return result


@router.post("/assistant/voice", response_model=VoiceResponse)
async def voice_chat(
    farm_id: str = Form(...),
    audio: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Send a voice message to the AI assistant."""
    farm = await _get_farm_or_404(farm_id, db)
    # Transcribe audio
    stt = get_stt_service()
    audio_bytes = await audio.read()
    transcript = await stt.transcribe(audio_bytes, content_type=audio.content_type)

    # Get AI response
    assistant = get_assistant_service()
    result = await assistant.answer(
        message=transcript,
        farm=farm,
        user=current_user,
        db=db,
    )
    # Persist to advice log
    log_entry = AdviceLog(
        user_id=current_user.id,
        farm_id=farm_id,
        question=transcript,
        answer=result.answer,
        confidence=result.confidence,
        escalated=result.escalated,
        channel="voice",
    )
    db.add(log_entry)
    await db.commit()

    return VoiceResponse(
        transcript=transcript,
        answer=result.answer,
        confidence=result.confidence,
        escalated=result.escalated,
        case_id=result.case_id,
    )


@router.get("/advice/log", response_model=AdviceLogListResponse, tags=["advice"])
async def get_advice_log(
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get the advice history for the current user."""
    count_result = await db.execute(
        select(func.count()).select_from(AdviceLog).where(AdviceLog.user_id == current_user.id)
    )
    total = count_result.scalar_one()

    result = await db.execute(
        select(AdviceLog)
        .where(AdviceLog.user_id == current_user.id)
        .order_by(AdviceLog.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    items = result.scalars().all()
    return AdviceLogListResponse(
        items=[AdviceLogResponse.model_validate(i) for i in items],
        total=total,
    )
