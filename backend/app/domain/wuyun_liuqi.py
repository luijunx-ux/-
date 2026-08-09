from datetime import date

from app.domain.models import WuyunLiuqiInfo

_STEMS = "甲乙丙丁戊己庚辛壬癸"
_BRANCHES = "子丑寅卯辰巳午未申酉戌亥"
_MOVEMENTS = {
    "甲": "土运",
    "己": "土运",
    "乙": "金运",
    "庚": "金运",
    "丙": "水运",
    "辛": "水运",
    "丁": "木运",
    "壬": "木运",
    "戊": "火运",
    "癸": "火运",
}
_GOVERNING = {
    "巳": ("厥阴风木", "少阳相火"),
    "亥": ("厥阴风木", "少阳相火"),
    "子": ("少阴君火", "阳明燥金"),
    "午": ("少阴君火", "阳明燥金"),
    "丑": ("太阴湿土", "太阳寒水"),
    "未": ("太阴湿土", "太阳寒水"),
    "寅": ("少阳相火", "厥阴风木"),
    "申": ("少阳相火", "厥阴风木"),
    "卯": ("阳明燥金", "少阴君火"),
    "酉": ("阳明燥金", "少阴君火"),
    "辰": ("太阳寒水", "太阴湿土"),
    "戌": ("太阳寒水", "太阴湿土"),
}


def calculate_wuyun_liuqi(birth_date: date) -> WuyunLiuqiInfo:
    """计算公历年对应的年干支、中运与司天/在泉。

    v1 暂以公历年份映射干支。1 月 1 日至 2 月 4 日属于立春换年敏感区，调用方
    必须展示边界提示；后续版本需接入可靠节气历书，按出生地点和时刻判定。
    """
    stem = _STEMS[(birth_date.year - 4) % 10]
    branch = _BRANCHES[(birth_date.year - 4) % 12]
    governing, responding = _GOVERNING[branch]
    warning = None
    if (birth_date.month, birth_date.day) <= (2, 4):
        warning = "出生日期接近立春换年边界，当前版本按公历年计算，需经节气历书复核。"
    return WuyunLiuqiInfo(
        year=birth_date.year,
        heavenly_stem=stem,
        earthly_branch=branch,
        middle_movement=_MOVEMENTS[stem],
        movement_strength="太过" if _STEMS.index(stem) % 2 == 0 else "不及",
        governing_qi=governing,
        responding_qi=responding,
        algorithm_version="calendar_year_v1",
        boundary_warning=warning,
    )
