# API SECURITY GUIDE
## HyperLocal Enterprise Platform — API Security Standards

---

## 1. Authentication Requirements

Every API endpoint must be classified as:

| Class | Description | JWT Required | Example |
|---|---|---|---|
| **PUBLIC** | No auth needed | ❌ | `GET /api/v1/config/app-settings` |
| **AUTHENTICATED** | Valid JWT required | ✅ | `GET /api/v1/customers/me` |
| **AUTHORIZED** | JWT + specific role required | ✅ + Role | `POST /api/v1/branches` |
| **SCOPED** | JWT + role + resource ownership | ✅ + Role + Scope | `GET /api/v1/orders/{id}` |

### JWT Validation Checklist (Gateway)
- [ ] `Authorization: Bearer <token>` header present
- [ ] Token is well-formed (3 parts: header.payload.signature)
- [ ] Signature validates against current signing key
- [ ] `exp` claim is in the future
- [ ] `iss` == `"hyperlocal-auth-service"`
- [ ] `aud` == `"hyperlocal-platform"`
- [ ] Session ID (`sessionId` claim) exists in Redis active sessions

---

## 2. Rate Limiting

### Implementation (Redis Sliding Window)
```java
// RateLimitFilter.java in API Gateway
// Key format: ratelimit:{endpoint_category}:{identifier}
// Sliding window: 60 seconds

String key = "ratelimit:auth:" + clientIp;
Long count = redisTemplate.opsForValue().increment(key);
if (count == 1) {
    redisTemplate.expire(key, 60, TimeUnit.SECONDS);
}
if (count > LIMIT) {
    response.setStatus(429);
    response.setHeader("Retry-After", "60");
    return;
}
```

### Limits
| Category | Key | Window | Limit |
|---|---|---|---|
| Auth (login/register) | IP | 1 min | 10 |
| OTP send | identity (email/phone) | 5 min | 3 |
| OTP verify | identity | 5 min | 5 |
| Standard API | userId | 1 min | 300 |
| Search | userId | 1 min | 60 |
| Admin operations | userId | 1 min | 120 |

---

## 3. Input Validation Standards

### Bean Validation Annotations
```java
public record CreateProductRequest(
    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 100, message = "Name must be 2–100 characters")
    String name,

    @NotNull @DecimalMin("0.01") @DecimalMax("999999.99")
    BigDecimal price,

    @NotNull
    UUID shopId,

    @NotBlank @Size(max = 2000)
    String description,

    @Pattern(regexp = "^https://cdn\\.hyperlocal\\.app/.*",
             message = "Image URL must be from CDN")
    String imageUrl
) {}
```

### Dangerous Input Patterns (Blocked at Gateway)
```yaml
# Nginx/Gateway block patterns:
- SQL meta-characters in path params: /orders/' OR 1=1--
- Path traversal: /../../../etc/passwd
- Oversized payloads: > 2MB for standard endpoints, > 50MB for file uploads
- Binary content-type mismatch: JSON endpoint receiving XML
```

---

## 4. Correlation IDs

Every request receives a unique `X-Correlation-ID` header at the gateway:

```java
// MdcCorrelationFilter.java (already implemented in hyperlocal-common)
String correlationId = Optional.ofNullable(request.getHeader("X-Correlation-ID"))
    .filter(h -> h.matches("[a-f0-9\\-]{36}"))  // Validate format
    .orElse(UUID.randomUUID().toString());

MDC.put("correlationId", correlationId);
response.setHeader("X-Correlation-ID", correlationId);
```

All log entries include `correlationId` for request tracing across services.

---

## 5. Idempotency

Critical write operations support idempotent re-submission:

```java
// Order creation, payment initiation, wallet operations
@PostMapping("/orders")
public ResponseEntity<OrderResponse> createOrder(
    @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
    @Valid @RequestBody CreateOrderRequest request) {

    if (idempotencyKey != null) {
        // Check Redis for existing result with this key
        String cached = redisTemplate.opsForValue().get("idempotency:" + idempotencyKey);
        if (cached != null) {
            return ResponseEntity.ok(objectMapper.readValue(cached, OrderResponse.class));
        }
    }
    OrderResponse result = orderService.createOrder(request);
    if (idempotencyKey != null) {
        // Cache result for 24 hours
        redisTemplate.opsForValue().set("idempotency:" + idempotencyKey,
            objectMapper.writeValueAsString(result), 24, TimeUnit.HOURS);
    }
    return ResponseEntity.status(201).body(result);
}
```

---

## 6. Replay Attack Prevention

For payment callbacks and sensitive webhooks:

```java
// Webhook signature verification
String signature = request.getHeader("X-Webhook-Signature");
String body = new String(request.getInputStream().readAllBytes());
String expectedSig = hmacSha256(WEBHOOK_SECRET, body);

if (!MessageDigest.isEqual(signature.getBytes(), expectedSig.getBytes())) {
    throw new SecurityException("Invalid webhook signature");
}

// Replay prevention: check nonce not seen before
String nonce = request.getHeader("X-Nonce");
if (redisTemplate.opsForValue().get("nonce:" + nonce) != null) {
    throw new SecurityException("Replay detected: nonce already used");
}
redisTemplate.opsForValue().set("nonce:" + nonce, "1", 5, TimeUnit.MINUTES);
```

---

## 7. API Versioning

All APIs are versioned via URL path:
```
/api/v1/...   Current stable version
/api/v2/...   Future — breaking changes go here
```

Version negotiation rules:
- `v1` is supported for minimum 12 months after `v2` release
- Deprecation notices added to response headers: `Deprecation: true`, `Sunset: <date>`
- Clients should always specify version explicitly

---

## 8. Error Response Standard

```json
{
  "errorCode":     "PRODUCT_NOT_FOUND",
  "message":       "Product with ID 'abc-123' was not found",
  "correlationId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "timestamp":     "2026-07-03T10:00:00Z",
  "path":          "/api/v1/inventory/products/abc-123"
}
```

**Never include:**
- Stack traces
- Internal class names
- Database error messages
- SQL queries
- File paths

---

## 9. CORS Configuration

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of(
        "https://portal.hyperlocal.app",   // Production portal
        "http://localhost:4000"            // Dev portal
    ));
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
    config.setAllowedHeaders(List.of(
        "Authorization", "Content-Type", "X-Correlation-ID",
        "X-Device-Info", "Idempotency-Key"
    ));
    config.setAllowCredentials(true);
    config.setMaxAge(3600L);
    return new UrlBasedCorsConfigurationSource();
}
```

---

## 10. Security Testing Checklist

Before every release, verify:

- [ ] JWT with tampered payload rejected (401)
- [ ] JWT with wrong signature rejected (401)
- [ ] Expired JWT rejected (401)
- [ ] Missing JWT on protected endpoint rejected (401)
- [ ] ROLE_CUSTOMER token rejected on admin endpoint (403)
- [ ] BRANCH_MANAGER accessing another branch's data rejected (403)
- [ ] SQL injection in path params returns 400, not 500
- [ ] XSS payload in JSON body sanitized in response
- [ ] Rate limit triggers after specified threshold (429)
- [ ] Replay of payment callback with same nonce rejected
- [ ] CORS rejects origin not in allowlist
- [ ] Error responses contain no stack traces in production
