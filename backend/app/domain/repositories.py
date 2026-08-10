from typing import Protocol
from uuid import UUID

from app.domain.models import LifeProfile


class LifeProfileRepository(Protocol):
    async def add(self, profile: LifeProfile, owner_id: UUID) -> UUID: ...

    async def add_named(
        self, profile: LifeProfile, owner_id: UUID, name: str, make_default: bool
    ) -> tuple[UUID, bool]: ...

    async def get(self, profile_id: UUID, owner_id: UUID) -> LifeProfile | None: ...

    async def list_for_owner(self, owner_id: UUID) -> list[tuple[UUID, LifeProfile, str, bool]]: ...

    async def get_stored(
        self, profile_id: UUID, owner_id: UUID
    ) -> tuple[LifeProfile, str, bool] | None: ...

    async def update(
        self,
        profile_id: UUID,
        owner_id: UUID,
        profile: LifeProfile,
        name: str,
        make_default: bool,
    ) -> bool: ...

    async def delete(self, profile_id: UUID, owner_id: UUID) -> bool: ...
