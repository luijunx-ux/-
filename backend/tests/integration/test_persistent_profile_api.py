from collections.abc import AsyncIterator
from uuid import UUID, uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import get_profile_repository
from app.domain.models import LifeProfile
from app.domain.repositories import LifeProfileRepository
from app.main import app


class InMemoryLifeProfileRepository:
    def __init__(self) -> None:
        self.profiles: dict[UUID, LifeProfile] = {}

    async def add(self, profile: LifeProfile) -> UUID:
        profile_id = uuid4()
        self.profiles[profile_id] = profile
        return profile_id

    async def get(self, profile_id: UUID) -> LifeProfile | None:
        return self.profiles.get(profile_id)


repository = InMemoryLifeProfileRepository()


async def override_repository() -> AsyncIterator[LifeProfileRepository]:
    yield repository


app.dependency_overrides[get_profile_repository] = override_repository
client = TestClient(app)

VALID_BIRTH = {
    "occurred_at": "1990-08-15T10:30:00+08:00",
    "place_name": "上海市",
    "latitude": 31.2304,
    "longitude": 121.4737,
    "timezone": "Asia/Shanghai",
}


def test_create_then_read_profile() -> None:
    created = client.post("/api/v1/profiles", json=VALID_BIRTH)
    assert created.status_code == 201
    profile_id = created.json()["id"]

    fetched = client.get(f"/api/v1/profiles/{profile_id}")
    assert fetched.status_code == 200
    assert fetched.json()["id"] == profile_id
    assert fetched.json()["profile"]["zodiac"]["sign"] == "狮子座"


def test_missing_profile_returns_404() -> None:
    response = client.get(f"/api/v1/profiles/{uuid4()}")
    assert response.status_code == 404
