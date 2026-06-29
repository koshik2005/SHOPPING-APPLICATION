# Production Third-Party Integration Checklist

This checklist documents the exact setup steps, credentials, URLs, and file modifications required to transition the HyperLocal Enterprise Platform from local mock UAT testing to live production-grade environments.

---

## 1. Google Maps
* **Purpose:** Geolocation searches, location suggestions, geofencing branch detection, and delivery rider map tracking.
* **Required Account:** Google Cloud Console account with billing enabled.
* **Required API Keys:** Web/Android/iOS API Key with the following APIs enabled:
  - Maps SDK for Android
  - Maps SDK for iOS
  - Places API
  - Geocoding API
  - Distance Matrix API
* **Console URL:** [https://console.cloud.google.com](https://console.cloud.google.com)
* **Environment Variables:**
  - Client-side: `--dart-define=GOOGLE_MAPS_API_KEY=your_key`
  - Backend-side: `GOOGLE_MAPS_API_KEY`
* **Files Needing Modification:**
  - Client config: [state.dart](file:///e:/shopping/lib/core/state.dart) (replace `ENVIRONMENT_SECURE_MAPS_KEY`)
  - Android config: `android/app/src/main/AndroidManifest.xml` (add meta-data API key entry)
  - iOS config: `ios/Runner/AppDelegate.swift` and `ios/Runner/Info.plist`
* **Verification Steps:**
  1. Boot client app, open `/maps` route, and verify the animated location canvas loads pins correctly.
  2. Verify geofencing detection queries distance matrix without API signature rejections.

---

## 2. Firebase & FCM (Firebase Cloud Messaging)
* **Purpose:** Mobile OAuth logins, push notifications, and device analytics.
* **Required Account:** Firebase Console account.
* **Required API Keys:**
  - Android config: `google-services.json`
  - iOS config: `GoogleService-Info.plist`
  - Private key credentials file for the Firebase Service Account (used by backend).
* **Console URL:** [https://console.firebase.google.com](https://console.firebase.google.com)
* **Environment Variables:**
  - Backend: `GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-adminsdk-key.json` inside the `notification-service`.
* **Files Needing Modification:**
  - Android config: Add `google-services.json` in `android/app/` and update `android/build.gradle`.
  - iOS config: Add `GoogleService-Info.plist` to the Xcode project workspace.
  - Backend config: `notification-service` application properties defining the firebase project path.
* **Verification Steps:**
  1. Trigger push notifications from the Firebase Console to a registered device token.
  2. Verify that the mobile client displays notification banners.

---

## 3. Razorpay
* **Purpose:** Payment gateway for local credit cards, NetBanking, and UPI (specifically for India markets).
* **Required Account:** Razorpay Merchant account.
* **Required API Keys:** Razorpay Key ID, Key Secret, Webhook Secret.
* **Console URL:** [https://dashboard.razorpay.com](https://dashboard.razorpay.com)
* **Environment Variables:**
  - Backend: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET` in `payment-service`.
* **Files Needing Modification:**
  - Backend config: Add `RazorpayProvider.java` in `payment-service` implementing `PaymentGatewayProvider`.
  - Client config: Integrate Razorpay SDK dependency in client `pubspec.yaml` and initialize Razorpay checkout listeners on payment.
* **Verification Steps:**
  1. Execute a checkout session in the customer app, complete the transaction in Razorpay sandbox using dummy cards/UPI.
  2. Verify backend receives Razorpay Webhook callback and updates the `payments` state table.

---

## 4. Stripe
* **Purpose:** Payment gateway for international debit/credit cards, Google Pay, and Apple Pay.
* **Required Account:** Stripe Developer account.
* **Required API Keys:** Stripe Secret Key, Publishable Key, Webhook Signing Secret.
* **Console URL:** [https://dashboard.stripe.com](https://dashboard.stripe.com)
* **Environment Variables:**
  - Backend: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` in `payment-service`.
  - Client-side: `--dart-define=STRIPE_PUBLISHABLE_KEY=your_key`
* **Files Needing Modification:**
  - Backend config: Update `StripeProvider.java` in `payment-service` to call Stripe SDK library instead of returning mock checkouts.
  - Client config: Update [state.dart](file:///e:/shopping/lib/core/state.dart) publishable key.
* **Verification Steps:**
  1. Boot Stripe CLI webhook listener: `stripe listen --forward-to localhost:8086/api/v1/payments/webhook`.
  2. Initiate checkout in client, inspect webhook log output, and verify order transitions to `PAID`.

---

## 5. Twilio & MSG91
* **Purpose:** Dispatching SMS OTP verification codes during user logins, password recoveries, and checkout confirmations.
* **Required Account:** Twilio Developer account / MSG91 merchant account.
* **Required API Keys:**
  - Twilio: Account SID, Auth Token, Twilio verified phone number.
  - MSG91: Authkey, DLT Template ID.
* **Console URL:**
  - Twilio: [https://www.twilio.com/console](https://www.twilio.com/console)
  - MSG91: [https://control.msg91.com](https://control.msg91.com)
* **Environment Variables:**
  - Backend: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER`, `MSG91_AUTH_KEY` in `notification-service`.
* **Files Needing Modification:**
  - Backend config: `notification-service` application resource properties and SMS dispatcher classes.
* **Verification Steps:**
  1. Request an OTP verification code inside the mobile application.
  2. Verify that the SMS delivers the template code correctly to the target phone number.

---

## 6. SendGrid & AWS SES
* **Purpose:** Sending system emails (OTP codes, receipt PDF invoices, account activity alerts).
* **Required Account:** SendGrid account / AWS console account with Simple Email Service (SES) access.
* **Required API Keys:**
  - SendGrid: API Key.
  - AWS: Access Key ID, Secret Access Key, verified sender identity.
* **Console URL:**
  - SendGrid: [https://app.sendgrid.com](https://app.sendgrid.com)
  - AWS SES: [https://console.aws.amazon.com/ses](https://console.aws.amazon.com/ses)
* **Environment Variables:**
  - Backend: `SENDGRID_API_KEY`, `AWS_SES_ACCESS_KEY`, `AWS_SES_SECRET_KEY` in `notification-service`.
* **Files Needing Modification:**
  - Backend config: `notification-service` email templates and template routing config maps.
* **Verification Steps:**
  1. Request password recovery inside the mobile application.
  2. Check email inbox for the system-dispatched recovery message.

---

## 7. Cloudinary
* **Purpose:** Dynamic hosting, compression, and delivery optimization for merchant logo banners, profiles, and product images.
* **Required Account:** Cloudinary Console account.
* **Required API Keys:** Cloud Name, API Key, API Secret.
* **Console URL:** [https://cloudinary.com/console](https://cloudinary.com/console)
* **Environment Variables:**
  - Backend: `CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name` in `inventory-service` and `shop-service`.
* **Files Needing Modification:**
  - Backend config: S3/Cloudinary configuration profiles in shop and inventory services.
* **Verification Steps:**
  1. Upload a merchant banner photo through the backend portal API.
  2. Verify that the service returns a processed optimization CDN URL (e.g., `res.cloudinary.com/...`).

---

## 8. S3 (AWS Simple Storage Service)
* **Purpose:** Bulk persistent cloud storage (merchant registration documents, rider licenses, PDF invoices).
* **Required Account:** AWS Console account.
* **Required API Keys:** AWS Access Key ID, Secret Access Key, S3 Bucket Name, Bucket Region.
* **Console URL:** [https://s3.console.aws.amazon.com](https://s3.console.aws.amazon.com)
* **Environment Variables:**
  - Backend: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_S3_BUCKET_NAME`, `AWS_REGION` inside `branch-manager-service` and `delivery-service`.
* **Files Needing Modification:**
  - Backend config: AWS S3 client builder classes in target services.
* **Verification Steps:**
  1. Upload a delivery driver PDF document via registration portal APIs.
  2. Log in to the S3 bucket dashboard to verify that the file metadata matches the database registries.
