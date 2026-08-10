from collections.abc import Sequence
from typing import Protocol


class GeocodedPlace(Protocol):
    @property
    def display_name(self) -> str: ...

    @property
    def latitude(self) -> float: ...

    @property
    def longitude(self) -> float: ...


class Geocoder(Protocol):
    async def search(self, query: str, limit: int) -> Sequence[GeocodedPlace]: ...


class TimezoneResolver(Protocol):
    async def resolve(self, latitude: float, longitude: float) -> str | None: ...
