
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Annotated
from uuid import UUID

from fastapi import (
    APIRouter, Depends, File, Form, HTTPException,
    UploadFile, status,
)
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.permissions import require_approved_expert
from app.models.crop import Crop
from app.models.diagnosis import DiagnosisCase
from app.models.farm import Farm
from app.models.user import User
from app.schemas.diagnosis import DiagnosisPublic, DiagnosisReview

router = APIRouter(prefix="/diagnoses", tags=["Crop Diagnosis"])

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]
ApprovedExpert = Annotated[User, Depends(require_approved_expert)]

UPLOAD_DIR = Path(__file__).resolve().parents[2] / "uploads" / "diagnoses"
MAX_IMAGE_SIZE = 8 * 1024 * 1024


def image_extension(data: bytes) -> str | None:
    if data.startswith(b"\xff\xd8\xff"):
        return ".jpg"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return ".png"
    if data.startswith(b"RIFF") and data[8:12] == b"WEBP":
        return ".webp"
    return None


@router.post(
    "",
    response_model=DiagnosisPublic,
    status_code=status.HTTP_201_CREATED,
)
async def submit_diagnosis(
    db: DbSession,
    current_user: CurrentUser,
    farm_id: UUID = Form(...),
    symptoms: str = Form(..., min_length=5, max_length=5000),
    crop_id: UUID | None = Form(None),
    photo: UploadFile = File(...),
):
    if current_user.role != "farmer":
        raise HTTPException(403, "Only farmers can submit diagnosis cases.")

    farm = await db.scalar(
        select(Farm).where(
            Farm.id == farm_id,
            Farm.owner_id == current_user.id,
        )
    )
    if farm is None:
        raise HTTPException(404, "Farm not found.")

    if crop_id is not None:
        crop = await db.scalar(
            select(Crop).where(
                Crop.id == crop_id,
                Crop.farm_id == farm_id,
            )
        )
        if crop is None:
            raise HTTPException(404, "Crop not found in this farm.")

    contents = await photo.read(MAX_IMAGE_SIZE + 1)
    if len(contents) > MAX_IMAGE_SIZE:
        raise HTTPException(413, "Image must be 8 MB or smaller.")

    extension = image_extension(contents)
    if extension is None:
        raise HTTPException(400, "Upload a valid JPG, PNG, or WEBP image.")

    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid.uuid4().hex}{extension}"
    destination = UPLOAD_DIR / filename
    destination.write_bytes(contents)

    case = DiagnosisCase(
        farmer_id=current_user.id,
        farm_id=farm_id,
        crop_id=crop_id,
        photo_path=f"/uploads/diagnoses/{filename}",
        symptoms=symptoms.strip(),
        status="pending_review",
    )

    db.add(case)
    await db.commit()
    await db.refresh(case)
    return case


@router.get("/mine", response_model=list[DiagnosisPublic])
async def list_my_diagnoses(
    db: DbSession,
    current_user: CurrentUser,
):
    if current_user.role != "farmer":
        raise HTTPException(403, "Farmer account required.")

    result = await db.scalars(
        select(DiagnosisCase)
        .where(DiagnosisCase.farmer_id == current_user.id)
        .order_by(DiagnosisCase.created_at.desc())
    )
    return result.all()


@router.get("/queue", response_model=list[DiagnosisPublic])
async def expert_queue(
    db: DbSession,
    current_user: ApprovedExpert,
):
    result = await db.scalars(
        select(DiagnosisCase)
        .where(DiagnosisCase.status == "pending_review")
        .order_by(DiagnosisCase.created_at.asc())
    )
    return result.all()


@router.get("/{case_id}", response_model=DiagnosisPublic)
async def get_diagnosis(
    case_id: UUID,
    db: DbSession,
    current_user: CurrentUser,
):
    case = await db.get(DiagnosisCase, case_id)
    if case is None:
        raise HTTPException(404, "Diagnosis case not found.")

    is_owner = (
        current_user.role == "farmer"
        and case.farmer_id == current_user.id
    )
    is_approved_expert = (
        current_user.role == "expert"
        and current_user.expert_approval_status == "approved"
    )

    if not (is_owner or is_approved_expert):
        raise HTTPException(403, "You cannot access this case.")

    return case


@router.post("/{case_id}/review", response_model=DiagnosisPublic)
async def review_diagnosis(
    case_id: UUID,
    payload: DiagnosisReview,
    db: DbSession,
    current_user: ApprovedExpert,
):
    case = await db.get(DiagnosisCase, case_id)
    if case is None:
        raise HTTPException(404, "Diagnosis case not found.")

    if case.status != "pending_review":
        raise HTTPException(409, "This case has already been reviewed.")

    case.status = payload.status
    case.expert_id = current_user.id
    case.expert_diagnosis = payload.expert_diagnosis.strip()
    case.expert_advice = payload.expert_advice.strip()
    case.reviewed_at = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(case)
    return case
