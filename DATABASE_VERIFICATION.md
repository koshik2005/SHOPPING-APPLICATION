# HyperLocal Platform — Database Verification
**Phase:** P2 (Production Readiness)
**Status:** COMPLETE

---

## 1. Relational Integrity Checks
Database tables are initialized using Flyway migrations:
- **`V1__initial_schema.sql`**: Configures entities for branches, shops, categories, products, inventory, orders, and payment records.
- **`V2__rbac_roles.sql`**: Configures the RBAC tables.
- **`V3__iam_tables.sql`**: Configures tables for devices, logins, locks, and OTP verification requests.

---

## 2. Table Checklist

- **`[x]` users** — account identities
- **`[x]` user_roles** — junction permissions mappings
- **`[x]` device_registry** — trusted and blocked hardware fingerprints
- **`[x]` login_attempts** — failed logins metrics logs
- **`[x]` user_lock_history** — lockout state parameters
- **`[x]` otp_requests** — dynamic 6-digit codes
- **`[x]` user_sessions** — active JWT registry
- **`[x]` branches / shops** — multi-tenant scopes
- **`[x]` products / inventory** — stock tracking
- **`[x]` orders / order_items** — cart conversions
- **`[x]` audit_events** — non-repudiation logging
