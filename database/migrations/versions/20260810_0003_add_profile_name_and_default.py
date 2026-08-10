"""add profile name and default selection

Revision ID: 20260810_0003
Revises: 20260810_0002
Create Date: 2026-08-10
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260810_0003"
down_revision: str | None = "20260810_0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "life_profiles",
        sa.Column(
            "name",
            sa.String(length=80),
            server_default="我的生命档案",
            nullable=False,
        ),
    )
    op.add_column(
        "life_profiles",
        sa.Column("is_default", sa.Boolean(), server_default=sa.false(), nullable=False),
    )
    op.execute(
        """
        UPDATE life_profiles AS profile
        SET is_default = true
        FROM (
            SELECT DISTINCT ON (owner_id) id
            FROM life_profiles
            WHERE owner_id IS NOT NULL
            ORDER BY owner_id, created_at DESC
        ) AS latest
        WHERE profile.id = latest.id
        """
    )
    op.create_index(
        "uq_life_profiles_one_default_per_owner",
        "life_profiles",
        ["owner_id"],
        unique=True,
        postgresql_where=sa.text("is_default = true AND owner_id IS NOT NULL"),
    )


def downgrade() -> None:
    op.drop_index("uq_life_profiles_one_default_per_owner", table_name="life_profiles")
    op.drop_column("life_profiles", "is_default")
    op.drop_column("life_profiles", "name")
