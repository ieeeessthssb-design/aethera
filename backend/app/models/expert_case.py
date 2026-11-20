"""Expert Case and Expert Review ORM models."""
import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    String, Float, Boolean, DateTime, Enum as SAEnum, ForeignKey, Text, event
)
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class ExpertCase(Base):
    __tablename__ = "expert_cases"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    farm_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("farms.id", ondelete="SET NULL"), nullable=True
    )
    advice_log_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("advice_log.id", ondelete="SET NULL"), nullable=True
    )
    # Denormalized for display without joins
    farmer_name: Mapped[str] = mapped_column(String(255), nullable=False)
    crop: Mapped[str] = mapped_column(String(100), nullable=False)
    region: Mapped[str] = mapped_column(String(100), nullable=False)
    ai_diagnosis: Mapped[str] = mapped_column(Text, nullable=False)
    ai_confidence: Mapped[float] = mapped_column(Float, nullable=False)
    symptoms: Mapped[str] = mapped_column(Text, nullable=True)
    original_question: Mapped[str] = mapped_column(Text, nullable=True)
    ai_sources: Mapped[str] = mapped_column(Text, nullable=True)  # JSON array stored as string
    photo_url: Mapped[str] = mapped_column(String(512), nullable=True)
    status: Mapped[str] = mapped_column(
        SAEnum("pending", "confirmed", "rejected", name="case_status_enum"),
        nullable=False,
        default="pending",
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True
    )


class ExpertReview(Base):
    __tablename__ = "expert_reviews"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    case_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("expert_cases.id", ondelete="CASCADE"), nullable=False, unique=True
    )
    expert_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    expert_name: Mapped[str] = mapped_column(String(255), nullable=False)
    decision: Mapped[str] = mapped_column(
        SAEnum("confirm", "reject", name="review_decision_enum"), nullable=False
    )
    comment: Mapped[str] = mapped_column(Text, nullable=True)
    corrected_diagnosis: Mapped[str] = mapped_column(Text, nullable=True)
    reviewed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
