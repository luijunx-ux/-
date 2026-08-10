from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class SafetyDecision:
    allowed: bool
    reasons: list[str]


class AdviceSafetyPolicy:
    _forbidden_groups = {
        "medical": ("诊断", "治愈", "治疗方案", "停药", "用药", "替代医生"),
        "fatalism": ("注定", "必然发生", "一定会", "百分之百", "保证你"),
        "risk_prediction": ("寿命", "患癌", "重大疾病", "死亡时间"),
    }

    def evaluate(self, items: list[str]) -> SafetyDecision:
        reasons: list[str] = []
        if not 2 <= len(items) <= 3:
            reasons.append("invalid_item_count")
        for item in items:
            normalized = item.strip()
            if not 5 <= len(normalized) <= 120:
                reasons.append("invalid_item_length")
            for group, patterns in self._forbidden_groups.items():
                if any(pattern in normalized for pattern in patterns):
                    reasons.append(group)
        return SafetyDecision(allowed=not reasons, reasons=sorted(set(reasons)))
