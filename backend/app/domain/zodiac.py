from datetime import date

from app.domain.models import ZodiacInfo

_SIGNS: tuple[tuple[int, int, str, str, str], ...] = (
    (1, 20, "水瓶座", "风", "固定"),
    (2, 19, "双鱼座", "水", "变动"),
    (3, 21, "白羊座", "火", "本位"),
    (4, 20, "金牛座", "土", "固定"),
    (5, 21, "双子座", "风", "变动"),
    (6, 22, "巨蟹座", "水", "本位"),
    (7, 23, "狮子座", "火", "固定"),
    (8, 23, "处女座", "土", "变动"),
    (9, 23, "天秤座", "风", "本位"),
    (10, 24, "天蝎座", "水", "固定"),
    (11, 23, "射手座", "火", "变动"),
    (12, 22, "摩羯座", "土", "本位"),
)


def calculate_zodiac(birth_date: date) -> ZodiacInfo:
    """按常用热带黄道日期边界计算太阳星座。"""
    selected = _SIGNS[-1]
    for boundary in _SIGNS:
        if (birth_date.month, birth_date.day) >= boundary[:2]:
            selected = boundary
        else:
            break
    return ZodiacInfo(sign=selected[2], element=selected[3], modality=selected[4])
