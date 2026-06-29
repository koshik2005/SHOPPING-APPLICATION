# Environment Audit Report — HyperLocal Enterprise Platform

This document details the configuration audit of the environment properties and variables across the platform microservices.

---

## 1. Properties Verification Status

All 19 microservices have been audited to ensure compliance with the Twelve-Factor App methodology for configuration management.

* **Standardization:** Every microservice has a standard `src/main/resources/application.properties` file.
* **Environment Bindings:** All critical properties (Databases, Redis, RabbitMQ, SMTP, JWT Signing Key, and Google Web Clients) are bound to environment variables via the `${VAR:default}` syntax.
* **Zero Hardcoded Secrets:** No hardcoded passwords, tokens, API keys, or private URLs are declared in plain text.

---

## 2. Microservice Property Matrix

| Service Name | Port | Database (PostgreSQL) | Message Queue | Cache | Actuator / Metrics |
|--------------|------|------------------------|---------------|-------|--------------------|
| `api-gateway` | 8080 | N/A (Routing only) | N/A | Redis | Health / Prometheus |
| `auth-service` | 8081 | `${DB_NAME:hyperlocal_auth_db}` | RabbitMQ | Redis | Health / Prometheus |
| `customer-service` | 8082 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `inventory-service` | 8083 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `order-service` | 8084 | `${DB_NAME:hyperlocal_db}` | RabbitMQ | N/A | Health / Prometheus |
| `payment-service` | 8085 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `wallet-service` | 8086 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `delivery-service` | 8087 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `branch-service` | 8088 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `search-service` | 8089 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `config-service` | 8090 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `audit-service` | 8091 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `notification-service`| 8092 | `${DB_NAME:hyperlocal_db}` | RabbitMQ | N/A | Health / Prometheus |
| `scheduler-service` | 8093 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `shop-service` | 8094 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `branch-manager` | 8095 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `cart-service` | 8096 | `${DB_NAME:hyperlocal_db}` | N/A | Redis | Health / Prometheus |
| `mobility-service` | 8097 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `support-service` | 8098 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `ai-service` | 8099 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |
| `reporting-service` | 8100 | `${DB_NAME:hyperlocal_db}` | N/A | N/A | Health / Prometheus |

---

## 3. Environment Variables Definition

All service deployments resolve configuration using the following environment variable namespace:

* **`DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` / `DB_PASS`:** PostgreSQL details.
* **`REDIS_HOST` / `REDIS_PORT`:** Redis details.
* **`RABBITMQ_HOST` / `RABBITMQ_PORT` / `RABBITMQ_USER` / `RABBITMQ_PASS`:** RabbitMQ details.
* **`SMTP_HOST` / `SMTP_PORT` / `SMTP_FROM`:** SMTP integration.
* **`JWT_SECRET` / `JWT_EXPIRY_ACCESS` / `JWT_EXPIRY_REFRESH`:** Token signing and expiry rules.
* **`GOOGLE_CLIENT_WEB_ID`:** Google OAuth Client credentials.

---

## Verdict
**Status:** **100% Environment-Driven.** All services satisfy the clean separation of code and configuration. No secrets or environment-specific values are hardcoded in the codebase.
