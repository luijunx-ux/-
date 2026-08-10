from fastapi.testclient import TestClient

from app.api.dependencies import get_location_service
from app.domain.location import LocationCandidate
from app.main import app


class FakeLocationService:
    async def search(self, query: str, limit: int = 5) -> list[LocationCandidate]:
        return [
            LocationCandidate(
                display_name=f"{query}, 中国",
                latitude=31.2304,
                longitude=121.4737,
                timezone="Asia/Shanghai",
            )
        ]


app.dependency_overrides[get_location_service] = FakeLocationService
client = TestClient(app)


def test_search_location() -> None:
    response = client.get("/api/v1/locations/search", params={"q": "上海"})

    assert response.status_code == 200
    assert response.json()[0] == {
        "display_name": "上海, 中国",
        "latitude": 31.2304,
        "longitude": 121.4737,
        "timezone": "Asia/Shanghai",
    }


def test_search_requires_two_characters() -> None:
    response = client.get("/api/v1/locations/search", params={"q": "上"})
    assert response.status_code == 422
