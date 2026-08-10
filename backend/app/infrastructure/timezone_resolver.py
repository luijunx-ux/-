import asyncio
from threading import Lock

from timezonefinder import TimezoneFinder


class OfflineTimezoneResolver:
    def __init__(self) -> None:
        self._finder = TimezoneFinder(in_memory=True)
        self._lock = Lock()

    async def resolve(self, latitude: float, longitude: float) -> str | None:
        return await asyncio.to_thread(self._resolve_sync, latitude, longitude)

    def _resolve_sync(self, latitude: float, longitude: float) -> str | None:
        with self._lock:
            return self._finder.timezone_at(lng=longitude, lat=latitude)
