from dataclasses import asdict
from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.api.dependencies import ProfileRepositoryDependency
from app.application.persistent_profile_service import create_profile, get_profile
from app.application.profile_service import build_life_profile, generate_daily_advice
from app.domain.models import BirthData
from app.schemas.profile import (
    BirthDataRequest,
    DailyAdviceRequest,
    DailyAdviceResponse,
    ProfileResponse,
    StoredProfileResponse,
)

router = APIRouter(prefix="/api/v1")
DISCLAIMER = "内容仅用于个人节律观察与一般生活参考，不构成医疗诊断或治疗建议。"


def _birth(payload: BirthDataRequest) -> BirthData:
    return BirthData(
        occurred_at=payload.occurred_at,
        place_name=payload.place_name,
        latitude=payload.latitude,
        longitude=payload.longitude,
        timezone=payload.timezone,
    )


@router.post("/profiles/generate", response_model=ProfileResponse)
def generate_profile(payload: BirthDataRequest) -> ProfileResponse:
    return ProfileResponse(
        profile=asdict(build_life_profile(_birth(payload))), disclaimer=DISCLAIMER
    )


@router.post(
    "/profiles",
    response_model=StoredProfileResponse,
    status_code=status.HTTP_201_CREATED,
)
async def store_profile(
    payload: BirthDataRequest,
    repository: ProfileRepositoryDependency,
) -> StoredProfileResponse:
    profile_id, profile = await create_profile(repository, _birth(payload))
    return StoredProfileResponse(id=profile_id, profile=asdict(profile), disclaimer=DISCLAIMER)


@router.get("/profiles/{profile_id}", response_model=StoredProfileResponse)
async def read_profile(
    profile_id: UUID,
    repository: ProfileRepositoryDependency,
) -> StoredProfileResponse:
    profile = await get_profile(repository, profile_id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="生命档案不存在")
    return StoredProfileResponse(id=profile_id, profile=asdict(profile), disclaimer=DISCLAIMER)


@router.post("/advice/daily", response_model=DailyAdviceResponse)
def daily_advice(payload: DailyAdviceRequest) -> DailyAdviceResponse:
    profile = build_life_profile(_birth(payload))
    return DailyAdviceResponse(
        target_date=payload.target_date,
        advice=generate_daily_advice(profile, payload.target_date),
        disclaimer=DISCLAIMER,
    )
