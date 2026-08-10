from collections.abc import AsyncIterator
from datetime import date, timedelta
from uuid import UUID, uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import (
    get_advice_history_repository,
    get_current_user,
    get_profile_repository,
)
from app.domain.advice import DailyAdviceResult
from app.domain.advice_history import AdviceHistoryRepository, StoredDailyAdvice
from app.domain.models import LifeProfile
from app.domain.repositories import LifeProfileRepository
from app.domain.user import User
from app.main import app


class InMemoryLifeProfileRepository:
    def __init__(self) -> None:
        self.profiles: dict[tuple[UUID, UUID], tuple[LifeProfile, str, bool]] = {}

    async def add(self, profile: LifeProfile, owner_id: UUID) -> UUID:
        profile_id = uuid4()
        self.profiles[(owner_id, profile_id)] = (profile, "我的生命档案", False)
        return profile_id

    async def add_named(
        self, profile: LifeProfile, owner_id: UUID, name: str, make_default: bool
    ) -> tuple[UUID, bool]:
        is_default = make_default or not any(key[0] == owner_id for key in self.profiles)
        if is_default:
            self._clear_default(owner_id)
        profile_id = uuid4()
        self.profiles[(owner_id, profile_id)] = (profile, name, is_default)
        return profile_id, is_default

    async def get(self, profile_id: UUID, owner_id: UUID) -> LifeProfile | None:
        stored = self.profiles.get((owner_id, profile_id))
        return None if stored is None else stored[0]

    async def get_stored(
        self, profile_id: UUID, owner_id: UUID
    ) -> tuple[LifeProfile, str, bool] | None:
        return self.profiles.get((owner_id, profile_id))

    async def list_for_owner(self, owner_id: UUID) -> list[tuple[UUID, LifeProfile, str, bool]]:
        return [
            (profile_id, profile, name, is_default)
            for (profile_owner_id, profile_id), (
                profile,
                name,
                is_default,
            ) in self.profiles.items()
            if profile_owner_id == owner_id
        ]

    async def update(
        self,
        profile_id: UUID,
        owner_id: UUID,
        profile: LifeProfile,
        name: str,
        make_default: bool,
    ) -> bool:
        key = (owner_id, profile_id)
        current = self.profiles.get(key)
        if current is None:
            return False
        if make_default:
            self._clear_default(owner_id)
        self.profiles[key] = (profile, name, make_default or current[2])
        return True

    async def delete(self, profile_id: UUID, owner_id: UUID) -> bool:
        return self.profiles.pop((owner_id, profile_id), None) is not None

    def _clear_default(self, owner_id: UUID) -> None:
        for key, (profile, name, _) in list(self.profiles.items()):
            if key[0] == owner_id:
                self.profiles[key] = (profile, name, False)


repository = InMemoryLifeProfileRepository()


class InMemoryAdviceHistoryRepository:
    def __init__(self) -> None:
        self.records: dict[UUID, StoredDailyAdvice] = {}

    async def get_for_date(
        self, owner_id: UUID, profile_id: UUID, target_date: date
    ) -> StoredDailyAdvice | None:
        return next(
            (
                record
                for record in self.records.values()
                if record.owner_id == owner_id
                and record.profile_id == profile_id
                and record.target_date == target_date
            ),
            None,
        )

    async def add(
        self,
        owner_id: UUID,
        profile_id: UUID,
        target_date: date,
        result: DailyAdviceResult,
    ) -> StoredDailyAdvice:
        record = StoredDailyAdvice(uuid4(), owner_id, profile_id, target_date, result)
        self.records[record.id] = record
        return record

    async def list_for_owner(self, owner_id: UUID, limit: int) -> list[StoredDailyAdvice]:
        records = [r for r in self.records.values() if r.owner_id == owner_id]
        return sorted(records, key=lambda r: r.target_date, reverse=True)[:limit]

    async def set_feedback(
        self, advice_id: UUID, owner_id: UUID, helpful: bool
    ) -> StoredDailyAdvice | None:
        record = self.records.get(advice_id)
        if record is None or record.owner_id != owner_id:
            return None
        updated = StoredDailyAdvice(
            record.id,
            record.owner_id,
            record.profile_id,
            record.target_date,
            record.result,
            helpful,
        )
        self.records[advice_id] = updated
        return updated

    async def viewing_streak(self, owner_id: UUID, through_date: date) -> int:
        dates = {r.target_date for r in self.records.values() if r.owner_id == owner_id}
        streak = 0
        cursor = through_date
        while cursor in dates:
            streak += 1
            cursor -= timedelta(days=1)
        return streak


advice_history_repository = InMemoryAdviceHistoryRepository()


async def override_repository() -> AsyncIterator[LifeProfileRepository]:
    yield repository


async def override_advice_history() -> AsyncIterator[AdviceHistoryRepository]:
    yield advice_history_repository


test_user = User(id=uuid4(), email="user@example.com", password_hash="not-used")


async def override_current_user() -> User:
    return test_user


app.dependency_overrides[get_profile_repository] = override_repository
app.dependency_overrides[get_advice_history_repository] = override_advice_history
app.dependency_overrides[get_current_user] = override_current_user
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
    assert created.json()["is_default"] is True
    profile_id = created.json()["id"]

    fetched = client.get(f"/api/v1/profiles/{profile_id}")
    assert fetched.status_code == 200
    assert fetched.json()["id"] == profile_id
    assert fetched.json()["profile"]["zodiac"]["sign"] == "狮子座"


def test_missing_profile_returns_404() -> None:
    response = client.get(f"/api/v1/profiles/{uuid4()}")
    assert response.status_code == 404


def test_list_then_delete_profile() -> None:
    repository.profiles.clear()
    created = client.post("/api/v1/profiles", json=VALID_BIRTH)
    profile_id = created.json()["id"]

    listed = client.get("/api/v1/profiles")
    assert listed.status_code == 200
    assert [item["id"] for item in listed.json()] == [profile_id]
    assert listed.json()[0]["profile"]["birth"]["place_name"] == "上海市"

    deleted = client.delete(f"/api/v1/profiles/{profile_id}")
    assert deleted.status_code == 204
    assert client.get(f"/api/v1/profiles/{profile_id}").status_code == 404
    assert client.delete(f"/api/v1/profiles/{profile_id}").status_code == 404


def test_rename_edit_and_make_default() -> None:
    repository.profiles.clear()
    first = client.post("/api/v1/profiles", json={**VALID_BIRTH, "name": "我的档案"}).json()
    second = client.post("/api/v1/profiles", json={**VALID_BIRTH, "name": "家人档案"}).json()

    updated = client.put(
        f"/api/v1/profiles/{second['id']}",
        json={
            **VALID_BIRTH,
            "place_name": "杭州市",
            "name": "新名称",
            "is_default": True,
        },
    )

    assert updated.status_code == 200
    assert updated.json()["name"] == "新名称"
    assert updated.json()["is_default"] is True
    assert updated.json()["profile"]["birth"]["place_name"] == "杭州市"
    listed = client.get("/api/v1/profiles").json()
    defaults = [item["id"] for item in listed if item["is_default"]]
    assert defaults == [second["id"]]
    assert first["id"] != second["id"]


def test_daily_advice_cache_history_feedback_and_streak() -> None:
    repository.profiles.clear()
    advice_history_repository.records.clear()
    profile_id = client.post("/api/v1/profiles", json=VALID_BIRTH).json()["id"]

    first = client.post(
        f"/api/v1/profiles/{profile_id}/advice/daily",
        json={"target_date": "2026-08-10"},
    )
    second = client.post(
        f"/api/v1/profiles/{profile_id}/advice/daily",
        json={"target_date": "2026-08-10"},
    )

    assert first.status_code == 200
    assert first.json()["cached"] is False
    assert second.json()["cached"] is True
    assert second.json()["id"] == first.json()["id"]

    feedback = client.put(
        f"/api/v1/advice/{first.json()['id']}/feedback",
        json={"helpful": True},
    )
    assert feedback.json()["helpful"] is True
    history = client.get("/api/v1/advice/history")
    assert history.json()[0]["id"] == first.json()["id"]
    stats = client.get("/api/v1/advice/stats?through_date=2026-08-10")
    assert stats.json() == {"viewing_streak": 1}
