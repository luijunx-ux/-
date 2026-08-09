from datetime import date

from app.domain.models import BirthData, LifeProfile
from app.domain.wuyun_liuqi import calculate_wuyun_liuqi
from app.domain.zodiac import calculate_zodiac


def build_life_profile(birth: BirthData) -> LifeProfile:
    local_date = birth.occurred_at.date()
    return LifeProfile(
        birth=birth,
        zodiac=calculate_zodiac(local_date),
        wuyun_liuqi=calculate_wuyun_liuqi(local_date),
    )


def generate_daily_advice(profile: LifeProfile, target_date: date) -> list[str]:
    """生成可复现的基础建议；后续 LLM 只能在此结果上做有边界的表达增强。"""
    element_advice = {
        "火": "把精力集中在一项最重要的行动上，并为节奏过快预留停顿。",
        "土": "优先完成稳定、可衡量的小步骤，避免一次承担过多事务。",
        "风": "记录今天最关键的三个想法，并安排一段无通知的专注时间。",
        "水": "给情绪留出觉察空间，用散步或书写完成一次温和整理。",
    }
    rotation = (
        "保持规律作息，并根据身体感受调整活动强度。",
        "安排至少一次短暂离屏休息，观察呼吸与肩颈状态。",
        "今天适合复盘近期节奏，只调整一个最有影响的习惯。",
    )
    return [
        element_advice[profile.zodiac.element],
        rotation[target_date.toordinal() % len(rotation)],
    ]
