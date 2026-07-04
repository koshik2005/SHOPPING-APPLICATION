# DATABASE SECURITY GUIDE
## HyperLocal Enterprise Platform — Database Security Standards

---

## 1. Database Users & Least Privilege

Three PostgreSQL roles are used:

| Role | Privileges | Used By |
|---|---|---|
| `hyperlocal_admin` | SUPERUSER | Flyway migrations only |
| `hyperlocal_app` | SELECT, INSERT, UPDATE, DELETE on app tables | All microservices |
| `hyperlocal_readonly` | SELECT only | Reporting, Auditor role queries |

```sql
-- Create application user with minimal privileges
CREATE ROLE hyperlocal_app LOGIN PASSWORD '<strong-password>';
GRANT CONNECT ON DATABASE hyperlocal_db TO hyperlocal_app;
GRANT USAGE ON SCHEMA public TO hyperlocal_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO hyperlocal_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO hyperlocal_app;

-- Readonly user for reports
CREATE ROLE hyperlocal_readonly LOGIN PASSWORD '<strong-password>';
GRANT CONNECT ON DATABASE hyperlocal_db TO hyperlocal_readonly;
GRANT USAGE ON SCHEMA public TO hyperlocal_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO hyperlocal_readonly;
```

---

## 2. Flyway Migration Strategy

All schema changes managed via Flyway versioned migrations in each service's `src/main/resources/db/migration/`:

```
V1__initial_schema.sql         ← baseline schema
V2__rbac_roles.sql             ← add user_roles, branchId, shopId
V3__audit_tables.sql           ← audit_events table
V4__flyway_rls_policies.sql    ← Row Level Security
V5__encrypted_columns.sql      ← encrypted PII columns
```

### V2__rbac_roles.sql (Required for RBAC)
```sql
-- Add RBAC columns to users table
ALTER TABLE users ADD COLUMN branch_id UUID REFERENCES branches(id);
ALTER TABLE users ADD COLUMN shop_id UUID REFERENCES shops(id);
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP;

-- Create user_roles junction table
CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role    VARCHAR(50) NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    PRIMARY KEY (user_id, role)
);

-- Migrate existing users to ROLE_CUSTOMER
INSERT INTO user_roles (user_id, role)
SELECT id, 'ROLE_CUSTOMER' FROM users WHERE deleted = false;

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_users_branch_id ON users(branch_id) WHERE branch_id IS NOT NULL;
CREATE INDEX idx_users_shop_id ON users(shop_id) WHERE shop_id IS NOT NULL;
```

---

## 3. Soft Delete

All entities use soft delete — **records are never physically deleted in production**:

```java
// Standard pattern across all entities
@Column(nullable = false)
private boolean deleted = false;

@Column(name = "deleted_at")
private Instant deletedAt;

@Column(name = "deleted_by")
private UUID deletedBy; // userId of who performed deletion
```

```sql
-- All queries filter deleted=false
SELECT * FROM products WHERE shop_id = ? AND deleted = false;

-- Soft delete operation
UPDATE products
SET deleted = true, deleted_at = NOW(), deleted_by = ?
WHERE id = ?;

-- Hard delete is never used (only for GDPR erasure requests, with audit trail)
```

---

## 4. Audit Tables

```sql
CREATE TABLE audit_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id        UUID NOT NULL UNIQUE,
    user_id         UUID REFERENCES users(id),
    user_role       VARCHAR(50),
    device_id       VARCHAR(255),
    ip_address      INET,
    correlation_id  VARCHAR(36),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    action          VARCHAR(100) NOT NULL,
    entity_type     VARCHAR(50),
    entity_id       UUID,
    old_value       JSONB,   -- state before change
    new_value       JSONB,   -- state after change
    result          VARCHAR(20) NOT NULL, -- SUCCESS, FAILURE
    metadata        JSONB
);

-- Immutable: no UPDATE or DELETE on audit_events
REVOKE UPDATE, DELETE ON audit_events FROM hyperlocal_app;
GRANT INSERT, SELECT ON audit_events TO hyperlocal_app;

CREATE INDEX idx_audit_user_id    ON audit_events(user_id);
CREATE INDEX idx_audit_entity     ON audit_events(entity_type, entity_id);
CREATE INDEX idx_audit_created_at ON audit_events(created_at DESC);
CREATE INDEX idx_audit_action     ON audit_events(action);
```

---

## 5. Optimistic Locking

All mutable entities use optimistic locking to prevent lost updates:

```java
@Version
private Integer version = 0;
```

When a concurrent modification is detected, Spring Data JPA throws `OptimisticLockingFailureException`, which is mapped to `409 Conflict` by the global exception handler.

---

## 6. Sensitive Column Encryption

PII and sensitive fields encrypted at application layer using AES-256:

```java
// @Convert applied to sensitive columns
@Convert(converter = EncryptedStringConverter.class)
@Column(name = "phone_number")
private String phoneNumber;

@Convert(converter = EncryptedStringConverter.class)
@Column(name = "national_id")
private String nationalId; // Aadhar/ID card

// Key management: encryption key from environment variable, never in code
// ENCRYPTION_KEY=<32-byte AES key from Docker secret>
```

Encrypted columns in critical tables:
- `users.phone_number`
- `delivery_partners.national_id`
- `delivery_partners.license_number`
- `payment_methods.masked_account` (last 4 digits stored plain, rest encrypted)

---

## 7. Password Security

```java
// BCrypt configuration
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(12); // Cost factor 12 (~350ms/hash)
}

// Password policy enforcement
public void validatePasswordPolicy(String password) {
    if (password.length() < 8) throw new ValidationException("Password too short");
    if (!password.matches(".*[A-Z].*")) throw new ValidationException("Need uppercase");
    if (!password.matches(".*[0-9].*")) throw new ValidationException("Need digit");
    if (!password.matches(".*[!@#$%^&*].*")) throw new ValidationException("Need special char");
}
```

**Refresh tokens**: Stored as BCrypt hash in `user_sessions.refresh_token_hash`.
**JWT signing key**: Loaded from environment variable, never hardcoded.

---

## 8. Connection Pooling

```yaml
# application.yml for each service
spring:
  datasource:
    hikari:
      minimum-idle: 5
      maximum-pool-size: 20
      connection-timeout: 30000     # 30s
      idle-timeout: 600000          # 10min
      max-lifetime: 1800000         # 30min
      leak-detection-threshold: 60000  # 1min
```

---

## 9. Row Level Security (PostgreSQL)

```sql
-- Enable RLS on critical tables
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

-- Application sets user context at start of each request
-- (via JDBC connection interception or stored procedure)
SELECT set_config('app.current_user_id', ?, false);
SELECT set_config('app.current_branch_id', ?, false);

-- RLS policy: wallets visible only to owner or admins
CREATE POLICY wallet_owner_policy ON wallets
    FOR ALL TO hyperlocal_app
    USING (
        user_id = current_setting('app.current_user_id', true)::uuid
        OR current_setting('app.is_admin', true) = 'true'
    );
```

---

## 10. Database Security Checklist

- [ ] All services connect as `hyperlocal_app` (not superuser)
- [ ] Flyway uses `hyperlocal_admin` only for migrations
- [ ] All passwords stored as BCrypt hashes (strength >= 12)
- [ ] JWT secrets stored as environment variables (not in code or properties files)
- [ ] PII columns encrypted with AES-256
- [ ] `audit_events` table has INSERT-only permission for app user
- [ ] Optimistic locking (`@Version`) on all mutable entities
- [ ] Soft delete implemented on all entities (never hard-delete)
- [ ] Connection pool configured with leak detection
- [ ] RLS enabled on `wallets` and `user_sessions`
- [ ] Database backup encrypted at rest
- [ ] Point-in-time recovery enabled
