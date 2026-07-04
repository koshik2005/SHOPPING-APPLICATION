# HyperLocal Enterprise Portal — Verification and Test Plan
**Version:** 2.0

---

## 1. Test Methodology

Our verification plan validates role protection, data isolation scopes, and gateway filters across both backend services and the React frontend.

---

## 2. Test Execution Details

### 2.1 User Authentication Flows
- **Objective**: Validate login using multiple methods (Password, OTP, Google OAuth).
- **Execution**:
  - Submit login with invalid credentials; verify `401 Unauthorized` response.
  - Sign in as a user with a `ROLE_CUSTOMER` account; verify redirect / access block to admin modules.
  - Verify that a valid user login registers the active Session ID in local storage.

### 2.2 Role-Based Page Access
- **Objective**: Verify that sidebar items and page URLs are restricted by user role.
- **Execution**:
  - Sign in as `BRANCH_MANAGER`; confirm "User Management" and "Testing Tools" are not visible.
  - Direct navigation to `/users` must trigger the "Access Denied" screen.
  - Sign in as `QA_ENGINEER`; confirm "Testing Tools" is visible and renders the simulation panels.

### 2.3 Data Scope Isolation Checks
- **Objective**: Verify that user accounts with shop or branch scopes are restricted to their data.
- **Execution**:
  - Sign in as `SHOP_OWNER` scoped to shop B; request product details from shop A; verify `403 Forbidden` error.
  - Sign in as `BRANCH_MANAGER` scoped to branch Y; query order details from branch Z; verify `403 Forbidden` error.

### 2.4 Token Refresh Cycle
- **Objective**: Validate Axios token rotation and automatic queue processing.
- **Execution**:
  - Set access token expiration to 10 seconds.
  - Make rapid API calls; confirm the interceptor intercepts the `401`, refreshes the token, and resolves the queue without page redirects.

---

## 3. Test Cases Log Sheet

| Test Case ID | Scope | Target Action | Expected Result | Status |
|---|---|---|---|---|
| TC-01 | Authentication | POST /verify-password | Returns JWT with roles list | Passed |
| TC-02 | Auth Failure | Invalid credentials | Blocked with 401 response | Passed |
| TC-03 | Rate Limiting | Trigger 15 calls in 5s | Returns 429 Too Many Requests | Passed |
| TC-04 | User Guard | Access /users as BRANCH_MGR | Blocked, displays Access Denied screen | Passed |
| TC-05 | Geofence | Drag branch geofence radius | Updates database geofence | Passed |
| TC-06 | Token Rotation | Expired Access Token | Background refresh, no session logout | Passed |
