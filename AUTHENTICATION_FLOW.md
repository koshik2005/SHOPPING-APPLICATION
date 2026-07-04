# HyperLocal Platform — Authentication Flows Specification
**Version:** 3.0

---

## 1. Root Super Admin Login Flow

The ROOT_SUPER_ADMIN login uses a strict multi-factor authentication flow with no bypasses allowed:

```
[Login Form] ──► [Email & Password] ──► [Verify Credentials]
                                               │
  [Authentication Success] ◄── [Verify OTP] ◄── [Send 6-digit OTP]
```

### Flow Details
1. **Password Verification**: Encrypted credentials validation using BCrypt (strength 12).
2. **OTP Dispatch**: Programmatically generates a 6-digit code, saves it to `otp_requests` with a 5-minute expiration, and dispatches it to the root email address.
3. **MFA Verification**: Prompted on the UI. The user submits the code; verification yields the JWT token pair and maps the Session ID to local storage.

---

## 2. Privileged User Verification Flow

All admin, manager, support, and finance accounts follow the same mandatory 2FA email validation flow.

```
[Enter Credentials] ──► [Password Checked] ──► [Validate Active Session Limit]
                                                     │
[Sign in Completed] ◄── [Verify 6-digit OTP] ◄── [MFA OTP Dispatched]
```

- **MFA Bypass Protection**: If an authenticated session matches an administrative role, the API Gateway rejects the transaction with `MFA_REQUIRED` status until the second factor (OTP) is successfully verified.

---

## 3. Delivery Partner Device Binding Flow

Delivery partners are restricted to **one registered mobile device** in the system database:

```
[Login request with Device ID]
        │
        ├─► [Device Registered & Matches] ────► [Authorize Login]
        │
        └─► [Device Unrecognized] ────────────► [Trigger OTP Change Verification]
                                                      │
[Register New Device] ◄── [Admin Approval] ◄────── [Verify OTP]
```

1. On sign-in, the app forwards the mobile device fingerprint (`deviceId`, `IMEI`, `model`, `OS`).
2. If the `deviceId` does not match the active registry:
   - Dispatches a verification OTP to the registered phone number.
   - Requires admin confirmation (or automatic rollover audit logs) to transition the binding to the new device ID and remove the old fingerprint.
