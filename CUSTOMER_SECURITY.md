# HyperLocal Customer Application — Security Standards
**Version:** 3.0

---

## 1. Authentication Flows

The Customer Flutter Application supports multiple registration and login methods:
- **Google OAuth Federated Sign-In**: Excharges identity profiles using secure backend validation.
- **Email + Password + OTP**: Validates users using standard password verification and email/SMS OTP checks.

All successful login paths generate a secure token pair (Short-lived JWT access token + long-lived UUID refresh token).

---

## 2. Token Storage and Refresh Security

### 2.1 Pinned Secure Storage
- Token details are stored in the device's secure keystore:
  - iOS: Keychain services.
  - Android: EncryptedSharedPreferences.
- This prevents local malware from reading authentication credentials.

### 2.2 Refresh Token Rotation (RTR)
- The app uses refresh token rotation to prevent token reuse:
```
[Access Expired] ──► [Post Refresh Token] ──► [Invalidate Old Token]
                                                    │
    [Save New Tokens] ◄── [Return New Pair] ◄───────┘
```
- If a client attempts to reuse an invalidated refresh token, the auth service:
  - Detects the reuse event.
  - Revokes all sessions linked to the user immediately as a precaution against hijacking.

---

## 3. Scoped Data Isolation

The Customer application has no access to admin APIs:
- **Own Records Only**: Database queries automatically filter results by the customer's authenticated user ID.
- **No Direct Object Reference (IDOR)**: The API Gateway rejects calls that query orders or wallets matching other IDs.
- **Session Timeout Protection**: Sessions are automatically logged out after 30 days of inactivity.
