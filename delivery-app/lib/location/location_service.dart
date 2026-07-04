import 'dart:async';
import 'package:dio/dio';
import 'auth_repository.dart';

class LocationService {
  final AuthRepository _authRepository = AuthRepository();
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  Timer? _timer;

  void startTracking(String deliveryId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final token = await _authRepository.getAccessToken();
      if (token == null) return;

      // Mock geolocator location updates for simulation sandbox
      final mockLat = 37.7749 + (timer.tick * 0.0001);
      final mockLng = -122.4194 + (timer.tick * 0.0001);

      try {
        await _dio.post(
          '/api/v1/deliveries/$deliveryId/location',
          data: {
            'latitude': mockLat,
            'longitude': mockLng,
            'timestamp': DateTime.now().toIso8601String(),
          },
          options: Options(headers: {
            'Authorization': 'Bearer $token',
          }),
        );
      } catch (e) {
        print('Error publishing delivery location: $e');
      }
    });
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }
}
