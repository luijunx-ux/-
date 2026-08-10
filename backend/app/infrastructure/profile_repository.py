from dataclasses import asdict
from uuid import UUID

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.models import BirthData, LifeProfile, WuyunLiuqiInfo, ZodiacInfo
from app.infrastructure.orm import DailyAdviceRecord, LifeProfileRecord


class SqlAlchemyLifeProfileRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def add(self, profile: LifeProfile, owner_id: UUID) -> UUID:
        profile_id, _ = await self.add_named(profile, owner_id, "我的生命档案", False)
        return profile_id

    async def add_named(
        self, profile: LifeProfile, owner_id: UUID, name: str, make_default: bool
    ) -> tuple[UUID, bool]:
        existing = await self._session.scalar(
            select(LifeProfileRecord.id).where(LifeProfileRecord.owner_id == owner_id).limit(1)
        )
        is_default = make_default or existing is None
        if is_default:
            await self._clear_default(owner_id)
        record = LifeProfileRecord(
            owner_id=owner_id,
            name=name,
            is_default=is_default,
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
        return record.id, is_default

    async def get(self, profile_id: UUID, owner_id: UUID) -> LifeProfile | None:
        result = await self._session.execute(
            select(LifeProfileRecord).where(
                LifeProfileRecord.id == profile_id,
                LifeProfileRecord.owner_id == owner_id,
            )
        )
        record = result.scalar_one_or_none()
        if record is None:
            return None
        return self._to_domain(record)

    async def list_for_owner(self, owner_id: UUID) -> list[tuple[UUID, LifeProfile, str, bool]]:
        result = await self._session.execute(
            select(LifeProfileRecord)
            .where(LifeProfileRecord.owner_id == owner_id)
            .order_by(LifeProfileRecord.created_at.desc())
        )
        return [
            (record.id, self._to_domain(record), record.name, record.is_default)
            for record in result.scalars()
        ]

    async def get_stored(
        self, profile_id: UUID, owner_id: UUID
    ) -> tuple[LifeProfile, str, bool] | None:
        result = await self._session.execute(
            select(LifeProfileRecord).where(
                LifeProfileRecord.id == profile_id,
                LifeProfileRecord.owner_id == owner_id,
            )
        )
        record = result.scalar_one_or_none()
        if record is None:
            return None
        return self._to_domain(record), record.name, record.is_default

    async def update(
        self,
        profile_id: UUID,
        owner_id: UUID,
        profile: LifeProfile,
        name: str,
        make_default: bool,
    ) -> bool:
        result = await self._session.execute(
            select(LifeProfileRecord).where(
                LifeProfileRecord.id == profile_id,
                LifeProfileRecord.owner_id == owner_id,
            )
        )
        record = result.scalar_one_or_none()
        if record is None:
            return False
        if make_default:
            await self._clear_default(owner_id)
        record.name = name
        record.is_default = make_default or record.is_default
        record.occurred_at = profile.birth.occurred_at
        record.place_name = profile.birth.place_name
        record.latitude = profile.birth.latitude
        record.longitude = profile.birth.longitude
        record.timezone = profile.birth.timezone
        record.zodiac = asdict(profile.zodiac)
        record.wuyun_liuqi = asdict(profile.wuyun_liuqi)
        await self._session.execute(
            delete(DailyAdviceRecord).where(DailyAdviceRecord.profile_id == profile_id)
        )
        await self._session.commit()
        return True

    async def delete(self, profile_id: UUID, owner_id: UUID) -> bool:
        result = await self._session.execute(
            select(LifeProfileRecord).where(
                LifeProfileRecord.id == profile_id,
                LifeProfileRecord.owner_id == owner_id,
            )
        )
        record = result.scalar_one_or_none()
        if record is None:
            return False
        was_default = record.is_default
        await self._session.delete(record)
        await self._session.flush()
        if was_default:
            replacement = await self._session.scalar(
                select(LifeProfileRecord)
                .where(LifeProfileRecord.owner_id == owner_id)
                .order_by(LifeProfileRecord.created_at.desc())
                .limit(1)
            )
            if replacement is not None:
                replacement.is_default = True
        await self._session.commit()
        return True

    def _to_domain(self, record: LifeProfileRecord) -> LifeProfile:
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

    async def _clear_default(self, owner_id: UUID) -> None:
        await self._session.execute(
            update(LifeProfileRecord)
            .where(LifeProfileRecord.owner_id == owner_id)
            .values(is_default=False)
        )
