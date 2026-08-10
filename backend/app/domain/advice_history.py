from dataclasses import dataclass
from datetime import date
from typing import Protocol
from uuid import UUID

from app.domain.advice import DailyAdviceResult


@dataclass(frozen=True, slots=True)
class StoredDailyAdvice:
    id: UUID
    owner_id: UUID
    profile_id: UUID
    target_date: date
    result: DailyAdviceResult
    helpful: bool | None = None


class AdviceHistoryRepository(Protocol):
    async def get_for_date(
        self, owner_id: UUID, profile_id: UUID, target_date: date
    ) -> StoredDailyAdvice | None: ...

    async def add(
        self,
        owner_id: UUID,
        profile_id: UUID,
        target_date: date,
        result: DailyAdviceResult,
    ) -> StoredDailyAdvice: ...

    async def list_for_owner(self, owner_id: UUID, limit: int) -> list[StoredDailyAdvice]: ...

    async def set_feedback(
        self, advice_id: UUID, owner_id: UUID, helpful: bool
    ) -> StoredDailyAdvice | None: ...

    async def viewing_streak(self, owner_id: UUID, through_date: date) -> int: ...
