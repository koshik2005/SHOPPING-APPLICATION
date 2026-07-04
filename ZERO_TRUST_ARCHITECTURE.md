# HyperLocal Platform — Zero Trust Security Design
**Version:** 3.0

---

## 1. Zero Trust Principles

The platform is designed around **Zero Trust Architecture (ZTA)** principles:

> **"Never trust, always verify."**

No request is implicitly trusted based on its origin (e.g. internal service, VPN, local network). Every request must be authenticated, authorized, and scoped on every call.

---

## 2. Dynamic Policy Verification Matrix

When a client initiates a request, the API Gateway and downstream services validate the transaction across multiple security dimensions:

```
[Request Received] 
        │
        ├──► [JWT Signature Validation] (RS256)
        ├──► [Active Session Check] (Redis Registry)
        ├──► [Role & Permission Check] (RBAC Matrix)
        ├──► [Data Scope Scoping] (AuthContext)
        └──► [Correlation Trace Check] (MDC logs)
```

1. **Authentication Check**: Verifies the JWT signature using the auth service's public JWKS endpoint.
2. **Session Verification**: Verifies the session ID is active in the Redis session registry.
3. **Role & Permission Check**: Confirms the user has the required roles and permissions.
4. **Data Scope Scoping**: Downstream services use `AuthContext` to restrict queries to the caller's specific branch, shop, or user context.
5. **Correlation Trace Check**: Every transaction logs a unique correlation ID to create a continuous audit trail.

---

## 3. Perimeter & Network Isolation

- **Docker Bridge Separation**: Services communicate within isolated networks. The API Gateway is the only service exposed to the public internet.
- **Mutual TLS (mTLS) Ready**: Service-to-service communication is designed to support mutual TLS encryption using mesh infrastructure like Istio.
- **Log Management**: Loki collects logs with correlation IDs, allowing administrators to trace requests across services.
