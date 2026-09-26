from typing import cast
from unittest import IsolatedAsyncioTestCase

from pydantic import SecretStr, ValidationError
from redis.asyncio import Redis
from redis.exceptions import ConnectionError

from app.core.config import Settings
from app.core.rate_limit import (
    MemorySlidingWindowRateLimiter,
    RateLimiterUnavailableError,
    RedisSlidingWindowRateLimiter,
    ResilientRateLimiter,
)


class FakeRedis:
    def __init__(self, result: int = 1) -> None:
        self.result = result
        self.arguments: tuple[object, ...] = ()

    async def eval(self, *arguments: object) -> int:
        self.arguments = arguments
        return self.result


class UnavailableRateLimiter:
    async def allow(self, key: str) -> bool:
        raise ConnectionError("Redis unavailable")


class RateLimiterTests(IsolatedAsyncioTestCase):
    def test_production_requires_redis_configuration(self) -> None:
        with self.assertRaises(ValidationError):
            Settings(
                app_env="production",
                jwt_secret_key=SecretStr("production-jwt-secret-that-is-long-enough"),
                safety_identifier_secret=SecretStr(
                    "production-safety-secret-that-is-long-enough"
                ),
            )

    def test_production_accepts_redis_configuration(self) -> None:
        settings = Settings(
            app_env="production",
            jwt_secret_key=SecretStr("production-jwt-secret-that-is-long-enough"),
            safety_identifier_secret=SecretStr("production-safety-secret-that-is-long-enough"),
            redis_url="rediss://cache.example.com:6379/0",
            database_url="postgresql+asyncpg://app:strong-password@db.example.com/tianrenlu",
            app_public_url="https://app.example.com",
            smtp_host="smtp.example.com",
            smtp_from_email="no-reply@example.com",
        )

        self.assertEqual(settings.redis_url, "rediss://cache.example.com:6379/0")

    def test_production_rejects_template_database_credentials(self) -> None:
        with self.assertRaises(ValidationError):
            Settings(
                app_env="production",
                jwt_secret_key=SecretStr("production-jwt-secret-that-is-long-enough"),
                safety_identifier_secret=SecretStr(
                    "production-safety-secret-that-is-long-enough"
                ),
                redis_url="rediss://cache.example.com:6379/0",
                database_url="postgresql+asyncpg://app:change_me@db.example.com/tianrenlu",
                app_public_url="https://app.example.com",
                smtp_host="smtp.example.com",
                smtp_from_email="no-reply@example.com",
            )

    def test_production_rejects_ai_without_model_key(self) -> None:
        with self.assertRaises(ValidationError):
            Settings(
                app_env="production",
                jwt_secret_key=SecretStr("production-jwt-secret-that-is-long-enough"),
                safety_identifier_secret=SecretStr(
                    "production-safety-secret-that-is-long-enough"
                ),
                redis_url="rediss://cache.example.com:6379/0",
                database_url="postgresql+asyncpg://app:strong-password@db.example.com/tianrenlu",
                app_public_url="https://app.example.com",
                smtp_host="smtp.example.com",
                smtp_from_email="no-reply@example.com",
                ai_enabled=True,
            )

    async def test_memory_limiter_rejects_after_limit(self) -> None:
        limiter = MemorySlidingWindowRateLimiter(limit=2, window_seconds=60)

        self.assertTrue(await limiter.allow("user@example.com"))
        self.assertTrue(await limiter.allow("user@example.com"))
        self.assertFalse(await limiter.allow("user@example.com"))
        self.assertTrue(await limiter.allow("other@example.com"))

    async def test_redis_limiter_hashes_personal_identifier(self) -> None:
        fake = FakeRedis()
        limiter = RedisSlidingWindowRateLimiter(cast(Redis, fake), limit=3, window_seconds=60)

        self.assertTrue(await limiter.allow("user@example.com"))

        redis_key = str(fake.arguments[2])
        self.assertTrue(redis_key.startswith("tianrenlu:auth-rate-limit:"))
        self.assertNotIn("user@example.com", redis_key)
        self.assertEqual(fake.arguments[5], "3")

    async def test_development_falls_back_when_redis_is_unavailable(self) -> None:
        fallback = MemorySlidingWindowRateLimiter(limit=1, window_seconds=60)
        limiter = ResilientRateLimiter(UnavailableRateLimiter(), fallback)

        self.assertTrue(await limiter.allow("user@example.com"))
        self.assertFalse(await limiter.allow("user@example.com"))

    async def test_production_fails_closed_when_redis_is_unavailable(self) -> None:
        limiter = ResilientRateLimiter(UnavailableRateLimiter())

        with self.assertRaises(RateLimiterUnavailableError):
            await limiter.allow("user@example.com")
