import logging
import smtplib
from asyncio import to_thread
from email.message import EmailMessage
from typing import Protocol
from urllib.parse import urlencode

logger = logging.getLogger("tianrenlu.auth_email")


class AccountEmailSender(Protocol):
    async def send_action_token(self, email: str, purpose: str, token: str) -> None: ...


class DevelopmentLogEmailSender:
    def __init__(self, public_url: str) -> None:
        self._public_url = public_url.rstrip("/")

    async def send_action_token(self, email: str, purpose: str, token: str) -> None:
        link = _action_link(self._public_url, purpose, token)
        logger.warning(
            "development_account_email",
            extra={"recipient": email, "purpose": purpose, "action_link": link},
        )


class SmtpAccountEmailSender:
    def __init__(
        self,
        *,
        host: str,
        port: int,
        username: str | None,
        password: str | None,
        from_email: str,
        public_url: str,
        use_tls: bool = True,
    ) -> None:
        self._host = host
        self._port = port
        self._username = username
        self._password = password
        self._from_email = from_email
        self._public_url = public_url.rstrip("/")
        self._use_tls = use_tls

    async def send_action_token(self, email: str, purpose: str, token: str) -> None:
        await to_thread(self._send, email, purpose, token)

    def _send(self, email: str, purpose: str, token: str) -> None:
        verification = purpose == "email_verification"
        action = "验证邮箱" if verification else "重置密码"
        message = EmailMessage()
        message["Subject"] = "验证你的天人律邮箱" if verification else "重置你的天人律密码"
        message["From"] = self._from_email
        message["To"] = email
        message.set_content(
            f"请打开以下链接完成{action}：\n\n"
            f"{_action_link(self._public_url, purpose, token)}\n\n"
            "如果不是你发起的请求，请忽略此邮件。"
        )
        with smtplib.SMTP(self._host, self._port, timeout=15) as client:
            if self._use_tls:
                client.starttls()
            if self._username and self._password:
                client.login(self._username, self._password)
            client.send_message(message)


def _action_link(public_url: str, purpose: str, token: str) -> str:
    return f"{public_url}/?{urlencode({'purpose': purpose, 'token': token})}"
