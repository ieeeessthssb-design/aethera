"""add image path to social posts"""

from alembic import op
import sqlalchemy as sa

revision = "577406604f06"
down_revision = "a71f3c9d2e10"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "social_posts",
        sa.Column("image_path", sa.String(length=500), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("social_posts", "image_path")