# SECURITY ARCHITECTURE
## HyperLocal Enterprise Platform — Zero Trust Security Design

**Version:** 2.0  
**Classification:** Internal — Security Team

---

## 1. Security Philosophy: Zero Trust

The platform operates on **Zero Trust Architecture (ZTA)** principles:

> **"Never trust, always verify."**

Every request — regardless of origin (internal service, browser, mobile app, VPN) — is treated as potentially hostile until proven otherwise by:
1. Valid, unexpired, correctly signed JWT
2. Authenticated session in the session registry
3. Role + scope authorization for the specific resource

---

## 2. Threat Model

### Attack Surface

| Surface | Threats |
|---|---|
| Public API (Gateway) | SQLi, XSS, CSRF, JWT tampering, replay attacks, brute force, IDOR |
| Authentication | Credential stuffing, OTP brute force, token theft, session hijacking |
| Internal Services | SSRF, privilege escalation, lateral movement if perimeter breached |
| Database | SQL injection, unauthorized access, data exfiltration |
| Message Broker | Event replay, spoofed events, unauthorized queue access |
| Flutter Apps | Reverse engineering, SSL stripping, token extraction from storage |
| Enterprise Portal | XSS, CSRF, broken access control |
| Admin Operations | Insider threat, privilege abuse, audit log tampering |

### Risk Classification

| Severity | Examples |
|---|---|
| **CRITICAL** | JWT secret compromise, DB credentials leak, admin account takeover |
| **HIGH** | IDOR across tenants, session fixation, OTP bypass |
| **MEDIUM** | Rate limit bypass, information disclosure |
| **LOW** | Missing security headers, verbose error messages |

---

## 3. Authentication Security

### 3.1 JWT Design
```
Header: { "alg": "HS256", "typ": "JWT" }   [dev]
         { "alg": "RS256", "typ": "JWT", "kid": "key-v2" }  [prod]

Payload: {
  "sub":       "550e8400-e29b-41d4-a716-446655440000",  // userId (UUID)
  "email":     "user@example.com",
  "roles":     ["ROLE_BRANCH_MANAGER"],
  "branchId":  "branch-uuid",
  "shopId":    null,
  "sessionId": "session-uuid",
  "deviceId":  "device-fingerprint",
  "iss":       "hyperlocal-auth-service",
  "aud":       "hyperlocal-platform",
  "iat":       1720000000,
  "exp":       1720000900  // 15-minute lifetime
}
```

### 3.2 Token Lifecycle
```
Login Request
  ↓
Auth Service issues:
  accessToken  (15 min, JWT)
  refreshToken (7 days, opaque UUID, BCrypt-hashed in DB)
  ↓
Client stores tokens securely:
  Flutter: FlutterSecureStorage (Keychain/Keystore)
  Web Portal: httpOnly cookie (accessToken) + sessionStorage (refreshToken)
  ↓
On accessToken expiry:
  Client sends refreshToken → Auth Service
  Auth Service: verify hash match → issue NEW accessToken + NEW refreshToken
  (Refresh Token Rotation — old token invalidated immediately)
  ↓
On logout:
  Session deleted from session_registry table
  refreshToken hash removed
  All other sessions can be terminated via logoutAll()
```

### 3.3 Multi-Factor Authentication
- Architecture is MFA-ready: `user.mfaEnabled` flag exists
- When enabled: login returns `MFA_REQUIRED` state → client presents TOTP/OTP
- TOTP secret stored encrypted in `user_mfa_secrets` table (future)

### 3.4 Device Binding
- Every login records device fingerprint (`deviceId`, `model`, `OS`, `push_token`)
- `UserDeviceEntity` tracks trusted devices
- Unrecognized device login triggers elevated risk score

---

## 4. Authorization Security

### 4.1 Gateway Layer (First Defense)
```java
// GatewayJwtFilter validates every non-public request:
// 1. Extract Bearer token from Authorization header
// 2. Verify signature against secret/public key
// 3. Verify expiry (exp claim)
// 4. Verify issuer (iss == "hyperlocal-auth-service")
// 5. Verify audience (aud == "hyperlocal-platform")
// 6. Check session is still active in Redis session cache
// 7. Inject claims as downstream headers
```

### 4.2 Service Layer (Second Defense)
```java
// Every protected endpoint uses @PreAuthorize:
@PreAuthorize("hasRole('BRANCH_MANAGER') and @authContext.branchId == #branchId")
public OrderPage getOrdersByBranch(UUID branchId, Pageable pageable) { ... }
```

### 4.3 Repository Layer (Third Defense)
```java
// Every query is scoped by tenancy context — never trusts URL parameters alone:
productRepository.findByShopIdAndDeletedFalse(
    authContext.requireShopId()  // throws 403 if no shop context
);
```

---

## 5. Input Validation

All API inputs validated at controller layer using Jakarta Bean Validation:
```java
@NotBlank @Email String email
@Size(min=8, max=72) String password
@Pattern(regexp="^[0-9]{6}$") String otpCode
@Valid @RequestBody CreateProductRequest request
```

All SQL access via JPA/Hibernate with parameterized queries — no string concatenation.

---

## 6. Output Sanitization

- Internal UUIDs used for all entity IDs (no sequential integer IDs exposed)
- Error responses return `errorCode` + `message` only — no stack traces in production
- Database entity fields with `@JsonIgnore` where applicable (password hashes, internal flags)
- Sensitive fields (phone numbers, emails) masked in logs

---

## 7. Rate Limiting

Redis-backed sliding window rate limiter at the API Gateway:

| Endpoint Category | Limit |
|---|---|
| Auth endpoints (`/api/v1/auth/**`) | 10 req/min per IP |
| OTP endpoints | 3 req/5min per identity |
| Standard API | 300 req/min per authenticated user |
| Search API | 60 req/min per user |
| Admin APIs | 120 req/min per user |

Exceeded limits return `429 Too Many Requests` with `Retry-After` header.

---

## 8. OWASP Top 10 Coverage

| OWASP Category | Mitigation |
|---|---|
| A01 Broken Access Control | JWT + RBAC at gateway + service + repository layers |
| A02 Cryptographic Failures | BCrypt (pwd), encrypted JWT secret, TLS 1.3, encrypted columns |
| A03 Injection | JPA parameterized queries, bean validation, no raw SQL |
| A04 Insecure Design | ZTA design, threat modeling, principle of least privilege |
| A05 Security Misconfiguration | Security headers filter, no debug endpoints in prod |
| A06 Vulnerable Components | Dependency scanning (OWASP Dependency Check in Maven) |
| A07 Auth Failures | Rate limiting, device binding, token rotation, session registry |
| A08 Data Integrity Failures | JWT signature verification, signed RabbitMQ events (future) |
| A09 Logging & Monitoring | Audit service, Loki log aggregation, Grafana alerts |
| A10 SSRF | Internal services not directly reachable; gateway is sole entry |

---

## 9. Security Headers

Applied by `SecurityHeadersFilter` in `hyperlocal-common`:

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'; img-src 'self' data: https://cdn.hyperlocal.app
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(self), microphone=()
```

---

## 10. Incident Response

### Security Event Categories
| Event | Action |
|---|---|
| 5 failed logins in 15 min | Auto-suspend account, alert SECURITY_ADMIN |
| Unrecognized device login | Flag HIGH risk, require MFA |
| JWT from revoked session | Immediate 401, log security event |
| Admin action on sensitive data | Audit event written to immutable log |
| Data exfiltration pattern | Rate limit triggers + alert |

### Audit Event Schema
```json
{
  "eventId":       "uuid",
  "userId":        "uuid",
  "userRole":      "ROLE_BRANCH_MANAGER",
  "deviceId":      "device-fingerprint",
  "ipAddress":     "203.0.113.42",
  "correlationId": "req-uuid",
  "timestamp":     "2026-07-03T10:00:00Z",
  "action":        "ORDER_STATUS_UPDATE",
  "entityType":    "Order",
  "entityId":      "order-uuid",
  "result":        "SUCCESS",
  "metadata":      { "from": "PENDING", "to": "ACCEPTED" }
}
```
