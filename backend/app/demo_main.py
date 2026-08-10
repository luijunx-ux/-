"""Disposable in-memory API used only for local product demonstrations."""

from dataclasses import asdict
from datetime import date
from typing import Annotated, Any
from uuid import uuid4

from fastapi import Depends, FastAPI, Header, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from app.api.routes import DISCLAIMER
from app.application.profile_service import build_life_profile, generate_daily_advice
from app.core.security import PasswordService
from app.domain.models import BirthData
from app.schemas.auth import CredentialsRequest, RefreshTokenRequest
from app.schemas.profile import (
    AdviceFeedbackRequest,
    ProfileAdviceRequest,
    ProfileCreateRequest,
    ProfileUpdateRequest,
)

app = FastAPI(title="天人律本地演示 API")
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_methods=["*"],
    allow_headers=["*"],
)

passwords = PasswordService()
users: dict[str, dict[str, Any]] = {}
access_tokens: dict[str, str] = {}
refresh_tokens: dict[str, str] = {}
profiles: dict[str, dict[str, Any]] = {}
advice_records: dict[str, dict[str, Any]] = {}


class DemoLoginRequest(BaseModel):
    email: str = Field(min_length=1, max_length=320)
    password: str = Field(min_length=12, max_length=128)


users["admin"] = {
    "id": str(uuid4()),
    "password_hash": passwords.hash("123456qwerty"),
}


def _birth(payload: ProfileCreateRequest | ProfileUpdateRequest) -> BirthData:
    return BirthData(
        occurred_at=payload.occurred_at,
        place_name=payload.place_name,
        latitude=payload.latitude,
        longitude=payload.longitude,
        timezone=payload.timezone,
    )


def _session(email: str) -> dict[str, Any]:
    access = str(uuid4())
    refresh = f"demo-refresh-{uuid4()}-{uuid4()}"
    access_tokens[access] = email
    refresh_tokens[refresh] = email
    user = users[email]
    return {
        "access_token": access,
        "token_type": "bearer",
        "expires_in": 1800,
        "refresh_token": refresh,
        "refresh_expires_in": 2592000,
        "user": {
            "id": user["id"],
            "email": email,
            "email_verified": True,
        },
    }


def _email(authorization: Annotated[str | None, Header()] = None) -> str:
    token = "" if authorization is None else authorization.removeprefix("Bearer ")
    email = access_tokens.get(token)
    if email is None:
        raise HTTPException(status_code=401, detail="演示会话无效，请重新登录")
    return email


CurrentEmail = Annotated[str, Depends(_email)]


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "mode": "in-memory-demo"}


@app.post("/api/v1/auth/register", status_code=201)
def register(payload: CredentialsRequest) -> dict[str, Any]:
    email = str(payload.email).lower()
    if email in users:
        raise HTTPException(status_code=409, detail="该邮箱已注册")
    users[email] = {
        "id": str(uuid4()),
        "password_hash": passwords.hash(payload.password),
    }
    return _session(email)


@app.post("/api/v1/auth/login")
def login(payload: DemoLoginRequest) -> dict[str, Any]:
    email = str(payload.email).lower()
    user = users.get(email)
    if user is None or not passwords.verify(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="邮箱或密码错误")
    return _session(email)


@app.post("/api/v1/auth/refresh")
def refresh(payload: RefreshTokenRequest) -> dict[str, Any]:
    email = refresh_tokens.pop(payload.refresh_token, None)
    if email is None:
        raise HTTPException(status_code=401, detail="刷新令牌无效")
    return _session(email)


@app.post("/api/v1/auth/logout", status_code=204)
def logout(payload: RefreshTokenRequest) -> Response:
    refresh_tokens.pop(payload.refresh_token, None)
    return Response(status_code=204)


@app.get("/api/v1/users/me")
def me(email: CurrentEmail) -> dict[str, Any]:
    return {"id": users[email]["id"], "email": email, "email_verified": True}


@app.delete("/api/v1/users/me", status_code=204)
def delete_me(email: CurrentEmail) -> Response:
    users.pop(email, None)
    for profile_id in [key for key, value in profiles.items() if value["email"] == email]:
        profiles.pop(profile_id)
    return Response(status_code=204)


@app.get("/api/v1/locations/search")
def locations(q: str) -> list[dict[str, Any]]:
    known = {
        "上海": ("上海市, 中国", 31.2304, 121.4737),
        "北京": ("北京市, 中国", 39.9042, 116.4074),
        "广州": ("广州市, 中国", 23.1291, 113.2644),
        "深圳": ("深圳市, 中国", 22.5431, 114.0579),
    }
    match = next((value for key, value in known.items() if key in q), None)
    if match is None:
        match = (f"{q}（演示地点）", 31.2304, 121.4737)
    return [
        {
            "display_name": match[0],
            "latitude": match[1],
            "longitude": match[2],
            "timezone": "Asia/Shanghai",
        }
    ]


def _profile_response(profile_id: str, stored: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": profile_id,
        "name": stored["name"],
        "is_default": stored["is_default"],
        "profile": asdict(stored["profile"]),
        "disclaimer": DISCLAIMER,
    }


@app.post("/api/v1/profiles", status_code=201)
def create_profile(payload: ProfileCreateRequest, email: CurrentEmail) -> dict[str, Any]:
    owned = [value for value in profiles.values() if value["email"] == email]
    make_default = payload.is_default or not owned
    if make_default:
        for value in owned:
            value["is_default"] = False
    profile_id = str(uuid4())
    profiles[profile_id] = {
        "email": email,
        "name": payload.name,
        "is_default": make_default,
        "profile": build_life_profile(_birth(payload)),
    }
    return _profile_response(profile_id, profiles[profile_id])


@app.get("/api/v1/profiles")
def list_profiles(email: CurrentEmail) -> list[dict[str, Any]]:
    return [
        _profile_response(profile_id, value)
        for profile_id, value in profiles.items()
        if value["email"] == email
    ]


@app.put("/api/v1/profiles/{profile_id}")
def update_profile(
    profile_id: str, payload: ProfileUpdateRequest, email: CurrentEmail
) -> dict[str, Any]:
    stored = profiles.get(profile_id)
    if stored is None or stored["email"] != email:
        raise HTTPException(status_code=404, detail="生命档案不存在")
    if payload.is_default:
        for value in profiles.values():
            if value["email"] == email:
                value["is_default"] = False
    stored.update(
        name=payload.name,
        is_default=payload.is_default or stored["is_default"],
        profile=build_life_profile(_birth(payload)),
    )
    return _profile_response(profile_id, stored)


@app.delete("/api/v1/profiles/{profile_id}", status_code=204)
def delete_profile(profile_id: str, email: CurrentEmail) -> Response:
    stored = profiles.get(profile_id)
    if stored is None or stored["email"] != email:
        raise HTTPException(status_code=404, detail="生命档案不存在")
    profiles.pop(profile_id)
    return Response(status_code=204)


@app.post("/api/v1/profiles/{profile_id}/advice/daily")
def daily_advice(
    profile_id: str, payload: ProfileAdviceRequest, email: CurrentEmail
) -> dict[str, Any]:
    stored = profiles.get(profile_id)
    if stored is None or stored["email"] != email:
        raise HTTPException(status_code=404, detail="生命档案不存在")
    key = f"{email}:{profile_id}:{payload.target_date}"
    cached = key in advice_records
    if not cached:
        advice_records[key] = {
            "id": str(uuid4()),
            "profile_id": profile_id,
            "target_date": payload.target_date.isoformat(),
            "advice": generate_daily_advice(stored["profile"], payload.target_date),
            "disclaimer": DISCLAIMER,
            "generation_mode": "deterministic",
            "model": None,
            "knowledge_sources": [],
            "request_id": str(uuid4()),
            "input_tokens": 0,
            "output_tokens": 0,
            "helpful": None,
        }
    return {**advice_records[key], "cached": cached}


@app.get("/api/v1/advice/history")
def history(email: CurrentEmail) -> list[dict[str, Any]]:
    return [
        {**value, "cached": True}
        for key, value in advice_records.items()
        if key.startswith(f"{email}:")
    ]


@app.put("/api/v1/advice/{advice_id}/feedback")
def feedback(advice_id: str, payload: AdviceFeedbackRequest, email: CurrentEmail) -> dict[str, Any]:
    record = next(
        (
            value
            for key, value in advice_records.items()
            if key.startswith(f"{email}:") and value["id"] == advice_id
        ),
        None,
    )
    if record is None:
        raise HTTPException(status_code=404, detail="每日建议不存在")
    record["helpful"] = payload.helpful
    return {**record, "cached": True}


@app.get("/api/v1/advice/stats")
def stats(through_date: date, email: CurrentEmail) -> dict[str, int]:
    viewed = {
        value["target_date"] for key, value in advice_records.items() if key.startswith(f"{email}:")
    }
    return {"viewing_streak": 1 if through_date.isoformat() in viewed else 0}
