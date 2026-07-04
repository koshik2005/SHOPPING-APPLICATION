# FLUTTER APP ARCHITECTURE
## HyperLocal Enterprise Platform — Mobile Application Specifications

**Version:** 2.0

---

## 1. Application Overview

The platform has **exactly two Flutter applications**:

| App | Directory | Target Users | Store |
|---|---|---|---|
| **Customer App** | `e:\shopping\` (workspace root) | End customers | Play Store + App Store |
| **Delivery Partner App** | `e:\shopping\delivery-app\` | Delivery partners only | Play Store + App Store |

**No admin features exist in either Flutter app.**

---

## 2. Customer Application

### 2.1 Core Features
- **Authentication**: Google OAuth, Email+Password, OTP (phone/email)
- **Product Discovery**: Category browsing, search, filters
- **Cart & Checkout**: Multi-shop cart, address selection, delivery slot
- **Payment**: Wallet, UPI, Card (via payment gateway SDK)
- **Order Tracking**: Real-time status timeline + live GPS map
- **Wallet**: Balance view, top-up, transaction history
- **Profile**: Account settings, saved addresses, device management
- **Notifications**: Push (FCM), in-app notification center

### 2.2 Package Structure
```
lib/
  core/
    auth/
      auth_repository.dart       ← login, register, refresh, logout
      auth_state.dart            ← AuthState sealed class
      auth_bloc.dart             ← BLoC for auth state management
      secure_storage_service.dart ← FlutterSecureStorage wrapper
    network/
      api_client.dart            ← Dio with JWT interceptor + refresh
      interceptors/
        auth_interceptor.dart    ← attach Bearer token
        refresh_interceptor.dart ← auto-refresh on 401
    di/
      injection_container.dart   ← GetIt service locator
  features/
    home/              ← banner carousel, category grid, featured products
    product/           ← product detail, variant selection, reviews
    cart/              ← cart management, quantity controls
    checkout/          ← address, delivery slot, payment method selection
    payment/           ← payment gateway SDK integration
    order/             ← order list, order detail, timeline tracker
    tracking/          ← real-time GPS map (Google Maps / Mapbox)
    wallet/            ← balance, top-up, transaction history
    search/            ← search bar, filters, results
    profile/           ← account info, saved addresses, logout
    notification/      ← notification center
  shared/
    widgets/           ← reusable UI components
    theme/             ← color system, typography, spacing
    utils/             ← date formatting, currency, validators
```

### 2.3 State Management
- **BLoC** (flutter_bloc) for all features
- **Riverpod** or **GetIt** for dependency injection
- **Dio** for HTTP with interceptors

### 2.4 Security
```dart
// Token Storage: FlutterSecureStorage
// Uses iOS Keychain + Android Keystore
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

// Certificate Pinning (production)
(dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) {
    return cert.pem == PINNED_CERT;
  };
  return client;
};

// Secure Request Headers
dio.options.headers['X-Device-Info'] =
    'id=${deviceId};model=${model};os=${osVersion};fcm=${fcmToken}';
```

### 2.5 API Endpoints Used
```
Auth:     POST /api/v1/auth/google-login
          POST /api/v1/auth/send-otp
          POST /api/v1/auth/verify-otp
          POST /api/v1/auth/refresh-token
          POST /api/v1/auth/logout
Products: GET  /api/v1/inventory/categories
          GET  /api/v1/inventory/products?shopId=&categoryId=
          GET  /api/v1/search?q=&lat=&lng=
Cart:     GET/POST/PUT/DELETE /api/v1/cart
Orders:   POST /api/v1/orders
          GET  /api/v1/orders/{id}
          GET  /api/v1/orders
Tracking: GET  /api/v1/deliveries/{orderId}/track
Wallet:   GET  /api/v1/wallets/me
          POST /api/v1/wallets/topup
Profile:  GET/PUT /api/v1/customers/me
```

---

## 3. Delivery Partner Application

### 3.1 Directory
```
e:\shopping\delivery-app\
```
A completely separate Flutter project. Shares no code with the customer app.

### 3.2 Core Features
- **Authentication**: Email+Password + OTP (same backend auth APIs, `ROLE_DELIVERY_PARTNER`)
- **Active Deliveries**: List of assigned orders to accept/reject
- **Order Detail**: Pickup address, customer address, order items
- **GPS Tracking**: Background location publishing to backend
- **Navigation**: Launch Google Maps with order pickup/dropoff coordinates
- **Delivery Actions**: Accept → Picked Up → In Transit → Delivered flow
- **Wallet**: Earnings view + transaction history
- **Profile**: Personal info, vehicle info, documents, availability toggle

### 3.3 Package Structure
```
delivery-app/lib/
  core/
    auth/
      auth_repository.dart    ← login with DELIVERY_PARTNER role validation
      auth_bloc.dart
    network/
      api_client.dart         ← Dio with JWT + refresh
    location/
      location_service.dart   ← Geolocator background tracking
      location_publisher.dart ← POST /api/v1/deliveries/{id}/location
  features/
    login/                    ← Delivery partner login screen
    home/                     ← Dashboard: active delivery, earnings today
    deliveries/               ← Incoming orders list + accept/reject
    order_detail/             ← Order items, addresses, customer contact
    navigation/               ← Maps integration for pickup/dropoff
    tracking/                 ← Live GPS publishing while order is active
    wallet/                   ← Earnings breakdown, payout history
    profile/                  ← Availability toggle, documents, vehicle
  shared/
    widgets/
    theme/                    ← Different color theme (orange/dark)
    utils/
```

### 3.4 GPS Tracking Architecture
```dart
// Background location publishing:
// 1. Partner accepts order → LocationService.start(deliveryId)
// 2. Every 5 seconds: publish to /api/v1/deliveries/{id}/location
// 3. On delivery completion → LocationService.stop()

class LocationService {
  Timer? _timer;

  void start(String deliveryId) {
    _timer = Timer.periodic(Duration(seconds: 5), (_) async {
      final position = await Geolocator.getCurrentPosition();
      await apiClient.post('/api/v1/deliveries/$deliveryId/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  void stop() => _timer?.cancel();
}
```

### 3.5 API Endpoints Used
```
Auth:      POST /api/v1/auth/send-otp
           POST /api/v1/auth/verify-otp
           POST /api/v1/auth/refresh-token
Deliveries: GET  /api/v1/deliveries/assigned
            PUT  /api/v1/deliveries/{id}/accept
            PUT  /api/v1/deliveries/{id}/reject
            POST /api/v1/deliveries/{id}/location
            PUT  /api/v1/deliveries/{id}/status   (picked-up, delivered)
Wallet:    GET  /api/v1/wallets/partner/me
           GET  /api/v1/wallets/partner/transactions
Profile:   GET/PUT /api/v1/deliveries/partners/me
           PUT  /api/v1/deliveries/partners/me/availability
```

### 3.6 Security (Same as Customer App)
- FlutterSecureStorage for token storage
- Certificate pinning in production
- Device binding via `X-Device-Info` header
- No admin APIs accessible (server-side role enforcement)

---

## 4. Shared API Contract

Both apps communicate with the same API Gateway at `:8080`. Authentication uses the same auth-service endpoints. The difference is:

- Customer app users have `ROLE_CUSTOMER` → can access customer endpoints
- Delivery partner users have `ROLE_DELIVERY_PARTNER` → can access delivery partner endpoints
- Cross-role access is rejected at the gateway and service layer with `403 Forbidden`
