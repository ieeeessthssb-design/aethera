"""add farm coordinates, device heartbeat and farm alerts

Revision ID: c4a9e72b1f30
Revises: 577406604f06
Create Date: 2026-11-25
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "c4a9e72b1f30"
down_revision: Union[str, Sequence[str], None] = "577406604f06"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("farms", sa.Column("latitude", sa.Float(), nullable=True))
    op.add_column("farms", sa.Column("longitude", sa.Float(), nullable=True))
    op.create_check_constraint(
        "farm_coordinates_valid",
        "farms",
        "(latitude IS NULL AND longitude IS NULL) OR "
        "(latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)",
    )
    op.add_column("devices", sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True))
    op.create_index("ix_devices_last_seen_at", "devices", ["last_seen_at"], unique=False)
    op.create_table(
        "farm_alerts",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("farm_id", sa.UUID(), nullable=False),
        sa.Column("device_id", sa.UUID(), nullable=True),
        sa.Column("alert_type", sa.String(length=40), nullable=False),
        sa.Column("severity", sa.String(length=20), nullable=False),
        sa.Column("title", sa.String(length=160), nullable=False),
        sa.Column("detail", sa.String(length=500), nullable=False),
        sa.Column("source", sa.String(length=30), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("acknowledged_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["farm_id"], ["farms.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["device_id"], ["devices.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_farm_alerts_farm_id", "farm_alerts", ["farm_id"], unique=False)
    op.create_index("ix_farm_alerts_device_id", "farm_alerts", ["device_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_farm_alerts_device_id", table_name="farm_alerts")
    op.drop_index("ix_farm_alerts_farm_id", table_name="farm_alerts")
    op.drop_table("farm_alerts")
    op.drop_index("ix_devices_last_seen_at", table_name="devices")
    op.drop_column("devices", "last_seen_at")
    op.drop_constraint("farm_coordinates_valid", "farms", type_="check")
    op.drop_column("farms", "longitude")
    op.drop_column("farms", "latitude")
