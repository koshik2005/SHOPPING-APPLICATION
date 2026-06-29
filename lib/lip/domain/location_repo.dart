import 'package:geolocator/geolocator.dart';
import 'permission_state.dart';

abstract class LocationRepository {
  Future<Position?> getCurrentLocation();
  Stream<Position> getLocationStream();
  Future<Position?> getLastKnownLocation();
  Future<LipPermissionState> checkPermissionState();
  Future<LipPermissionState> requestPermission();
  Future<bool> isLocationServiceEnabled();
  Future<bool> isMockLocationDetected();
}
