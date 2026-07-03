import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'repositories.dart';
import 'identity_providers.dart';
import 'session_manager.dart';
import 'google_sdk_adapter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

String get apiBaseUrl {
  switch (environment) {
    case 'staging':
      return const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://staging.api.hyperlocal.app');
    case 'production':
      return const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.hyperlocal.app');
    case 'dev':
    default:
      return const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.61.26.56:8080');
  }
}

const String _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '1086613811908-vf6okpd8jvr0f5oaqvnemujb7niooe7k.apps.googleusercontent.com',
);

String get serverClientId {
  if (_googleServerClientId.isEmpty || _googleServerClientId.contains('placeholder')) {
    throw UnsupportedError(
      'CRITICAL CONFIG ERROR: GOOGLE_SERVER_CLIENT_ID is not configured!\n'
      'You must run the application supplying your real Web Client ID via --dart-define:\n'
      'flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your_real_client_id'
    );
  }
  return _googleServerClientId;
}

final googleSdkAdapterProvider = Provider<GoogleSdkAdapter>((ref) => GoogleSdkAdapter());

final identityProvider = Provider<IdentityProvider>((ref) {
  return GoogleIdentityProvider(serverClientId, ref.watch(googleSdkAdapterProvider));
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager(ref.watch(secureStorageProvider));
});

// --------------------------------------------------------------------------
// Riverpod Providers for Repositories & ApiClient
// --------------------------------------------------------------------------
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(sessionManagerProvider));
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(apiClientProvider));
});

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.watch(apiClientProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(apiClientProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(apiClientProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(apiClientProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(apiClientProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiClientProvider));
});

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(ref.watch(apiClientProvider));
});

// --------------------------------------------------------------------------
// 1. App Configuration & Remote Config Model
// --------------------------------------------------------------------------
class AppConfig {
  final bool maintenanceMode;
  final String appVersion;
  final bool forceUpdateRequired;
  final String apiVersion;
  final int otpLength;
  final int otpExpirySeconds;
  final List<String> enabledLoginMethods;
  final String passwordPolicyRegex;
  final int sessionTimeoutSeconds;
  final int maxLoginAttempts;
  final double baseDeliveryFee;
  final double deliveryFeePerMile;
  final double platformFee;
  final double taxRate;
  final String termsUrl;
  final String privacyUrl;

  AppConfig({
    required this.maintenanceMode,
    required this.appVersion,
    required this.forceUpdateRequired,
    required this.apiVersion,
    required this.otpLength,
    required this.otpExpirySeconds,
    required this.enabledLoginMethods,
    required this.passwordPolicyRegex,
    required this.sessionTimeoutSeconds,
    required this.maxLoginAttempts,
    required this.baseDeliveryFee,
    required this.deliveryFeePerMile,
    required this.platformFee,
    required this.taxRate,
    required this.termsUrl,
    required this.privacyUrl,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      maintenanceMode: json['maintenanceMode'] ?? false,
      appVersion: json['appVersion'] ?? '2.4.12',
      forceUpdateRequired: json['forceUpdateRequired'] ?? false,
      apiVersion: json['apiVersion'] ?? 'v1.4',
      otpLength: json['otpLength'] ?? 6,
      otpExpirySeconds: json['otpExpirySeconds'] ?? 60,
      enabledLoginMethods: List<String>.from(json['enabledLoginMethods'] ?? ['phone', 'google', 'apple']),
      passwordPolicyRegex: json['passwordPolicyRegex'] ?? "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}\$",
      sessionTimeoutSeconds: json['sessionTimeoutSeconds'] ?? 3600,
      maxLoginAttempts: json['maxLoginAttempts'] ?? 5,
      baseDeliveryFee: (json['baseDeliveryFee'] ?? 2.50).toDouble(),
      deliveryFeePerMile: (json['deliveryFeePerMile'] ?? 0.75).toDouble(),
      platformFee: (json['platformFee'] ?? 0.50).toDouble(),
      taxRate: (json['taxRate'] ?? 0.08).toDouble(),
      termsUrl: json['termsUrl'] ?? '',
      privacyUrl: json['privacyUrl'] ?? '',
    );
  }
}

class AppConfigNotifier extends StateNotifier<AppConfig> {
  final CustomerRepository _repository;
  
  AppConfigNotifier(this._repository) : super(AppConfig(
    maintenanceMode: false,
    appVersion: '2.4.12',
    forceUpdateRequired: false,
    apiVersion: 'v1.4',
    otpLength: 6,
    otpExpirySeconds: 60,
    enabledLoginMethods: ['phone', 'google', 'apple'],
    passwordPolicyRegex: r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
    sessionTimeoutSeconds: 3600,
    maxLoginAttempts: 5,
    baseDeliveryFee: 2.50,
    deliveryFeePerMile: 0.75,
    platformFee: 0.50,
    taxRate: 0.08,
    termsUrl: 'https://cdn.hyperlocal.app/legal/terms.html',
    privacyUrl: 'https://cdn.hyperlocal.app/legal/privacy.html',
  )) {
    fetchConfig();
  }

  Future<void> fetchConfig() async {
    try {
      final data = await _repository.bootstrapHome("87ef769c-d021-4f11-ba32-aafe812bb31c");
      if (data.containsKey('appConfig')) {
        state = AppConfig.fromJson(data['appConfig']);
      }
    } catch (_) {}
  }
}

final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier(ref.watch(customerRepositoryProvider));
});

// --------------------------------------------------------------------------
// 2. User Data Model
// --------------------------------------------------------------------------
class UserProfile {
  final String name;
  final String email;
  final String mobileNumber;
  final String gender;
  final String dob;
  final String profilePhotoUrl;
  final List<String> addresses;
  final Map<String, String> savedPlaces;
  final String preferredLanguage;
  final String preferredCurrency;
  final String themePreference;

  UserProfile({
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.gender,
    required this.dob,
    required this.profilePhotoUrl,
    required this.addresses,
    required this.savedPlaces,
    required this.preferredLanguage,
    required this.preferredCurrency,
    required this.themePreference,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['displayName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] ?? '',
      addresses: List<String>.from(json['addresses'] ?? []),
      savedPlaces: Map<String, String>.from(json['savedPlaces'] ?? {}),
      preferredLanguage: json['preferredLanguage'] ?? 'English',
      preferredCurrency: json['preferredCurrency'] ?? 'USD',
      themePreference: json['themePreference'] ?? 'light',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'gender': gender,
      'dob': dob,
      'profilePhotoUrl': profilePhotoUrl,
      'addresses': addresses,
      'savedPlaces': savedPlaces,
      'preferredLanguage': preferredLanguage,
      'preferredCurrency': preferredCurrency,
      'themePreference': themePreference,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? mobileNumber,
    String? gender,
    String? dob,
    String? profilePhotoUrl,
    List<String>? addresses,
    Map<String, String>? savedPlaces,
    String? preferredLanguage,
    String? preferredCurrency,
    String? themePreference,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      addresses: addresses ?? this.addresses,
      savedPlaces: savedPlaces ?? this.savedPlaces,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile(
    name: '',
    email: '',
    mobileNumber: '',
    gender: '',
    dob: '',
    profilePhotoUrl: '',
    addresses: [],
    savedPlaces: {},
    preferredLanguage: 'English',
    preferredCurrency: 'USD',
    themePreference: 'light',
  ));

  void updateProfile(UserProfile updated) => state = updated;

  void addAddress(String address) {
    state = state.copyWith(addresses: [...state.addresses, address]);
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});

final authStateProvider = StateProvider<bool>((ref) => false);
final sentOtpProvider = StateProvider<String>((ref) => '');
final tempRegistrationProvider = StateProvider<UserProfile?>((ref) => null);
final tempWalletBalanceProvider = StateProvider<double>((ref) => 0.00);

class WalletNotifier extends StateNotifier<double> {
  WalletNotifier() : super(0.00);
  void deduct(double amount) => state = state - amount;
  void add(double amount) => state = state + amount;
  void setBalance(double val) => state = val;
}

final walletProvider = StateNotifierProvider<WalletNotifier, double>((ref) {
  return WalletNotifier();
});

class PointsNotifier extends StateNotifier<int> {
  PointsNotifier() : super(0);
  void addPoints(int amount) => state = state + amount;
}

final pointsProvider = StateNotifierProvider<PointsNotifier, int>((ref) {
  return PointsNotifier();
});

// --------------------------------------------------------------------------
// 3. Location, Geofencing & Branch Setup
// --------------------------------------------------------------------------
class UserLocationState {
  final double latitude;
  final double longitude;
  final String pincode;
  final String city;
  final bool serviceAvailable;

  UserLocationState({
    required this.latitude,
    required this.longitude,
    required this.pincode,
    required this.city,
    required this.serviceAvailable,
  });
}

class LocationNotifier extends StateNotifier<UserLocationState> {
  LocationNotifier() : super(UserLocationState(
    latitude: 37.7749,
    longitude: -122.4194,
    pincode: '94103',
    city: 'San Francisco',
    serviceAvailable: true,
  ));

  void updateLocation(UserLocationState newLoc) => state = newLoc;
}

final locationProvider = StateNotifierProvider<LocationNotifier, UserLocationState>((ref) {
  return LocationNotifier();
});

// --------------------------------------------------------------------------
// 4. Branch Info Details
// --------------------------------------------------------------------------
class BranchInfo {
  final String id;
  final String name;
  final String address;
  final String workingHours;
  final bool isOpen;
  final double deliveryRadiusMiles;
  final String contactNumber;
  final double latitude;
  final double longitude;

  BranchInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.workingHours,
    required this.isOpen,
    required this.deliveryRadiusMiles,
    required this.contactNumber,
    required this.latitude,
    required this.longitude,
  });

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'],
      name: json['name'],
      address: json['address'] ?? '',
      workingHours: json['workingHours'] ?? '',
      isOpen: json['isOpen'] ?? true,
      deliveryRadiusMiles: (json['deliveryRadiusMiles'] ?? 5.0).toDouble(),
      contactNumber: json['contactNumber'] ?? '',
      latitude: (json['latitude'] ?? 37.7749).toDouble(),
      longitude: (json['longitude'] ?? -122.4194).toDouble(),
    );
  }
}

class BranchInfoNotifier extends StateNotifier<Map<String, BranchInfo>> {
  BranchInfoNotifier() : super({
    'branch-a': BranchInfo(
      id: 'branch-a',
      name: 'Downtown Main Hub',
      address: '100 Main St, San Francisco',
      workingHours: '08:00 AM - 10:00 PM',
      isOpen: true,
      deliveryRadiusMiles: 5.0,
      contactNumber: '+15551110001',
      latitude: 37.7749,
      longitude: -122.4194,
    ),
  });

  Future<void> fetchBranches() async {}
}

final branchInfoListProvider = StateNotifierProvider<BranchInfoNotifier, Map<String, BranchInfo>>((ref) {
  return BranchInfoNotifier();
});

class SelectedBranchNotifier extends StateNotifier<String> {
  SelectedBranchNotifier() : super('branch-a');
  void selectBranch(String id) => state = id;
}

final selectedBranchProvider = StateNotifierProvider<SelectedBranchNotifier, String>((ref) {
  return SelectedBranchNotifier();
});

// --------------------------------------------------------------------------
// 5. Backend Categories & Product Catalog
// --------------------------------------------------------------------------
class CategoryItem {
  final String id;
  final String label;
  final String iconUrl;
  final bool isAvailable;
  final int displayOrder;

  CategoryItem({
    required this.id,
    required this.label,
    required this.iconUrl,
    required this.isAvailable,
    required this.displayOrder,
  });
}

class CategoryNotifier extends StateNotifier<List<CategoryItem>> {
  final InventoryRepository _repository;
  
  CategoryNotifier(this._repository) : super([]) {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final list = await _repository.getCategories();
      state = list.map((item) => CategoryItem(
        id: item['id'],
        label: item['name'],
        iconUrl: item['iconUrl'] ?? 'category',
        isAvailable: true,
        displayOrder: 1,
      )).toList();
    } catch (_) {
      state = [
        CategoryItem(id: 'food', label: 'Restaurant', iconUrl: 'restaurant', isAvailable: true, displayOrder: 1),
        CategoryItem(id: 'grocery', label: 'Local Shop', iconUrl: 'local_grocery_store', isAvailable: true, displayOrder: 2),
      ];
    }
  }
}

final categoriesProvider = StateNotifierProvider.family<CategoryNotifier, List<CategoryItem>, String>((ref, branchId) {
  return CategoryNotifier(ref.watch(inventoryRepositoryProvider));
});

class ProductItem {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double discountPrice;
  final int stockCount;
  final double taxPercent;
  final double weightGrams;
  final List<String> variants;
  final bool isAvailable;

  ProductItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.discountPrice,
    required this.stockCount,
    required this.taxPercent,
    required this.weightGrams,
    required this.variants,
    required this.isAvailable,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'],
      categoryId: json['categoryId'] ?? '',
      name: json['name'],
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] ?? 10.0).toDouble(),
      discountPrice: 0.0,
      stockCount: 100,
      taxPercent: 0.05,
      weightGrams: 100.0,
      variants: ['Standard'],
      isAvailable: true,
    );
  }
}

class ProductCatalogNotifier extends StateNotifier<List<ProductItem>> {
  final InventoryRepository _repository;
  
  ProductCatalogNotifier(this._repository) : super([]) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final list = await _repository.getProducts("87ef769c-d021-4f11-ba32-aafe812bb31c");
      state = list.map((json) => ProductItem.fromJson(json)).toList();
    } catch (_) {
      state = [
        ProductItem(id: 'p1', categoryId: 'food', name: 'Chicken Rice', description: 'Savory chicken rice with egg', imageUrl: '', price: 12.0, discountPrice: 0.0, stockCount: 100, taxPercent: 0.05, weightGrams: 200.0, variants: ['Standard'], isAvailable: true),
      ];
    }
  }
}

final catalogProvider = StateNotifierProvider.family<ProductCatalogNotifier, List<ProductItem>, String>((ref, branchId) {
  return ProductCatalogNotifier(ref.watch(inventoryRepositoryProvider));
});

// --------------------------------------------------------------------------
// 6. Restaurants / Shops Model
// --------------------------------------------------------------------------
class MerchantInfo {
  final String id;
  final String name;
  final String logoUrl;
  final String bannerUrl;
  final double rating;
  final String openingTime;
  final String closingTime;
  final double deliveryFee;
  final double minOrderValue;
  final int averagePrepTimeMinutes;

  MerchantInfo({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.bannerUrl,
    required this.rating,
    required this.openingTime,
    required this.closingTime,
    required this.deliveryFee,
    required this.minOrderValue,
    required this.averagePrepTimeMinutes,
  });
}

class MerchantListNotifier extends StateNotifier<List<MerchantInfo>> {
  final ShopRepository _repository;
  
  MerchantListNotifier(this._repository) : super([]) {
    fetchShops();
  }

  Future<void> fetchShops() async {
    try {
      final list = await _repository.getShops("branch-a");
      state = list.map((item) => MerchantInfo(
        id: item['id'],
        name: item['name'],
        logoUrl: 'https://cdn.hyperlocal.app/shops/logos/green_market.png',
        bannerUrl: 'https://cdn.hyperlocal.app/shops/banners/green_market.png',
        rating: 4.8,
        openingTime: '08:00 AM',
        closingTime: '09:00 PM',
        deliveryFee: 1.99,
        minOrderValue: 10.00,
        averagePrepTimeMinutes: 15,
      )).toList();
    } catch (_) {
      state = [
        MerchantInfo(
          id: 'm1',
          name: 'Dynamic Merchant Shop',
          logoUrl: 'https://cdn.hyperlocal.app/shops/logos/green_market.png',
          bannerUrl: 'https://cdn.hyperlocal.app/shops/banners/green_market.png',
          rating: 4.8,
          openingTime: '08:00 AM',
          closingTime: '09:00 PM',
          deliveryFee: 1.99,
          minOrderValue: 10.00,
          averagePrepTimeMinutes: 15,
        ),
      ];
    }
  }
}

final merchantListProvider = StateNotifierProvider<MerchantListNotifier, List<MerchantInfo>>((ref) {
  return MerchantListNotifier(ref.watch(shopRepositoryProvider));
});

// --------------------------------------------------------------------------
// 7. Cart State Notifier
// --------------------------------------------------------------------------
class CartStateItem {
  final ProductItem product;
  final int quantity;
  final String selectedVariant;

  CartStateItem({required this.product, required this.quantity, required this.selectedVariant});

  CartStateItem copyWith({int? quantity, String? selectedVariant}) {
    return CartStateItem(
      product: product,
      quantity: quantity ?? this.quantity,
      selectedVariant: selectedVariant ?? this.selectedVariant,
    );
  }
}

class DynamicCartNotifier extends StateNotifier<List<CartStateItem>> {
  DynamicCartNotifier() : super([]);

  void addItem(ProductItem product, String variant) {
    final existingIndex = state.indexWhere((i) => 
        i.product.id == product.id && 
        i.product.categoryId == product.categoryId && 
        i.selectedVariant == variant);
    if (existingIndex >= 0) {
      final list = List<CartStateItem>.from(state);
      list[existingIndex] = list[existingIndex].copyWith(quantity: list[existingIndex].quantity + 1);
      state = list;
    } else {
      state = [...state, CartStateItem(product: product, quantity: 1, selectedVariant: variant)];
    }
  }

  void updateQuantity(String id, String categoryId, String variant, int change) {
    final list = <CartStateItem>[];
    for (var item in state) {
      if (item.product.id == id && item.product.categoryId == categoryId && item.selectedVariant == variant) {
        final newQty = item.quantity + change;
        if (newQty > 0) {
          list.add(item.copyWith(quantity: newQty));
        }
      } else {
        list.add(item);
      }
    }
    state = list;
  }

  void clear() => state = [];
}

final dynamicCartProvider = StateNotifierProvider<DynamicCartNotifier, List<CartStateItem>>((ref) {
  return DynamicCartNotifier();
});

// --------------------------------------------------------------------------
// 8. Offers & Discounts Model
// --------------------------------------------------------------------------
class PromoOffer {
  final String code;
  final String title;
  final String description;
  final double discountAmount;
  final double minPurchase;

  PromoOffer({
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.minPurchase,
  });
}

class OffersNotifier extends StateNotifier<List<PromoOffer>> {
  OffersNotifier() : super([]);
}

final offersProvider = StateNotifierProvider<OffersNotifier, List<PromoOffer>>((ref) {
  return OffersNotifier();
});

// --------------------------------------------------------------------------
// 9. Active Order, Delivery Tracking & Statuses
// --------------------------------------------------------------------------
enum TrackingStatus { placed, accepted, preparing, ready, assigned, pickedUp, onTheWay, delivered, cancelled }

class TrackingMetrics {
  final TrackingStatus status;
  final double riderLat;
  final double riderLng;
  final String etaMinutes;
  final double currentSpeedMph;
  final double remainingDistanceMiles;
  final String driverName;
  final String driverPhone;

  TrackingMetrics({
    required this.status,
    required this.riderLat,
    required this.riderLng,
    required this.etaMinutes,
    required this.currentSpeedMph,
    required this.remainingDistanceMiles,
    required this.driverName,
    required this.driverPhone,
  });
}

class LiveTrackingNotifier extends StateNotifier<TrackingMetrics> {
  LiveTrackingNotifier() : super(TrackingMetrics(
    status: TrackingStatus.preparing,
    riderLat: 37.7752,
    riderLng: -122.4200,
    etaMinutes: '6 mins',
    currentSpeedMph: 15.5,
    remainingDistanceMiles: 0.8,
    driverName: 'Rider Rajesh',
    driverPhone: '+15559990001',
  ));

  void updateStatus(TrackingStatus next) {
    state = TrackingMetrics(
      status: next,
      riderLat: state.riderLat + 0.0005,
      riderLng: state.riderLng + 0.0005,
      etaMinutes: '4 mins',
      currentSpeedMph: 20.0,
      remainingDistanceMiles: 0.4,
      driverName: state.driverName,
      driverPhone: state.driverPhone,
    );
  }
}

final trackingProvider = StateNotifierProvider<LiveTrackingNotifier, TrackingMetrics>((ref) {
  return LiveTrackingNotifier();
});

// --------------------------------------------------------------------------
// 10. Gateway & Security Configs
// --------------------------------------------------------------------------
class SecurityKeys {
  final String mapsApiKey;
  final String paymentMerchantId;
  final String stripePublicKey;

  SecurityKeys({
    required this.mapsApiKey,
    required this.paymentMerchantId,
    required this.stripePublicKey,
  });
}

final securityProvider = Provider<SecurityKeys>((ref) {
  return SecurityKeys(
    mapsApiKey: 'ENVIRONMENT_SECURE_MAPS_KEY',
    paymentMerchantId: 'MERCHANT_GPAY_PRODUCTION_ID',
    stripePublicKey: 'pk_live_secure_credentials_holder',
  );
});

// --------------------------------------------------------------------------
// 11. FAQ & Support Contents
// --------------------------------------------------------------------------
class FAQItem {
  final String question;
  final String answer;
  FAQItem({required this.question, required this.answer});
}

final faqProvider = Provider<List<FAQItem>>((ref) {
  return [
    FAQItem(question: 'How do I request a refund?', answer: 'Refunds are automatically credited to your HyperWallet balance upon order cancellation.'),
  ];
});

class ConnectionNotifier extends StateNotifier<bool> {
  ConnectionNotifier() : super(true);
  void setOnline(bool state) => this.state = state;
}

final connectivityStateProvider = StateNotifierProvider<ConnectionNotifier, bool>((ref) {
  return ConnectionNotifier();
});

final userOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final user = ref.watch(userProfileProvider);
  if (user.email.isEmpty) return [];
  return [];
});

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: json['timestamp'] ?? '',
      isRead: json['isRead'] ?? false,
    );
  }
}

final notificationsProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
  try {
    final response = await ref.read(apiClientProvider).dio.get('/api/v1/notifications');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => NotificationItem.fromJson(json)).toList();
  } catch (_) {
    // Fallback notifications if backend notification service is unreachable/empty
    return [
      NotificationItem(
        id: '1',
        title: 'Order Placed successfully',
        body: 'Your order #HL-9824 has been received by Downtown Main Hub.',
        timestamp: '10 mins ago',
      ),
      NotificationItem(
        id: '2',
        title: 'Wallet Loaded',
        body: 'Successfully credited \$50.00 to your HyperWallet.',
        timestamp: '1 hour ago',
      ),
    ];
  }
});

