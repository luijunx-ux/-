import pytest

from app.core import health


@pytest.mark.asyncio
async def test_readiness_succeeds_when_required_dependencies_are_available(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    async def available() -> health.DependencyStatus:
        return {"status": "ok"}

    monkeypatch.setattr(health, "_check_database", available)
    monkeypatch.setattr(health, "_check_redis", available)

    result = await health.check_readiness()

    assert result["status"] == "ready"


@pytest.mark.asyncio
async def test_readiness_fails_when_database_is_unavailable(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    async def unavailable() -> health.DependencyStatus:
        return {"status": "unavailable"}

    async def disabled() -> health.DependencyStatus:
        return {"status": "disabled"}

    monkeypatch.setattr(health, "_check_database", unavailable)
    monkeypatch.setattr(health, "_check_redis", disabled)

    result = await health.check_readiness()

    assert result["status"] == "not_ready"
    assert result["checks"]["database"] == {"status": "unavailable"}
