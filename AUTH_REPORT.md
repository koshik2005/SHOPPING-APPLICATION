# HyperLocal Platform — Hardened Authentication & Identity Subsystem Report

This report documents the design, implementation, and database schema mappings of the production-grade, hardened authentication and identity subsystem implemented for the HyperLocal Enterprise Platform.

---

## 1. Authentication Subsystem Architecture

The platform's identity layer is built using a decoupled, secure architecture split between the Flutter mobile client, Spring Cloud Gateway, and a dedicated, relational-database-backed Spring Boot `auth-service`.

```mermaid
sequenceDiagram
    participant Client as Flutter Client
    participant Gateway as Spring Cloud Gateway (Port 8080)
    participant AuthServ as Auth Service (Port 8081)
    participant DB as PostgreSQL Database

    Client->>Gateway: POST /api/v1/auth/google-login { idToken }
    Gateway->>AuthServ: Proxy to /api/v1/auth/google-login
    AuthServ->>AuthServ: Google ID Token Cryptographic Verification
    AuthServ->>DB: Check User Identity Table
    alt Identity Exists (MFA Disabled)
        AuthServ->>DB: Create Session & Device Registry
        AuthServ-->>Client: LOGIN_COMPLETED { accessToken, refreshToken }
    alt Identity Exists (MFA Enabled)
        AuthServ-->>Client: PASSWORD_REQUIRED { existingProfile }
    alt Identity Missing (New Account)
        AuthServ-->>Client: REGISTRATION_REQUIRED { googleProfile }
    end
```

---

## 2. Implementation Status of Requirements

Every core authentication and security requirement has been fully realized without fallback mock mechanisms:

### 2.1 Google Sign-In & Verification
* **Implementation:** Integrated Google Identity Services token verification in `GoogleIdTokenVerifierService.java`.
* **Details:** Uses the official Google APIs HTTP Client to cryptographically parse and verify the signature, audience (`google.client.web-id`), and issuer of Google ID Tokens sent by the client. Unverified token parsing is blocked.
* **Exceptions Managed:** Custom exceptions like `InvalidGoogleTokenException`, `ExpiredGoogleTokenException`, and `EmailNotVerifiedException` are caught and mapped to standard HTTP error statuses.

### 2.2 Google Registration
* **Implementation:** Handled via the `/api/v1/auth/register` endpoint in `AuthController.java` and `AuthService.java`.
* **Details:** If the Google login check returns `REGISTRATION_REQUIRED`, the client is redirected to the SignUp screen, prefilling their Name, Email, and Profile Photo URL from the Google Profile payload. Completing registration creates the DB entries for both the `users` profile and the linked provider mapping.

### 2.3 Existing User Login & Account Linking
* **Implementation:** Embedded in `loginWithGoogle` in `AuthService.java`.
* **Details:** If a user logs in via Google and no Google identity mapping exists, but their email is already registered, the backend automatically performs secure account linking. It appends the Google identity provider mappings to the existing user record instead of creating duplicate accounts.

### 2.4 Email & SMS OTP Verification
* **Implementation:** Realized in `/otp/send` and `/otp/verify` endpoints.
* **Details:** Generates a secure, 6-digit one-time password (OTP) via `SecureRandom` and persists it in the `one_time_passwords` table. It contains an expiry timestamp (5-minute expiration limit).

### 2.5 Password Login & Cryptographic Hashing
* **Implementation:** Mapped under `/api/v1/auth/verify-password`.
* **Details:** Uses Spring Security's `PasswordEncoder` (specifically `BCryptPasswordEncoder`) to verify user credentials. Plaintext passwords are never stored in the database.

### 2.6 Forgot & Reset Password
* **Implementation:** Handled in `/password/forgot` and `/password/reset` endpoints.
* **Details:** Dispatches a verification OTP to the user's email. Verifying the reset request changes the password hash in the database and immediately invalidates all active sessions (`sessionRepository.deleteByUserId(userId)`) to enforce remote lockout.

### 2.7 JWT Tokens & Refresh Token Rotation
* **Implementation:** Handled by `JwtProvider.java` and the `/token/refresh` endpoint.
* **Details:** Generates stateless JWT access tokens for authorization. Refresh tokens are tracked in the database session registry.
* **Token Rotation:** On every refresh request, the backend performs token rotation: it verifies the refresh token, deletes the old session signature, generates a new JWT token, generates a new refresh token, hashes it using BCrypt, and updates the session registry.

### 2.8 Session Registry
* **Implementation:** Handled via the `user_sessions` table and `UserSessionRepository`.
* **Details:** Active logins write session metadata (`id`, `user_id`, `device_id`, `ip_address`, `user_agent`, `expires_at`, `refresh_token_hash`) directly into the registry. Tokens are verified against active registry sessions.

### 2.9 Device Registry
* **Implementation:** Tracked in the `user_devices` table.
* **Details:** Captures and stores mobile/client hardware signatures (device ID, model, manufacturer, OS, push notification FCM tokens, last activity timestamps) to register trusted client hardware.

### 2.10 Logout & Remote Logout
* **Implementation:** Handled under `/logout` (single session invalidation) and `/remote-logout` (revoke all user sessions).
* **Details:** Single logout invalidates and deletes the current session ID. Remote logout queries the session database by User ID and purges all active session rows, forcing all logged-in devices to request re-authentication.

### 2.11 Sliding Rate Limiting
* **Implementation:** Handled via `enforceRateLimit(String emailOrPhone)` in `AuthService.java`.
* **Details:** Performs a database check against the `login_history` table. If the number of failed attempts within the last 15 minutes exceeds 5, the service blocks further verification attempts, returning a `TOO_MANY_REQUESTS` error code.

### 2.12 Security Auditing & Logs
* **Implementation:** Logged in the `login_history` and `security_events` tables.
* **Details:** Captures auditing records for successful/failed logins (tracking IP, device, and risk level) and logs critical event signals (like `PASSWORD_RESET_SUCCESS`, `LOGOUT`, `REMOTE_LOGOUT_ALL`, `FORGOT_PASSWORD_REQUEST`).

---

## 3. Database Schema Migrations

The identity subsystem schema is fully versioned using Flyway migrations:

### Migration `V10__authentication_refactoring.sql`
Creates the schema for hardening authentication:
```sql
-- 1. Add session refresh token support
ALTER TABLE user_sessions ADD COLUMN refresh_token_hash VARCHAR(255);

-- 2. Link provider identities (Google, Apple, Phone)
CREATE TABLE user_identities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    email VARCHAR(150) NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    linked_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_provider_user UNIQUE (provider, provider_user_id)
);

-- 3. Device registries
CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(150) NOT NULL,
    model VARCHAR(100) NOT NULL,
    manufacturer VARCHAR(100) NOT NULL,
    os VARCHAR(50) NOT NULL,
    push_token TEXT,
    trusted BOOLEAN NOT NULL DEFAULT FALSE,
    last_login TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_device UNIQUE (user_id, device_id)
);

-- 4. Audit tables
CREATE TABLE login_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    device VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    country VARCHAR(100) NOT NULL,
    risk VARCHAR(20) NOT NULL DEFAULT 'LOW',
    result VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    correlation_id VARCHAR(100) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Migration `V11__otp_support.sql`
Creates the schema for one-time password storage:
```sql
CREATE TABLE one_time_passwords (
    id UUID PRIMARY KEY,
    email_or_phone VARCHAR(150) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    expiry_time TIMESTAMPTZ NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

---

## 4. Auth Service REST API Contract

The `AuthController.java` publishes the following endpoints:

| Method | Endpoint | Request Body | Description |
| :--- | :--- | :--- | :--- |
| **POST** | `/api/v1/auth/google-login` | `GoogleLoginRequest` | Evaluates Google ID tokens and handles state flow transitions. |
| **POST** | `/api/v1/auth/register` | `RegisterRequest` | Submits profile and linked identities registration. |
| **POST** | `/api/v1/auth/verify-password`| `VerifyPasswordRequest` | Verifies account credentials using BCrypt. |
| **POST** | `/api/v1/auth/send-otp` | `SendOtpRequest` | Generates and sends verification OTP. |
| **POST** | `/api/v1/auth/verify-otp` | `VerifyOtpRequest` | Validates OTP codes and signs in the user. |
| **POST** | `/api/v1/auth/forgot-password`| `ForgotPasswordRequest` | Requests password recovery via OTP challenge. |
| **POST** | `/api/v1/auth/reset-password` | `ResetPasswordRequest` | Completes password resets and logs out other devices. |
| **POST** | `/api/v1/auth/refresh` | `RefreshTokenRequest` | Rotates and generates new token credentials. |
| **POST** | `/api/v1/auth/logout` | None (Requires session header)| Revokes the current login session. |
| **POST** | `/api/v1/auth/remote-logout` | Query Param `email` | Purges all active sessions for the specified user email. |

---

## 5. Verification Status

* **Compilation:** ✅ Verified. The multi-module Maven reactor compiles successfully.
* **Google Signature Validation:** ✅ Verified. Direct validation against Google API servers is integrated.
* **Token Security:** ✅ Verified. Password and token storage leverage BCrypt encoding.
* **Routing Integration:** ✅ Verified. All client calls mapped to `/api/v1/auth/**` on port `8080` are proxied to the service instance.
