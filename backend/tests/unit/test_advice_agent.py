import json
import unittest
from datetime import UTC, date, datetime
from pathlib import Path

import httpx

from app.application.advice_agent import DailyAdviceAgent
from app.application.profile_service import build_life_profile
from app.domain.advice import GeneratedAdvice, KnowledgeExcerpt
from app.domain.advice_audit import AdviceAuditRecord
from app.domain.models import BirthData, LifeProfile
from app.infrastructure.markdown_retriever import MarkdownKnowledgeRetriever
from app.infrastructure.openai_advice_generator import OpenAIAdviceGenerator


class FakeRetriever:
    async def retrieve(self, query: str, limit: int = 3) -> list[KnowledgeExcerpt]:
        return [KnowledgeExcerpt("guidelines.md", "保持温和且可执行的作息调整。", 1.0)]


class FakeGenerator:
    async def generate(
        self,
        profile: LifeProfile,
        target_date: date,
        baseline: list[str],
        knowledge: list[KnowledgeExcerpt],
        safety_identifier: str | None,
    ) -> GeneratedAdvice:
        return GeneratedAdvice(
            items=["今天先完成一项重要行动。", "晚上预留十分钟安静整理当天感受。"],
            model="test-model",
        )


class FailingGenerator(FakeGenerator):
    async def generate(
        self,
        profile: LifeProfile,
        target_date: date,
        baseline: list[str],
        knowledge: list[KnowledgeExcerpt],
        safety_identifier: str | None,
    ) -> GeneratedAdvice:
        raise httpx.TimeoutException("timeout")


class UnsafeGenerator(FakeGenerator):
    async def generate(
        self,
        profile: LifeProfile,
        target_date: date,
        baseline: list[str],
        knowledge: list[KnowledgeExcerpt],
        safety_identifier: str | None,
    ) -> GeneratedAdvice:
        return GeneratedAdvice(
            items=["你注定会出现重大疾病。", "这套治疗方案可以替代医生。"],
            model="unsafe-model",
            input_tokens=100,
            output_tokens=20,
        )


class CapturingAuditSink:
    def __init__(self) -> None:
        self.records: list[AdviceAuditRecord] = []

    async def record(self, audit: AdviceAuditRecord) -> None:
        self.records.append(audit)


def sample_profile() -> LifeProfile:
    return build_life_profile(
        BirthData(
            occurred_at=datetime(1990, 8, 15, 2, 30, tzinfo=UTC),
            place_name="上海市",
            latitude=31.2304,
            longitude=121.4737,
            timezone="Asia/Shanghai",
        )
    )


class AdviceAgentTests(unittest.IsolatedAsyncioTestCase):
    async def test_retrieves_versioned_markdown_knowledge(self) -> None:
        knowledge_directory = Path(__file__).resolve().parents[3] / "ai" / "rag" / "knowledge"
        retriever = MarkdownKnowledgeRetriever(knowledge_directory)

        results = await retriever.retrieve("作息调整 活动建议", limit=2)

        self.assertTrue(results)
        self.assertIn("daily_rhythm_guidelines.md", {item.source for item in results})

    async def test_returns_llm_result_with_sources(self) -> None:
        agent = DailyAdviceAgent(FakeRetriever(), FakeGenerator())

        result = await agent.run(sample_profile(), date(2026, 8, 10))

        self.assertEqual(result.generation_mode, "llm")
        self.assertEqual(result.model, "test-model")
        self.assertEqual(result.knowledge_sources, ["guidelines.md"])

    async def test_falls_back_when_provider_fails(self) -> None:
        agent = DailyAdviceAgent(FakeRetriever(), FailingGenerator())

        result = await agent.run(sample_profile(), date(2026, 8, 10))

        self.assertEqual(result.generation_mode, "fallback")
        self.assertEqual(len(result.items), 2)

    async def test_safety_violation_falls_back_and_is_audited(self) -> None:
        audit_sink = CapturingAuditSink()
        agent = DailyAdviceAgent(
            FakeRetriever(),
            UnsafeGenerator(),
            audit_sink=audit_sink,
        )

        result = await agent.run(sample_profile(), date(2026, 8, 10))

        self.assertEqual(result.generation_mode, "safety_fallback")
        self.assertFalse(audit_sink.records[0].safety_passed)
        self.assertEqual(audit_sink.records[0].input_tokens, 100)

    async def test_openai_adapter_uses_structured_output_without_birth_pii(self) -> None:
        captured: dict[str, object] = {}

        async def handler(request: httpx.Request) -> httpx.Response:
            captured.update(json.loads(request.content))
            return httpx.Response(
                200,
                json={
                    "id": "resp_test",
                    "usage": {"input_tokens": 123, "output_tokens": 45},
                    "output": [
                        {
                            "type": "message",
                            "content": [
                                {
                                    "type": "output_text",
                                    "text": json.dumps(
                                        {
                                            "advice": [
                                                "今天专注完成一个清晰的小目标。",
                                                "晚间安排短暂离屏休息。",
                                            ]
                                        },
                                        ensure_ascii=False,
                                    ),
                                }
                            ],
                        }
                    ],
                },
            )

        client = httpx.AsyncClient(
            transport=httpx.MockTransport(handler),
            base_url="https://api.openai.test/v1",
        )
        generator = OpenAIAdviceGenerator(
            api_key="test-key",
            base_url="https://api.openai.test/v1",
            model="gpt-test",
            reasoning_effort="low",
            timeout_seconds=5,
            client=client,
        )

        result = await generator.generate(
            profile=sample_profile(),
            target_date=date(2026, 8, 10),
            baseline=["建议一", "建议二"],
            knowledge=await FakeRetriever().retrieve("节律"),
            safety_identifier="anonymous-safe-id",
        )

        serialized = json.dumps(captured, ensure_ascii=False)
        self.assertNotIn("上海市", serialized)
        self.assertNotIn("121.4737", serialized)
        self.assertEqual(captured["store"], False)
        self.assertEqual(captured["safety_identifier"], "anonymous-safe-id")
        self.assertEqual(result.model, "gpt-test")
        self.assertEqual(result.response_id, "resp_test")
        self.assertEqual(result.input_tokens, 123)
        self.assertEqual(result.output_tokens, 45)
        await client.aclose()
