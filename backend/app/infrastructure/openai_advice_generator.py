import json
from datetime import date

import httpx

from app.domain.advice import GeneratedAdvice, KnowledgeExcerpt
from app.domain.models import LifeProfile


class OpenAIAdviceGenerator:
    def __init__(
        self,
        api_key: str,
        base_url: str,
        model: str,
        reasoning_effort: str,
        timeout_seconds: float,
        client: httpx.AsyncClient | None = None,
    ) -> None:
        self._client = client or httpx.AsyncClient(
            base_url=base_url,
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=httpx.Timeout(timeout_seconds),
        )
        self._model = model
        self._reasoning_effort = reasoning_effort

    async def generate(
        self,
        profile: LifeProfile,
        target_date: date,
        baseline: list[str],
        knowledge: list[KnowledgeExcerpt],
        safety_identifier: str | None,
    ) -> GeneratedAdvice:
        context = {
            "target_date": target_date.isoformat(),
            "zodiac": {
                "sign": profile.zodiac.sign,
                "element": profile.zodiac.element,
                "modality": profile.zodiac.modality,
            },
            "wuyun_liuqi": {
                "middle_movement": profile.wuyun_liuqi.middle_movement,
                "movement_strength": profile.wuyun_liuqi.movement_strength,
                "governing_qi": profile.wuyun_liuqi.governing_qi,
                "responding_qi": profile.wuyun_liuqi.responding_qi,
                "algorithm_version": profile.wuyun_liuqi.algorithm_version,
            },
            "deterministic_baseline": baseline,
            "knowledge": [{"source": item.source, "content": item.content} for item in knowledge],
        }
        request_body: dict[str, object] = {
            "model": self._model,
            "store": False,
            "reasoning": {"effort": self._reasoning_effort},
            "instructions": (
                "你是天人律日常节律建议助手。只能基于输入事实和知识片段表达，"
                "不得新增或修改星座、五运六气计算结果。输出2至3条温和、可执行、"
                "非医疗建议；不得诊断、治疗、预测疾病或制造确定性命运结论。"
            ),
            "input": json.dumps(context, ensure_ascii=False),
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": "daily_life_advice",
                    "strict": True,
                    "schema": {
                        "type": "object",
                        "properties": {
                            "advice": {
                                "type": "array",
                                "minItems": 2,
                                "maxItems": 3,
                                "items": {"type": "string"},
                            }
                        },
                        "required": ["advice"],
                        "additionalProperties": False,
                    },
                }
            },
        }
        if safety_identifier is not None:
            request_body["safety_identifier"] = safety_identifier
        response = await self._client.post("/responses", json=request_body)
        response.raise_for_status()
        payload = response.json()
        output_text = self._extract_output_text(payload)
        parsed: object = json.loads(output_text)
        if not isinstance(parsed, dict):
            raise ValueError("OpenAI response was not a JSON object")
        advice = parsed.get("advice")
        if not isinstance(advice, list) or not all(isinstance(item, str) for item in advice):
            raise ValueError("OpenAI response did not include a string advice list")
        usage = payload.get("usage")
        input_tokens = 0
        output_tokens = 0
        if isinstance(usage, dict):
            input_tokens = self._integer(usage.get("input_tokens"))
            output_tokens = self._integer(usage.get("output_tokens"))
        response_id = payload.get("id")
        return GeneratedAdvice(
            items=advice,
            model=self._model,
            response_id=response_id if isinstance(response_id, str) else None,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
        )

    def _integer(self, value: object) -> int:
        return value if isinstance(value, int) else 0

    def _extract_output_text(self, payload: dict[str, object]) -> str:
        raw_output = payload.get("output")
        if not isinstance(raw_output, list):
            raise ValueError("OpenAI response did not include output items")
        for output in raw_output:
            if not isinstance(output, dict) or output.get("type") != "message":
                continue
            raw_content = output.get("content")
            if not isinstance(raw_content, list):
                continue
            for content in raw_content:
                if isinstance(content, dict) and content.get("type") == "output_text":
                    text = content.get("text")
                    if isinstance(text, str):
                        return text
        raise ValueError("OpenAI response did not include output_text")
