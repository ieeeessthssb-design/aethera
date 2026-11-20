"""Sensor Reading ORM model — high-volume time-series."""
from datetime import datetime, timezone
from sqlalchemy import (
    BigInteger, Integer, String, Float, DateTime, Enum as SAEnum, ForeignKey, Index
)
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Reading(Base):
    __tablename__ = "readings"
    __table_args__ = (
        # Composite index for time-series queries
        Index("ix_readings_device_time", "device_id", "recorded_at"),
        Index("ix_readings_farm_metric_time", "farm_id", "metric", "recorded_at"),
    )

    id: Mapped[int] = mapped_column(
        BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True
    )
    device_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("devices.id", ondelete="SET NULL"), nullable=True, index=True
    )
    farm_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("farms.id", ondelete="CASCADE"), nullable=False
    )
    metric: Mapped[str] = mapped_column(
        SAEnum("soil_moisture", "temperature", "humidity", name="metric_enum"),
        nullable=False,
    )
    value: Mapped[float] = mapped_column(Float, nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, index=True
    )
    source: Mapped[str] = mapped_column(
        SAEnum("real", "simulated", name="source_enum"),
        nullable=False,
        default="simulated",
    )
