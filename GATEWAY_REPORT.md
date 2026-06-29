# HyperLocal Platform — Spring Cloud Gateway Routing Report

This report documents the implementation of the Spring Cloud Gateway MVC service to replace the Python server as the main API Gateway for the HyperLocal Enterprise Platform.

---

## 1. Gateway Architecture & Dependencies

The [hyperlocal-api-gateway](file:///e:/shopping/hyperlocal-platform/hyperlocal-api-gateway) module is configured as a lightweight, non-database Spring Cloud Gateway for Spring MVC.

### Key Maven Configuration (`pom.xml`):
* Removed reactive `spring-cloud-starter-gateway` to prevent WebFlux classpath conflicts with standard Servlet MVC libraries.
* Added `spring-cloud-starter-gateway-mvc` and the `spring-cloud-dependencies` BOM:
  ```xml
  <dependency>
      <groupId>org.springframework.cloud</groupId>
      <artifactId>spring-cloud-starter-gateway-mvc</artifactId>
  </dependency>
  ```
* Excluded database configurations (`DataSourceAutoConfiguration`, `HibernateJpaAutoConfiguration`, `FlywayAutoConfiguration`) and Redis configurations in `GatewayApplication.java` to boot the gateway as a stateless router.

---

## 2. API Proxy Routing Mappings

All client API requests received by the gateway on port `8080` are proxied to their respective standalone service instances.

### Routes Implemented in `GatewayRoutingConfig.java`:
The router function proxies all HTTP verbs (GET, POST, PUT, DELETE) using wildcard path predicates:

| Path Pattern | Target Local Address | Target Subsystem |
| :--- | :--- | :--- |
| `/api/v1/auth/**` | `http://localhost:8081` | `auth-service` |
| `/api/v1/customers/**` | `http://localhost:8082` | `customer-service` |
| `/api/v1/inventory/**` | `http://localhost:8083` | `inventory-service` |
| `/api/v1/orders/**` | `http://localhost:8084` | `order-service` |
| `/api/v1/payments/**` | `http://localhost:8085` | `payment-service` |
| `/api/v1/wallets/**` | `http://localhost:8086` | `wallet-service` |
| `/api/v1/deliveries/**` | `http://localhost:8087` | `delivery-service` |
| `/api/v1/branches/**` | `http://localhost:8088` | `branch-service` |
| `/api/v1/search/**` | `http://localhost:8089` | `search-service` |
| `/api/v1/config/**` | `http://localhost:8090` | `config-service` |
| `/api/v1/audit/**` | `http://localhost:8091` | `audit-service` |
| `/api/v1/notifications/**` | `http://localhost:8092` | `notification-service` |
| `/api/v1/scheduler/**` | `http://localhost:8093` | `scheduler-service` |
| `/api/v1/shops/**` | `http://localhost:8094` | `shop-service` |
| `/api/v1/branch-manager/**` | `http://localhost:8095` | `branch-manager-service` |

---

## 3. Verification & Deployment

* **Compilation:** ✅ Built successfully.
* **Routing Setup:** Verified. All incoming client request patterns are handled by Spring Cloud Gateway MVC router rules.
* **MDC Context Interceptor:** Transitive context filtering (`CorrelationIdFilter.java`) is fully integrated to append correlation headers on proxied requests.
