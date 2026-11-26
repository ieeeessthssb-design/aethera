
"""Add optional image attachment path to social messages."""

from alembic import op
import sqlalchemy as sa


revision = "a71f3c9d2e10"
down_revision = "5cde51da433c"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "social_messages",
        sa.Column("image_path", sa.String(length=500), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("social_messages", "image_path")
