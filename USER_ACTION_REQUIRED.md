# USER ACTION REQUIRED
## HyperLocal Enterprise Platform — External Credential Dependencies

The following integrations require credentials that **cannot be created automatically**.
All platform features that depend on these providers will use free/self-hosted alternatives
until credentials are provided.

---

## Status Summary

| # | Provider | Required For | Current Alternative | Status |
|---|----------|-------------|--------------------|----|
| 1 | Google OAuth Web Client ID | Google Sign-In | Existing dev ID (see below) | ⚠️ Review |
| 2 | SMTP Credentials (Production) | Password reset emails, OTP emails | MailHog (localhost:8025) | ✅ Dev OK |
| 3 | Razorpay / Stripe | Production payments | Simulated gateway | ✅ Dev OK |
| 4 | Twilio / MSG91 | SMS OTP delivery | Console log OTP | ✅ Dev OK |
| 5 | Firebase (FCM) | Mobile push notifications | SSE streaming | ✅ Dev OK |
| 6 | MinIO Production TLS | Secure file uploads | MinIO without TLS | ⚠️ Dev OK |
| 7 | Domain Name & SSL | HTTPS deployment | localhost | 🔴 Needed for prod |
| 8 | Production Server / VPS | Deployment target | Docker local | 🔴 Needed for prod |

---

## 1. Google OAuth Client ID

**Current status:** A development client ID is present in `auth-service/application.properties`:
```
GOOGLE_CLIENT_WEB_ID=1086613811908-vf6okpd8jvr0f5oaqvnemujb7niooe7k.apps.googleusercontent.com
```

**Action required for production:**
1. Go to [https://console.cloud.google.com](https://console.cloud.google.com)
2. Create an OAuth 2.0 Web Client credential
3. Add your production domain to "Authorized JavaScript origins"
4. Add your Android app SHA-1 fingerprint for mobile Google Sign-In
5. Set: `GOOGLE_CLIENT_WEB_ID=your_production_client_id`

---

## 2. Production SMTP

**Current:** MailHog running on port 1025 (catch-all SMTP for development).

**Action for production:**
Choose one provider and set in `.env`:
```
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=YOUR_SENDGRID_API_KEY
```
Or use AWS SES, Mailgun, Postmark, etc.

---

## 3. Payment Gateway (Razorpay / Stripe)

**Current:** `SimulatedPaymentProvider` is active (PAYMENT_GATEWAY=SIMULATED).

**Action for production (Razorpay):**
1. Create account at [https://razorpay.com](https://razorpay.com)
2. Get API keys from Dashboard → Settings → API Keys
3. Set in `.env`:
   ```
   PAYMENT_GATEWAY=RAZORPAY
   RAZORPAY_KEY_ID=rzp_live_...
   RAZORPAY_KEY_SECRET=...
   ```

**Action for production (Stripe):**
1. Create account at [https://stripe.com](https://stripe.com)
2. Get API keys from Dashboard → Developers → API Keys
3. Set in `.env`:
   ```
   PAYMENT_GATEWAY=STRIPE
   STRIPE_SECRET_KEY=sk_live_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```

---

## 4. SMS OTP (Twilio / MSG91)

**Current:** `DevLogOtpProvider` logs OTP codes to server console only.

**Action for production (Twilio):**
1. Create account at [https://www.twilio.com](https://www.twilio.com)
2. Get Account SID and Auth Token
3. Buy a phone number
4. Set in `.env`:
   ```
   OTP_PROVIDER=TWILIO
   TWILIO_ACCOUNT_SID=ACxxxxxxx
   TWILIO_AUTH_TOKEN=...
   TWILIO_PHONE_NUMBER=+1XXXXXXXXXX
   ```

**Action for production (MSG91 — India):**
1. Create account at [https://msg91.com](https://msg91.com)
2. Get API key and configure sender
3. Set in `.env`:
   ```
   OTP_PROVIDER=MSG91
   MSG91_API_KEY=...
   MSG91_SENDER_ID=HPLCAL
   MSG91_TEMPLATE_ID=...
   ```

---

## 5. Firebase (FCM Push Notifications)

**Current:** SSE (Server-Sent Events) delivers real-time notifications without Firebase.

**Action to enable FCM (optional):**
1. Create Firebase project at [https://console.firebase.google.com](https://console.firebase.google.com)
2. Enable Firebase Cloud Messaging
3. Download `google-services.json` for Android Flutter app
4. Generate Firebase Admin SDK service account key
5. Add `google-services.json` to `android/app/` in the Flutter project
6. Set in `.env`:
   ```
   PUSH_PROVIDER=FCM
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_PRIVATE_KEY_ID=...
   FIREBASE_PRIVATE_KEY=...
   FIREBASE_CLIENT_EMAIL=...
   ```

---

## 6. Production Domain & SSL

**Current:** Platform runs on localhost without TLS.

**Action for production:**
1. Purchase or point a domain to your server IP
2. Generate SSL certificate (Let's Encrypt — free):
   ```
   certbot certonly --standalone -d api.yourdomain.com
   ```
3. Configure Nginx/Caddy reverse proxy in front of the API Gateway
4. Update Flutter `apiBaseUrl`:
   ```dart
   case 'production':
     return 'https://api.yourdomain.com';
   ```

---

## No Action Needed — Fully Working with FOSS

The following work completely without any credentials:
- ✅ Maps (OpenStreetMap + flutter_map)
- ✅ Route calculation (OSRM)
- ✅ Geocoding (Nominatim)
- ✅ Full-text search (PostgreSQL ILIKE)
- ✅ File storage (MinIO)
- ✅ Email dev (MailHog)
- ✅ Real-time notifications (SSE)
- ✅ Simulated payments (all 6 states)
- ✅ OTP verification (console log)
- ✅ JWT authentication
- ✅ Monitoring (Prometheus + Grafana + Loki)
