# RBAC MATRIX
## HyperLocal Enterprise Platform — Role-Based Access Control

**Version:** 2.0

---

## 1. Role Definitions

| Role Constant | Display Name | Scope |
|---|---|---|
| `ROLE_SUPER_ADMIN` | Super Administrator | Platform-wide access |
| `ROLE_SYSTEM_ADMIN` | System Administrator | Platform-wide, no role management |
| `ROLE_REGIONAL_MANAGER` | Regional Manager | Multiple branches in a region |
| `ROLE_BRANCH_MANAGER` | Branch Manager | Single branch + all shops within |
| `ROLE_SHOP_OWNER` | Shop Owner | Single shop + all products within |
| `ROLE_SHOP_MANAGER` | Shop Manager | Delegated shop operations |
| `ROLE_DELIVERY_PARTNER` | Delivery Partner | Assigned deliveries only |
| `ROLE_CUSTOMER` | Customer | Own account/orders/wallet only |
| `ROLE_QA_ENGINEER` | QA Engineer | Read all + simulation tools |
| `ROLE_SUPPORT_AGENT` | Support Agent | Read customer data, manage tickets |
| `ROLE_FINANCE` | Finance | Read financial data, reports |
| `ROLE_AUDITOR` | Auditor | Read-only audit logs |

---

## 2. Permission Matrix

Legend: ✅ Full Access | 📖 Read Only | 🔒 Own Data Only | ❌ No Access | 🏢 Scoped to Branch | 🏪 Scoped to Shop

### 2.1 Authentication & User Management

| Endpoint | SUPER | SYS_ADMIN | REG_MGR | BRANCH_MGR | SHOP_OWNER | DELIVERY | CUSTOMER | QA | SUPPORT | FINANCE | AUDITOR |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `POST /auth/login` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `GET /users` (all) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | 📖 | 📖 | ❌ | 📖 |
| `POST /users` (create) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `PUT /users/{id}/roles` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `POST /users/{id}/suspend` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `GET /users/me` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `GET /sessions` (all) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | 🔒 | 📖 | ❌ | ❌ | 📖 |

### 2.2 Branch Management

| Endpoint | SUPER | SYS_ADMIN | REG_MGR | BRANCH_MGR | SHOP_OWNER | DELIVERY | CUSTOMER | QA | SUPPORT | FINANCE | AUDITOR |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `GET /branches` | ✅ | ✅ | 📖 | 🏢📖 | ❌ | ❌ | 📖 | 📖 | 📖 | 📖 | 📖 |
| `POST /branches` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `PUT /branches/{id}` | ✅ | ✅ | 🏢 | 🏢 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `DELETE /branches/{id}` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `PUT /branches/{id}/hours` | ✅ | ✅ | 🏢 | 🏢 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

### 2.3 Shop Management

| Endpoint | SUPER | SYS_ADMIN | REG_MGR | BRANCH_MGR | SHOP_OWNER | DELIVERY | CUSTOMER | QA | SUPPORT | FINANCE | AUDITOR |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `GET /shops` | ✅ | ✅ | 📖 | 🏢📖 | 🏪📖 | ❌ | 📖 | 📖 | 📖 | 📖 | 📖 |
| `POST /shops` | ✅ | ✅ | 🏢 | 🏢 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `PUT /shops/{id}` | ✅ | ✅ | 🏢 | 🏢 | 🏪 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `PUT /shops/{id}/status` | ✅ | ✅ | 🏢 | 🏢 | 🏪 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

### 2.4 Products & Inventory

| Endpoint | SUPER | SYS_ADMIN | REG_MGR | BRANCH_MGR | SHOP_OWNER | DELIVERY | CUSTOMER | QA | SUPPORT | FINANCE | AUDITOR |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `GET /inventory/products` | ✅ | ✅ | 📖 | 🏢📖 | 🏪📖 | ❌ | 📖 | 📖 | 📖 | 📖 | 📖 |
| `POST /inventory/products` | ✅ | ✅ | ❌ | 🏢 | 🏪 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `PUT /inventory/products/{id}` | ✅ | ✅ | ❌ | 🏢 | 🏪 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `DELETE /inventory/products/{id}` | ✅ | ✅ | ❌ | 🏢 | 🏪 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `PUT /inventory/stock/{variantId}` | ✅ | ✅ | ❌ | 🏢 | 🏪 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `GET /inventory/categories` | ✅ | ✅ | 📖 | 📖 | 📖 | ❌ | 📖 | 📖 | 📖 | ❌ | 📖 |
| `POST /inventory/categories` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

### 2.5 Orders

| Endpoint | SUPER | SYS_ADMIN | REG_MGR | BRANCH_MGR | SHOP_OWNER | DELIVERY | CUSTOMER | QA | SUPPORT | FINANCE | AUDITOR |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `GET /orders` (all) | ✅ | ✅ | 🏢 | 🏢 | 🏪 | ❌ | 🔒 | 📖 | 📖 | 📖 | 📖 |
| `POST /orders` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `PUT /orders/{id}/status` | ✅ | ✅ | 🏢 | 🏢 | 🏪 | 🔒 | ❌ | ✅ | ❌ | ❌ | ❌ |
| `PUT /orders/{id}/cancel` | ✅ | ✅ | 🏢 | 🏢 | ❌ | ❌ | 🔒 | ✅ | ✅ | ❌ | ❌ |
| `GET /orders/{id}` | ✅ | ✅ | 🏢 | 🏢 | 🏪 | 🔒 | 🔒 | 📖 | 📖 | 📖 | 📖 |

### 2.6 Wallet & Payments

| Endpoint | SUPER | SYS_ADMIN | REG_MGR | BRANCH_MGR | SHOP_OWNER | DELIVERY | CUSTOMER | QA | SUPPORT | FINANCE | AUDITOR |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `GET /wallets/{id}` | ✅ | ✅ | ❌ | ❌ | ❌ | 🔒 | 🔒 | 📖 | 📖 | 📖 | 📖 |
| `POST /wallets/{id}/credit` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| `POST /wallets/{id}/debit` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | 🔒 | ✅ | ❌ | ❌ | ❌ |
| `GET /payments` (all) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | 🔒 | 📖 | 📖 | ✅ | 📖 |

### 2.7 Delivery

| Endpoint | SUPER | SYS_ADMIN | REG_MGR | BRANCH_MGR | SHOP_OWNER | DELIVERY | CUSTOMER | QA | SUPPORT | FINANCE | AUDITOR |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `GET /deliveries` | ✅ | ✅ | 🏢 | 🏢 | ❌ | 🔒 | 🔒 | 📖 | 📖 | ❌ | 📖 |
| `PUT /deliveries/{id}/accept` | ❌ | ❌ | ❌ | ❌ | ❌ | 🔒 | ❌ | ✅ | ❌ | ❌ | ❌ |
| `POST /deliveries/{id}/location` | ❌ | ❌ | ❌ | ❌ | ❌ | 🔒 | ❌ | ✅ | ❌ | ❌ | ❌ |
| `GET /deliveries/partners` | ✅ | ✅ | 🏢 | 🏢 | ❌ | ❌ | ❌ | 📖 | 📖 | ❌ | 📖 |

### 2.8 Platform Administration

| Endpoint | SUPER | SYS_ADMIN | REG_MGR | BRANCH_MGR | SHOP_OWNER | DELIVERY | CUSTOMER | QA | SUPPORT | FINANCE | AUDITOR |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `GET /audit/logs` | ✅ | 📖 | ❌ | ❌ | ❌ | ❌ | ❌ | 📖 | ❌ | ❌ | 📖 |
| `GET /config` | ✅ | ✅ | 📖 | 📖 | 📖 | ❌ | ❌ | 📖 | ❌ | ❌ | 📖 |
| `PUT /config` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `POST /notifications/broadcast` | ✅ | ✅ | 🏢 | 🏢 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| `GET /reports` | ✅ | ✅ | 🏢 | 🏢 | 🏪 | ❌ | ❌ | 📖 | ❌ | ✅ | 📖 |

---

## 3. Enterprise Portal Module Access

| Portal Module | SUPER | SYS | REG | BRANCH | SHOP | DELIVER | CUSTOMER | QA | SUPPORT | FINANCE | AUDITOR |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Dashboard | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Branches | ✅ | ✅ | ✅ | 🏢 | ❌ | ❌ | ❌ | ✅ | 📖 | ❌ | 📖 |
| Shops | ✅ | ✅ | ✅ | 🏢 | 🏪 | ❌ | ❌ | ✅ | 📖 | ❌ | 📖 |
| Products | ✅ | ✅ | ✅ | 🏢 | 🏪 | ❌ | ❌ | ✅ | 📖 | ❌ | 📖 |
| Categories | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Orders | ✅ | ✅ | 🏢 | 🏢 | 🏪 | ❌ | ❌ | ✅ | ✅ | 📖 | 📖 |
| Customers | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | 📖 | ✅ | ❌ | 📖 |
| Delivery | ✅ | ✅ | 🏢 | 🏢 | ❌ | ❌ | ❌ | ✅ | 📖 | ❌ | 📖 |
| Inventory | ✅ | ✅ | ✅ | 🏢 | 🏪 | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Payments | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | 📖 | ✅ | 📖 |
| Wallet | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | 📖 |
| Reports | ✅ | ✅ | 🏢 | 🏢 | 🏪 | ❌ | ❌ | ✅ | ❌ | ✅ | 📖 |
| Analytics | ✅ | ✅ | 🏢 | 🏢 | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| Notifications | ✅ | ✅ | 🏢 | 🏢 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Users | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | 📖 | ❌ | ❌ | ❌ |
| Roles & Perms | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Audit Logs | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| System Settings | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Testing Tools** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |

---

## 4. JWT Role Claim Implementation

```java
// Roles stored in user_roles table, joined with users
@ElementCollection(fetch = FetchType.EAGER)
@CollectionTable(name = "user_roles",
    joinColumns = @JoinColumn(name = "user_id"))
@Column(name = "role")
private Set<String> roles = new HashSet<>(Set.of("ROLE_CUSTOMER"));

// JWT generation includes all roles
Map<String, Object> claims = Map.of(
    "roles", user.getRoles(),       // ["ROLE_BRANCH_MANAGER"]
    "branchId", user.getBranchId(), // nullable UUID
    "shopId", user.getShopId()      // nullable UUID
);
```
