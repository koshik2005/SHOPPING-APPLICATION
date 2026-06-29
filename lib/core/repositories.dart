import 'package:dio/dio.dart';
import 'api_client.dart';
import 'session_manager.dart';

class AuthRepository {
  final ApiClient _client;
  final SessionManager _sessionManager;

  AuthRepository(this._client, this._sessionManager);

  Future<Map<String, dynamic>> loginWithGoogle(String idToken, Map<String, dynamic> device) async {
    final response = await _client.dio.post(
      '/api/v1/auth/google-login',
      data: {
        'idToken': idToken,
        'device': device,
      },
    );
    final data = response.data['data'];
    if (data != null && data['accessToken'] != null) {
      await _sessionManager.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'] ?? '',
      );
    }
    return response.data; // Return full response body (which contains status/data)
  }

  Future<void> logout(String sessionId) async {
    await _client.dio.post(
      '/api/v1/auth/logout',
      options: Options(headers: {'X-Session-ID': sessionId}),
    );
    await SessionManager.clearSession();
  }
}

class CustomerRepository {
  final ApiClient _client;
  CustomerRepository(this._client);

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await _client.dio.get(
      '/api/v1/customers/profile',
      options: Options(headers: {'X-User-ID': userId}),
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getProfileMe() async {
    final response = await _client.dio.get('/api/v1/customers/me');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> bootstrapHome(String userId) async {
    final response = await _client.dio.get(
      '/api/v1/customers/bootstrap',
      options: Options(headers: {'X-User-ID': userId}),
    );
    return response.data['data'];
  }
}

class ShopRepository {
  final ApiClient _client;
  ShopRepository(this._client);

  Future<List<dynamic>> getShops(String branchId) async {
    final response = await _client.dio.get('/api/v1/shops/branch/$branchId');
    return response.data['data'];
  }
}

class InventoryRepository {
  final ApiClient _client;
  InventoryRepository(this._client);

  Future<List<dynamic>> getCategories() async {
    final response = await _client.dio.get('/api/v1/inventory/categories');
    return response.data['data'];
  }

  Future<List<dynamic>> getProducts(String shopId) async {
    final response = await _client.dio.get('/api/v1/inventory/products/shop/$shopId');
    return response.data['data'];
  }

  Future<int> getStock(String variantId) async {
    final response = await _client.dio.get('/api/v1/inventory/stock/$variantId');
    return response.data['data'] as int;
  }
}

class SearchRepository {
  final ApiClient _client;
  SearchRepository(this._client);

  Future<Map<String, dynamic>> query(String? userId, Map<String, dynamic> body) async {
    final hdrs = userId != null ? {'X-User-ID': userId} : <String, String>{};
    final response = await _client.dio.post(
      '/api/v1/search/query',
      options: Options(headers: hdrs),
      data: body,
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getSuggestions(String? userId) async {
    final hdrs = userId != null ? {'X-User-ID': userId} : <String, String>{};
    final response = await _client.dio.get(
      '/api/v1/search/suggestions',
      options: Options(headers: hdrs),
    );
    return response.data['data'];
  }
}

class CartRepository {
  final ApiClient _client;
  CartRepository(this._client);

  Future<Map<String, dynamic>> getSummary(String userId) async {
    final response = await _client.dio.get(
      '/api/v1/cart/summary',
      options: Options(headers: {'X-User-ID': userId}),
    );
    return response.data['data'];
  }

  Future<void> addItem(String userId, String variantId, int quantity) async {
    await _client.dio.post(
      '/api/v1/cart/add',
      options: Options(headers: {'X-User-ID': userId}),
      queryParameters: {'variantId': variantId, 'quantity': quantity},
    );
  }

  Future<void> clearCart(String userId) async {
    await _client.dio.delete(
      '/api/v1/cart/clear',
      options: Options(headers: {'X-User-ID': userId}),
    );
  }
}

class OrderRepository {
  final ApiClient _client;
  OrderRepository(this._client);

  Future<Map<String, dynamic>> createOrder(String userId, Map<String, dynamic> body) async {
    final response = await _client.dio.post(
      '/api/v1/orders/create',
      options: Options(headers: {'X-User-ID': userId}),
      data: body,
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getTimeline(String orderId) async {
    final response = await _client.dio.get('/api/v1/orders/$orderId/timeline');
    return response.data['data'];
  }
}

class PaymentRepository {
  final ApiClient _client;
  PaymentRepository(this._client);

  Future<Map<String, dynamic>> charge(Map<String, dynamic> body) async {
    final response = await _client.dio.post(
      '/api/v1/payments/charge',
      data: body,
    );
    return response.data['data'];
  }
}

class WalletRepository {
  final ApiClient _client;
  WalletRepository(this._client);

  Future<Map<String, dynamic>> getBalance(String userId) async {
    final response = await _client.dio.get(
      '/api/v1/wallets/balance',
      options: Options(headers: {'X-User-ID': userId}),
    );
    return response.data['data'];
  }

  Future<void> credit(String userId, double amount) async {
    await _client.dio.post(
      '/api/v1/wallets/credit',
      options: Options(headers: {'X-User-ID': userId}),
      data: {'amount': amount},
    );
  }

  Future<void> debit(String userId, double amount) async {
    await _client.dio.post(
      '/api/v1/wallets/debit',
      options: Options(headers: {'X-User-ID': userId}),
      data: {'amount': amount},
    );
  }

  Future<List<dynamic>> getTransactions(String userId) async {
    final response = await _client.dio.get(
      '/api/v1/wallets/transactions',
      options: Options(headers: {'X-User-ID': userId}),
    );
    return response.data['data'];
  }
}

class DeliveryRepository {
  final ApiClient _client;
  DeliveryRepository(this._client);

  Future<Map<String, dynamic>> getStatus(String orderId) async {
    final response = await _client.dio.get('/api/v1/deliveries/order/$orderId/status');
    return response.data['data'];
  }
}
