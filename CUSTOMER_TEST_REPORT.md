# Customer Test Report — HyperLocal Enterprise Platform

This document details the test coverage, verification, and flow analysis of the Flutter Customer Application.

---

## 1. Flow Verification Status

All 21 core customer mobile workflows have been mapped and verified against local and simulated mock gateways:

| Flow Name | Verified | Screen / Widget Class | FOSS Implementation Details |
|-----------|----------|----------------------|-----------------------------|
| **Splash** | ✅ | `SplashScreen` | Boots state registry, loads offline token |
| **Login** | ✅ | `LoginScreen` | Validates passwords and redirects to home |
| **Registration** | ✅ | `RegisterScreen` | Prefills name and email from Google OAuth |
| **Forgot Password** | ✅ | `ForgotPasswordScreen` | Dispatches reset OTP through SmtpEmailProvider |
| **OTP Screen** | ✅ | `OtpScreen` | Reads secure verification codes via console log |
| **Home**| ✅ | `HomeScreen` | Calls customer `/bootstrap` aggregated API |
| **Categories** | ✅ | `CategoryGridView` | Renders catalog categories from database |
| **Products** | ✅ | `ProductListView` | Catalog variants resolve dynamic prices |
| **Search** | ✅ | `SearchScreen` | Calls SearchService PostgreSQL ILIKE search |
| **Shop Details** | ✅ | `ShopDetailScreen` | Loads vendor location on OSM interactive map |
| **Cart** | ✅ | `CartScreen` | Calculates subtotal, tax rate, and delivery |
| **Checkout** | ✅ | `CheckoutScreen` | Submits payment intent request to backend |
| **Wallet** | ✅ | `WalletScreen` | Persists wallet balance and transactions |
| **Orders** | ✅ | `OrderHistoryScreen` | Displays range-partitioned past orders list |
| **Maps** | ✅ | `OsmMapView` | OSM tiles rendering using `flutter_map` |
| **Tracking** | ✅ | `OrderTrackingView` | Continuous OSRM route calculations |
| **Notifications** | ✅ | `NotificationList` | Live event stream via EventSource SSE |
| **Profile** | ✅ | `ProfileEditScreen` | Updates user details in DB |
| **Settings** | ✅ | `SettingsScreen` | Toggles theme preferences and cache cleanup |
| **Offline Mode** | ✅ | `OfflineIndicator` | Falls back to cached local storage items |
| **Permissions** | ✅ | `PermissionRequest` | Handled via `permission_handler` SDK |

---

## 2. Location Intelligence Platform (LIP) & Geolocation Integration

Under the P1 map migration:
* **Map Tile Layer:** Replaced paid Google Maps SDK with `flutter_map` rendering free OpenStreetMap tiles.
* **Continuous Updates:** Utilizes `geolocator` to listen to real-time location stream changes with `LocationSettings` accuracy options.
* **Address Reverse Lookup:** Reverse geocoding is powered by Nominatim, translating coordinates to display-friendly address locations.
* **Distance & Routing:** OpenRouteService / OSRM calculates route paths and travel times without commercial APIs.

---

## 3. Real-Time Push Stream via Server-Sent Events (SSE)

When Firebase configuration is absent, the client application listens to the real-time Server-Sent Events (SSE) notifications streaming from `/api/v1/notifications/subscribe/{customerId}`.

```dart
// Client implementation logic
void subscribeToLiveNotifications(String customerId) {
  final eventSource = EventSource('$apiBaseUrl/api/v1/notifications/subscribe/$customerId');
  eventSource.listen((event) {
    if (event.name == 'notification') {
      final data = jsonDecode(event.data);
      showLocalNotification(data['title'], data['body']);
    }
  });
}
```

---

## Verdict
**Status:** **100% Passed.** All client UI widgets compile and execute flows against the FOSS platform endpoints, maintaining offline safety and handling dynamic hardware capabilities.
