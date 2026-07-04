# HyperLocal Platform — API Verification
**Phase:** P2 (Production Readiness)
**Status:** COMPLETE

---

## 1. Gateway Routing Mappings
All API calls from the client apps are processed through the API Gateway, validating JWT signatures and rate limit headers on every request.

---

## 2. API Telemetry Matrix

| Context Route | Target Service | Authentication | Response Check | Status |
|---|---|---|---|---|
| `/api/v1/auth/**` | `auth-service` | Public / Token | Code 200 / 201 | VERIFIED |
| `/api/v1/customers/**` | `auth-service` | Scoped JWT | Code 200 | VERIFIED |
| `/api/v1/branches/**` | `branch-service` | Scoped JWT | Code 200 | VERIFIED |
| `/api/v1/shops/**` | `shop-service` | Scoped JWT | Code 200 | VERIFIED |
| `/api/v1/inventory/**` | `inventory-service` | Scoped JWT | Code 200 | VERIFIED |
| `/api/v1/orders/**` | `order-service` | User JWT | Code 200 | VERIFIED |
| `/api/v1/deliveries/**`| `delivery-service` | Rider JWT | Code 200 | VERIFIED |
| `/api/v1/wallets/**` | `wallet-service` | Scoped JWT | Code 200 | VERIFIED |

---

## 3. Correlation Tracking
Every request header carries the `X-Correlation-ID` property, mapping the request context across services.
