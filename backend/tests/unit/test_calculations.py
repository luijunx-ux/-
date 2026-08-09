import unittest
from datetime import date

from app.domain.wuyun_liuqi import calculate_wuyun_liuqi
from app.domain.zodiac import calculate_zodiac


class ZodiacTests(unittest.TestCase):
    def test_capricorn_wraps_across_year(self) -> None:
        self.assertEqual(calculate_zodiac(date(2000, 1, 1)).sign, "摩羯座")
        self.assertEqual(calculate_zodiac(date(2000, 12, 31)).sign, "摩羯座")

    def test_aries_boundary(self) -> None:
        self.assertEqual(calculate_zodiac(date(2000, 3, 20)).sign, "双鱼座")
        self.assertEqual(calculate_zodiac(date(2000, 3, 21)).sign, "白羊座")


class WuyunLiuqiTests(unittest.TestCase):
    def test_2024_calendar_year_mapping(self) -> None:
        result = calculate_wuyun_liuqi(date(2024, 8, 1))
        self.assertEqual((result.heavenly_stem, result.earthly_branch), ("甲", "辰"))
        self.assertEqual(result.middle_movement, "土运")
        self.assertEqual(result.movement_strength, "太过")
        self.assertEqual(result.governing_qi, "太阳寒水")

    def test_boundary_warning(self) -> None:
        self.assertIsNotNone(calculate_wuyun_liuqi(date(2024, 2, 1)).boundary_warning)


if __name__ == "__main__":
    unittest.main()
