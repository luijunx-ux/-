import hashlib
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from app.application.email_sender import AccountEmailSender
from app.core.security import PasswordService, TokenService
from app.domain.user import User
from app.domain.user_repository import UserRepository


class EmailAlreadyRegisteredError(Exception):
    pass


class InvalidCredentialsError(Exception):
    pass


class InvalidRefreshTokenError(Exception):
    pass


class InvalidActionTokenError(Exception):
    pass


@dataclass(frozen=True, slots=True)
class AuthenticationResult:
    user: User
    access_token: str
    expires_in: int
    refresh_token: str
    refresh_expires_in: int


class AuthService:
    def __init__(
        self,
        repository: UserRepository,
        passwords: PasswordService,
        tokens: TokenService,
        refresh_token_days: int = 30,
        email_sender: AccountEmailSender | None = None,
    ) -> None:
        self._repository = repository
        self._passwords = passwords
        self._tokens = tokens
        self._refresh_token_days = refresh_token_days
        self._email_sender = email_sender

    async def register(self, email: str, password: str) -> AuthenticationResult:
        normalized = email.strip().lower()
        if await self._repository.get_by_email(normalized) is not None:
            raise EmailAlreadyRegisteredError
        user = await self._repository.create(normalized, self._passwords.hash(password))
        return await self._result(user)

    async def authenticate(self, email: str, password: str) -> AuthenticationResult:
        normalized = email.strip().lower()
        subject_hash = hashlib.sha256(normalized.encode()).hexdigest()
        user = await self._repository.get_by_email(normalized)
        if user is None or not self._passwords.verify(password, user.password_hash):
            await self._repository.record_security_event("login", subject_hash, False)
            raise InvalidCredentialsError
        await self._repository.record_security_event("login", subject_hash, True)
        return await self._result(user)

    async def refresh(self, refresh_token: str) -> AuthenticationResult:
        token_hash = self._tokens.hash_opaque_token(refresh_token)
        user = await self._repository.consume_refresh_token(token_hash)
        if user is None:
            raise InvalidRefreshTokenError
        return await self._result(user)

    async def revoke(self, refresh_token: str) -> None:
        await self._repository.revoke_refresh_token(self._tokens.hash_opaque_token(refresh_token))

    async def _result(self, user: User) -> AuthenticationResult:
        refresh_token, token_hash = self._tokens.create_refresh_token()
        refresh_seconds = self._refresh_token_days * 24 * 60 * 60
        session_id = await self._repository.create_refresh_token(
            user.id,
            token_hash,
            datetime.now(UTC) + timedelta(seconds=refresh_seconds),
        )
        token, expires_in = self._tokens.create_access_token(user.id, session_id)
        return AuthenticationResult(user, token, expires_in, refresh_token, refresh_seconds)

    async def request_email_verification(self, email: str) -> None:
        await self._request_action(email, "email_verification", 24)

    async def verify_email(self, token: str) -> User:
        user = await self._consume_action("email_verification", token)
        updated = await self._repository.set_email_verified(user.id)
        assert updated is not None
        return updated

    async def request_password_reset(self, email: str) -> None:
        await self._request_action(email, "password_reset", 1)

    async def reset_password(self, token: str, new_password: str) -> None:
        user = await self._consume_action("password_reset", token)
        await self._repository.update_password(user.id, self._passwords.hash(new_password))

    async def _request_action(self, email: str, purpose: str, hours: int) -> None:
        normalized = email.strip().lower()
        user = await self._repository.get_by_email(normalized)
        if user is None or self._email_sender is None:
            return
        token, token_hash = self._tokens.create_refresh_token()
        await self._repository.create_action_token(
            user.id,
            purpose,
            token_hash,
            datetime.now(UTC) + timedelta(hours=hours),
        )
        await self._email_sender.send_action_token(user.email, purpose, token)

    async def _consume_action(self, purpose: str, token: str) -> User:
        user = await self._repository.consume_action_token(
            purpose, self._tokens.hash_opaque_token(token)
        )
        if user is None:
            raise InvalidActionTokenError
        return user
