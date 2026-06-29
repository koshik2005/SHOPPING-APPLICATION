# Provider Guide — HyperLocal Enterprise Platform

This document explains how to implement and switch provider implementations
across the entire platform without changing any business logic.

---

## How Providers Work

All external dependencies are abstracted as Java interfaces in `hyperlocal-common`:

```
com.hyperlocal.common.provider/
├── OtpProvider.java
├── SmsProvider.java
├── EmailProvider.java
├── StorageProvider.java
└── PushNotificationProvider.java
```

Spring selects the active implementation using `@Profile` annotations:
- `@Profile("dev")` → Free/FOSS development implementation
- `@Profile("prod")` → Production commercial implementation
- `@Profile({"dev", "prod"})` → Works in both (e.g., SMTP email)

Set the active profile via: `SPRING_PROFILES_ACTIVE=dev` or `=prod`

---

## OTP Provider

**Interface:** `com.hyperlocal.common.provider.OtpProvider`

```java
void sendOtp(String emailOrPhone, String code, String type);
```

| Profile | Class | Where | Behavior |
|---------|-------|-------|----------|
| `dev` | `DevLogOtpProvider` | auth-service | Prints OTP to server logs |
| `prod` | `TwilioOtpProvider` *(Future)* | auth-service | Sends real SMS via Twilio |
| `prod` | `Msg91OtpProvider` *(Future)* | auth-service | Sends real SMS via MSG91 |

**Switch:** Set `SPRING_PROFILES_ACTIVE=prod` + add `TwilioOtpProvider` with credentials.

---

## Email Provider

**Interface:** `com.hyperlocal.common.provider.EmailProvider`

```java
void sendEmail(String toEmail, String subject, String body);
```

| Profile | Class | Where | Behavior |
|---------|-------|-------|----------|
| `dev+prod` | `SmtpEmailProvider` | auth-service | Sends via SMTP (MailHog dev / Real SMTP prod) |

**Dev:** SMTP points to `mailhog:1025` — all emails visible at `http://localhost:8025`

**Production switch:** Set `SMTP_HOST` + `SMTP_PORT` to real SMTP server in `.env`

---

## Storage Provider

**Interface:** `com.hyperlocal.common.provider.StorageProvider`

```java
String uploadFile(String bucketName, String objectName, InputStream data, String contentType);
void deleteFile(String bucketName, String objectName);
```

| Profile | Class | Where | Behavior |
|---------|-------|-------|----------|
| `dev+prod` | `MinioStorageProvider` *(Future)* | All services | MinIO self-hosted S3 |
| `prod` | `S3StorageProvider` *(Future)* | All services | AWS S3 |

**Switch:** Set `STORAGE_PROVIDER=s3` + add AWS credentials

---

## Payment Provider

**Interface:** `com.hyperlocal.payment.infrastructure.gateway.PaymentGatewayProvider`

```java
PaymentResponseDto initiatePayment(PaymentRequestDto request);
boolean verifyWebhookSignature(String payload, String signature);
```

| Profile | Class | PAYMENT_GATEWAY env | Behavior |
|---------|-------|---------------------|----------|
| `dev` | `SimulatedPaymentProvider` | `SIMULATED` | All 6 states in-memory |
| `prod` | `RazorpayProvider` *(Future)* | `RAZORPAY` | Razorpay India |
| `prod` | `StripeProvider` *(Future)* | `STRIPE` | Stripe International |

**Simulated payment states (dev):**
Include `"simulatedOutcome": "FAILURE"` in the payment request body to test different states:
- `SUCCESS` → Payment completes
- `FAILURE` → Card declined
- `PENDING` → Awaiting bank redirect
- `CANCELLED` → User cancelled
- `TIMEOUT` → Gateway timeout
- `REFUND` → Completes then refunds

---

## Push Notification Provider

**Interface:** `com.hyperlocal.common.provider.PushNotificationProvider`

```java
void sendPush(String token, String title, String body);
```

| Profile | Class | Behavior |
|---------|-------|----------|
| `dev` | `SseNotificationController` | Server-Sent Events on `GET /api/v1/notifications/subscribe/{id}` |
| `prod` | `FcmPushProvider` *(Future)* | Firebase Cloud Messaging |

**Flutter SSE subscription:**
```dart
final channel = await EventSource.connect(
  '$apiBaseUrl/api/v1/notifications/subscribe/$customerId',
  headers: {'Authorization': 'Bearer $accessToken'},
);
channel.listen((event) {
  // Handle notification event
});
```

---

## Adding a New Provider Implementation

1. Create a new class implementing the interface
2. Annotate with `@Component` + `@Profile("prod")`
3. Inject credentials via `@Value("${provider.key:}")` from environment
4. Test with `SPRING_PROFILES_ACTIVE=prod`
5. No changes to any service, controller, or domain class required
