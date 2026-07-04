# HyperLocal Platform — Database Security Schema
**Version:** 3.0

---

## 1. Relational Security Model

The entity security model contains dedicated tables to log sessions, device bindings, failed login lock histories, password changes, and OTP requests.

```
┌──────────────┐      ┌─────────────┐      ┌────────────────────┐
│    users     ├─────►│ user_roles  ├─────►│  password_history  │
└──────┬───────┘      └─────────────┘      └────────────────────┘
       │
       ├─────────────► [user_sessions]
       │
       ├─────────────► [device_registry]
       │
       ├─────────────► [login_attempts]
       │
       └─────────────► [user_lock_history]
```

---

## 2. Table Specifications

### 2.1 Table: `users`
- Stores user accounts, tenant context, and current status:
```sql
CREATE TABLE users (
    id            UUID PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status        VARCHAR(50) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, SUSPENDED, TEMP_LOCKED
    mfa_enabled   BOOLEAN NOT NULL DEFAULT FALSE,
    branch_id     UUID REFERENCES branches(id),
    shop_id       UUID,
    deleted       BOOLEAN NOT NULL DEFAULT FALSE
);
```

### 2.2 Table: `user_sessions`
- Maps session IDs, refresh tokens, and browser fingerprints:
```sql
CREATE TABLE user_sessions (
    id                 UUID PRIMARY KEY,
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id          VARCHAR(255) NOT NULL,
    ip_address         VARCHAR(45),
    user_agent         VARCHAR(500),
    refresh_token_hash VARCHAR(255),
    created_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at         TIMESTAMP NOT NULL
);
```

### 2.3 Table: `device_registry`
- Registers trusted devices and fingerprints:
```sql
CREATE TABLE device_registry (
    id            UUID PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id     VARCHAR(255) NOT NULL UNIQUE,
    os_name       VARCHAR(50),
    os_version    VARCHAR(50),
    browser_name  VARCHAR(50),
    trusted       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 2.4 Table: `login_attempts`
- Tracks failed login attempts to trigger locks:
```sql
CREATE TABLE login_attempts (
    id            UUID PRIMARY KEY,
    email         VARCHAR(255) NOT NULL,
    ip_address    VARCHAR(45),
    status        VARCHAR(20) NOT NULL, -- SUCCESS, FAILED
    attempt_time  TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 2.5 Table: `user_lock_history`
- Logs temporary and permanent lockouts:
```sql
CREATE TABLE user_lock_history (
    id            UUID PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lock_type     VARCHAR(20) NOT NULL, -- TEMPORARY, PERMANENT
    locked_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    unlocked_at   TIMESTAMP,
    reason        VARCHAR(255)
);
```
