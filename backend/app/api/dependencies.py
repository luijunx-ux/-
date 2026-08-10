from collections.abc import AsyncIterator
from functools import lru_cache
from pathlib import Path
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.advice_agent import DailyAdviceAgent
from app.application.auth_service import AuthService
from app.application.email_sender import DevelopmentLogEmailSender
from app.application.location_service import LocationSearchService
from app.core.config import get_settings
from app.core.security import PasswordService, TokenService
from app.domain.advice_history import AdviceHistoryRepository
from app.domain.repositories import LifeProfileRepository
from app.domain.user import User
from app.domain.user_repository import UserRepository
from app.infrastructure.advice_audit_logger import LoggingAdviceAuditSink
from app.infrastructure.advice_history_repository import SqlAlchemyAdviceHistoryRepository
from app.infrastructure.database import get_session
from app.infrastructure.markdown_retriever import MarkdownKnowledgeRetriever
from app.infrastructure.nominatim import NominatimGeocoder
from app.infrastructure.openai_advice_generator import OpenAIAdviceGenerator
from app.infrastructure.profile_repository import SqlAlchemyLifeProfileRepository
from app.infrastructure.timezone_resolver import OfflineTimezoneResolver
from app.infrastructure.user_repository import SqlAlchemyUserRepository


async def get_profile_repository(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> AsyncIterator[LifeProfileRepository]:
    yield SqlAlchemyLifeProfileRepository(session)


ProfileRepositoryDependency = Annotated[LifeProfileRepository, Depends(get_profile_repository)]


async def get_advice_history_repository(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> AsyncIterator[AdviceHistoryRepository]:
    yield SqlAlchemyAdviceHistoryRepository(session)


AdviceHistoryRepositoryDependency = Annotated[
    AdviceHistoryRepository, Depends(get_advice_history_repository)
]


async def get_user_repository(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> AsyncIterator[UserRepository]:
    yield SqlAlchemyUserRepository(session)


UserRepositoryDependency = Annotated[UserRepository, Depends(get_user_repository)]


def get_auth_service(repository: UserRepositoryDependency) -> AuthService:
    settings = get_settings()
    return AuthService(
        repository=repository,
        passwords=PasswordService(),
        tokens=TokenService(
            secret_key=settings.jwt_secret_key.get_secret_value(),
            issuer=settings.jwt_issuer,
            audience=settings.jwt_audience,
            access_token_minutes=settings.jwt_access_token_minutes,
        ),
        refresh_token_days=settings.refresh_token_days,
        email_sender=(
            DevelopmentLogEmailSender() if settings.app_env.lower() == "development" else None
        ),
    )


AuthServiceDependency = Annotated[AuthService, Depends(get_auth_service)]
_bearer = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    repository: UserRepositoryDependency,
) -> User:
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效或已过期的访问令牌",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None:
        raise unauthorized
    settings = get_settings()
    tokens = TokenService(
        secret_key=settings.jwt_secret_key.get_secret_value(),
        issuer=settings.jwt_issuer,
        audience=settings.jwt_audience,
        access_token_minutes=settings.jwt_access_token_minutes,
    )
    user_id = tokens.decode_user_id(credentials.credentials)
    if user_id is None:
        raise unauthorized
    user = await repository.get_by_id(user_id)
    if user is None:
        raise unauthorized
    return user


CurrentUserDependency = Annotated[User, Depends(get_current_user)]


async def get_optional_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    repository: UserRepositoryDependency,
) -> User | None:
    if credentials is None:
        return None
    settings = get_settings()
    tokens = TokenService(
        secret_key=settings.jwt_secret_key.get_secret_value(),
        issuer=settings.jwt_issuer,
        audience=settings.jwt_audience,
        access_token_minutes=settings.jwt_access_token_minutes,
    )
    user_id = tokens.decode_user_id(credentials.credentials)
    user = None if user_id is None else await repository.get_by_id(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效或已过期的访问令牌",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


OptionalCurrentUserDependency = Annotated[User | None, Depends(get_optional_current_user)]


@lru_cache
def get_location_service() -> LocationSearchService:
    settings = get_settings()
    return LocationSearchService(
        geocoder=NominatimGeocoder(
            base_url=settings.geocoding_base_url,
            user_agent=settings.geocoding_user_agent,
            cache_seconds=settings.geocoding_cache_seconds,
        ),
        timezone_resolver=OfflineTimezoneResolver(),
    )


LocationServiceDependency = Annotated[LocationSearchService, Depends(get_location_service)]


@lru_cache
def get_advice_agent() -> DailyAdviceAgent:
    settings = get_settings()
    knowledge_directory = Path(__file__).resolve().parents[3] / "ai" / "rag" / "knowledge"
    retriever = MarkdownKnowledgeRetriever(knowledge_directory)
    generator = None
    if settings.ai_enabled and settings.llm_api_key is not None:
        generator = OpenAIAdviceGenerator(
            api_key=settings.llm_api_key.get_secret_value(),
            base_url=settings.llm_base_url,
            model=settings.llm_model,
            reasoning_effort=settings.llm_reasoning_effort,
            timeout_seconds=settings.llm_timeout_seconds,
        )
    return DailyAdviceAgent(
        retriever=retriever,
        generator=generator,
        audit_sink=LoggingAdviceAuditSink(),
    )


AdviceAgentDependency = Annotated[DailyAdviceAgent, Depends(get_advice_agent)]
