import os
from datetime import UTC, date, datetime
from uuid import uuid4

import pytest
from redis.asyncio import Redis
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.rate_limit import RedisSlidingWindowRateLimiter
from app.domain.advice import DailyAdviceResult
from app.domain.models import BirthData, LifeProfile, WuyunLiuqiInfo, ZodiacInfo
from app.infrastructure.advice_history_repository import SqlAlchemyAdviceHistoryRepository
from app.infrastructure.orm import DailyAdviceRecord, LifeProfileRecord
from app.infrastructure.profile_repository import SqlAlchemyLifeProfileRepository
from app.infrastructure.user_repository import SqlAlchemyUserRepository

SERVICE_TESTS_ENABLED = os.getenv("TIANRENLV_SERVICE_TESTS") == "1"
pytestmark = pytest.mark.skipif(
    not SERVICE_TESTS_ENABLED,
    reason="Set TIANRENLV_SERVICE_TESTS=1 to run real service integration tests.",
)


def _database_url() -> str:
    value = os.getenv("DATABASE_URL")
    if value is None:
        raise RuntimeError("DATABASE_URL is required for real service integration tests")
    return value


def _redis_url() -> str:
    value = os.getenv("REDIS_URL")
    if value is None:
        raise RuntimeError("REDIS_URL is required for real service integration tests")
    return value


@pytest.mark.asyncio
async def test_migrated_postgres_repositories_and_cascade_delete() -> None:
    engine = create_async_engine(_database_url(), pool_pre_ping=True)
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    unique = uuid4().hex

    try:
        async with sessions() as session:
            revision = await session.scalar(text("SELECT version_num FROM alembic_version"))
            assert revision == "20260810_0006"

            users = SqlAlchemyUserRepository(session)
            profiles = SqlAlchemyLifeProfileRepository(session)
            advice_history = SqlAlchemyAdviceHistoryRepository(session)

            user = await users.create(f"service-{unique}@example.invalid", "test-only-hash")
            profile = LifeProfile(
                birth=BirthData(
                    occurred_at=datetime(1990, 8, 15, 2, 30, tzinfo=UTC),
                    place_name="合成测试地点",
                    latitude=31.2304,
                    longitude=121.4737,
                    timezone="Asia/Shanghai",
                ),
                zodiac=ZodiacInfo(sign="狮子座", element="火", modality="固定"),
                wuyun_liuqi=WuyunLiuqiInfo(
                    year=1990,
                    heavenly_stem="庚",
                    earthly_branch="午",
                    middle_movement="金运",
                    movement_strength="太过",
                    governing_qi="少阴君火",
                    responding_qi="阳明燥金",
                    algorithm_version="service-test-v1",
                    boundary_warning=None,
                ),
            )
            profile_id, is_default = await profiles.add_named(
                profile, user.id, "CI 合成档案", False
            )
            assert is_default is True

            stored = await profiles.get(profile_id, user.id)
            assert stored is not None
            assert stored.birth.place_name == "合成测试地点"
            assert stored.wuyun_liuqi.algorithm_version == "service-test-v1"

            result = DailyAdviceResult(
                items=["今天可以安排一次温和伸展。"],
                generation_mode="deterministic_fallback",
                model=None,
                knowledge_sources=["service-test"],
                request_id=str(uuid4()),
            )
            advice = await advice_history.add(user.id, profile_id, date(2026, 8, 18), result)
            assert advice.result.items == result.items
            assert await advice_history.get_for_date(
                user.id, profile_id, date(2026, 8, 18)
            ) is not None

            assert await users.delete(user.id) is True
            profile_count = await session.scalar(
                select(func.count()).select_from(LifeProfileRecord).where(
                    LifeProfileRecord.id == profile_id
                )
            )
            advice_count = await session.scalar(
                select(func.count()).select_from(DailyAdviceRecord).where(
                    DailyAdviceRecord.id == advice.id
                )
            )
            assert profile_count == 0
            assert advice_count == 0
    finally:
        await engine.dispose()


@pytest.mark.asyncio
async def test_real_redis_rate_limit_is_shared_and_privacy_preserving() -> None:
    redis = Redis.from_url(_redis_url(), decode_responses=True)
    namespace = f"tianrenlu:service-test:{uuid4().hex}"
    identifier = f"service-{uuid4().hex}@example.invalid"
    first = RedisSlidingWindowRateLimiter(
        redis, limit=2, window_seconds=60, namespace=namespace
    )
    second = RedisSlidingWindowRateLimiter(
        redis, limit=2, window_seconds=60, namespace=namespace
    )

    try:
        assert await first.allow(identifier) is True
        assert await second.allow(identifier) is True
        assert await first.allow(identifier) is False

        keys = [key async for key in redis.scan_iter(match=f"{namespace}:*")]
        assert len(keys) == 1
        assert identifier not in keys[0]
    finally:
        keys = [key async for key in redis.scan_iter(match=f"{namespace}:*")]
        if keys:
            await redis.delete(*keys)
        await redis.aclose()
