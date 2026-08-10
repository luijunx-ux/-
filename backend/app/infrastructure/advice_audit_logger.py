import json
import logging
from dataclasses import asdict

from app.domain.advice_audit import AdviceAuditRecord


class LoggingAdviceAuditSink:
    def __init__(self) -> None:
        self._logger = logging.getLogger("tianrenlu.ai.audit")

    async def record(self, audit: AdviceAuditRecord) -> None:
        self._logger.info(
            "ai_advice_audit %s",
            json.dumps(asdict(audit), ensure_ascii=False, default=str),
        )
