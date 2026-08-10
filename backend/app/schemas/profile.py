from datetime import date, datetime
from typing import Any
from uuid import UUID
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, Field, field_validator


class BirthDataRequest(BaseModel):
    occurred_at: datetime
    place_name: str = Field(min_length=1, max_length=200)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    timezone: str

    @field_validator("occurred_at")
    @classmethod
    def require_timezone(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() is None:
            raise ValueError("出生时间必须包含 UTC 偏移")
        return value

    @field_validator("timezone")
    @classmethod
    def validate_timezone(cls, value: str) -> str:
        try:
            ZoneInfo(value)
        except ZoneInfoNotFoundError as exc:
            raise ValueError("必须使用有效的 IANA 时区名称") from exc
        return value


class DailyAdviceRequest(BirthDataRequest):
    target_date: date


class ProfileAdviceRequest(BaseModel):
    target_date: date


class AdviceFeedbackRequest(BaseModel):
    helpful: bool


class ProfileCreateRequest(BirthDataRequest):
    name: str = Field(default="我的生命档案", min_length=1, max_length=80)
    is_default: bool = False


class ProfileUpdateRequest(BirthDataRequest):
    name: str = Field(min_length=1, max_length=80)
    is_default: bool = False


class ProfileResponse(BaseModel):
    profile: dict[str, Any]
    disclaimer: str


class StoredProfileResponse(ProfileResponse):
    id: UUID
    name: str
    is_default: bool


class DailyAdviceResponse(BaseModel):
    target_date: date
    advice: list[str]
    disclaimer: str
    generation_mode: str
    model: str | None = None
    knowledge_sources: list[str] = Field(default_factory=list)
    request_id: str
    input_tokens: int = 0
    output_tokens: int = 0


class StoredDailyAdviceResponse(DailyAdviceResponse):
    id: UUID
    profile_id: UUID
    cached: bool = False
    helpful: bool | None = None


class AdviceStatsResponse(BaseModel):
    viewing_streak: int


class LocationCandidateResponse(BaseModel):
    display_name: str
    latitude: float
    longitude: float
    timezone: str
