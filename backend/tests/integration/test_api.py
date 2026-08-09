from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)
VALID_BIRTH = {
    "occurred_at": "1990-08-15T10:30:00+08:00",
    "place_name": "上海市",
    "latitude": 31.2304,
    "longitude": 121.4737,
    "timezone": "Asia/Shanghai",
}


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_generate_profile() -> None:
    response = client.post("/api/v1/profiles/generate", json=VALID_BIRTH)
    assert response.status_code == 200
    body = response.json()
    assert body["profile"]["zodiac"]["sign"] == "狮子座"
    assert body["profile"]["wuyun_liuqi"]["algorithm_version"] == "calendar_year_v1"
    assert "不构成医疗诊断" in body["disclaimer"]


def test_rejects_birth_time_without_offset() -> None:
    payload = {**VALID_BIRTH, "occurred_at": "1990-08-15T10:30:00"}
    response = client.post("/api/v1/profiles/generate", json=payload)
    assert response.status_code == 422


def test_daily_advice_is_returned() -> None:
    payload = {**VALID_BIRTH, "target_date": "2026-08-09"}
    response = client.post("/api/v1/advice/daily", json=payload)
    assert response.status_code == 200
    assert len(response.json()["advice"]) == 2
