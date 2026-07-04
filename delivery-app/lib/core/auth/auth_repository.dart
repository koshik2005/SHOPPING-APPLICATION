import 'dart:convert';
import 'package:dio/dio';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080', // Proxy target / direct gateway URL
    connectTimeout: const Duration(seconds: 10),
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/v1/auth/verify-password', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final role = data['user']?['role'] ?? '';

        // Verification: Only delivery partners can log in to the partner app!
        if (role != 'ROLE_DELIVERY_PARTNER') {
          throw Exception('UNAUTHORIZED: Account is not registered as a delivery partner.');
        }

        await _storage.write(key: 'accessToken', value: data['accessToken']);
        await _storage.write(key: 'refreshToken', value: data['refreshToken']);
        await _storage.write(key: 'user', value: jsonEncode(data['user']));
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }
}
