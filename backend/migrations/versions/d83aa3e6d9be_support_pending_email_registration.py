
"""support pending email registration

Revision ID: d83aa3e6d9be
Revises: 4530e867f341
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d83aa3e6d9be"
down_revision: Union[str, Sequence[str], None] = "4530e867f341"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add registration details as nullable first, so existing records survive.
    op.add_column(
        "pending_verifications",
        sa.Column("full_name", sa.String(length=150), nullable=True),
    )

    op.add_column(
        "pending_verifications",
        sa.Column("password_hash", sa.String(length=255), nullable=True),
    )

    op.add_column(
        "pending_verifications",
        sa.Column("preferred_language", sa.String(length=5), nullable=True),
    )

    # Populate existing pending records from their associated users.
    op.execute(
        """
        UPDATE pending_verifications AS pending
        SET
            full_name = users.full_name,
            password_hash = users.password_hash,
            preferred_language = COALESCE(users.preferred_language, 'en')
        FROM users
        WHERE pending.user_id = users.id
        """
    )

    # Make registration details mandatory after backfilling old records.
    op.alter_column(
        "pending_verifications",
        "full_name",
        existing_type=sa.String(length=150),
        nullable=False,
    )

    op.alter_column(
        "pending_verifications",
        "password_hash",
        existing_type=sa.String(length=255),
        nullable=False,
    )

    op.alter_column(
        "pending_verifications",
        "preferred_language",
        existing_type=sa.String(length=5),
        nullable=False,
    )

    # New pending registrations will not have a user account yet.
    op.alter_column(
        "pending_verifications",
        "user_id",
        existing_type=sa.UUID(),
        nullable=True,
    )


def downgrade() -> None:
    # Restore the original requirement that every pending record has a user.
    op.execute(
        """
        DELETE FROM pending_verifications
        WHERE user_id IS NULL
        """
    )

    op.alter_column(
        "pending_verifications",
        "user_id",
        existing_type=sa.UUID(),
        nullable=False,
    )

    op.drop_column("pending_verifications", "preferred_language")
    op.drop_column("pending_verifications", "password_hash")
    op.drop_column("pending_verifications", "full_name")
