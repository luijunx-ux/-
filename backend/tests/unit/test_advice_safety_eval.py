import json
import unittest
from pathlib import Path

from app.application.advice_safety import AdviceSafetyPolicy


class AdviceSafetyEvaluationTests(unittest.TestCase):
    def test_versioned_safety_dataset(self) -> None:
        dataset = (
            Path(__file__).resolve().parents[3]
            / "ai"
            / "evaluations"
            / "datasets"
            / "advice_safety_v1.jsonl"
        )
        policy = AdviceSafetyPolicy()
        failures: list[str] = []
        for line in dataset.read_text(encoding="utf-8").splitlines():
            case = json.loads(line)
            decision = policy.evaluate(case["advice"])
            if decision.allowed is not case["expected_allowed"]:
                failures.append(case["id"])
        self.assertEqual(failures, [])
