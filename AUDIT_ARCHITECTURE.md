# HyperLocal Platform — Immutable Audit Log Architecture
**Version:** 3.0

---

## 1. Audit Log Philosophy

To enforce compliance and guarantee non-repudiation, the platform writes **immutable audit records** for all critical system activities.

These logs are:
- **Write-Once**: Database roles do not have update or delete permissions on the `audit_events` tables.
- **Traceable**: Every entry maps to a unique request ID using `correlationId` tracking.
- **Detailed**: Logs include both the pre-change (`old_value`) and post-change (`new_value`) state representations.

---

## 2. Core Audit Event Schema

Audit events are logged in the `audit_events` database schema:

| Column | Type | Description |
|---|---|---|
| `id` | UUID | Unique identifier for the audit entry. |
| `event_id` | UUID | Unique identifier for the event. |
| `user_id` | UUID | User who performed the action (null for public events). |
| `user_role` | VARCHAR | Primary role of the caller. |
| `ip_address` | INET | Client IP address. |
| `correlation_id`| VARCHAR | Trace ID propagated from the gateway. |
| `action` | VARCHAR | Type of action performed (e.g. `PRODUCT_UPDATE`, `ROLE_CHANGE`). |
| `entity_type` | VARCHAR | Target entity model (e.g. `Order`, `Product`). |
| `entity_id` | UUID | Identifier for the target record. |
| `old_value` | JSONB | Pre-change record state (JSON payload). |
| `new_value` | JSONB | Post-change record state. |
| `status` | VARCHAR | Result status (e.g. `SUCCESS`, `FAILURE`). |

---

## 3. Auditing Workflows

```
[REST Controller Request] ──► [Service action complete]
                                     │
   [Async Publish] ◄── [Create Event Payload with correlationId]
         │
         ▼
[RabbitMQ Exchange: audit.events] ──► [Audit Service writes to DB]
```

- **Asynchronous Execution**: In order to keep API latency low, audit logs are published to the `audit.events` RabbitMQ exchange and written to the database asynchronously by the Audit service.
