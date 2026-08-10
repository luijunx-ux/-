from __future__ import annotations

import hashlib
import time
from collections import defaultdict, deque
from collections.abc import Awaitable
from functools import lru_cache
from typing import Protocol, cast
from uuid import uuid4

from redis.asyncio import Redis
from redis.exceptions import RedisError

from app.core.config import get_settings


class RateLimiter(Protocol):
    async def allow(self, key: str) -> bool: ...


class RateLimiterUnavailableError(RuntimeError):
    """Raised when the configured shared rate limiter cannot be reached."""


class MemorySlidingWindowRateLimiter:
    def __init__(self, limit: int = 5, window_seconds: int = 900) -> None:
        self._limit = limit
        self._window_seconds = window_seconds
        self._attempts: dict[str, deque[float]] = defaultdict(deque)

    async def allow(self, key: str) -> bool:
        now = time.monotonic()
        attempts = self._attempts[key]
        cutoff = now - self._window_seconds
        while attempts and attempts[0] <= cutoff:
            attempts.popleft()
        if len(attempts) >= self._limit:
            return False
        attempts.append(now)
        return True


class RedisSlidingWindowRateLimiter:
    _SCRIPT = """
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])
redis.call('ZREMRANGEBYSCORE', key, '-inf', now - window)
if redis.call('ZCARD', key) >= limit then
    redis.call('PEXPIRE', key, window)
    return 0
end
redis.call('ZADD', key, now, ARGV[4])
redis.call('PEXPIRE', key, window)
return 1
"""

    def __init__(
        self,
        client: Redis,
        *,
        limit: int = 5,
        window_seconds: int = 900,
        namespace: str = "tianrenlu:auth-rate-limit",
    ) -> None:
        self._client = client
        self._limit = limit
        self._window_ms = window_seconds * 1000
        self._namespace = namespace

    async def allow(self, key: str) -> bool:
        digest = hashlib.sha256(key.encode("utf-8")).hexdigest()
        redis_key = f"{self._namespace}:{digest}"
        now_ms = time.time_ns() // 1_000_000
        member = f"{now_ms}:{uuid4().hex}"
        operation = cast(
            Awaitable[object],
            self._client.eval(
                self._SCRIPT,
                1,
                redis_key,
                str(now_ms),
                str(self._window_ms),
                str(self._limit),
                member,
            ),
        )
        result = await operation
        return bool(result)


class ResilientRateLimiter:
    def __init__(self, primary: RateLimiter, fallback: RateLimiter | None = None) -> None:
        self._primary = primary
        self._fallback = fallback

    async def allow(self, key: str) -> bool:
        try:
            return await self._primary.allow(key)
        except RedisError as exc:
            if self._fallback is None:
                raise RateLimiterUnavailableError from exc
            return await self._fallback.allow(key)


@lru_cache
def get_auth_rate_limiter() -> RateLimiter:
    settings = get_settings()
    memory = MemorySlidingWindowRateLimiter(
        limit=settings.auth_rate_limit_attempts,
        window_seconds=settings.auth_rate_limit_window_seconds,
    )
    if settings.redis_url is None:
        return memory

    client = Redis.from_url(
        settings.redis_url,
        socket_connect_timeout=settings.redis_timeout_seconds,
        socket_timeout=settings.redis_timeout_seconds,
        decode_responses=True,
    )
    redis_limiter = RedisSlidingWindowRateLimiter(
        client,
        limit=settings.auth_rate_limit_attempts,
        window_seconds=settings.auth_rate_limit_window_seconds,
    )
    fallback = memory if settings.app_env.lower() == "development" else None
    return ResilientRateLimiter(redis_limiter, fallback)
