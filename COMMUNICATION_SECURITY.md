# COMMUNICATION SECURITY
## HyperLocal Enterprise Platform — End-to-End Communication Security

---

## 1. Communication Channels

```
Flutter Apps ←──HTTPS/TLS 1.3──→ API Gateway
API Gateway  ←──HTTP (internal)──→ Microservices (mTLS-ready)
Microservices ←──AMQP/TLS──→ RabbitMQ
Microservices ←──Redis Protocol──→ Redis (authenticated)
Services ←──JDBC──→ PostgreSQL (TLS connection)
```

---

## 2. Client → Gateway (Public Channel)

### TLS Configuration
- **Protocol:** TLS 1.3 only (TLS 1.0/1.1/1.2 disabled in production)
- **Cipher Suites:** TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256
- **Certificate:** Let's Encrypt (auto-renewal via Certbot) in production
- **HSTS:** `max-age=31536000; includeSubDomains; preload`

### Certificate Pinning (Flutter)
```dart
// Production only — pins the server's public key hash
const String PINNED_PUBLIC_KEY_HASH =
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

(dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) {
    final fingerprint = sha256.convert(cert.der).toString();
    return fingerprint == EXPECTED_FINGERPRINT;
  };
  return client;
};
```

### Required HTTP Headers (every request)
```http
Authorization: Bearer <JWT>
X-Correlation-ID: <UUID>
X-Device-Info: id=<deviceId>;model=<model>;os=<osVersion>;fcm=<token>
Content-Type: application/json
```

---

## 3. Gateway → Microservices (Internal Channel)

### Current State
All inter-service communication is HTTP within the `hyperlocal-network` Docker bridge network — isolated from the public internet.

### mTLS-Ready Architecture (Production Path)
When deploying to Kubernetes, each service will present a client certificate:
```yaml
# Each service's Deployment will mount:
# /etc/ssl/certs/service.crt  ← service identity certificate
# /etc/ssl/private/service.key ← private key (from K8s Secret)

# Istio sidecar proxy enforces mTLS at the mesh layer:
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
```

### JWT Propagation
The gateway extracts validated claims and forwards them as trusted internal headers:
```http
X-User-Id:     550e8400-e29b-41d4-a716-446655440000
X-User-Roles:  ROLE_BRANCH_MANAGER
X-Branch-Id:   branch-uuid
X-Shop-Id:     (empty)
X-Session-Id:  session-uuid
X-Correlation-ID: request-uuid
```
Internal services trust these headers **only from the gateway** (enforced by network policy in production).

---

## 4. RabbitMQ Security

### Authentication
```yaml
# docker-compose.yml
rabbitmq:
  environment:
    RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER}   # from .env
    RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASS}   # strong random password
    RABBITMQ_ERLANG_COOKIE: ${RABBITMQ_ERLANG_COOKIE}  # cluster cookie
```

### Virtual Hosts & Per-Service Credentials
Each service connects with a **dedicated user** with permissions only for its own exchanges/queues:
```bash
rabbitmqctl add_vhost hyperlocal
rabbitmqctl add_user order_svc <strong-password>
rabbitmqctl set_permissions -p hyperlocal order_svc \
  "^order\.*"   # configure only order.* exchanges
  "^order\.*"   # write only order.* exchanges
  "^(order|notification)\.*"  # read order + notification queues
```

### TLS for RabbitMQ (Production)
```yaml
rabbitmq:
  environment:
    RABBITMQ_SSL_CERTFILE: /certs/rabbitmq.crt
    RABBITMQ_SSL_KEYFILE: /certs/rabbitmq.key
    RABBITMQ_SSL_CACERTFILE: /certs/ca.crt
    RABBITMQ_SSL_VERIFY: verify_peer
    RABBITMQ_SSL_FAIL_IF_NO_PEER_CERT: "true"
  ports:
    - "5671:5671"   # AMQPS (TLS)
    # 5672 (plain) not exposed
```

### Event Signing (Future)
For critical financial events (payment.completed, wallet.credited), messages will include:
```json
{
  "eventId": "uuid",
  "eventType": "payment.completed",
  "payload": { ... },
  "signature": "HMAC-SHA256(payload, EVENT_SIGNING_KEY)",
  "timestamp": "2026-07-03T10:00:00Z"
}
```
Consumers verify signature before processing — prevents spoofed events if broker is compromised.

---

## 5. Redis Security

### Authentication
```yaml
# docker-compose.yml
redis:
  command: >
    redis-server
    --requirepass ${REDIS_PASSWORD}
    --maxmemory 256mb
    --maxmemory-policy allkeys-lru
    --bind 127.0.0.1  # bind only to internal network
```

### ACL (Redis 6+)
```bash
# auth-service: can access session:* and ratelimit:* keys only
ACL SETUSER auth_svc on ><password> ~session:* ~ratelimit:* +GET +SET +DEL +EXPIRE

# cart-service: can access cart:* keys only
ACL SETUSER cart_svc on ><password> ~cart:* +GET +SET +DEL +EXPIRE
```

### TLS for Redis (Production)
```bash
redis-server --tls-port 6380 --port 0 \
  --tls-cert-file /certs/redis.crt \
  --tls-key-file /certs/redis.key \
  --tls-ca-cert-file /certs/ca.crt \
  --tls-auth-clients yes
```

---

## 6. PostgreSQL TLS

```yaml
# docker-compose.yml
postgres:
  environment:
    POSTGRES_HOST_SSL: "on"
  command: >
    postgres
    -c ssl=on
    -c ssl_cert_file=/certs/server.crt
    -c ssl_key_file=/certs/server.key

# JDBC connection string in services:
# jdbc:postgresql://postgres:5432/hyperlocal_db?sslmode=require
```

---

## 7. Secret Management

### Development (Current)
Secrets are stored in `.env` file (gitignored):
```env
DB_PASS=<strong-random>
JWT_SECRET=<min-256-bit-key>
REDIS_PASSWORD=<strong-random>
RABBITMQ_PASS=<strong-random>
RABBITMQ_ERLANG_COOKIE=<random-string>
ENCRYPTION_KEY=<32-byte-aes-key>
GOOGLE_CLIENT_WEB_ID=<from-google-console>
```

### Production (Docker Secrets)
```yaml
# docker-compose.prod.yml
secrets:
  jwt_secret:
    external: true   # managed via Docker Swarm secrets or Vault

services:
  auth-service:
    secrets:
      - jwt_secret
    environment:
      JWT_SECRET_FILE: /run/secrets/jwt_secret
```

### Never In Code
- ❌ Never hardcode secrets in Java or TypeScript source files
- ❌ Never commit `.env` to Git
- ❌ Never log secrets (even partially)
- ✅ Read from environment variables at runtime only
- ✅ Rotate secrets quarterly with zero-downtime JWKS rotation

---

## 8. Network Isolation (Docker)

```yaml
networks:
  hyperlocal-network:
    driver: bridge
    internal: false   # gateway accessible externally
    ipam:
      config:
        - subnet: 172.20.0.0/16

# Only API Gateway exposes a port to the host:
# api-gateway: "8080:8080"
# All other services: NO ports exposed to host → internal only
```

In production Kubernetes:
```yaml
# NetworkPolicy: deny all ingress by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: deny-all }
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
# Allow: api-gateway → all services
# Allow: services → postgres, redis, rabbitmq
# Deny: services → external internet (except notification-service for FCM/SMTP)
```
