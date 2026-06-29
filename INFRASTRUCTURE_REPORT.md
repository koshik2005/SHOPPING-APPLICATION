# HyperLocal Platform — Infrastructure Audit and Report

This report documents the containerization, network configuration, and database transition details for the HyperLocal Enterprise Platform.

---

## 1. Container Orchestration (`docker-compose.yml`)

The platform's external system dependencies are configured using the authored [docker-compose.yml](file:///e:/shopping/docker-compose.yml) file.

### Services Defined:
1. **PostgreSQL (`hyperlocal-postgres`):**
   - **Image:** `postgres:15-alpine`
   - **Default Port:** `5432` (mapped to host `5432`)
   - **Database Name:** `hyperlocal_auth_db`
   - **User Credentials:** `hyperlocal_user` / `hyperlocal_secure_pass`
   - **Storage Volume:** `postgres_data` (mapped to `/var/lib/postgresql/data`)
2. **Redis (`hyperlocal-redis`):**
   - **Image:** `redis:7-alpine`
   - **Default Port:** `6379` (mapped to host `6379`)
   - **Storage Volume:** `redis_data` (mapped to `/data`)
3. **RabbitMQ (`hyperlocal-rabbitmq`):**
   - **Image:** `rabbitmq:3-management-alpine`
   - **Ports Mapped:** `5672` (AMQP Broker) and `15672` (Web Management Console)
   - **Default Credentials:** `guest` / `guest`
   - **Storage Volume:** `rabbitmq_data` (mapped to `/var/lib/rabbitmq`)

### Networks:
- **Type:** Bridge network named `hyperlocal-network` enables isolated, name-resolved communication between containers.

---

## 2. Spring Boot Configurations (PostgreSQL Transition)

All database and broker parameters have been successfully moved from local in-memory H2 setups to the target production-grade stack inside [application.properties](file:///e:/shopping/hyperlocal-platform/hyperlocal-services/platform/auth-service/src/main/resources/application.properties):

* **Database Connection Properties:**
  ```properties
  spring.datasource.url=jdbc:postgresql://localhost:5432/hyperlocal_auth_db
  spring.datasource.driver-class-name=org.postgresql.Driver
  spring.datasource.username=hyperlocal_user
  spring.datasource.password=hyperlocal_secure_pass
  spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect
  spring.jpa.hibernate.ddl-auto=validate
  ```
* **Auto-run Flyway Migrations:**
  ```properties
  spring.flyway.enabled=true
  spring.flyway.locations=classpath:db/migration
  spring.flyway.baseline-on-migrate=true
  ```
* **Active Broker Endpoints:**
  - Redis Host: `localhost:6379`
  - RabbitMQ Host: `localhost:5672` (user `guest`)

---

## 3. Runtime Verification Status

* **Flyway Schemas:** Mapped and validated (Ready).
* **Docker Service:** 🔴 **Offline**
* **Verification Status:** FAILED. 
* **Reason:** Docker Desktop is not installed on this Windows environment. An automated attempt using `winget` to install the service initiated but failed with exit code `4294967291` because Windows UAC requires an interactive Administrator confirmation to proceed.
* **Ports Audited:**
  - Port `5432` (PostgreSQL): Offline.
  - Port `6379` (Redis): Offline.
  - Port `5672` (RabbitMQ): Offline.

---

## 4. Verdict & Recommendations
To complete the setup, follow the instructions in the manual actions guidelines to start the Docker services. Once the Docker containers are online, Flyway will run migrations automatically upon starting the microservices.
