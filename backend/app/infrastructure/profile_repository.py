from dataclasses import asdict
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.models import BirthData, LifeProfile, WuyunLiuqiInfo, ZodiacInfo
from app.infrastructure.orm import LifeProfileRecord


class SqlAlchemyLifeProfileRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def add(self, profile: LifeProfile) -> UUID:
        record = LifeProfileRecord(
            occurred_at=profile.birth.occurred_at,
            place_name=profile.birth.place_name,
            latitude=profile.birth.latitude,
            longitude=profile.birth.longitude,
            timezone=profile.birth.timezone,
            zodiac=asdict(profile.zodiac),
            wuyun_liuqi=asdict(profile.wuyun_liuqi),
            algorithm_versions={
                "wuyun_liuqi": profile.wuyun_liuqi.algorithm_version,
                "zodiac": "tropical_date_v1",
            },
        )
        self._session.add(record)
        await self._session.commit()
        await self._session.refresh(record)
        return record.id

    async def get(self, profile_id: UUID) -> LifeProfile | None:
        record = await self._session.get(LifeProfileRecord, profile_id)
        if record is None:
            return None
        return LifeProfile(
            birth=BirthData(
                occurred_at=record.occurred_at,
                place_name=record.place_name,
                latitude=record.latitude,
                longitude=record.longitude,
                timezone=record.timezone,
            ),
            zodiac=ZodiacInfo(**record.zodiac),
            wuyun_liuqi=WuyunLiuqiInfo(**record.wuyun_liuqi),
        )
