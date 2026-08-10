from uuid import UUID

from app.application.profile_service import build_life_profile
from app.domain.models import BirthData, LifeProfile
from app.domain.repositories import LifeProfileRepository


async def create_profile(
    repository: LifeProfileRepository,
    birth: BirthData,
    owner_id: UUID,
    name: str,
    make_default: bool,
) -> tuple[UUID, LifeProfile, bool]:
    profile = build_life_profile(birth)
    profile_id, is_default = await repository.add_named(profile, owner_id, name, make_default)
    return profile_id, profile, is_default


async def get_profile(
    repository: LifeProfileRepository, profile_id: UUID, owner_id: UUID
) -> LifeProfile | None:
    return await repository.get(profile_id, owner_id)


async def get_stored_profile(
    repository: LifeProfileRepository, profile_id: UUID, owner_id: UUID
) -> tuple[LifeProfile, str, bool] | None:
    return await repository.get_stored(profile_id, owner_id)


async def list_profiles(
    repository: LifeProfileRepository, owner_id: UUID
) -> list[tuple[UUID, LifeProfile, str, bool]]:
    return await repository.list_for_owner(owner_id)


async def delete_profile(
    repository: LifeProfileRepository, profile_id: UUID, owner_id: UUID
) -> bool:
    return await repository.delete(profile_id, owner_id)


async def update_profile(
    repository: LifeProfileRepository,
    profile_id: UUID,
    owner_id: UUID,
    birth: BirthData,
    name: str,
    make_default: bool,
) -> LifeProfile | None:
    profile = build_life_profile(birth)
    updated = await repository.update(profile_id, owner_id, profile, name, make_default)
    return profile if updated else None
