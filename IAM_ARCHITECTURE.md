# HyperLocal Platform — Identity & Access Management (IAM) Architecture
**Version:** 3.0 (Enterprise Zero Trust Edition)

---

## 1. IAM Architectural Philosophy

The HyperLocal Identity Platform replaces basic auth mechanisms with a secure, centralized **Zero Trust Access** core. It functions as the single authority for identity validation, cryptographic signature verification, session state checks, and resource access scopes across all three system clients:

```
[Customer App] ────► [ API GATEWAY ] ◄──── [Delivery App]
                           │
                           ▼
                  [Enterprise Portal]
                           │
                           ▼
                 [Auth Service (IAM)]
```

---

## 2. Key Identity Capabilities

### 2.1 Multi-Tenant Core Scopes
Every identity record in the database holds explicit tenant mappings:
- **Global**: Bypasses regional scoping (`ROLE_SUPER_ADMIN`).
- **Branch Scoped**: Scope restricted to specific geofence nodes (`ROLE_BRANCH_MANAGER`).
- **Shop Scoped**: Scoped to specific merchant storefront IDs (`ROLE_SHOP_OWNER`).
- **User Scoped**: Restricts queries to the user’s personal ID (`ROLE_CUSTOMER`, `ROLE_DELIVERY_PARTNER`).

### 2.2 Security Tokens (Token Pairs)
- **Access Token**: Short-lived, asymmetric JWT (RS256 signed, 15-minute expiry). Includes list of roles, `branchId`, `shopId`, `sessionId`, and `deviceId`.
- **Refresh Token**: Long-lived, opaque UUID. Stored as a secure BCrypt hash in the database, validating token rotation cycles.
- **Refresh Token Rotation (RTR)**: On token exchange, the old refresh token is immediately blacklisted, and a new token pair is issued.

### 2.3 Identity Life Cycle
```
[User Provisioned] ──► [Invite Dispatched] ──► [Password Setup] ──► [Account Activated]
                                                                          │
                                         [Account Blocked] ◄── [Suspended]┘
```
- **Administrative Users**: Provisioned by authenticated Super Admins with temp credentials. Require immediate password reset on initial login.
- **Customers & Partners**: Self-registered through secure OTP verification or federated Google OAuth.
- **Account Suspension**: Hard lock in the `users` repository instantly revoking all active sessions in the registry.
