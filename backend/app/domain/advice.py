from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class KnowledgeExcerpt:
    source: str
    content: str
    score: float


@dataclass(frozen=True, slots=True)
class GeneratedAdvice:
    items: list[str]
    model: str
    response_id: str | None = None
    input_tokens: int = 0
    output_tokens: int = 0


@dataclass(frozen=True, slots=True)
class DailyAdviceResult:
    items: list[str]
    generation_mode: str
    model: str | None
    knowledge_sources: list[str]
    request_id: str
    input_tokens: int = 0
    output_tokens: int = 0
