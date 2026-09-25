from __future__ import annotations

import asyncio
from typing import Literal, TypedDict

from redis.asyncio import Redis
from sqlalchemy import text

from app.core.config import get_settings
from app.infrastructure.database import engine


class DependencyStatus(TypedDict):
    status: Literal["ok", "unavailable", "disabled"]


class ReadinessStatus(TypedDict):
    status: Literal["ready", "not_ready"]
    checks: dict[str, DependencyStatus]


async def _check_database() -> DependencyStatus:
    try:
        async with engine.connect() as connection:
            await connection.execute(text("SELECT 1"))
    except Exception:
        return {"status": "unavailable"}
    return {"status": "ok"}


async def _check_redis() -> DependencyStatus:
    settings = get_settings()
    if settings.redis_url is None:
        return {"status": "disabled"}
    client = Redis.from_url(
        settings.redis_url,
        socket_connect_timeout=settings.redis_timeout_seconds,
        socket_timeout=settings.redis_timeout_seconds,
        decode_responses=True,
    )
    try:
        await client.ping()
    except Exception:
        return {"status": "unavailable"}
    finally:
        await client.aclose()
    return {"status": "ok"}


async def check_readiness() -> ReadinessStatus:
    database, redis = await asyncio.gather(_check_database(), _check_redis())
    checks = {"database": database, "redis": redis}
    required_checks = [database]
    if get_settings().redis_url is not None:
        required_checks.append(redis)
    is_ready = all(check["status"] == "ok" for check in required_checks)
    return {"status": "ready" if is_ready else "not_ready", "checks": checks}
