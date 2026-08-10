from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class LocationCandidate:
    display_name: str
    latitude: float
    longitude: float
    timezone: str
