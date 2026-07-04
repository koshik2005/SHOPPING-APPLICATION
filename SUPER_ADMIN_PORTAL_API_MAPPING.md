# HyperLocal Enterprise Super Admin Portal — API Endpoint Specifications
**Version:** 2.0

---

## 1. Gateway Routing Architecture

All communication from the Enterprise Web Portal is channeled through the **Spring Cloud API Gateway** running on port `8080`. The gateway is responsible for authentication, JWT verification, header propagation, and rate limiting.

Downstream service paths are resolved dynamically using these prefix patterns:

```
[Portal UI] ─── http://localhost:8080/api/v1/... ───► [API Gateway]
                                                           │
              ┌─────────────────┬──────────────────────────┼───────────────┐
              ▼                 ▼                          ▼               ▼
        /auth/**          /customers/**              /inventory/**     /orders/**
      [Auth Service]    [Customer Service]        [Inventory Service] [Order Service]
```

---

## 2. API Contract Directory

### 2.1 Identity & Access Management (Auth Service)

| HTTP Method | URI Path | Access Level | Description |
|---|---|---|---|
| `POST` | `/api/v1/auth/verify-password` | Public | Authenticates credentials, returns JWT tokens and active Session ID. |
| `POST` | `/api/v1/auth/verify-otp` | Public | Verifies OTP code generated for specific identity. |
| `POST` | `/api/v1/auth/google-login` | Public | Signs in via Google OAuth profile authentication. |
| `POST` | `/api/v1/auth/token/refresh` | Public | Rotates expired access tokens using the refresh token context. |
| `POST` | `/api/v1/auth/logout` | Authenticated | Revokes current session ID in the Redis session registry. |
| `POST` | `/api/v1/auth/signout/remote` | SUPER_ADMIN | Terminates all active sessions for specified email. |
| `GET` | `/api/v1/auth/jwks.json` | Public | Serves the active public key set to decode and verify JWT signatures. |

### 2.2 User & Tenant Management (Customer & Auth Service)

| HTTP Method | URI Path | Access Level | Description |
|---|---|---|---|
| `GET` | `/api/v1/customers` | SUPER_ADMIN | Retrieves a list of registered customers. |
| `POST` | `/api/v1/customers` | SUPER_ADMIN | Creates new admin, manager, or support account. |
| `PUT` | `/api/v1/customers/{id}` | SUPER_ADMIN | Updates user metadata and role templates. |
| `DELETE` | `/api/v1/customers/{id}` | SUPER_ADMIN | Soft deletes user account (marks as deleted). |
| `POST` | `/api/v1/customers/{id}/suspend` | SYSTEM_ADMIN | Suspends/Locks account access. |
| `GET` | `/api/v1/customers/{id}/login-history` | AUDITOR | Retrieves login logs for security checks. |

### 2.3 Operations & Logistics (Branch & Shop Services)

| HTTP Method | URI Path | Access Level | Description |
|---|---|---|---|
| `GET` | `/api/v1/branches` | BRANCH_MANAGER | Lists branches scoped to manager region. |
| `POST` | `/api/v1/branches` | SYSTEM_ADMIN | Provisions a new branch with operational geofence. |
| `PUT` | `/api/v1/branches/{id}` | BRANCH_MANAGER | Updates operational hours, taxes, and service radius. |
| `GET` | `/api/v1/shops` | SHOP_OWNER | Lists shops. |
| `POST` | `/api/v1/shops` | BRANCH_MANAGER | Grants approval to launch a new vendor shop. |
| `PUT` | `/api/v1/shops/{id}/status` | BRANCH_MANAGER | Suspends or toggles merchant shop operations. |

### 2.4 Catalog & Stock Controls (Inventory Service)

| HTTP Method | URI Path | Access Level | Description |
|---|---|---|---|
| `GET` | `/api/v1/inventory/products` | SHOP_OWNER | Lists products scoped to shop. |
| `POST` | `/api/v1/inventory/products` | SHOP_OWNER | Creates product, variant specifications, and pricing. |
| `PUT` | `/api/v1/inventory/products/{id}` | SHOP_OWNER | Updates catalog description. |
| `PUT` | `/api/v1/inventory/stock/{variantId}` | SHOP_OWNER | Adjusts stock count (adds audit movement record). |
| `POST` | `/api/v1/inventory/products/bulk-import` | SHOP_OWNER | Performs bulk CSV import operations. |

### 2.5 Orders & Shipments (Order & Delivery Services)

| HTTP Method | URI Path | Access Level | Description |
|---|---|---|---|
| `GET` | `/api/v1/orders` | BRANCH_MANAGER | Lists active orders scoped to branch. |
| `PUT` | `/api/v1/orders/{id}/status` | BRANCH_MANAGER | Progresses order state machine (accepted, transit, delivered). |
| `PUT` | `/api/v1/orders/{id}/cancel` | SUPPORT_AGENT | Cancels active order and triggers refund flow. |
| `GET` | `/api/v1/deliveries/partners` | BRANCH_MANAGER | Lists active partners, locations, and KYC logs. |
| `POST` | `/api/v1/deliveries/{id}/location` | QA_ENGINEER | Updates GPS location for simulation/tracking. |

### 2.6 Financial Ledgers (Wallet & Payment Services)

| HTTP Method | URI Path | Access Level | Description |
|---|---|---|---|
| `GET` | `/api/v1/wallets/{id}` | FINANCE | Retrieves wallet ledger details. |
| `POST` | `/api/v1/wallets/{id}/credit` | FINANCE | Manually credits wallet (e.g. payout, refund correction). |
| `POST` | `/api/v1/wallets/{id}/debit` | FINANCE | Debits wallet balance. |
| `GET` | `/api/v1/payments/transactions` | FINANCE | Lists transaction logs. |

### 2.7 Platform Telemetry & Config (Audit & Config Services)

| HTTP Method | URI Path | Access Level | Description |
|---|---|---|---|
| `GET` | `/api/v1/audit/logs` | AUDITOR | Lists system audit events matching correlation ID. |
| `GET` | `/api/v1/config` | SYSTEM_ADMIN | Lists feature flags and currencies configurations. |
| `PUT` | `/api/v1/config` | SUPER_ADMIN | Updates parameters (maintenance mode toggle, key rotation). |
