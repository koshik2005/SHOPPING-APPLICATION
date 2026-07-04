# HyperLocal Enterprise Portal — Super Admin Security Standards
**Version:** 3.0

---

## 1. Credentials Policy

Super Admins represent the most privileged access level on the platform. Consequently, strict security policies are enforced:

- **Password Rules**:
  - Minimum 12 characters.
  - Must contain uppercase, lowercase, numbers, and special characters.
  - Password reuse restriction: Cannot reuse any of the previous 5 passwords.
- **Login Requirements**:
  - Mandatory Email + Password + Email OTP flow.
  - Super Admins can never bypass MFA.
- **Force Reset**: Temporary credentials generated during invite provisionings require immediate update upon initial login.

---

## 2. Session Integrity Safeguards

- **Absolute Timeout**: Session registry limits token lifetime to a maximum of 24 hours. After this period, users are forced to log in again.
- **Active Idle Monitor**: The portal logs out users automatically if no interactions or API calls are registered for 30 minutes.
- **Session Revocation**: Super Admins can view and terminate active sessions globally from the Security Center.

---

## 3. Remote Audit Trails

Every admin transaction propagates the caller's correlation ID. This creates a detailed, chronological timeline of actions:

```
[Admin Page] ──► [REST Action (X-Correlation-ID)] ──► [Audit Log Generated]
                                                            │
    [Audit Registry] ◄── [Write Immutable Record] ◄─────────┘
```
- Actions like `ROLE_CHANGE`, `USER_SUSPEND`, `CONFIG_UPDATE`, and `GATEWAY_ROUTE_REFRESH` write details directly to the audit database to ensure non-repudiation.
