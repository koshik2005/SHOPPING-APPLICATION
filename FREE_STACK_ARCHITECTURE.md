# Free Stack Architecture — HyperLocal Enterprise Platform

## Philosophy

> "The platform must be fully functional using only free and open-source technologies.
> Every commercial provider must be replaceable via configuration only."

The HyperLocal platform is built on a **Zero Vendor Lock-In** architecture. Every external dependency is abstracted behind a provider interface, and all default implementations use free, self-hosted, or community-licensed technologies.

---

## Complete Technology Stack

| Layer | Technology | License | Purpose |
|-------|-----------|---------|---------|
| **Backend Runtime** | Java 21 + Spring Boot 3.3 | Apache 2.0 | Core microservices framework |
| **API Gateway** | Spring Cloud Gateway MVC | Apache 2.0 | Request routing, CORS, rate limiting |
| **Database** | PostgreSQL 15 | PostgreSQL License (Free) | Primary relational data store |
| **Spatial** | PostGIS 3.3 | GPL 2.0 | Geospatial queries for branch detection |
| **Migrations** | Flyway Community | Apache 2.0 | Schema versioning and migration |
| **Cache** | Redis 7 (Community) | BSD 3-Clause | Session cache, rate limiting |
| **Message Queue** | RabbitMQ 3.13 (Community) | Mozilla Public License | Async event-driven messaging |
| **Object Storage** | MinIO | GNU AGPL 3.0 | S3-compatible self-hosted file storage |
| **Email (Dev)** | MailHog | MIT | SMTP catch-all for development emails |
| **Search** | PostgreSQL Full-Text (ILIKE) | PostgreSQL License | Product and shop catalog search |
| **Maps** | OpenStreetMap + flutter_map | ODbL / MIT | Map tiles, rendering, markers |
| **Geocoding** | Nominatim | ODbL | Reverse geocoding, address lookup |
| **Routing** | OSRM | BSD 2-Clause | Route calculation, distance estimation |
| **Notifications** | Server-Sent Events (SSE) | Open Standard | Real-time push to Flutter clients |
| **Monitoring** | Prometheus | Apache 2.0 | Metrics collection and alerting |
| **Dashboards** | Grafana | Apache 2.0 | Metrics visualization |
| **Log Aggregation** | Loki | Apache 2.0 | Structured log storage and querying |
| **Mobile SDK** | Flutter | BSD 3-Clause | Cross-platform mobile application |
| **State Management** | Riverpod | MIT | Flutter dependency injection & state |
| **HTTP Client** | Dio | MIT | Flutter HTTP with interceptors |
| **JWT** | JJWT 0.12.6 | Apache 2.0 | Token signing and validation |
| **Containerization** | Docker + Docker Compose | Apache 2.0 | Service orchestration |
| **CI/CD** | GitHub Actions | Free for OSS | Build, test, deploy pipelines |
| **Build Tool** | Maven 3.9 | Apache 2.0 | Java build and dependency management |

---

## Provider Interface Abstraction Map

```
OtpProvider
├── DevLogOtpProvider        (Active: dev profile)      — Logs OTP to console
├── TwilioOtpProvider        (Future: prod profile)     — Twilio SMS
└── Msg91OtpProvider         (Future: prod profile)     — MSG91 SMS

EmailProvider
├── SmtpEmailProvider        (Active: dev + prod)       — MailHog / Any SMTP
└── SendGridEmailProvider    (Future: prod profile)     — SendGrid API

StorageProvider
├── MinioStorageProvider     (Active: dev + prod)       — MinIO self-hosted
├── S3StorageProvider        (Future: prod profile)     — AWS S3
└── CloudinaryProvider       (Future: prod profile)     — Cloudinary CDN

PaymentProvider
├── SimulatedPaymentProvider (Active: dev profile)      — All 6 states in-memory
├── RazorpayProvider         (Future: prod profile)     — Razorpay (India)
├── StripeProvider           (Future: prod profile)     — Stripe (International)
└── PhonePeProvider          (Future: prod profile)     — PhonePe UPI

PushNotificationProvider
├── SseNotificationController(Active: dev + self-hosted)— Server-Sent Events
└── FcmPushProvider          (Future: prod profile)     — Firebase Cloud Messaging

SearchProvider
├── PostgreSQLSearchProvider (Active: dev + prod)       — JPQL ILIKE full-text
└── ElasticsearchProvider    (Future: prod profile)     — Elasticsearch/OpenSearch

MapProvider (LIP)
├── OpenStreetMapProvider    (Active: all)              — OSM tiles + flutter_map
└── GoogleMapsProvider       (Future: optional)         — Google Maps SDK
```

---

## Cost Comparison

| Component | Current (FOSS) | Commercial Alternative | Monthly Saving |
|-----------|---------------|----------------------|----------------|
| Maps | OpenStreetMap (Free) | Google Maps ($7/1000 requests) | $700+ |
| SMS OTP | Dev log (Free) | Twilio ($0.0075/SMS) | $75+ |
| Email | MailHog (Free) | SendGrid ($20/month) | $20 |
| Storage | MinIO (Free, self-hosted) | AWS S3 ($23/100GB) | $23 |
| Push Notifications | SSE (Free) | Firebase ($0 free tier) | $0 |
| Search | PostgreSQL (Free) | Elasticsearch ($95/month) | $95 |
| Monitoring | Prometheus+Grafana (Free) | Datadog ($15/host) | $150+ |
| **TOTAL** | **~$0/month** | **~$1,000+/month** | **$1,000+** |

---

## Migration Path to Enterprise Providers

When ready to scale beyond self-hosted:

1. **SMS OTP** → Set `spring.profiles.active=prod` + `OTP_PROVIDER=twilio` env var → Inject `TwilioOtpProvider`
2. **Payments** → Set `PAYMENT_GATEWAY=razorpay` → Inject `RazorpayProvider`
3. **Storage** → Set `STORAGE_PROVIDER=s3` + AWS credentials → Inject `S3StorageProvider`
4. **Notifications** → Deploy Firebase project + set `PUSH_PROVIDER=fcm` → Inject `FcmPushProvider`
5. **Search** → Deploy Elasticsearch cluster + set `SEARCH_PROVIDER=elasticsearch` → Inject `ElasticsearchProvider`

**No business logic changes required. Only configuration.**

---

## Scalability Limits of Free Stack

| Component | Single Node Limit | Scale Strategy |
|-----------|------------------|----------------|
| PostgreSQL | ~10,000 concurrent connections | PgBouncer + Read replicas |
| Redis | ~100GB memory | Redis Cluster |
| RabbitMQ | ~50,000 messages/sec | Federation + Sharding |
| MinIO | ~1PB per node | MinIO distributed mode |
| SSE Connections | ~10,000 per notification-service instance | Horizontal scaling |
| Search (ILIKE) | ~1M products before slowdown | Add GIN/GiST indexes → then Elasticsearch |
