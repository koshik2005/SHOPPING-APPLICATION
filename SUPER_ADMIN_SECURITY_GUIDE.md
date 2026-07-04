# HyperLocal Enterprise Portal — Security Manual
**Version:** 2.0

---

## 1. Security Architecture

The Super Admin Portal operates on **Zero Trust Architecture (ZTA)** principles. Every client session must be authenticated and authorized. No request or local storage layout is implicitly trusted.

```
[Web Browser] ────► [Gateway Validation] ────► [Downstream Services]
  - httpOnly session    - Signature Check        - Thread-scoped AuthContext
  - Bearer headers      - Expire Verification    - Scoped Entity Queries
```

---

## 2. Authentication Protocol

### 2.1 Multi-Method Authentication
The login screen supports three verification flows:
1. **Password Verification**: Classic email/password check hashed via BCrypt (cost strength 12).
2. **OTP Dispatch**: Two-step validation (transmits 6-digit random codes via SMTP / SMS provider).
3. **Google OAuth Federated Sign-In**: Token exchange verifying account identity using dynamic JWKS keys.

### 2.2 Token Storage & Rotation
- **Local Cache**: Tokens are stored in browser localStorage.
- **Refresh Interceptor**: Access tokens are automatically refreshed in the background upon `401 Unauthorized` responses by sending the refresh token to the rotation endpoint.
- **Session Revocation**: Remote logouts invalidate tokens and delete session records from Redis.

---

## 3. Authorization Enforcement

### 3.1 Route Protection (Permission Guards)
Every admin route in `App.tsx` is wrapped in a `ProtectedRoute` validation check:
```typescript
<Route path="users" element={
  <ProtectedRoute requirePermission="users:view">
    <Users />
  </ProtectedRoute>
} />
```

### 3.2 Fine-Grained UI Component Guarding
Components can be conditionally rendered based on permissions:
```typescript
<PermissionGuard require="branches:write">
  <Button onClick={openCreateDialog}>New Branch</Button>
</PermissionGuard>
```

---

## 4. Threat Mitigations

| Threat | Mitigation |
|---|---|
| **SQL Injection (SQLi)** | Enforced parameterized queries in all Hibernate/JPA repositories. |
| **Cross-Site Scripting (XSS)**| Auto-sanitized React JSX render context + secure Content-Security-Policy. |
| **Cross-Site Request Forgery (CSRF)**| Secure Bearer headers stored inside memory state/secure variables. |
| **Brute Force / Rate Limit** | Sliding window rate limits at the API Gateway backed by Redis. |
| **Insecure Direct Object Reference (IDOR)**| Scoped DB queries using ThreadLocal `AuthContext` to restrict access by `shopId`/`branchId`. |
