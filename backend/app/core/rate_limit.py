from collections import defaultdict, deque
from datetime import UTC, datetime, timedelta


class SlidingWindowRateLimiter:
    def __init__(self, limit: int = 5, window_minutes: int = 15) -> None:
        self._limit = limit
        self._window = timedelta(minutes=window_minutes)
        self._attempts: dict[str, deque[datetime]] = defaultdict(deque)

    def allow(self, key: str) -> bool:
        now = datetime.now(UTC)
        attempts = self._attempts[key]
        while attempts and attempts[0] <= now - self._window:
            attempts.popleft()
        if len(attempts) >= self._limit:
            return False
        attempts.append(now)
        return True
