# HyperLocal Platform — User Action Required (Production Launch Checklist)
**Phase:** P2 (Production Readiness)
**Status:** ACTION REQUIRED

---

## 1. Third-Party Credentials & Keys
To deploy the platform to a production environment, the following credentials must be configured:

- **SMTP Server Details**: Update the host, port, username, and password parameters in the env config to enable OTP email dispatches.
- **Google OAuth Client IDs**: Configure production Google client IDs to support customer logins.
- **SMS Gateway API Keys**: Provide Twilio or similar SMS gateway credentials to enable mobile OTP logins.
- **Payment Gateway API Keys**: Provide Stripe, Razorpay, or similar payment gateway credentials to enable card payments and transactions.

---

## 2. Infrastructure Setup
- **Domain Names & SSL Certificates**: Configure domain routes and SSL/TLS certificates at the gateway proxy layer.
- **Firebase/FCM Server Keys**: Provide Firebase server keys to enable push notifications on mobile devices.
- **Hardware Security Modules (HSMs)**: Configure HSMs or cloud key managers (e.g. AWS KMS, HashiCorp Vault) to manage private signing keys securely.
- **Docker Compose Ports**: Update mapped ports in `docker-compose.yml` if target ports are already in use on the host machine.
