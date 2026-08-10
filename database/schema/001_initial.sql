CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(320) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS life_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(80) NOT NULL DEFAULT '我的生命档案',
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    occurred_at TIMESTAMPTZ NOT NULL,
    place_name VARCHAR(200) NOT NULL,
    latitude NUMERIC(9, 6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude NUMERIC(9, 6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    timezone VARCHAR(64) NOT NULL,
    zodiac JSONB NOT NULL,
    wuyun_liuqi JSONB NOT NULL,
    algorithm_versions JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_refresh_tokens_user_id ON refresh_tokens(user_id);

CREATE TABLE IF NOT EXISTS account_action_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    purpose VARCHAR(32) NOT NULL,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_account_action_tokens_user_id
    ON account_action_tokens(user_id);

CREATE TABLE IF NOT EXISTS auth_security_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(40) NOT NULL,
    subject_hash VARCHAR(64) NOT NULL,
    succeeded BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_auth_security_events_event_type
    ON auth_security_events(event_type);
CREATE INDEX IF NOT EXISTS ix_auth_security_events_subject_hash
    ON auth_security_events(subject_hash);
CREATE INDEX IF NOT EXISTS ix_auth_security_events_created_at
    ON auth_security_events(created_at);

CREATE INDEX IF NOT EXISTS ix_life_profiles_owner_id ON life_profiles(owner_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_life_profiles_one_default_per_owner
    ON life_profiles(owner_id) WHERE is_default = TRUE AND owner_id IS NOT NULL;

COMMENT ON TABLE life_profiles IS '敏感个人出生资料与版本化计算结果；生产环境必须启用访问控制和加密策略';

CREATE TABLE IF NOT EXISTS daily_advice_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES life_profiles(id) ON DELETE CASCADE,
    target_date DATE NOT NULL,
    viewed_on DATE NOT NULL DEFAULT CURRENT_DATE,
    advice JSONB NOT NULL,
    generation_mode VARCHAR(32) NOT NULL,
    model VARCHAR(100),
    knowledge_sources JSONB NOT NULL,
    request_id VARCHAR(36) NOT NULL,
    input_tokens INTEGER NOT NULL DEFAULT 0,
    output_tokens INTEGER NOT NULL DEFAULT 0,
    helpful BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_advice_profile_date UNIQUE (owner_id, profile_id, target_date)
);

CREATE INDEX IF NOT EXISTS ix_daily_advice_records_owner_id
    ON daily_advice_records(owner_id);
CREATE INDEX IF NOT EXISTS ix_daily_advice_records_profile_id
    ON daily_advice_records(profile_id);
