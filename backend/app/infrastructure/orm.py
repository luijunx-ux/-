from datetime import datetime
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Numeric, String, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class LifeProfileRecord(Base):
    __tablename__ = "life_profiles"

    id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), primary_key=True, default=uuid4)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    place_name: Mapped[str] = mapped_column(String(200), nullable=False)
    latitude: Mapped[float] = mapped_column(Numeric(9, 6, asdecimal=False), nullable=False)
    longitude: Mapped[float] = mapped_column(Numeric(9, 6, asdecimal=False), nullable=False)
    timezone: Mapped[str] = mapped_column(String(64), nullable=False)
    zodiac: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    wuyun_liuqi: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    algorithm_versions: Mapped[dict[str, str]] = mapped_column(JSONB, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
