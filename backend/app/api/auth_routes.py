from fastapi import APIRouter, HTTPException, Response, status

from app.api.dependencies import (
    AuthServiceDependency,
    CurrentUserDependency,
    UserRepositoryDependency,
)
from app.application.auth_service import (
    AuthenticationResult,
    EmailAlreadyRegisteredError,
    InvalidActionTokenError,
    InvalidCredentialsError,
    InvalidRefreshTokenError,
)
from app.core.rate_limit import RateLimiterUnavailableError, get_auth_rate_limiter
from app.schemas.auth import (
    ActionTokenRequest,
    AuthenticationResponse,
    CredentialsRequest,
    EmailActionRequest,
    MessageResponse,
    PasswordResetRequest,
    RefreshTokenRequest,
    UserResponse,
)

router = APIRouter(prefix="/api/v1")
async def _check_rate_limit(email: str) -> None:
    try:
        allowed = await get_auth_rate_limiter().allow(email.strip().lower())
    except RateLimiterUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="认证服务暂时不可用，请稍后再试",
        ) from exc
    if not allowed:
        raise HTTPException(
            status_code=429,
            detail="请求过于频繁，请稍后再试",
            headers={"Retry-After": "900"},
        )


def _auth_response(result: AuthenticationResult) -> AuthenticationResponse:
    return AuthenticationResponse(
        access_token=result.access_token,
        expires_in=result.expires_in,
        refresh_token=result.refresh_token,
        refresh_expires_in=result.refresh_expires_in,
        user=UserResponse(
            id=str(result.user.id),
            email=result.user.email,
            email_verified=result.user.email_verified,
        ),
    )


@router.post("/auth/register", response_model=AuthenticationResponse, status_code=201)
async def register(
    payload: CredentialsRequest,
    service: AuthServiceDependency,
) -> AuthenticationResponse:
    await _check_rate_limit(str(payload.email))
    try:
        result = await service.register(str(payload.email), payload.password)
    except EmailAlreadyRegisteredError as exc:
        raise HTTPException(status_code=409, detail="该邮箱已注册") from exc
    return _auth_response(result)


@router.post("/auth/login", response_model=AuthenticationResponse)
async def login(
    payload: CredentialsRequest,
    service: AuthServiceDependency,
) -> AuthenticationResponse:
    await _check_rate_limit(str(payload.email))
    try:
        result = await service.authenticate(str(payload.email), payload.password)
    except InvalidCredentialsError as exc:
        raise HTTPException(status_code=401, detail="邮箱或密码错误") from exc
    return _auth_response(result)


@router.get("/users/me", response_model=UserResponse)
async def current_user(user: CurrentUserDependency) -> UserResponse:
    return UserResponse(id=str(user.id), email=user.email, email_verified=user.email_verified)


@router.post("/auth/refresh", response_model=AuthenticationResponse)
async def refresh_session(
    payload: RefreshTokenRequest,
    service: AuthServiceDependency,
) -> AuthenticationResponse:
    try:
        result = await service.refresh(payload.refresh_token)
    except InvalidRefreshTokenError as exc:
        raise HTTPException(status_code=401, detail="刷新令牌无效或已失效") from exc
    return _auth_response(result)


@router.post("/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout_session(
    payload: RefreshTokenRequest,
    service: AuthServiceDependency,
) -> Response:
    await service.revoke(payload.refresh_token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/auth/email-verification/request", response_model=MessageResponse)
async def request_email_verification(
    payload: EmailActionRequest, service: AuthServiceDependency
) -> MessageResponse:
    await _check_rate_limit(str(payload.email))
    await service.request_email_verification(str(payload.email))
    return MessageResponse(message="如果账户存在，验证邮件将很快发送")


@router.post("/auth/email-verification/confirm", response_model=UserResponse)
async def confirm_email_verification(
    payload: ActionTokenRequest, service: AuthServiceDependency
) -> UserResponse:
    try:
        user = await service.verify_email(payload.token)
    except InvalidActionTokenError as exc:
        raise HTTPException(status_code=400, detail="验证链接无效或已过期") from exc
    return UserResponse(id=str(user.id), email=user.email, email_verified=True)


@router.post("/auth/password-reset/request", response_model=MessageResponse)
async def request_password_reset(
    payload: EmailActionRequest, service: AuthServiceDependency
) -> MessageResponse:
    await _check_rate_limit(str(payload.email))
    await service.request_password_reset(str(payload.email))
    return MessageResponse(message="如果账户存在，重置邮件将很快发送")


@router.post("/auth/password-reset/confirm", response_model=MessageResponse)
async def confirm_password_reset(
    payload: PasswordResetRequest, service: AuthServiceDependency
) -> MessageResponse:
    try:
        await service.reset_password(payload.token, payload.new_password)
    except InvalidActionTokenError as exc:
        raise HTTPException(status_code=400, detail="重置链接无效或已过期") from exc
    return MessageResponse(message="密码已更新，请重新登录")


@router.delete("/users/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_current_user(
    user: CurrentUserDependency,
    repository: UserRepositoryDependency,
) -> Response:
    await repository.delete(user.id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
