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


class ProfileResponse(BaseModel):
    profile: dict[str, Any]
    disclaimer: str


class StoredProfileResponse(ProfileResponse):
    id: UUID


class DailyAdviceResponse(BaseModel):
    target_date: date
    advice: list[str]
    disclaimer: str
