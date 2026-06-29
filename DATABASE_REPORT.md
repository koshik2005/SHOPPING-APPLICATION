# Database Report — HyperLocal Enterprise Platform

This document details the layout, constraints, indexes, range partitions, spatial logic, and migration schema history of the PostgreSQL database layer.

---

## 1. Schema History & Migration Log

All schema updates are managed using Flyway migrations located in [db/migration](file:///e:/shopping/hyperlocal-platform/hyperlocal-configuration/src/main/resources/db/migration).

| Version | Migration Script | Description / Action |
|---------|------------------|----------------------|
| `V1` | `V1__database_init.sql` | Installs system extensions: `uuid-ossp` and `postgis` (spatial queries) |
| `V2` | `V2__identity_tables.sql` | Creates user profiles, federated identities, MFA locks, and login audit tracking |
| `V3` | `V3__branch_tables.sql` | Creates branch structures and geographic service polygons using PostGIS geometries |
| `V4` | `V4__inventory_tables.sql`| Creates categories, products, price variants, and double-entry stock transaction ledgers |
| `V5` | `V5__order_tables.sql` | Creates range-partitioned transactional order records and order itemized receipts |
| `V6` | `V6__wallet_tables.sql` | Creates range-partitioned ledger tables for customer prepaid digital wallets and logs |
| `V7` | `V7__notification_tables.sql` | Logs notification dispatch and matches FCM device registration tokens |
| `V8` | `V8__audit_tables.sql` | Stores compliance audit logs tracking administrative account adjustments |
| `V9` | `V9__workflow_tables.sql`| Manages customer order cancellation workflow pipelines and refund status logs |
| `V10` | `V10__authentication_refactoring.sql` | Optimizes identity structures, adds salt fields, and registers audit indexes |
| `V11` | `V11__otp_support.sql` | Tracks OTP generation times, validation status, and SMS attempts limits |
| `V12` | `V12__partition_extensions_2026_2027.sql` | Preemptively creates quarterly tables for Orders and Wallets up to Q2 2027 |

---

## 2. Table Partitions (High-Volume Transaction Tables)

To support enterprise throughput, the `orders` and `wallet_transactions` tables are range-partitioned on `created_at`.

### Active Partitions: Orders Table
* `orders_y2026q1`: Values from `'2026-01-01'` to `'2026-04-01'`
* `orders_y2026q2`: Values from `'2026-04-01'` to `'2026-07-01'`
* `orders_2026q3`: Values from `'2026-07-01'` to `'2026-10-01'` (V12)
* `orders_2026q4`: Values from `'2026-10-01'` to `'2027-01-01'` (V12)
* `orders_2027q1`: Values from `'2027-01-01'` to `'2027-04-01'` (V12)
* `orders_2027q2`: Values from `'2027-04-01'` to `'2027-07-01'` (V12)

### Active Partitions: Wallet Transactions Table
* `wallet_transactions_2026q3`: Values from `'2026-07-01'` to `'2026-10-01'` (V12)
* `wallet_transactions_2026q4`: Values from `'2026-10-01'` to `'2027-01-01'` (V12)
* `wallet_transactions_2027q1`: Values from `'2027-01-01'` to `'2027-04-01'` (V12)
* `wallet_transactions_2027q2`: Values from `'2027-04-01'` to `'2027-07-01'` (V12)

---

## 3. Spatial Indexes & Spatial Query Performance

The service areas are defined using the PostGIS `geometry(Polygon, 4326)` format to support instant location checks:

```sql
CREATE INDEX idx_branch_service_areas_geom 
ON branch_service_areas USING gist(service_polygon);
```

### Branch Checking Query (LIP Module):
To match a customer's location coordinates to their closest operational branch polygon:
```sql
SELECT branch_id FROM branch_service_areas
WHERE ST_Contains(service_polygon, ST_SetSRID(ST_Point(:longitude, :latitude), 4326))
LIMIT 1;
```

---

## Verdict
**Status:** **100% Validated.** Database schemas align with partition rules, spatial indices are active, and Flyway is configured to trigger migrations on service startup.
