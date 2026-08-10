from app.domain.location import LocationCandidate
from app.domain.location_ports import Geocoder, TimezoneResolver


class LocationSearchService:
    def __init__(self, geocoder: Geocoder, timezone_resolver: TimezoneResolver) -> None:
        self._geocoder = geocoder
        self._timezone_resolver = timezone_resolver

    async def search(self, query: str, limit: int = 5) -> list[LocationCandidate]:
        normalized = " ".join(query.split())
        if len(normalized) < 2:
            return []
        places = await self._geocoder.search(normalized, limit)
        results: list[LocationCandidate] = []
        for place in places:
            timezone = await self._timezone_resolver.resolve(
                place.latitude,
                place.longitude,
            )
            if timezone is None:
                continue
            results.append(
                LocationCandidate(
                    display_name=place.display_name,
                    latitude=place.latitude,
                    longitude=place.longitude,
                    timezone=timezone,
                )
            )
        return results
