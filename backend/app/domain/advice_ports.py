from datetime import date
from typing import Protocol

from app.domain.advice import GeneratedAdvice, KnowledgeExcerpt
from app.domain.models import LifeProfile


class KnowledgeRetriever(Protocol):
    async def retrieve(self, query: str, limit: int = 3) -> list[KnowledgeExcerpt]: ...


class AdviceGenerator(Protocol):
    async def generate(
        self,
        profile: LifeProfile,
        target_date: date,
        baseline: list[str],
        knowledge: list[KnowledgeExcerpt],
        safety_identifier: str | None,
    ) -> GeneratedAdvice: ...
