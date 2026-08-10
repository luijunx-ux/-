"""add daily advice history

Revision ID: 20260810_0004
Revises: 20260810_0003
Create Date: 2026-08-10
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20260810_0004"
down_revision: str | None = "20260810_0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "daily_advice_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("owner_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("profile_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("target_date", sa.Date(), nullable=False),
        sa.Column("viewed_on", sa.Date(), server_default=sa.text("CURRENT_DATE"), nullable=False),
        sa.Column("advice", postgresql.JSONB(), nullable=False),
        sa.Column("generation_mode", sa.String(length=32), nullable=False),
        sa.Column("model", sa.String(length=100), nullable=True),
        sa.Column("knowledge_sources", postgresql.JSONB(), nullable=False),
        sa.Column("request_id", sa.String(length=36), nullable=False),
        sa.Column("input_tokens", sa.Integer(), server_default="0", nullable=False),
        sa.Column("output_tokens", sa.Integer(), server_default="0", nullable=False),
        sa.Column("helpful", sa.Boolean(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["owner_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["profile_id"], ["life_profiles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("owner_id", "profile_id", "target_date", name="uq_advice_profile_date"),
    )
    op.create_index("ix_daily_advice_records_owner_id", "daily_advice_records", ["owner_id"])
    op.create_index("ix_daily_advice_records_profile_id", "daily_advice_records", ["profile_id"])


def downgrade() -> None:
    op.drop_index("ix_daily_advice_records_profile_id", table_name="daily_advice_records")
    op.drop_index("ix_daily_advice_records_owner_id", table_name="daily_advice_records")
    op.drop_table("daily_advice_records")
