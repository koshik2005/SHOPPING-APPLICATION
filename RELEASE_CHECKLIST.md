# Release Checklist — HyperLocal Enterprise Platform

Use this checklist before every deployment. All items marked 🔴 are blocking.

---

## Pre-Release: Code Quality

- [ ] 🔴 `mvn clean verify` passes across all modules
- [ ] 🔴 No `TODO` / `FIXME` comments affecting runtime behavior
- [ ] 🔴 No hardcoded secrets, passwords, or API keys in source code
- [ ] 🔴 All provider interfaces have a non-stub implementation active
- [ ] 🔴 `JwtProvider` generates real JJWT tokens (verified)
- [ ] 🟡 Code coverage ≥ 85% overall
- [ ] 🟡 Code coverage = 100% for AuthService and PaymentService

---

## Pre-Release: Infrastructure

- [ ] 🔴 PostgreSQL/PostGIS healthy (`pg_isready`)
- [ ] 🔴 Redis healthy (`redis-cli ping`)
- [ ] 🔴 RabbitMQ healthy (`rabbitmq-diagnostics ping`)
- [ ] 🔴 MinIO accessible on port 9000
- [ ] 🟡 MailHog / SMTP configured and reachable
- [ ] 🔴 All Flyway migrations applied successfully (check `flyway_schema_history`)
- [ ] 🔴 Table partitions exist for current + next 2 quarters (V12 migration)

---

## Pre-Release: Authentication

- [ ] 🔴 Google Sign-In returns valid JWT (not a stub string)
- [ ] 🔴 JWT signature verifiable with `jwt.secret` key
- [ ] 🔴 Refresh token rotation works (old token invalidated after use)
- [ ] 🔴 Session logout clears Redis session key
- [ ] 🔴 Remote logout invalidates all user sessions
- [ ] 🔴 OTP rate limiting: max 5 attempts per 15 minutes enforced
- [ ] 🔴 Client IP is extracted from `X-Forwarded-For` (not hardcoded)
- [ ] 🔴 Device info extracted from `X-Device-Info` header

---

## Pre-Release: Commerce

- [ ] 🔴 Cart price = actual `product_variants.price` from database
- [ ] 🔴 Search returns real results (not empty list)
- [ ] 🔴 Checkout creates real order in database
- [ ] 🔴 Wallet transactions persisted correctly
- [ ] 🔴 Payment provider active and non-stub (Simulated in dev is OK)
- [ ] 🟡 Invoice generation produces valid PDF

---

## Pre-Release: Security

- [ ] 🔴 No plaintext secrets in `application.properties` (use `${ENV_VAR}` references)
- [ ] 🔴 HSTS header present on all responses
- [ ] 🔴 X-Frame-Options: DENY present
- [ ] 🔴 X-Content-Type-Options: nosniff present
- [ ] 🔴 CORS configured (not wildcard `*` in production)
- [ ] 🔴 MDC Correlation IDs present in all log lines

---

## Pre-Release: Observability

- [ ] 🔴 `/actuator/health` returns `{"status":"UP"}` on all services
- [ ] 🔴 `/actuator/prometheus` returns metrics on all services
- [ ] 🔴 Prometheus scraping all services (check Grafana "Targets")
- [ ] 🟡 Grafana dashboards show request rates and error rates
- [ ] 🟡 Loki receiving structured logs from all services

---

## Pre-Release: Docker

- [ ] 🔴 `docker-compose up --build` completes without errors
- [ ] 🔴 All containers reach `healthy` state
- [ ] 🔴 API Gateway routes all paths correctly
- [ ] 🔴 `.env.template` filled in and saved as `.env`
- [ ] 🔴 `.env` is in `.gitignore`

---

## Pre-Release: External Providers (Production Only)

- [ ] 🔴 Google OAuth Web Client ID registered with production domain
- [ ] 🔴 Production SMTP credentials set (not MailHog)
- [ ] 🔴 Payment gateway credentials set (Razorpay / Stripe)
- [ ] 🔴 Domain name pointing to server IP
- [ ] 🔴 SSL certificate installed and valid
- [ ] 🟡 Firebase FCM credentials set (if using FCM over SSE)
- [ ] 🟡 SMS OTP provider credentials set (if using Twilio/MSG91)

---

## Go / No-Go Decision

- **All 🔴 items complete** → ✅ Platform is Launch Ready
- **Any 🔴 item incomplete** → 🚫 Do NOT deploy to production
