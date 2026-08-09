from typing import Protocol
from uuid import UUID

from app.domain.models import LifeProfile


class LifeProfileRepository(Protocol):
    async def add(self, profile: LifeProfile) -> UUID: ...

    async def get(self, profile_id: UUID) -> LifeProfile | None: ...
