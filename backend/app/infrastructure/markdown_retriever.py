import asyncio
from pathlib import Path

from app.domain.advice import KnowledgeExcerpt


class MarkdownKnowledgeRetriever:
    def __init__(self, knowledge_directory: Path) -> None:
        self._knowledge_directory = knowledge_directory

    async def retrieve(self, query: str, limit: int = 3) -> list[KnowledgeExcerpt]:
        return await asyncio.to_thread(self._retrieve_sync, query, limit)

    def _retrieve_sync(self, query: str, limit: int) -> list[KnowledgeExcerpt]:
        query_tokens = self._tokens(query)
        candidates: list[KnowledgeExcerpt] = []
        for path in sorted(self._knowledge_directory.glob("*.md")):
            text = path.read_text(encoding="utf-8")
            for paragraph in (item.strip() for item in text.split("\n\n")):
                if not paragraph or paragraph.startswith("#"):
                    continue
                paragraph_tokens = self._tokens(paragraph)
                overlap = len(query_tokens & paragraph_tokens)
                if overlap == 0:
                    continue
                score = overlap / max(len(query_tokens), 1)
                candidates.append(
                    KnowledgeExcerpt(source=path.name, content=paragraph, score=score)
                )
        candidates.sort(key=lambda item: item.score, reverse=True)
        return candidates[:limit]

    def _tokens(self, text: str) -> set[str]:
        normalized = "".join(character.lower() for character in text if not character.isspace())
        return {normalized[index : index + 2] for index in range(max(len(normalized) - 1, 0))}
