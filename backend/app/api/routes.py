from dataclasses import asdict
from datetime import date
from typing import Annotated
from uuid import UUID

import httpx
from fastapi import APIRouter, HTTPException, Query, status

from app.api.dependencies import (
    AdviceAgentDependency,
    AdviceHistoryRepositoryDependency,
    CurrentUserDependency,
    LocationServiceDependency,
    OptionalCurrentUserDependency,
    ProfileRepositoryDependency,
)
from app.application.persistent_profile_service import (
    create_profile,
    delete_profile,
    get_stored_profile,
    list_profiles,
    update_profile,
)
from app.application.profile_service import build_life_profile
from app.core.config import get_settings
from app.core.security import SafetyIdentifierService
from app.domain.advice_history import StoredDailyAdvice
from app.domain.models import BirthData
from app.schemas.profile import (
    AdviceFeedbackRequest,
    AdviceStatsResponse,
    BirthDataRequest,
    DailyAdviceRequest,
    DailyAdviceResponse,
    LocationCandidateResponse,
    ProfileAdviceRequest,
    ProfileCreateRequest,
    ProfileResponse,
    ProfileUpdateRequest,
    StoredDailyAdviceResponse,
    StoredProfileResponse,
)

router = APIRouter(prefix="/api/v1")
DISCLAIMER = "内容仅用于个人节律观察与一般生活参考，不构成医疗诊断或治疗建议。"


@router.get("/locations/search", response_model=list[LocationCandidateResponse])
async def search_locations(
    service: LocationServiceDependency,
    query: str = Query(alias="q", min_length=2, max_length=100),
) -> list[LocationCandidateResponse]:
    try:
        results = await service.search(query)
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="地点搜索服务暂时不可用",
        ) from exc
    return [
        LocationCandidateResponse.model_validate(result, from_attributes=True) for result in results
    ]


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
    payload: ProfileCreateRequest,
    repository: ProfileRepositoryDependency,
    user: CurrentUserDependency,
) -> StoredProfileResponse:
    profile_id, profile, is_default = await create_profile(
        repository, _birth(payload), user.id, payload.name, payload.is_default
    )
    return StoredProfileResponse(
        id=profile_id,
        name=payload.name,
        is_default=is_default,
        profile=asdict(profile),
        disclaimer=DISCLAIMER,
    )


@router.get("/profiles", response_model=list[StoredProfileResponse])
async def read_profiles(
    repository: ProfileRepositoryDependency,
    user: CurrentUserDependency,
) -> list[StoredProfileResponse]:
    profiles = await list_profiles(repository, user.id)
    return [
        StoredProfileResponse(
            id=profile_id,
            name=name,
            is_default=is_default,
            profile=asdict(profile),
            disclaimer=DISCLAIMER,
        )
        for profile_id, profile, name, is_default in profiles
    ]


@router.get("/profiles/{profile_id}", response_model=StoredProfileResponse)
async def read_profile(
    profile_id: UUID,
    repository: ProfileRepositoryDependency,
    user: CurrentUserDependency,
) -> StoredProfileResponse:
    stored = await get_stored_profile(repository, profile_id, user.id)
    if stored is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="生命档案不存在")
    profile, name, is_default = stored
    return StoredProfileResponse(
        id=profile_id,
        name=name,
        is_default=is_default,
        profile=asdict(profile),
        disclaimer=DISCLAIMER,
    )


@router.put("/profiles/{profile_id}", response_model=StoredProfileResponse)
async def replace_profile(
    profile_id: UUID,
    payload: ProfileUpdateRequest,
    repository: ProfileRepositoryDependency,
    user: CurrentUserDependency,
) -> StoredProfileResponse:
    profile = await update_profile(
        repository,
        profile_id,
        user.id,
        _birth(payload),
        payload.name,
        payload.is_default,
    )
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="生命档案不存在")
    stored = await get_stored_profile(repository, profile_id, user.id)
    assert stored is not None
    _, name, is_default = stored
    return StoredProfileResponse(
        id=profile_id,
        name=name,
        is_default=is_default,
        profile=asdict(profile),
        disclaimer=DISCLAIMER,
    )


@router.delete("/profiles/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_profile(
    profile_id: UUID,
    repository: ProfileRepositoryDependency,
    user: CurrentUserDependency,
) -> None:
    deleted = await delete_profile(repository, profile_id, user.id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="生命档案不存在")


@router.post("/advice/daily", response_model=DailyAdviceResponse)
async def daily_advice(
    payload: DailyAdviceRequest,
    agent: AdviceAgentDependency,
    user: OptionalCurrentUserDependency,
) -> DailyAdviceResponse:
    profile = build_life_profile(_birth(payload))
    safety_identifier = None
    if user is not None:
        safety_identifier = SafetyIdentifierService(
            get_settings().safety_identifier_secret.get_secret_value()
        ).for_user(user.id)
    result = await agent.run(profile, payload.target_date, safety_identifier)
    return DailyAdviceResponse(
        target_date=payload.target_date,
        advice=result.items,
        disclaimer=DISCLAIMER,
        generation_mode=result.generation_mode,
        model=result.model,
        knowledge_sources=result.knowledge_sources,
        request_id=result.request_id,
        input_tokens=result.input_tokens,
        output_tokens=result.output_tokens,
    )


def _stored_advice_response(
    stored: StoredDailyAdvice, *, cached: bool
) -> StoredDailyAdviceResponse:
    result = stored.result
    return StoredDailyAdviceResponse(
        id=stored.id,
        profile_id=stored.profile_id,
        target_date=stored.target_date,
        advice=result.items,
        disclaimer=DISCLAIMER,
        generation_mode=result.generation_mode,
        model=result.model,
        knowledge_sources=result.knowledge_sources,
        request_id=result.request_id,
        input_tokens=result.input_tokens,
        output_tokens=result.output_tokens,
        cached=cached,
        helpful=stored.helpful,
    )


@router.post(
    "/profiles/{profile_id}/advice/daily",
    response_model=StoredDailyAdviceResponse,
)
async def profile_daily_advice(
    profile_id: UUID,
    payload: ProfileAdviceRequest,
    agent: AdviceAgentDependency,
    history: AdviceHistoryRepositoryDependency,
    profiles: ProfileRepositoryDependency,
    user: CurrentUserDependency,
) -> StoredDailyAdviceResponse:
    stored_profile = await get_stored_profile(profiles, profile_id, user.id)
    if stored_profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="生命档案不存在")
    cached = await history.get_for_date(user.id, profile_id, payload.target_date)
    if cached is not None:
        return _stored_advice_response(cached, cached=True)
    profile, _, _ = stored_profile
    safety_identifier = SafetyIdentifierService(
        get_settings().safety_identifier_secret.get_secret_value()
    ).for_user(user.id)
    result = await agent.run(profile, payload.target_date, safety_identifier)
    stored = await history.add(user.id, profile_id, payload.target_date, result)
    return _stored_advice_response(stored, cached=False)


@router.get("/advice/history", response_model=list[StoredDailyAdviceResponse])
async def advice_history(
    history: AdviceHistoryRepositoryDependency,
    user: CurrentUserDependency,
    limit: int = Query(default=30, ge=1, le=100),
) -> list[StoredDailyAdviceResponse]:
    records = await history.list_for_owner(user.id, limit)
    return [_stored_advice_response(record, cached=True) for record in records]


@router.put(
    "/advice/{advice_id}/feedback",
    response_model=StoredDailyAdviceResponse,
)
async def set_advice_feedback(
    advice_id: UUID,
    payload: AdviceFeedbackRequest,
    history: AdviceHistoryRepositoryDependency,
    user: CurrentUserDependency,
) -> StoredDailyAdviceResponse:
    stored = await history.set_feedback(advice_id, user.id, payload.helpful)
    if stored is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="每日建议不存在")
    return _stored_advice_response(stored, cached=True)


@router.get("/advice/stats", response_model=AdviceStatsResponse)
async def advice_stats(
    history: AdviceHistoryRepositoryDependency,
    user: CurrentUserDependency,
    through_date: Annotated[date, Query()],
) -> AdviceStatsResponse:
    streak = await history.viewing_streak(user.id, through_date)
    return AdviceStatsResponse(viewing_streak=streak)
