import hashlib
import hmac
import secrets
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import jwt
from jwt import InvalidTokenError
from pwdlib import PasswordHash


class PasswordService:
    def __init__(self) -> None:
        self._password_hash = PasswordHash.recommended()

    def hash(self, password: str) -> str:
        return self._password_hash.hash(password)

    def verify(self, password: str, password_hash: str) -> bool:
        return self._password_hash.verify(password, password_hash)


class TokenService:
    def __init__(
        self,
        secret_key: str,
        issuer: str,
        audience: str,
        access_token_minutes: int,
    ) -> None:
        self._secret_key = secret_key
        self._issuer = issuer
        self._audience = audience
        self._access_token_minutes = access_token_minutes

    def create_access_token(self, user_id: UUID, session_id: UUID | None = None) -> tuple[str, int]:
        now = datetime.now(UTC)
        expires = now + timedelta(minutes=self._access_token_minutes)
        payload = {
            "sub": str(user_id),
            "iss": self._issuer,
            "aud": self._audience,
            "iat": now,
            "nbf": now,
            "exp": expires,
            "jti": str(uuid4()),
        }
        if session_id is not None:
            payload["sid"] = str(session_id)
        token = jwt.encode(
            payload,
            self._secret_key,
            algorithm="HS256",
        )
        return token, self._access_token_minutes * 60

    def decode_user_id(self, token: str) -> UUID | None:
        payload = self._decode(token)
        if payload is None:
            return None
        try:
            subject = payload["sub"]
            return UUID(subject) if isinstance(subject, str) else None
        except (KeyError, TypeError, ValueError):
            return None

    def decode_session_id(self, token: str) -> UUID | None:
        payload = self._decode(token)
        if payload is None:
            return None
        try:
            session_id = payload["sid"]
            return UUID(session_id) if isinstance(session_id, str) else None
        except (KeyError, TypeError, ValueError):
            return None

    def _decode(self, token: str) -> dict[str, object] | None:
        try:
            payload = jwt.decode(
                token,
                self._secret_key,
                algorithms=["HS256"],
                issuer=self._issuer,
                audience=self._audience,
                options={"require": ["sub", "iss", "aud", "exp", "nbf", "jti"]},
            )
            return payload
        except InvalidTokenError:
            return None

    def create_refresh_token(self) -> tuple[str, str]:
        token = secrets.token_urlsafe(48)
        return token, self.hash_opaque_token(token)

    @staticmethod
    def hash_opaque_token(token: str) -> str:
        return hashlib.sha256(token.encode()).hexdigest()


class SafetyIdentifierService:
    def __init__(self, secret: str) -> None:
        self._secret = secret.encode()

    def for_user(self, user_id: UUID) -> str:
        return hmac.new(self._secret, str(user_id).encode(), hashlib.sha256).hexdigest()
