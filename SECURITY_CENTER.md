# HyperLocal Platform — Enterprise Security Control Center
**Version:** 3.0

---

## 1. Security Portal Console

The Security Center is a dedicated module inside the Enterprise Portal, accessible only to roles with `ROLE_SUPER_ADMIN` or `ROLE_AUDITOR` permissions.

It provides a real-time operations dashboard to monitor system health and security events:

```
┌───────────────────────────────────────────────────────────────┐
│              Live Security Monitor Telemetry                  │
├───────────────────────┬───────────────────────────────────────┤
│ Active Sessions Log   │ Blocked Device Mappings               │
│ - user session list   │ - blacklist device entries            │
│ - force-kill actions  │ - add/remove blocked fingerprints     │
├───────────────────────┼───────────────────────────────────────┤
│ Locked Accounts Queue │ Incident Alerts                       │
│ - list locked users   │ - impossible travel warnings          │
│ - admin unlock button │ - MFA brute-force trigger lists       │
└───────────────────────┴───────────────────────────────────────┘
```

---

## 2. Real-Time Security Telemetry Widgets

The Security Center displays the following real-time metrics:
- **Online Users**: Active sessions count in Redis.
- **Locked Accounts**: Total records in `users` with `TEMP_LOCKED` or `PERM_LOCKED` status.
- **Blocked Devices**: Fingerprints blacklisted due to suspicious activity.
- **Impossible Travel Warnings**: Real-time alerts generated when coordinate updates indicate geofence discrepancies.

---

## 3. Super Admin Notifications

Super Admins receive instant notification alerts for critical security events:
- **Root Admin Login**: Triggered immediately when the root email logs in.
- **Root Password Change**: Triggered when the root account updates its password.
- **Privilege Escalation**: Alerts generated when user roles are updated or new administrative accounts are provisioned.
- **Mass Login Failures**: Alerts sent if more than 20 failed login attempts are recorded within 5 minutes.
