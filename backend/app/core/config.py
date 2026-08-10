from functools import lru_cache

from pydantic import SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "development"
    log_level: str = "INFO"
    database_url: str = "postgresql+asyncpg://tianrenlu:change_me@localhost:5432/tianrenlu"
    database_echo: bool = False
    geocoding_base_url: str = "https://nominatim.openstreetmap.org"
    geocoding_user_agent: str = "Tianrenlu/0.1 (+https://github.com/luijunx-ux/-)"
    geocoding_cache_seconds: int = 86400
    ai_enabled: bool = False
    llm_api_key: SecretStr | None = None
    llm_base_url: str = "https://api.openai.com/v1"
    llm_model: str = "gpt-5.6-terra"
    llm_reasoning_effort: str = "low"
    llm_timeout_seconds: float = 20.0
    jwt_secret_key: SecretStr = SecretStr("development-only-change-me-at-least-32-characters")
    jwt_issuer: str = "tianrenlu-api"
    jwt_audience: str = "tianrenlu-mobile"
    jwt_access_token_minutes: int = 30
    refresh_token_days: int = 30
    safety_identifier_secret: SecretStr = SecretStr("development-only-safety-id-secret-change-me")

    @model_validator(mode="after")
    def reject_development_secrets_outside_development(self) -> "Settings":
        if self.app_env.lower() == "development":
            return self
        secrets = (
            self.jwt_secret_key.get_secret_value(),
            self.safety_identifier_secret.get_secret_value(),
        )
        if any(value.startswith(("development-only", "replace_with")) for value in secrets):
            raise ValueError("生产类环境必须配置独立的 JWT 与安全标识密钥")
        return self

    model_config = SettingsConfigDict(
        env_file=("../.env", ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
