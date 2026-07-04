# ENTERPRISE ARCHITECTURE V2
## HyperLocal Enterprise Platform — Complete Architecture Reference

**Version:** 2.0  
**Status:** Active  
**Classification:** Internal — Engineering

---

## 1. Executive Summary

The HyperLocal Enterprise Platform is a **multi-tenant, microservices-based commerce platform** designed for hyperlocal delivery and marketplace operations. Version 2 enforces Zero Trust security, hierarchical RBAC, tenant-aware data isolation, and enterprise-grade auditing across all platform layers.

The platform serves:
- **End customers** via a dedicated Flutter Customer Application
- **Delivery partners** via a dedicated Flutter Delivery Partner Application
- **All admin, merchant, QA, and support roles** via a single Enterprise Web Portal

---

## 2. Platform Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                                  │
│  Flutter Customer App  │  Flutter Delivery App  │  Enterprise    │
│  (iOS / Android)       │  (iOS / Android)       │  Web Portal    │
│                        │                        │  (port 4000)   │
└───────────┬────────────┴──────────┬─────────────┴───────┬───────┘
            │     HTTPS/TLS 1.3    │                     │
            ▼                      ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│              API GATEWAY  (port 8080)                           │
│  JWT Validation │ Rate Limiting │ Correlation IDs │ CORS        │
│  Route: /api/v1/auth/**  → auth-service                         │
│  Route: /api/v1/customers/** → customer-service                 │
│  Route: /api/v1/**        → [16 downstream services]           │
└──────────────────────────┬──────────────────────────────────────┘
                           │  mTLS-ready  +  JWT propagation
          ┌────────────────┼────────────────────────┐
          ▼                ▼                         ▼
┌──────────────┐  ┌──────────────────┐   ┌──────────────────────┐
│  PLATFORM    │  │    BUSINESS      │   │   MESSAGING          │
│  SERVICES    │  │    SERVICES      │   │   RabbitMQ           │
│              │  │                  │   │                      │
│ auth-service │  │ customer-service │   │ order.created        │
│ branch-svc   │  │ inventory-svc    │   │ payment.completed    │
│ audit-svc    │  │ order-service    │   │ delivery.assigned    │
│ config-svc   │  │ payment-service  │   │ notification.send    │
│ notif-svc    │  │ wallet-service   │   └──────────────────────┘
│ scheduler    │  │ delivery-service │
└──────────────┘  │ shop-service     │   ┌──────────────────────┐
                  │ cart-service     │   │   DATA LAYER         │
                  │ search-service   │   │                      │
                  │ support-service  │   │ PostgreSQL + PostGIS  │
                  │ ai-service       │   │ Redis (cache+session) │
                  │ reporting-svc    │   │ MinIO (object store) │
                  └──────────────────┘   └──────────────────────┘
```

---

## 3. Service Inventory

### Platform Services
| Service | Port | Responsibility |
|---|---|---|
| `auth-service` | 8081 | Authentication, JWT, Sessions, Device Binding |
| `branch-service` | 8088 | Branch CRUD, geofencing, operating hours |
| `audit-service` | 8091 | Immutable audit log ingestion and query |
| `config-service` | 8090 | Feature flags, app configuration |
| `notification-service` | 8092 | Push, email, SMS dispatch |
| `scheduler-service` | 8093 | Cron jobs, deferred tasks |

### Business Services
| Service | Port | Responsibility |
|---|---|---|
| `customer-service` | 8082 | Customer profile management |
| `inventory-service` | 8083 | Products, categories, stock levels |
| `order-service` | 8084 | Order lifecycle (8 states) |
| `payment-service` | 8085 | Payment gateway integration |
| `wallet-service` | 8086 | Customer wallet credit/debit |
| `delivery-service` | 8087 | Assignment, GPS tracking, partner management |
| `shop-service` | 8094 | Shop/merchant CRUD |
| `branch-manager-service` | 8095 | Branch-level admin operations |
| `cart-service` | 8096 | Shopping cart (Redis-backed) |
| `search-service` | 8089 | Elastic product search |
| `support-service` | 8098 | Customer support tickets |
| `ai-service` | — | Recommendations, demand forecasting |
| `reporting-service` | — | Analytics, revenue reports |
| `mobility-service` | — | Route optimization |

---

## 4. Technology Stack

| Layer | Technology | Version |
|---|---|---|
| **Backend Framework** | Spring Boot | 3.x |
| **Language** | Java | 21 LTS |
| **API Gateway** | Spring Cloud Gateway MVC | Latest |
| **Database** | PostgreSQL + PostGIS | 15.3 |
| **Cache / Session Store** | Redis | 7 |
| **Message Broker** | RabbitMQ | 3.13 |
| **Object Storage** | MinIO | Latest |
| **Auth Standard** | JWT (RS256 preferred / HS256 dev) + Google OAuth |
| **Password Hashing** | BCrypt (strength 12) |
| **DB Migrations** | Flyway |
| **Frontend Framework** | React 18 + TypeScript + Vite |
| **UI Design System** | Material UI v6 |
| **State Management** | TanStack React Query v5 |
| **Mobile Framework** | Flutter (Dart) |
| **Containerization** | Docker + Docker Compose |
| **Observability** | Prometheus + Grafana + Loki |

---

## 5. RBAC Role Hierarchy

```
SUPER_ADMIN
  └── SYSTEM_ADMIN
        ├── REGIONAL_MANAGER
        │     └── BRANCH_MANAGER
        │           ├── SHOP_OWNER
        │           │     └── SHOP_MANAGER
        │           └── DELIVERY_PARTNER
        ├── SUPPORT_AGENT
        ├── FINANCE
        ├── AUDITOR
        └── QA_ENGINEER

CUSTOMER  (standalone — no admin hierarchy)
```

---

## 6. Request Lifecycle

```
Client → [TLS 1.3] → API Gateway
  → CorrelationIdFilter (inject X-Correlation-ID)
  → GatewayJwtFilter (validate JWT, extract claims)
  → RateLimitFilter (Redis sliding window)
  → SecurityHeadersFilter (HSTS, CSP, X-Frame-Options)
  → Route to downstream service
  → AuthContextFilter (populate ThreadLocal from headers)
  → Controller → Service → Repository (scoped query)
  → AuditEventPublisher (async RabbitMQ event)
  ← Response with Correlation-ID echoed
```

---

## 7. Data Flow: Order Placement

```
Customer App
  POST /api/v1/cart/checkout
  → Gateway (validate JWT, rate limit)
  → cart-service (validate cart, calc total)
    → [RabbitMQ: cart.checkout.initiated]
  → order-service (create order in PENDING state)
    → [RabbitMQ: order.created]
  → payment-service (initiate payment)
    → [RabbitMQ: payment.initiated]
  ← 202 Accepted + orderId

Payment Gateway Callback
  POST /api/v1/payments/callback
  → payment-service (verify signature, record result)
    → [RabbitMQ: payment.completed]
  → order-service (advance to ACCEPTED)
    → [RabbitMQ: order.accepted]
  → delivery-service (assign partner)
  → notification-service (push to customer)
```

---

## 8. Deployment Architecture

All services deployed via Docker Compose in a single `hyperlocal-network` bridge network. In production, this maps to Kubernetes namespaces with NetworkPolicy enforcement.

```
External Internet
    │
    ▼ :443 (Nginx/Caddy TLS termination) [production]
    │ :8080 (direct) [development]
    ▼
API Gateway (hyperlocal-api-gateway)
    │
    ├── Platform Services (internal network only)
    ├── Business Services (internal network only)
    │
    ├── PostgreSQL :5432 (internal only)
    ├── Redis :6379 (internal only, authenticated)
    ├── RabbitMQ :5672 (internal only, authenticated)
    └── MinIO :9000 (internal) / :9001 console
```
