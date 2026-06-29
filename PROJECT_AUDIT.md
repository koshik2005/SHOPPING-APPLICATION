# Project Audit — HyperLocal Enterprise Platform

A complete review of the HyperLocal codebase has been executed. Filenames, class structures, package paths, and routing layouts have been inspected to isolate production readiness blockers.

---

## 1. Modular Directory Structures

### Root: Maven Aggregator (`/pom.xml`)
Coordinates Java JRE 21 compiler compilation and declares standard dependencies (Spring Boot 3.3.0, Spring Cloud 2023.0.2, Lombok) across the submodules:
1. **`hyperlocal-core`**: Core models (`ApiResponse`, `Coordinates`, `GeoLocation`, `Money`) and JPA `@MappedSuperclass` definitions (`BaseEntity`).
2. **`hyperlocal-common`**: System exceptions, utility classes (`ValidationUtils`, `CorrelationIdUtils`), and the controller advice handler (`GlobalExceptionHandler`).
3. **`hyperlocal-configuration`**: Contains the complete collection of Flyway database migrations (`db/migration/V1__database_init.sql` to `V11__otp_support.sql`).
4. **`hyperlocal-api-gateway`**: Spring Cloud Gateway MVC proxy dispatching route requests (`/api/v1/*`) to the respective microservices.
5. **`hyperlocal-integrations`**: Client wrappers for external APIs (stubs for Google Maps, SMS gateways, and Push FCM endpoints).
6. **`hyperlocal-services`**:
   - `platform/`: `auth-service`, `branch-service`, `config-service`, `notification-service`, `scheduler-service`, `audit-service`.
   - `business/`: `customer-service`, `shop-service`, `inventory-service`, `search-service`, `cart-service`, `order-service`, `payment-service`, `wallet-service`, `delivery-service`, `support-service`, `mobility-service`, `ai-service`, `reporting-service`, `branch-manager-service`.

---

## 2. Component Audits

### 1. API Routing Configuration
- **Status:** Integrated via Spring Cloud Gateway.
- **Blockers:** Hardcoded `localhost` destination targets in `GatewayRoutingConfig.java` prevent dynamic configuration inside containers.
- **Verification:** Requests default to gateway port `8080`, which clashes with the default Python port.

### 2. Databases & Flyway Configuration
- **Status:** Core database migrations are centralized in `hyperlocal-configuration`.
- **Blockers:**
  - H2 in-memory databases are hardcoded by default in microservices lacking properties configurations.
  - Flyway is disabled or missing references in 13 business services.
- **Verification:** Only `auth-service` contains active PostgreSQL parameters in its properties file.

### 3. Identity & Session Hardening
- **Status:** Authentication services support Google Sign-In verification, password hashing via BCrypt, and refresh token rotation.
- **Blockers:**
  - `JwtProvider.java` is a stub returning hardcoded mockup token bytes.
  - Login history logs hardcode client IP addresses to `127.0.0.1`.
  - Registered device streams hardcode device identifiers (`device_android_990`).

### 4. Commerce & Location Services
- **Status:** Orders, Carts, and LIP abstractions are architected.
- **Blockers:**
  - `CartService.java` hardcodes product variant prices to `10.00`.
  - `SearchService.java` returns hardcoded empty structures instead of querying catalog databases.
  - Delivery fees and tax formulas are calculated using mock figures.
