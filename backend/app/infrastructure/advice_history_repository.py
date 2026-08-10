from datetime import date, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.advice import DailyAdviceResult
from app.domain.advice_history import StoredDailyAdvice
from app.infrastructure.orm import DailyAdviceRecord


class SqlAlchemyAdviceHistoryRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_for_date(
        self, owner_id: UUID, profile_id: UUID, target_date: date
    ) -> StoredDailyAdvice | None:
        record = await self._session.scalar(
            select(DailyAdviceRecord).where(
                DailyAdviceRecord.owner_id == owner_id,
                DailyAdviceRecord.profile_id == profile_id,
                DailyAdviceRecord.target_date == target_date,
            )
        )
        if record is None:
            return None
        record.viewed_on = date.today()
        await self._session.commit()
        return self._to_domain(record)

    async def add(
        self,
        owner_id: UUID,
        profile_id: UUID,
        target_date: date,
        result: DailyAdviceResult,
    ) -> StoredDailyAdvice:
        record = DailyAdviceRecord(
            owner_id=owner_id,
            profile_id=profile_id,
            target_date=target_date,
            advice=result.items,
            generation_mode=result.generation_mode,
            model=result.model,
            knowledge_sources=result.knowledge_sources,
            request_id=result.request_id,
            input_tokens=result.input_tokens,
            output_tokens=result.output_tokens,
        )
        self._session.add(record)
        await self._session.commit()
        await self._session.refresh(record)
        return self._to_domain(record)

    async def list_for_owner(self, owner_id: UUID, limit: int) -> list[StoredDailyAdvice]:
        records = await self._session.scalars(
            select(DailyAdviceRecord)
            .where(DailyAdviceRecord.owner_id == owner_id)
            .order_by(DailyAdviceRecord.target_date.desc())
            .limit(limit)
        )
        return [self._to_domain(record) for record in records]

    async def set_feedback(
        self, advice_id: UUID, owner_id: UUID, helpful: bool
    ) -> StoredDailyAdvice | None:
        record = await self._session.scalar(
            select(DailyAdviceRecord).where(
                DailyAdviceRecord.id == advice_id,
                DailyAdviceRecord.owner_id == owner_id,
            )
        )
        if record is None:
            return None
        record.helpful = helpful
        await self._session.commit()
        return self._to_domain(record)

    async def viewing_streak(self, owner_id: UUID, through_date: date) -> int:
        dates = await self._session.scalars(
            select(DailyAdviceRecord.viewed_on)
            .where(
                DailyAdviceRecord.owner_id == owner_id,
                DailyAdviceRecord.viewed_on <= through_date,
            )
            .distinct()
            .order_by(DailyAdviceRecord.viewed_on.desc())
        )
        streak = 0
        expected = through_date
        for viewed_date in dates:
            if viewed_date != expected:
                break
            streak += 1
            expected -= timedelta(days=1)
        return streak

    def _to_domain(self, record: DailyAdviceRecord) -> StoredDailyAdvice:
        return StoredDailyAdvice(
            id=record.id,
            owner_id=record.owner_id,
            profile_id=record.profile_id,
            target_date=record.target_date,
            result=DailyAdviceResult(
                items=record.advice,
                generation_mode=record.generation_mode,
                model=record.model,
                knowledge_sources=record.knowledge_sources,
                request_id=record.request_id,
                input_tokens=record.input_tokens,
                output_tokens=record.output_tokens,
            ),
            helpful=record.helpful,
        )
