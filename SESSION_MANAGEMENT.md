# HyperLocal Platform — Session Management & Protection
**Version:** 3.0

---

## 1. Single Active Session Policy

The platform enforces a **Single Active Session Policy** for all roles except customers:
- Super Admins
- Branch Managers
- Shop Owners
- Support Agents
- Finance Operators
- QA Engineers
- Auditors

When a user attempts to log in while a session is already active, the new login attempt is flagged. Rather than logging the existing session out silently, a conflict alert is dispatched. The user must explicitly choose:
1. **Take Over Session**: Invalidates the active JWT session, logs out the previous device, and registers the new device.
2. **Cancel Login**: Aborts the authentication attempt.

---

## 2. Multi-Tab and Multi-Browser Guards

To enforce single session policies inside the Enterprise Control Center, client-side browser events are monitored:

### 2.1 Multi-Tab Protection
- Uses a local storage event channel (`BroadcastChannel` named `hyperlocal_session_channel`).
- When a new browser tab is opened on `/`:
  - It broadcasts a ping.
  - If another tab is active, the active tab responds, prompting the user: *"This account is already active in another tab."*
  - The user can select **Switch to this tab** (invalidates local storage context in the previous tab) or **Close Tab**.

### 2.2 Multi-Browser Protection
- A session fingerprint (consisting of the IP address, User-Agent, and screen resolution) is stored inside the database session record on login.
- If the session ID matches but the browser fingerprint changes:
  - The request is intercepted at the API Gateway.
  - Returns a `SESSION_CONFLICT` error, forcing the user to re-authenticate or take over the active session.

---

## 3. Session Lifecycles & Timeouts

| Timeout Type | Value | Scope | Description |
|---|---|---|---|
| **Access Token Expiry** | 15 Minutes | Global | Token is invalidated. Background refresh takes place. |
| **Idle Timeout** | 30 Minutes | Portal/Rider | Automatically logs the user out if no API activity is detected. |
| **Absolute Session Expiry** | 7 Days | Global | Revokes the refresh token, forcing a full login flow. |
