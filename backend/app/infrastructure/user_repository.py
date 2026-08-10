from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.user import User
from app.infrastructure.orm import (
    AccountActionTokenRecord,
    AuthSecurityEventRecord,
    RefreshTokenRecord,
    UserRecord,
)


class SqlAlchemyUserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create(self, email: str, password_hash: str) -> User:
        record = UserRecord(email=email, password_hash=password_hash)
        self._session.add(record)
        await self._session.commit()
        await self._session.refresh(record)
        return self._to_domain(record)

    async def get_by_email(self, email: str) -> User | None:
        result = await self._session.execute(select(UserRecord).where(UserRecord.email == email))
        record = result.scalar_one_or_none()
        return None if record is None else self._to_domain(record)

    async def get_by_id(self, user_id: UUID) -> User | None:
        record = await self._session.get(UserRecord, user_id)
        return None if record is None else self._to_domain(record)

    async def delete(self, user_id: UUID) -> bool:
        record = await self._session.get(UserRecord, user_id)
        if record is None:
            return False
        await self._session.delete(record)
        await self._session.commit()
        return True

    async def create_refresh_token(
        self, user_id: UUID, token_hash: str, expires_at: datetime
    ) -> None:
        self._session.add(
            RefreshTokenRecord(user_id=user_id, token_hash=token_hash, expires_at=expires_at)
        )
        await self._session.commit()

    async def consume_refresh_token(self, token_hash: str) -> User | None:
        record = await self._session.scalar(
            select(RefreshTokenRecord).where(RefreshTokenRecord.token_hash == token_hash)
        )
        now = datetime.now(UTC)
        if (
            record is None
            or record.consumed_at is not None
            or record.revoked_at is not None
            or record.expires_at <= now
        ):
            return None
        record.consumed_at = now
        user = await self._session.get(UserRecord, record.user_id)
        await self._session.commit()
        return None if user is None else self._to_domain(user)

    async def revoke_refresh_token(self, token_hash: str) -> bool:
        record = await self._session.scalar(
            select(RefreshTokenRecord).where(RefreshTokenRecord.token_hash == token_hash)
        )
        if record is None or record.revoked_at is not None:
            return False
        record.revoked_at = datetime.now(UTC)
        await self._session.commit()
        return True

    async def set_email_verified(self, user_id: UUID) -> User | None:
        record = await self._session.get(UserRecord, user_id)
        if record is None:
            return None
        record.email_verified = True
        await self._session.commit()
        return self._to_domain(record)

    async def update_password(self, user_id: UUID, password_hash: str) -> bool:
        record = await self._session.get(UserRecord, user_id)
        if record is None:
            return False
        record.password_hash = password_hash
        await self._session.commit()
        return True

    async def create_action_token(
        self, user_id: UUID, purpose: str, token_hash: str, expires_at: datetime
    ) -> None:
        self._session.add(
            AccountActionTokenRecord(
                user_id=user_id,
                purpose=purpose,
                token_hash=token_hash,
                expires_at=expires_at,
            )
        )
        await self._session.commit()

    async def consume_action_token(self, purpose: str, token_hash: str) -> User | None:
        record = await self._session.scalar(
            select(AccountActionTokenRecord).where(
                AccountActionTokenRecord.purpose == purpose,
                AccountActionTokenRecord.token_hash == token_hash,
            )
        )
        now = datetime.now(UTC)
        if record is None or record.consumed_at is not None or record.expires_at <= now:
            return None
        record.consumed_at = now
        user = await self._session.get(UserRecord, record.user_id)
        await self._session.commit()
        return None if user is None else self._to_domain(user)

    async def record_security_event(
        self, event_type: str, subject_hash: str, succeeded: bool
    ) -> None:
        self._session.add(
            AuthSecurityEventRecord(
                event_type=event_type,
                subject_hash=subject_hash,
                succeeded=succeeded,
            )
        )
        await self._session.commit()

    def _to_domain(self, record: UserRecord) -> User:
        return User(
            id=record.id,
            email=record.email,
            password_hash=record.password_hash,
            email_verified=record.email_verified,
        )
