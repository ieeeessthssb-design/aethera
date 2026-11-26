"""AI assistant router for text and voice queries."""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List
from app.core.dependencies import get_db, get_current_user
from app.models.farm import Farm
from app.models.user import User
from app.models.advice_log import AdviceLog
from app.models.expert_case import ExpertCase
import json
from datetime import datetime, timezone
from uuid import UUID
from app.schemas.assistant import (
    ChatRequest,
    ChatResponse,
    VoiceResponse,
    AdviceLogResponse,
    AdviceLogListResponse,
    IrrigationAdviceResponse,
    IrrigationAdviceRequest,
    VoiceTranscriptionResponse,
    VoiceAnswerRequest,
)
from app.services.assistant_service import get_assistant_service
from app.services.irrigation_advisor import generate_irrigation_advice
from app.services.stt_service import get_stt_service

router = APIRouter(tags=["assistant"])


async def _get_farm_or_404(farm_id: str | UUID, db: AsyncSession) -> Farm:
    try:
        farm_uuid = UUID(str(farm_id))
    except (ValueError, TypeError, AttributeError):
        raise HTTPException(status_code=404, detail="Farm not found") from None
    result = await db.execute(select(Farm).where(Farm.id == farm_uuid))
    farm = result.scalar_one_or_none()
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found")
    return farm


async def _create_irrigation_advice(
    farm_id: UUID, question: str, current_user: User, db: AsyncSession, channel: str
) -> IrrigationAdviceResponse:
    farm = await _get_farm_or_404(farm_id, db)
    if farm.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not own this farm")

    result = await generate_irrigation_advice(farm=farm, db=db, question=question)
    answer_text = (
        f"{result['action_label']}: {result['explanation']} "
        + " ".join(result["recommended_steps"])
    )
    log_entry = AdviceLog(
        user_id=current_user.id,
        farm_id=farm.id,
        question=question,
        answer=answer_text,
        confidence=result["confidence"],
        escalated=result["expert_review_required"],
        channel=channel,
    )
    db.add(log_entry)
    await db.flush()

    expert_case_id = None
    if result["expert_review_required"]:
        case = ExpertCase(
            farm_id=farm.id,
            advice_log_id=log_entry.id,
            farmer_name=current_user.name,
            crop=farm.crop,
            region=farm.region,
            ai_diagnosis=answer_text[:2000],
            ai_confidence=result["confidence"],
            original_question=question,
            ai_sources=json.dumps(result["source_labels"]),
            status="pending",
        )
        db.add(case)
        await db.flush()
        expert_case_id = case.id

    await db.commit()
    result["farm_id"] = farm.id
    result["expert_case_id"] = expert_case_id
    result["generated_at"] = datetime.now(timezone.utc)
    return IrrigationAdviceResponse(**result)


@router.post("/assistant/chat", response_model=ChatResponse)
async def chat(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Send a text message to the AI assistant."""
    farm = await _get_farm_or_404(request.farm_id, db)
    if farm.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not own this farm")
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
    if farm.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not own this farm")
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




@router.post(
    "/farms/{farm_id}/irrigation/advice",
    response_model=IrrigationAdviceResponse,
    tags=["irrigation"],
)
async def irrigation_advice(
    farm_id: UUID,
    request: IrrigationAdviceRequest | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generate farm-specific irrigation advice from profile, latest sensors and weather."""
    question = (request.message if request and request.message else "Should I irrigate this farm now?")
    return await _create_irrigation_advice(farm_id, question, current_user, db, "text")


@router.post("/assistant/voice/transcribe", response_model=VoiceTranscriptionResponse)
async def voice_transcribe(
    farm_id: str = Form(...),
    audio: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Transcribe audio and return it for farmer confirmation before answering."""
    farm = await _get_farm_or_404(farm_id, db)
    stt = get_stt_service()
    transcript = await stt.transcribe(await audio.read(), content_type=audio.content_type)
    return VoiceTranscriptionResponse(transcript=transcript)


@router.post(
    "/assistant/voice/answer",
    response_model=IrrigationAdviceResponse,
    tags=["irrigation"],
)
async def voice_answer(
    request: VoiceAnswerRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Answer only the transcript the farmer explicitly confirmed or edited."""
    if not request.confirmed:
        raise HTTPException(status_code=400, detail="Confirm the transcript before requesting advice")
    if not request.transcript.strip():
        raise HTTPException(status_code=400, detail="The confirmed transcript cannot be empty")
    return await _create_irrigation_advice(
        request.farm_id, request.transcript, current_user, db, "voice"
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
