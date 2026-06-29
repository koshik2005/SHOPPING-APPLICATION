import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state.dart';

class ApiClient {
  final Dio dio = Dio();
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    dio.options.baseUrl = apiBaseUrl; // maps to local Spring Boot gateway
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['X-Correlation-ID'] = DateTime.now().millisecondsSinceEpoch.toString();
          final token = await _storage.read(key: 'accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshToken = await _storage.read(key: 'refreshToken');
            if (refreshToken != null) {
              try {
                final refreshResponse = await dio.post(
                  '/api/v1/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );
                if (refreshResponse.statusCode == 200) {
                  final newAccess = refreshResponse.data['data']['accessToken'];
                  final newRefresh = refreshResponse.data['data']['refreshToken'];
                  await _storage.write(key: 'accessToken', value: newAccess);
                  await _storage.write(key: 'refreshToken', value: newRefresh);

                  final retryOptions = error.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newAccess';
                  final response = await dio.fetch(retryOptions);
                  return handler.resolve(response);
                }
              } catch (_) {
                await _storage.deleteAll();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}
