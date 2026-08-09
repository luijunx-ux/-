from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True, slots=True)
class BirthData:
    occurred_at: datetime
    place_name: str
    latitude: float
    longitude: float
    timezone: str


@dataclass(frozen=True, slots=True)
class ZodiacInfo:
    sign: str
    element: str
    modality: str


@dataclass(frozen=True, slots=True)
class WuyunLiuqiInfo:
    year: int
    heavenly_stem: str
    earthly_branch: str
    middle_movement: str
    movement_strength: str
    governing_qi: str
    responding_qi: str
    algorithm_version: str
    boundary_warning: str | None


@dataclass(frozen=True, slots=True)
class LifeProfile:
    birth: BirthData
    zodiac: ZodiacInfo
    wuyun_liuqi: WuyunLiuqiInfo
