import unittest
from datetime import datetime
from uuid import UUID, uuid4

from pydantic import ValidationError

from app.application.auth_service import (
    AuthService,
    EmailAlreadyRegisteredError,
    InvalidActionTokenError,
    InvalidCredentialsError,
    InvalidRefreshTokenError,
)
from app.core.config import Settings
from app.core.security import PasswordService, SafetyIdentifierService, TokenService
from app.domain.auth_session import AuthSession
from app.domain.user import User


class InMemoryUserRepository:
    def __init__(self) -> None:
        self.users: dict[UUID, User] = {}
        self.refresh_tokens: dict[str, tuple[UUID, UUID]] = {}
        self.sessions: dict[UUID, tuple[UUID, datetime]] = {}
        self.action_tokens: dict[tuple[str, str], UUID] = {}

    async def create(self, email: str, password_hash: str) -> User:
        user = User(id=uuid4(), email=email, password_hash=password_hash)
        self.users[user.id] = user
        return user

    async def get_by_email(self, email: str) -> User | None:
        return next((user for user in self.users.values() if user.email == email), None)

    async def get_by_id(self, user_id: UUID) -> User | None:
        return self.users.get(user_id)

    async def delete(self, user_id: UUID) -> bool:
        return self.users.pop(user_id, None) is not None

    async def create_refresh_token(
        self, user_id: UUID, token_hash: str, expires_at: datetime
    ) -> UUID:
        session_id = uuid4()
        self.refresh_tokens[token_hash] = (user_id, session_id)
        self.sessions[session_id] = (user_id, expires_at)
        return session_id

    async def consume_refresh_token(self, token_hash: str) -> User | None:
        token = self.refresh_tokens.pop(token_hash, None)
        if token is None:
            return None
        user_id, session_id = token
        self.sessions.pop(session_id, None)
        return self.users.get(user_id)

    async def revoke_refresh_token(self, token_hash: str) -> bool:
        token = self.refresh_tokens.pop(token_hash, None)
        if token is None:
            return False
        self.sessions.pop(token[1], None)
        return True

    async def list_active_sessions(self, user_id: UUID) -> list[AuthSession]:
        return [
            AuthSession(id=session_id, created_at=expires_at, expires_at=expires_at)
            for session_id, (owner_id, expires_at) in self.sessions.items()
            if owner_id == user_id
        ]

    async def is_session_active(self, user_id: UUID, session_id: UUID) -> bool:
        session = self.sessions.get(session_id)
        return session is not None and session[0] == user_id

    async def revoke_other_sessions(self, user_id: UUID, current_session_id: UUID) -> int:
        session_ids = [
            session_id
            for session_id, (owner_id, _) in self.sessions.items()
            if owner_id == user_id and session_id != current_session_id
        ]
        for session_id in session_ids:
            self.sessions.pop(session_id)
        return len(session_ids)

    async def set_email_verified(self, user_id: UUID) -> User | None:
        user = self.users.get(user_id)
        if user is None:
            return None
        updated = User(user.id, user.email, user.password_hash, True)
        self.users[user_id] = updated
        return updated

    async def update_password(self, user_id: UUID, password_hash: str) -> bool:
        user = self.users.get(user_id)
        if user is None:
            return False
        self.users[user_id] = User(user.id, user.email, password_hash, user.email_verified)
        return True

    async def create_action_token(
        self, user_id: UUID, purpose: str, token_hash: str, expires_at: datetime
    ) -> None:
        self.action_tokens[(purpose, token_hash)] = user_id

    async def consume_action_token(self, purpose: str, token_hash: str) -> User | None:
        user_id = self.action_tokens.pop((purpose, token_hash), None)
        return None if user_id is None else self.users.get(user_id)

    async def record_security_event(
        self, event_type: str, subject_hash: str, succeeded: bool
    ) -> None:
        return None


class CapturingEmailSender:
    def __init__(self) -> None:
        self.tokens: dict[str, str] = {}

    async def send_action_token(self, email: str, purpose: str, token: str) -> None:
        self.tokens[purpose] = token


def token_service(audience: str = "mobile") -> TokenService:
    return TokenService(
        secret_key="a-test-secret-that-is-long-enough-for-hs256",
        issuer="test-api",
        audience=audience,
        access_token_minutes=30,
    )


class AuthenticationTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        self.repository = InMemoryUserRepository()
        self.service = AuthService(
            self.repository,
            PasswordService(),
            token_service(),
        )

    async def test_register_hashes_password_and_returns_valid_token(self) -> None:
        result = await self.service.register(" USER@Example.com ", "long-password-123")

        self.assertEqual(result.user.email, "user@example.com")
        self.assertNotEqual(result.user.password_hash, "long-password-123")
        self.assertEqual(token_service().decode_user_id(result.access_token), result.user.id)
        self.assertIsNotNone(token_service().decode_session_id(result.access_token))

    async def test_duplicate_registration_is_rejected(self) -> None:
        await self.service.register("user@example.com", "long-password-123")
        with self.assertRaises(EmailAlreadyRegisteredError):
            await self.service.register("USER@example.com", "another-password-456")

    async def test_invalid_password_uses_generic_failure(self) -> None:
        await self.service.register("user@example.com", "long-password-123")
        with self.assertRaises(InvalidCredentialsError):
            await self.service.authenticate("user@example.com", "wrong-password")

    async def test_refresh_token_is_rotated_and_cannot_be_reused(self) -> None:
        registered = await self.service.register("user@example.com", "long-password-123")

        refreshed = await self.service.refresh(registered.refresh_token)

        self.assertNotEqual(refreshed.refresh_token, registered.refresh_token)
        with self.assertRaises(InvalidRefreshTokenError):
            await self.service.refresh(registered.refresh_token)

    async def test_delete_removes_account(self) -> None:
        result = await self.service.register("user@example.com", "long-password-123")
        self.assertTrue(await self.repository.delete(result.user.id))
        self.assertIsNone(await self.repository.get_by_id(result.user.id))

    async def test_token_rejects_wrong_audience(self) -> None:
        result = await self.service.register("user@example.com", "long-password-123")
        self.assertIsNone(token_service("other-audience").decode_user_id(result.access_token))

    async def test_safety_identifier_is_stable_and_pseudonymous(self) -> None:
        user_id = uuid4()
        identifiers = SafetyIdentifierService("separate-secret")
        value = identifiers.for_user(user_id)

        self.assertEqual(value, identifiers.for_user(user_id))
        self.assertNotIn(str(user_id), value)
        self.assertEqual(len(value), 64)

    async def test_production_rejects_development_secrets(self) -> None:
        with self.assertRaises(ValidationError):
            Settings(app_env="production")

    async def test_email_verification_and_password_reset_tokens_are_one_time(self) -> None:
        sender = CapturingEmailSender()
        service = AuthService(
            self.repository, PasswordService(), token_service(), email_sender=sender
        )
        registered = await service.register("user@example.com", "long-password-123")
        await service.request_email_verification(registered.user.email)
        verified = await service.verify_email(sender.tokens["email_verification"])
        self.assertTrue(verified.email_verified)
        with self.assertRaises(InvalidActionTokenError):
            await service.verify_email(sender.tokens["email_verification"])

        await service.request_password_reset(registered.user.email)
        await service.reset_password(sender.tokens["password_reset"], "new-long-password-456")
        authenticated = await service.authenticate(registered.user.email, "new-long-password-456")
        self.assertEqual(authenticated.user.id, registered.user.id)
