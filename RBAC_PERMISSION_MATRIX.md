# HyperLocal Enterprise Control Center — Role-Based Access Control Matrix
**Version:** 2.0

---

## 1. System Role Glossary

| Role Key | Name | Access Scope |
|---|---|---|
| `ROLE_SUPER_ADMIN` | Super Administrator | Global permission access across all system modules. |
| `ROLE_SYSTEM_ADMIN` | System Administrator | Global system control; cannot manage role matrices or keys. |
| `ROLE_REGIONAL_MANAGER`| Regional Manager | Multi-branch logistics management in a designated region. |
| `ROLE_BRANCH_MANAGER` | Branch Manager | Scoped to a single branch; controls geofencing, radius, and shops. |
| `ROLE_SHOP_OWNER` | Shop Owner | Scoped to own merchant storefront, products, and inventory. |
| `ROLE_SHOP_MANAGER` | Shop Manager | Delegated operations for a specific shop. |
| `ROLE_DELIVERY_PARTNER`| Delivery Partner | Assigned deliveries and earnings wallet inside mobile app only. |
| `ROLE_CUSTOMER` | Customer | Order placement and wallet settings inside customer app only. |
| `ROLE_QA_ENGINEER` | QA Engineer | Sandbox operations, SSE monitoring, and telemetry simulators. |
| `ROLE_SUPPORT_AGENT` | Support Agent | User account audits, dispute updates, and refund requests. |
| `ROLE_FINANCE` | Finance Operator | Payment ledgers, settlement reports, and transaction queries. |
| `ROLE_AUDITOR` | System Auditor | Read-only access to audit logs, security events, and sessions. |

---

## 2. API Level Access Matrix

Legend: 
- `F` Full Control (Create, Read, Update, Delete)
- `R` Read-Only Access
- `O` Scoped to Own Records
- `B` Scoped to Branch Context
- `S` Scoped to Shop Context
- `—` No Access

| Module API Group | SUPER | SYSTEM | REGIONAL | BRANCH | SHOP | SUPPORT | FINANCE | AUDITOR | QA |
|---|---|---|---|---|---|---|---|---|---|
| **Auth & Sessions** | F | F | R | R | R | R | R | R | R |
| **User Profiles** | F | F | R | R | — | R | R | R | R |
| **RBAC Roles** | F | — | — | — | — | — | — | — | — |
| **Branches** | F | F | F | B | — | R | R | R | R |
| **Shops** | F | F | F | B | S | R | R | R | R |
| **Products** | F | F | R | B | S | R | R | R | R |
| **Inventory** | F | F | — | B | S | — | — | R | R |
| **Orders** | F | F | B | B | S | F | R | R | F |
| **Delivery tracking** | F | F | B | B | — | R | — | R | F |
| **Wallet & Finance** | F | F | — | — | — | R | F | R | F |
| **Payments** | F | F | — | — | — | R | F | R | F |
| **Notifications** | F | F | B | B | — | — | — | R | F |
| **System Settings** | F | F | — | — | — | — | — | R | R |
| **Audit Logs** | F | R | — | — | — | — | — | R | R |
| **Testing Simulators**| — | — | — | — | — | — | — | — | F |

---

## 3. UI Route Visibility Access Map

This matrix determines which sidebar options and page layouts are accessible in the UI:

| Route Path | Module Name | SUPER | SYSTEM | REGIONAL | BRANCH | SHOP | SUPPORT | FINANCE | AUDITOR | QA |
|---|---|---|---|---|---|---|---|---|---|---|
| `/` | Dashboard | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `/branches` | Branches | Yes | Yes | Yes | Scoped | No | Read | No | Read | Read |
| `/shops` | Shops | Yes | Yes | Yes | Scoped | Scoped | Read | No | Read | Read |
| `/products` | Products | Yes | Yes | Yes | Scoped | Scoped | Read | No | Read | Read |
| `/inventory` | Inventory | Yes | Yes | No | Scoped | Scoped | No | No | Read | Read |
| `/orders` | Orders | Yes | Yes | Scoped | Scoped | Scoped | Yes | Read | Read | Yes |
| `/delivery` | Delivery tracking | Yes | Yes | Scoped | Scoped | No | Read | No | Read | Yes |
| `/payments` | Payments | Yes | Yes | No | No | No | Read | Yes | Read | Yes |
| `/wallet` | Wallet ledger | Yes | Yes | No | No | No | Read | Yes | Read | Yes |
| `/customers` | Customers | Yes | Yes | No | No | No | Yes | No | Read | Read |
| `/notifications`| Notifications | Yes | Yes | Scoped | Scoped | No | No | No | Read | Yes |
| `/users` | User management| Yes | Yes | No | No | No | No | No | No | No |
| `/audit-logs` | Audit logs | Yes | Read | No | No | No | No | No | Yes | Yes |
| `/system-settings`| Settings | Yes | Yes | No | No | No | No | No | Read | No |
| `/testing-tools` | Testing Tools | No | No | No | No | No | No | No | No | Yes |
