# HyperLocal Platform — Device Registry & Binding Manual
**Version:** 3.0

---

## 1. Device Scopes & Registries

All devices connecting to the microservices gateway are registered in the `device_registry` repository. This tracks hardware parameters, browser models, and trusted statuses:

- **Browser Fingerprints**: Generated dynamically in the React portal using properties like user-agent, language, screen resolution, and time zone.
- **Rider Device Bindings**: Mobile device identifier strings validated at login.

---

## 2. Delivery Partner Device Binding Constraint

### 2.1 One Mobile Device Policy
- Delivery partners (`ROLE_DELIVERY_PARTNER`) are strictly limited to **one registered device fingerprint**.
- If a partner tries to log in using a new phone, the authentication process is blocked:
```
[Unrecognized Device ID] ──► [Block Login] ──► [Dispatch OTP Challenge]
                                                     │
[Override Active Device ID] ◄── [Admin Approves] ◄── [Verify OTP Code]
```

### 2.2 Device Binding Operations Table

| Action | Execution Requirement | Description |
|---|---|---|
| **Register Initial Device** | Automatic on first login | Saves the device ID and sets status to `TRUSTED`. |
| **Change Registered Device**| 2FA OTP + Admin Override | Clears the previous binding and links the new device ID. |
| **Revoke Trusted Device** | Admin Console action | Moves the device ID to the blocked registry, preventing future logins. |

---

## 3. Threat Mitigations

- **Rooted/Jailbroken Devices**: The mobile apps perform root detection on startup. If root access is detected, the device is flagged as high-risk, and the session is suspended.
- **Emulator Detection**: Prevents riders from using fake GPS location providers to simulate orders completion.
- **Device Blocklist**: If suspicious login attempts are detected on a specific device fingerprint, the device is added to `blocked_devices` and rejected at the gateway.
