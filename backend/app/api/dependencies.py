from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.repositories import LifeProfileRepository
from app.infrastructure.database import get_session
from app.infrastructure.profile_repository import SqlAlchemyLifeProfileRepository


async def get_profile_repository(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> AsyncIterator[LifeProfileRepository]:
    yield SqlAlchemyLifeProfileRepository(session)


ProfileRepositoryDependency = Annotated[LifeProfileRepository, Depends(get_profile_repository)]
