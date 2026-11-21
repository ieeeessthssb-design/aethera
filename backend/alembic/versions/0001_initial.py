"""initial schema: users, farms, devices, readings, advice_log, expert_cases, expert_reviews"""
revision = "0001"
down_revision = None
from alembic import op
from app.core.database import Base
import app.models  # noqa


def upgrade():
    Base.metadata.create_all(bind=op.get_bind())


def downgrade():
    Base.metadata.drop_all(bind=op.get_bind())
