"""Add main assistant, time-series sensor and expert case tables.

Revision ID: f1a6c2d9e840
Revises: e91b8c7d2a40
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "f1a6c2d9e840"
down_revision: Union[str, Sequence[str], None] = "e91b8c7d2a40"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("region", sa.String(length=100), nullable=True))
    op.add_column("farms", sa.Column("crop", sa.String(length=100), nullable=True))
    op.add_column("farms", sa.Column("plant_age_days", sa.Integer(), nullable=True))

    op.create_table(
        "readings",
        sa.Column("id", sa.BigInteger().with_variant(sa.Integer(), "sqlite"), autoincrement=True, nullable=False),
        sa.Column("device_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("farm_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("metric", sa.Enum("soil_moisture", "temperature", "humidity", name="metric_enum"), nullable=False),
        sa.Column("value", sa.Float(), nullable=False),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("source", sa.Enum("real", "simulated", name="source_enum"), nullable=False),
        sa.ForeignKeyConstraint(["device_id"], ["devices.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["farm_id"], ["farms.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_readings_device_id", "readings", ["device_id"])
    op.create_index("ix_readings_recorded_at", "readings", ["recorded_at"])
    op.create_index("ix_readings_device_time", "readings", ["device_id", "recorded_at"])
    op.create_index("ix_readings_farm_metric_time", "readings", ["farm_id", "metric", "recorded_at"])

    op.create_table(
        "advice_log",
        sa.Column("id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("user_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("farm_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("question", sa.Text(), nullable=False),
        sa.Column("answer", sa.Text(), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("escalated", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("channel", sa.Enum("text", "voice", name="channel_enum"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["farm_id"], ["farms.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_advice_log_user_id", "advice_log", ["user_id"])
    op.create_index("ix_advice_log_created_at", "advice_log", ["created_at"])

    op.create_table(
        "expert_cases",
        sa.Column("id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("farm_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("advice_log_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("farmer_name", sa.String(length=255), nullable=False),
        sa.Column("crop", sa.String(length=100), nullable=False),
        sa.Column("region", sa.String(length=100), nullable=False),
        sa.Column("ai_diagnosis", sa.Text(), nullable=False),
        sa.Column("ai_confidence", sa.Float(), nullable=False),
        sa.Column("symptoms", sa.Text(), nullable=True),
        sa.Column("original_question", sa.Text(), nullable=True),
        sa.Column("ai_sources", sa.Text(), nullable=True),
        sa.Column("photo_url", sa.String(length=512), nullable=True),
        sa.Column("status", sa.Enum("pending", "confirmed", "rejected", name="case_status_enum"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["advice_log_id"], ["advice_log.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["farm_id"], ["farms.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_expert_cases_created_at", "expert_cases", ["created_at"])

    op.create_table(
        "expert_reviews",
        sa.Column("id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("case_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("expert_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("expert_name", sa.String(length=255), nullable=False),
        sa.Column("decision", sa.Enum("confirm", "reject", name="review_decision_enum"), nullable=False),
        sa.Column("comment", sa.Text(), nullable=True),
        sa.Column("corrected_diagnosis", sa.Text(), nullable=True),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["case_id"], ["expert_cases.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["expert_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("case_id"),
    )


def downgrade() -> None:
    op.drop_table("expert_reviews")
    op.drop_index("ix_expert_cases_created_at", table_name="expert_cases")
    op.drop_table("expert_cases")
    op.drop_index("ix_advice_log_created_at", table_name="advice_log")
    op.drop_index("ix_advice_log_user_id", table_name="advice_log")
    op.drop_table("advice_log")
    op.drop_index("ix_readings_farm_metric_time", table_name="readings")
    op.drop_index("ix_readings_device_time", table_name="readings")
    op.drop_index("ix_readings_recorded_at", table_name="readings")
    op.drop_index("ix_readings_device_id", table_name="readings")
    op.drop_table("readings")
    op.drop_column("farms", "plant_age_days")
    op.drop_column("farms", "crop")
    op.drop_column("users", "region")
