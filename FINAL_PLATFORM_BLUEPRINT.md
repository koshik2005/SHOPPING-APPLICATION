# FINAL PLATFORM BLUEPRINT
## HyperLocal Enterprise Platform — Complete Technical Reference

**Version:** 2.0 — Enterprise Architecture

---

## 1. Platform Summary

The HyperLocal Enterprise Platform is a **production-grade, zero-trust, microservices-based hyperlocal commerce and delivery platform**.

It serves:
- **Millions of customers** via the Customer Flutter App
- **Delivery partners** via the Delivery Partner Flutter App
- **All business operations roles** via the Enterprise Web Portal

---

## 2. Complete Document Index

| Document | Purpose |
|---|---|
| [ENTERPRISE_ARCHITECTURE_V2.md](ENTERPRISE_ARCHITECTURE_V2.md) | System overview, service map, tech stack, deployment topology |
| [SECURITY_ARCHITECTURE.md](SECURITY_ARCHITECTURE.md) | Zero Trust design, threat model, JWT lifecycle, OWASP coverage |
| [RBAC_MATRIX.md](RBAC_MATRIX.md) | 12 roles × all API endpoints + portal module access |
| [DATA_ISOLATION_DESIGN.md](DATA_ISOLATION_DESIGN.md) | AuthContext, tenant scoping, IDOR prevention, RLS |
| [API_SECURITY_GUIDE.md](API_SECURITY_GUIDE.md) | Rate limiting, input validation, idempotency, error standards |
| [DATABASE_SECURITY_GUIDE.md](DATABASE_SECURITY_GUIDE.md) | Flyway, soft delete, audit tables, encryption, connection pooling |
| [WEB_PORTAL_ARCHITECTURE.md](WEB_PORTAL_ARCHITECTURE.md) | Single React app, permission-aware routing, module design |
| [FLUTTER_APP_ARCHITECTURE.md](FLUTTER_APP_ARCHITECTURE.md) | Customer App + Delivery App specs, GPS tracking, security |
| [COMMUNICATION_SECURITY.md](COMMUNICATION_SECURITY.md) | TLS, mTLS, RabbitMQ auth, Redis ACL, secret management |
| **FINAL_PLATFORM_BLUEPRINT.md** | This document — master consolidated reference |

---

## 3. Full Platform Architecture Diagram

```
╔══════════════════════════════════════════════════════════════════════╗
║                       CLIENT TIER                                    ║
║                                                                      ║
║  ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐   ║
║  │ Flutter Customer│  │ Flutter Delivery  │  │ Enterprise Portal│   ║
║  │ App (iOS/Android│  │ Partner App       │  │ React/TS (4000)  │   ║
║  │                 │  │ e:\shopping\      │  │ e:\shopping\     │   ║
║  │ e:\shopping\    │  │ delivery-app\     │  │ enterprise-      │   ║
║  │ lib\            │  │                   │  │ portal\          │   ║
║  └────────┬────────┘  └────────┬──────────┘  └────────┬─────────┘  ║
╚═══════════╪════════════════════╪════════════════════════╪════════════╝
            │                   │                         │
            │          HTTPS / TLS 1.3                    │
            │                   │                         │
╔═══════════╪═══════════════════╪═════════════════════════╪════════════╗
║           ▼                   ▼                         ▼            ║
║     ┌─────────────────────────────────────────────────────┐         ║
║     │              API GATEWAY  (:8080)                    │         ║
║     │                                                       │         ║
║     │  GatewayJwtFilter    → JWT validation + claims        │         ║
║     │  RateLimitFilter     → Redis sliding window           │         ║
║     │  CorrelationIdFilter → inject X-Correlation-ID        │         ║
║     │  SecurityHeadersFilter → HSTS, CSP, X-Frame-Options  │         ║
║     │  GatewayRoutingConfig  → 16 downstream routes         │         ║
║     └───────────────────────────────────────────────────────┘         ║
║                              │ Internal HTTP (docker bridge)          ║
╚══════════════════════════════╪════════════════════════════════════════╝
                               │
          ┌─────────────────────┼──────────────────────────┐
          │                     │                           │
╔═════════╪═══════╗    ╔════════╪═══════════╗    ╔═════════╪═══════════╗
║ PLATFORM │       ║    ║BUSINESS│           ║    ║MESSAGING│           ║
║ SERVICES ▼       ║    ║SERVICES▼           ║    ║         ▼           ║
║                  ║    ║                    ║    ║ RabbitMQ :5672      ║
║ auth      :8081  ║    ║ customer  :8082    ║    ║ ┌─────────────────┐ ║
║ branch    :8088  ║    ║ inventory :8083    ║    ║ │ order.created   │ ║
║ audit     :8091  ║    ║ order     :8084    ║    ║ │ payment.done    │ ║
║ config    :8090  ║    ║ payment   :8085    ║    ║ │ delivery.assign │ ║
║ notif     :8092  ║    ║ wallet    :8086    ║    ║ │ notification.go │ ║
║ scheduler :8093  ║    ║ delivery  :8087    ║    ║ └─────────────────┘ ║
╚══════════════════╝    ║ shop      :8094    ║    ╚═════════════════════╝
                        ║ brnch-mgr :8095    ║
                        ║ cart      :8096    ║
                        ║ search    :8089    ║
                        ║ support   :8098    ║
                        ╚════════════════════╝
                                  │
         ┌────────────────────────┼────────────────────┐
         ▼                        ▼                     ▼
╔════════════════╗    ╔════════════════════╗  ╔════════════════╗
║ PostgreSQL     ║    ║ Redis :6379        ║  ║ MinIO :9000    ║
║ + PostGIS      ║    ║ (auth + requirepass║  ║ (Object Store) ║
║ :5432          ║    ║  cart + sessions   ║  ╚════════════════╝
╚════════════════╝    ║  rate-limit)       ║
                      ╚════════════════════╝
```

---

## 4. Authentication State Machine

```
[Initial]
    │
    ▼
[LOGIN_SCREEN]
    │
    ├──── Google OAuth ────→ [REGISTRATION_REQUIRED] ─→ [Register] ─┐
    │                                                                  │
    ├──── Email+Password ──→ [PASSWORD_CHECK] ─────────────────────┐  │
    │                                                                │  │
    ├──── OTP Email/SMS ───→ [OTP_VERIFICATION] ───────────────────┤  │
    │                                                                │  │
    └──── All paths with MFA enabled ──→ [MFA_REQUIRED] ──────────┤  │
                                                                    ▼  ▼
                                                           [LOGIN_COMPLETED]
                                                                    │
                                              ┌────────────────────┤
                                              ▼                     ▼
                                    [Customer App]         [Delivery App]
                                    [Enterprise Portal]
```

---

## 5. Complete Role-Application Matrix

| Role | Customer App | Delivery App | Enterprise Portal |
|---|---|---|---|
| `ROLE_SUPER_ADMIN` | ❌ No | ❌ No | ✅ All modules |
| `ROLE_SYSTEM_ADMIN` | ❌ No | ❌ No | ✅ All except Roles |
| `ROLE_REGIONAL_MANAGER` | ❌ No | ❌ No | ✅ Region-scoped |
| `ROLE_BRANCH_MANAGER` | ❌ No | ❌ No | ✅ Branch-scoped |
| `ROLE_SHOP_OWNER` | ❌ No | ❌ No | ✅ Shop-scoped |
| `ROLE_SHOP_MANAGER` | ❌ No | ❌ No | ✅ Shop-scoped (limited) |
| `ROLE_DELIVERY_PARTNER` | ❌ No | ✅ Yes | ❌ No |
| `ROLE_CUSTOMER` | ✅ Yes | ❌ No | ❌ No |
| `ROLE_QA_ENGINEER` | ❌ No | ❌ No | ✅ + Testing Tools |
| `ROLE_SUPPORT_AGENT` | ❌ No | ❌ No | ✅ Support modules |
| `ROLE_FINANCE` | ❌ No | ❌ No | ✅ Finance modules |
| `ROLE_AUDITOR` | ❌ No | ❌ No | ✅ Audit logs only |

---

## 6. Port Reference

| Service | Port | Protocol |
|---|---|---|
| API Gateway | 8080 | HTTP (dev) / HTTPS (prod) |
| Auth Service | 8081 | HTTP (internal) |
| Customer Service | 8082 | HTTP (internal) |
| Inventory Service | 8083 | HTTP (internal) |
| Order Service | 8084 | HTTP (internal) |
| Payment Service | 8085 | HTTP (internal) |
| Wallet Service | 8086 | HTTP (internal) |
| Delivery Service | 8087 | HTTP (internal) |
| Branch Service | 8088 | HTTP (internal) |
| Search Service | 8089 | HTTP (internal) |
| Config Service | 8090 | HTTP (internal) |
| Audit Service | 8091 | HTTP (internal) |
| Notification Service | 8092 | HTTP (internal) |
| Scheduler Service | 8093 | HTTP (internal) |
| Shop Service | 8094 | HTTP (internal) |
| Branch Manager Service | 8095 | HTTP (internal) |
| Cart Service | 8096 | HTTP (internal) |
| PostgreSQL | 5432 | TCP/TLS |
| Redis | 6379 | TCP/TLS (prod) |
| RabbitMQ | 5672 | AMQP / 5671 AMQPS |
| RabbitMQ Management | 15672 | HTTP |
| MinIO API | 9000 | HTTP |
| MinIO Console | 9001 | HTTP |
| Mailhog SMTP | 1025 | SMTP |
| Mailhog Web | 8025 | HTTP |
| Prometheus | 9090 | HTTP |
| Grafana | 3000 | HTTP |
| Loki | 3100 | HTTP |
| **Testing Portal** | **3000** | **HTTP** |
| **Enterprise Portal** | **4000** | **HTTP (dev) / HTTPS (prod)** |

---

## 7. Security Maturity Levels

| Capability | Current State | Target (V2) |
|---|---|---|
| Authentication | ✅ Google, OTP, Password | ✅ + JWKS rotation |
| Authorization | ⚠️ Hardcoded ROLE_CUSTOMER | ✅ Full RBAC |
| JWT Validation at Gateway | ❌ Missing | ✅ GatewayJwtFilter |
| Data Isolation | ⚠️ Partial (shop-level) | ✅ Full AuthContext scoping |
| Rate Limiting | ⚠️ Only in AuthService | ✅ Gateway-level Redis |
| Audit Logging | ⚠️ Partial | ✅ All critical actions |
| Redis Auth | ❌ No password | ✅ requirepass + ACL |
| RabbitMQ Auth | ⚠️ Default guest/guest | ✅ Per-service credentials |
| Secret Management | ⚠️ docker-compose env | ✅ .env + Docker secrets |
| Soft Delete | ✅ Present | ✅ Verified |
| Optimistic Locking | ✅ @Version present | ✅ Verified |
| DB Migrations | ⚠️ JPA ddl-auto | ✅ Flyway |
| mTLS (internal) | ❌ Not implemented | 🔄 Architecture ready |
| Enterprise Portal | ❌ Only testing portal | ✅ Full RBAC portal |
| Delivery App | ❌ Not built | ✅ New Flutter project |

---

## 8. Go-Live Checklist

### Pre-Launch Security
- [ ] All JWT secrets rotated from dev defaults
- [ ] Redis password configured
- [ ] RabbitMQ per-service users created
- [ ] Database `hyperlocal_app` user has minimal privileges
- [ ] Flyway V2 migration applied (user_roles table)
- [ ] GatewayJwtFilter deployed and tested
- [ ] Rate limiting tested at expected traffic loads
- [ ] Certificate pinning deployed in Flutter apps
- [ ] All .env secrets migrated to Docker secrets

### Pre-Launch Functional
- [ ] SUPER_ADMIN account created in database
- [ ] BRANCH_MANAGER accounts assigned with correct branchId
- [ ] SHOP_OWNER accounts assigned with correct shopId
- [ ] DELIVERY_PARTNER accounts created
- [ ] Enterprise portal deployed at :4000
- [ ] All 20 portal modules verified for correct role visibility
- [ ] Delivery Flutter app deployed and GPS tracking verified
- [ ] Audit log captures all critical events
- [ ] Grafana dashboards configured for alerting
