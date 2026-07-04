# HyperLocal Platform — RBAC Verification Report
**Phase:** P2 (Production Readiness)
**Status:** COMPLETE

---

## 1. Role Hierarchies
The platform enforces role-based access control (RBAC). Root Super Admins hold global permissions, while branch and shop manager scopes are restricted to their respective assets.

---

## 2. Verification Outcomes

### 2.1 API Endpoint Security
Downstream microservice controllers enforce role checks using Spring Security annotations:
- `@PreAuthorize("hasAuthority('branches:write')")` — restricted to super admins and branch managers.
- `@PreAuthorize("hasAuthority('testing-tools:view')")` — restricted to QA Engineers.

### 2.2 Client Render Protections
- Navigation menus and views in the React portal are rendered based on the user's permissions.
- Unauthorized path navigation redirects users to the "Access Denied" view.
- Buttons and action parameters are conditionally displayed using permission wrappers.
```typescript
<PermissionGuard require="branches:write">
  <Button>Register Branch</Button>
</PermissionGuard>
```
