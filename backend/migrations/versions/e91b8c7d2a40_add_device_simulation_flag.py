"""add simulated device type flag

Revision ID: e91b8c7d2a40
Revises: c4a9e72b1f30
Create Date: 2026-11-25
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "e91b8c7d2a40"
down_revision: Union[str, Sequence[str], None] = "c4a9e72b1f30"
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.add_column("devices", sa.Column("is_simulated", sa.Boolean(), nullable=False, server_default=sa.false()))

def downgrade() -> None:
    op.drop_column("devices", "is_simulated")
