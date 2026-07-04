# HyperLocal Platform — RBAC & Permission Architecture
**Version:** 3.0

---

## 1. Role Hierarchies

Role-Based Access Control (RBAC) is implemented using a structured hierarchy. Higher roles inherit the permissions of lower roles:

```
ROOT_SUPER_ADMIN
  └── SUPER_ADMIN
        └── SYSTEM_ADMIN
              ├── REGIONAL_MANAGER
              │     └── BRANCH_MANAGER
              │           ├── SHOP_OWNER
              │           │     └── SHOP_MANAGER
              │           └── DELIVERY_PARTNER
              ├── SUPPORT_AGENT
              ├── FINANCE
              └── AUDITOR

QA_ENGINEER (Standalone template)
CUSTOMER (Standalone template)
```

---

## 2. Dynamic Permission Matrix

Permissions are divided into distinct permission groups:
- **`branches:*`**: Read and write capabilities for geofences and operational times.
- **`shops:*`**: Read, write, suspend, and configure shop details.
- **`products:*`**: Edit inventories and product catalogs.
- **`orders:*`**: View details, modify status, reassign riders, and process cancellations.
- **`wallet:*`**: Process manual credits/debits and view transaction logs.
- **`audit-logs:view`**: Access security events logs.
- **`testing-tools:view`**: Access simulation tools (restricted to `ROLE_QA_ENGINEER`).

---

## 3. UI and API Layer Enforcement

### 3.1 UI Layer
- Sidebar options are conditionally rendered using the client-side permission matrix.
- URL routing is protected by route guards.
- Buttons and form controls are shielded using the `<PermissionGuard>` wrapper:
```typescript
<PermissionGuard require="branches:write">
  <Button onClick={openCreateDialog}>Register Branch</Button>
</PermissionGuard>
```

### 3.2 Service Layer
- Spring Security enforces authorization at the controller/service level using `@PreAuthorize`:
```java
@PreAuthorize("hasAuthority('branches:write')")
public BranchDto createBranch(BranchDto branch) { ... }
```
- Injected user permissions are checked downstream by checking the claims from the JWT.
