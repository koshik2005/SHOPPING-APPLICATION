-- Migration to add hardened authentication structures, linked identities, devices, login history, and security events.

-- 1. Add refresh_token_hash column to user_sessions table
ALTER TABLE user_sessions ADD COLUMN refresh_token_hash VARCHAR(255);

-- 2. Create user_identities table for OAuth linking
CREATE TABLE user_identities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    email VARCHAR(150) NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    linked_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_provider_user UNIQUE (provider, provider_user_id)
);

-- 3. Create user_devices table for device registries
CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(150) NOT NULL,
    model VARCHAR(100) NOT NULL,
    manufacturer VARCHAR(100) NOT NULL,
    os VARCHAR(50) NOT NULL,
    push_token TEXT,
    trusted BOOLEAN NOT NULL DEFAULT FALSE,
    last_login TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_device UNIQUE (user_id, device_id)
);

-- 4. Create login_history table for auditing login attempts
CREATE TABLE login_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    device VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    country VARCHAR(100) NOT NULL,
    risk VARCHAR(20) NOT NULL DEFAULT 'LOW',
    result VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create security_events table for auditing security alerts
CREATE TABLE security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    correlation_id VARCHAR(100) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indices for optimized lookups
CREATE INDEX idx_user_identities_lookup ON user_identities(provider, provider_user_id);
CREATE INDEX idx_user_devices_lookup ON user_devices(user_id, device_id);
CREATE INDEX idx_login_history_user ON login_history(user_id);
CREATE INDEX idx_security_events_user ON security_events(user_id);
