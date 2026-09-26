from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.auth_routes import router as auth_router
from app.api.routes import router
from app.core.config import get_settings
from app.core.health import check_readiness
from app.core.logging import configure_logging
from app.core.observability import RequestObservabilityMiddleware
from app.core.version import APP_VERSION

configure_logging()
app = FastAPI(title="天人律 AI 生命节律 API", version=APP_VERSION)
app.add_middleware(RequestObservabilityMiddleware)
if get_settings().app_env.lower() == "development":
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:\d+)?$",
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
app.include_router(router)
app.include_router(auth_router)


@app.get("/health", tags=["system"])
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/health/live", tags=["system"])
def liveness() -> dict[str, str]:
    return {"status": "alive"}


@app.get("/health/ready", tags=["system"])
async def readiness() -> JSONResponse:
    result = await check_readiness()
    status_code = 200 if result["status"] == "ready" else 503
    return JSONResponse(content=result, status_code=status_code)
