# Dependency Graph — HyperLocal Enterprise Platform

This document describes the compilation dependencies and runtime communications linkages across the platform modules.

---

## 1. Compile-Time Dependency Flow (Maven)

```mermaid
graph TD
    subgraph Shared Abstraction Modules
        Core[hyperlocal-core]
        Common[hyperlocal-common] --> Core
        Config[hyperlocal-configuration]
    end

    subgraph Integration Adapters
        Integrations[hyperlocal-integrations] --> Core
    end

    subgraph API Routing
        Gateway[hyperlocal-api-gateway]
    end

    subgraph Microservices Platform & Business
        Auth[auth-service] --> Core
        Auth --> Common
        Auth --> Config

        Business[Business Services: order, cart, wallet, etc.] --> Core
        Business --> Common
        Business --> Config
        Business --> Integrations
    end
```

---

## 2. Runtime Flow (Traffic & Data)

```mermaid
sequenceDiagram
    participant Flutter as Flutter Customer App
    participant GW as Spring Cloud Gateway (8080)
    participant Auth as auth-service (8081)
    participant Biz as Business Services (8082-8095)
    participant Cache as Redis Cache
    participant MQ as RabbitMQ Broker
    participant DB as PostgreSQL (5432)

    Flutter->>GW: API Request (X-Correlation-ID, Auth Header)
    alt Auth Endpoint (/api/v1/auth/*)
        GW->>Auth: Proxy Request
        Auth->>Cache: Rate limit & token check
        Auth->>DB: Query User Sessions
        Auth-->>GW: Return Token / Response
    else Business Endpoints (/api/v1/orders/*, etc.)
        GW->>Biz: Proxy Request
        Biz->>Cache: Read cache (e.g. Products/Cart)
        Biz->>DB: Query/Write Entities
        Biz->>MQ: Dispatch async event (e.g. OrderCreated)
        Biz-->>GW: Return JSON Payload
    end
    GW-->>Flutter: Return HTTP Response (ApiResponse)
```

---

## 3. Flutter Client Package Dependencies

- **`flutter_riverpod`**: State management and dependency injection container.
- **`dio`**: Http client library with retry capabilities, correlation header injections, and token refreshing interceptor.
- **`flutter_map` (OpenStreetMap)**: Dynamic map tile rendering engine using cached files.
- **`geolocator`**: Runtime geolocation provider supporting accuracy levels and mock GPS telemetry detection.
- **`permission_handler`**: Checks location settings status.
