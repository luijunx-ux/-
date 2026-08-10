from dataclasses import dataclass
from datetime import date
from typing import Protocol


@dataclass(frozen=True, slots=True)
class AdviceAuditRecord:
    request_id: str
    target_date: date
    generation_mode: str
    model: str | None
    response_id: str | None
    input_tokens: int
    output_tokens: int
    knowledge_source_count: int
    safety_passed: bool


class AdviceAuditSink(Protocol):
    async def record(self, audit: AdviceAuditRecord) -> None: ...
