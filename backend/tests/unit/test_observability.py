import logging
import re

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_request_id_is_returned_and_logged(caplog: pytest.LogCaptureFixture) -> None:
    request_id = "mobile-session-123"
    with caplog.at_level(logging.INFO, logger="tianrenlu.http"):
        response = client.get(
            "/health?token=must-not-be-logged",
            headers={"X-Request-ID": request_id, "Authorization": "Bearer secret-token"},
        )

    assert response.status_code == 200
    assert response.headers["X-Request-ID"] == request_id
    records = [record for record in caplog.records if record.name == "tianrenlu.http"]
    assert len(records) == 1
    record = records[0]
    assert record.__dict__["request_id"] == request_id
    assert record.__dict__["http_path"] == "/health"
    serialized = record.getMessage() + repr(record.__dict__)
    assert "must-not-be-logged" not in serialized
    assert "secret-token" not in serialized


def test_invalid_request_id_is_replaced() -> None:
    response = client.get("/health", headers={"X-Request-ID": "unsafe id with spaces"})

    assert response.status_code == 200
    assert re.fullmatch(r"[0-9a-f]{32}", response.headers["X-Request-ID"])


def test_liveness_endpoint() -> None:
    response = client.get("/health/live")

    assert response.status_code == 200
    assert response.json() == {"status": "alive"}
