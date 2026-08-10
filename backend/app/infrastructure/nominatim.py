import asyncio
from collections.abc import Sequence
from dataclasses import dataclass
from time import monotonic

import httpx

from app.domain.location_ports import GeocodedPlace


@dataclass(frozen=True, slots=True)
class NominatimPlace:
    display_name: str
    latitude: float
    longitude: float


@dataclass(slots=True)
class _CacheEntry:
    expires_at: float
    places: list[GeocodedPlace]


class NominatimGeocoder:
    def __init__(self, base_url: str, user_agent: str, cache_seconds: int) -> None:
        self._client = httpx.AsyncClient(
            base_url=base_url,
            headers={"User-Agent": user_agent},
            timeout=httpx.Timeout(8.0),
        )
        self._cache_seconds = cache_seconds
        self._cache: dict[str, _CacheEntry] = {}
        self._request_lock = asyncio.Lock()
        self._last_request_at = 0.0

    async def search(self, query: str, limit: int) -> Sequence[GeocodedPlace]:
        cache_key = query.casefold()
        cached = self._cache.get(cache_key)
        now = monotonic()
        if cached is not None and cached.expires_at > now:
            return cached.places[:limit]

        async with self._request_lock:
            wait_seconds = 1.0 - (monotonic() - self._last_request_at)
            if wait_seconds > 0:
                await asyncio.sleep(wait_seconds)
            response = await self._client.get(
                "/search",
                params={
                    "q": query,
                    "format": "jsonv2",
                    "addressdetails": 0,
                    "limit": min(limit, 5),
                    "accept-language": "zh-CN,zh,en",
                },
            )
            self._last_request_at = monotonic()
            response.raise_for_status()

        places: list[GeocodedPlace] = [
            NominatimPlace(
                display_name=item["display_name"],
                latitude=float(item["lat"]),
                longitude=float(item["lon"]),
            )
            for item in response.json()
        ]
        self._cache[cache_key] = _CacheEntry(
            expires_at=monotonic() + self._cache_seconds,
            places=places,
        )
        return places[:limit]
