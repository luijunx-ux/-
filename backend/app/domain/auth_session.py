from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

@dataclass(frozen=True, slots=True)
class AuthSession:
    id: UUID
    created_at: datetime
    expires_at: datetime
