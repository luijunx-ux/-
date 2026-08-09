from uuid import UUID

from app.application.profile_service import build_life_profile
from app.domain.models import BirthData, LifeProfile
from app.domain.repositories import LifeProfileRepository


async def create_profile(
    repository: LifeProfileRepository, birth: BirthData
) -> tuple[UUID, LifeProfile]:
    profile = build_life_profile(birth)
    profile_id = await repository.add(profile)
    return profile_id, profile


async def get_profile(repository: LifeProfileRepository, profile_id: UUID) -> LifeProfile | None:
    return await repository.get(profile_id)
