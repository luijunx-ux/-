import logging
from typing import Protocol

logger = logging.getLogger("tianrenlu.auth_email")


class AccountEmailSender(Protocol):
    async def send_action_token(self, email: str, purpose: str, token: str) -> None: ...


class DevelopmentLogEmailSender:
    async def send_action_token(self, email: str, purpose: str, token: str) -> None:
        logger.warning(
            "development_account_email",
            extra={"recipient": email, "purpose": purpose, "action_token": token},
        )
