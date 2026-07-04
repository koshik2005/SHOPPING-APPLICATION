# HyperLocal Delivery Partner App — Mobile Security Standards
**Version:** 3.0

---

## 1. Credentials & Login Flow

The Delivery Partner mobile app coordinates rider logins securely using standard 2FA verification:

```
[Credentials Form] ──► [Password check] ──► [SMS / Mobile OTP check]
                                                    │
[Login authorized] ◄── [Device ID verified] ◄───────┘
```

1. **Mobile Verification**: Support for both SMS OTP and Email/Password/OTP combinations.
2. **Mandatory Device Binding**: Sign-ins are restricted to a single registered device ID. If the ID changes, the user is locked out until an administrator approves the device rollover.

---

## 2. Emulators & Mock GPS Protections

- **Root & Jailbreak Checks**: The Flutter application uses integration hooks to detect root packages on Android and iOS. If root access is detected, the app blocks the partner from logging in.
- **Mock GPS Blockers**: The location service validates GPS updates. If mock locations or coordinates spoofing are detected, the app:
  - Halts delivery state updates.
  - Sends a warning notification to the audit service.
- **Certificate Pinning**: The app enforces HTTPS connections and pins the server's public key hash to prevent Man-in-the-Middle (MitM) attacks.

---

## 3. Data Scope Restrictions

Riders are restricted to their assigned deliveries:
- **No Catalog/Merchant Access**: The app contains no code or endpoints to query the general catalog or modify branch configurations.
- **Assigned Orders Only**: Downstream APIs filter order queries to match the authenticated partner's ID:
```java
// delivery-service enforces partner scope:
deliveryRepository.findByPartnerIdAndStatus(ctx.userId(), ACTIVE);
```
- **Local Cache Encryption**: App data (such as coordinates, customer phone numbers, and active routes) is stored in encrypted secure storage, preventing local extraction.
