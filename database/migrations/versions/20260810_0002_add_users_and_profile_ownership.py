"""add users and profile ownership

Revision ID: 20260810_0002
Revises: 20260809_0001
Create Date: 2026-08-10
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision: str = "20260810_0002"
down_revision: str | None = "20260809_0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("email", sa.String(length=320), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.add_column(
        "life_profiles",
        sa.Column("owner_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_index("ix_life_profiles_owner_id", "life_profiles", ["owner_id"])
    op.create_foreign_key(
        "fk_life_profiles_owner_id_users",
        "life_profiles",
        "users",
        ["owner_id"],
        ["id"],
        ondelete="CASCADE",
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_life_profiles_owner_id_users",
        "life_profiles",
        type_="foreignkey",
    )
    op.drop_index("ix_life_profiles_owner_id", table_name="life_profiles")
    op.drop_column("life_profiles", "owner_id")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
