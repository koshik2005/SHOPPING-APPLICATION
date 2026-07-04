-- ==============================================================================
-- V3__iam_tables.sql
-- HyperLocal Auth Service — IAM Schema Migration
--
-- Tables:
--   1. device_registry (Trusted and blocked client hardware signatures)
--   2. login_attempts (Failed logins monitoring table)
--   3. password_history (Previous password hash archives)
--   4. user_lock_history (Temporary/permanent lockout records)
--   5. otp_requests (Verification codes records)
-- ==============================================================================

-- 1. Create device_registry table
CREATE TABLE IF NOT EXISTS device_registry (
    id            UUID PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id     VARCHAR(255) NOT NULL,
    os_name       VARCHAR(50),
    os_version    VARCHAR(50),
    browser_name  VARCHAR(50),
    trusted       BOOLEAN NOT NULL DEFAULT TRUE,
    blocked       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, device_id)
);

-- 2. Create login_attempts table
CREATE TABLE IF NOT EXISTS login_attempts (
    id            UUID PRIMARY KEY,
    email         VARCHAR(255) NOT NULL,
    ip_address    VARCHAR(45),
    status        VARCHAR(20) NOT NULL, -- SUCCESS, FAILED
    attempt_time  TIMESTAMP NOT NULL DEFAULT NOW(),
    failure_reason VARCHAR(255)
);

-- 3. Create password_history table
CREATE TABLE IF NOT EXISTS password_history (
    id            UUID PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    changed_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    changed_by    UUID REFERENCES users(id) ON DELETE SET NULL
);

-- 4. Create user_lock_history table
CREATE TABLE IF NOT EXISTS user_lock_history (
    id            UUID PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lock_type     VARCHAR(20) NOT NULL, -- TEMPORARY, PERMANENT
    locked_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    unlocked_at   TIMESTAMP,
    reason        VARCHAR(255),
    unlocked_by   UUID REFERENCES users(id) ON DELETE SET NULL
);

-- 5. Create otp_requests table
CREATE TABLE IF NOT EXISTS otp_requests (
    id            UUID PRIMARY KEY,
    email_or_phone VARCHAR(255) NOT NULL,
    otp_code      VARCHAR(10) NOT NULL,
    expires_at    TIMESTAMP NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    verified      BOOLEAN NOT NULL DEFAULT FALSE,
    attempts      INT NOT NULL DEFAULT 0
);

-- 6. Performance indexes for IAM logs
CREATE INDEX IF NOT EXISTS idx_device_reg_user_id ON device_registry(user_id);
CREATE INDEX IF NOT EXISTS idx_login_attempts_email ON login_attempts(email, attempt_time DESC);
CREATE INDEX IF NOT EXISTS idx_pwd_hist_user_id ON password_history(user_id, changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_lock_hist_user_id ON user_lock_history(user_id, locked_at DESC);
CREATE INDEX IF NOT EXISTS idx_otp_requests_val ON otp_requests(email_or_phone, verified, expires_at DESC);
