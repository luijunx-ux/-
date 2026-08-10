import unittest
from dataclasses import dataclass

from app.application.location_service import LocationSearchService
from app.domain.location_ports import GeocodedPlace


@dataclass(frozen=True)
class FakePlace:
    display_name: str
    latitude: float
    longitude: float


class FakeGeocoder:
    def __init__(self) -> None:
        self.queries: list[str] = []

    async def search(self, query: str, limit: int) -> list[GeocodedPlace]:
        self.queries.append(query)
        return [FakePlace("上海市, 中国", 31.2304, 121.4737)]


class FakeTimezoneResolver:
    async def resolve(self, latitude: float, longitude: float) -> str | None:
        return "Asia/Shanghai"


class LocationSearchServiceTests(unittest.IsolatedAsyncioTestCase):
    async def test_normalizes_query_and_adds_timezone(self) -> None:
        geocoder = FakeGeocoder()
        service = LocationSearchService(geocoder, FakeTimezoneResolver())

        results = await service.search("  上海   中国  ")

        self.assertEqual(geocoder.queries, ["上海 中国"])
        self.assertEqual(results[0].timezone, "Asia/Shanghai")
        self.assertEqual(results[0].latitude, 31.2304)

    async def test_rejects_short_query_without_external_call(self) -> None:
        geocoder = FakeGeocoder()
        service = LocationSearchService(geocoder, FakeTimezoneResolver())

        self.assertEqual(await service.search("上"), [])
        self.assertEqual(geocoder.queries, [])
