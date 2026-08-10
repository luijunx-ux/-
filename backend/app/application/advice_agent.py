from datetime import date
from uuid import uuid4

from app.application.advice_safety import AdviceSafetyPolicy
from app.application.profile_service import generate_daily_advice
from app.domain.advice import DailyAdviceResult
from app.domain.advice_audit import AdviceAuditRecord, AdviceAuditSink
from app.domain.advice_ports import AdviceGenerator, KnowledgeRetriever
from app.domain.models import LifeProfile


class DailyAdviceAgent:
    def __init__(
        self,
        retriever: KnowledgeRetriever,
        generator: AdviceGenerator | None,
        safety_policy: AdviceSafetyPolicy | None = None,
        audit_sink: AdviceAuditSink | None = None,
    ) -> None:
        self._retriever = retriever
        self._generator = generator
        self._safety_policy = safety_policy or AdviceSafetyPolicy()
        self._audit_sink = audit_sink

    async def run(
        self,
        profile: LifeProfile,
        target_date: date,
        safety_identifier: str | None = None,
    ) -> DailyAdviceResult:
        request_id = str(uuid4())
        baseline = generate_daily_advice(profile, target_date)
        if self._generator is None:
            result = DailyAdviceResult(
                items=baseline,
                generation_mode="deterministic",
                model=None,
                knowledge_sources=[],
                request_id=request_id,
            )
            await self._audit(result, target_date, None, True)
            return result

        query = " ".join(
            (
                profile.zodiac.element,
                profile.wuyun_liuqi.middle_movement,
                profile.wuyun_liuqi.governing_qi,
                "作息 情绪 活动 日常节律",
            )
        )
        knowledge = await self._retriever.retrieve(query)
        sources = [item.source for item in knowledge]
        try:
            generated = await self._generator.generate(
                profile=profile,
                target_date=target_date,
                baseline=baseline,
                knowledge=knowledge,
                safety_identifier=safety_identifier,
            )
        except Exception:
            result = DailyAdviceResult(
                items=baseline,
                generation_mode="fallback",
                model=None,
                knowledge_sources=sources,
                request_id=request_id,
            )
            await self._audit(result, target_date, None, True)
            return result

        cleaned = [item.strip() for item in generated.items]
        safety = self._safety_policy.evaluate(cleaned)
        if not safety.allowed:
            result = DailyAdviceResult(
                items=baseline,
                generation_mode="safety_fallback",
                model=generated.model,
                knowledge_sources=sources,
                request_id=request_id,
                input_tokens=generated.input_tokens,
                output_tokens=generated.output_tokens,
            )
            await self._audit(result, target_date, generated.response_id, False)
            return result

        result = DailyAdviceResult(
            items=cleaned,
            generation_mode="llm",
            model=generated.model,
            knowledge_sources=sources,
            request_id=request_id,
            input_tokens=generated.input_tokens,
            output_tokens=generated.output_tokens,
        )
        await self._audit(result, target_date, generated.response_id, True)
        return result

    async def _audit(
        self,
        result: DailyAdviceResult,
        target_date: date,
        response_id: str | None,
        safety_passed: bool,
    ) -> None:
        if self._audit_sink is None:
            return
        await self._audit_sink.record(
            AdviceAuditRecord(
                request_id=result.request_id,
                target_date=target_date,
                generation_mode=result.generation_mode,
                model=result.model,
                response_id=response_id,
                input_tokens=result.input_tokens,
                output_tokens=result.output_tokens,
                knowledge_source_count=len(result.knowledge_sources),
                safety_passed=safety_passed,
            )
        )
