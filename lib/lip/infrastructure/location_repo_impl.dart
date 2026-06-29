import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/location_repo.dart';
import '../domain/permission_state.dart';
import '../lip_di.dart';

class LocationRepositoryImpl implements LocationRepository {
  final Ref _ref;

  LocationRepositoryImpl(this._ref);

  @override
  Future<Position?> getCurrentLocation() async {
    final status = await _ref.read(permissionManagerProvider).checkPermissionState();
    if (status == LipPermissionState.granted || status == LipPermissionState.limited) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    }
    return await getLastKnownLocation();
  }

  @override
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  @override
  Future<Position?> getLastKnownLocation() async {
    return await Geolocator.getLastKnownPosition();
  }

  @override
  Future<LipPermissionState> checkPermissionState() async {
    return await _ref.read(permissionManagerProvider).checkPermissionState();
  }

  @override
  Future<LipPermissionState> requestPermission() async {
    return await _ref.read(permissionManagerProvider).requestLocationPermission();
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> isMockLocationDetected() async {
    try {
      final pos = await getLastKnownLocation();
      if (pos != null && pos.isMocked) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}
