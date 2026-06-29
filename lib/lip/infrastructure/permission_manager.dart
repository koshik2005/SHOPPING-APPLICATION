import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../domain/permission_state.dart';

class PermissionManager {
  final Ref _ref;

  PermissionManager(this._ref);

  Future<LipPermissionState> checkPermissionState() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      final gpsEnabled = await geo.Geolocator.isLocationServiceEnabled();
      return gpsEnabled ? LipPermissionState.granted : LipPermissionState.gpsDisabled;
    }
    if (status.isDenied) return LipPermissionState.denied;
    if (status.isPermanentlyDenied) return LipPermissionState.permanentlyDenied;
    if (status.isLimited) return LipPermissionState.limited;
    if (status.isRestricted) return LipPermissionState.restricted;
    return LipPermissionState.unknown;
  }

  Future<LipPermissionState> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final gpsEnabled = await geo.Geolocator.isLocationServiceEnabled();
      return gpsEnabled ? LipPermissionState.granted : LipPermissionState.gpsDisabled;
    }
    if (status.isDenied) return LipPermissionState.denied;
    if (status.isPermanentlyDenied) return LipPermissionState.permanentlyDenied;
    if (status.isLimited) return LipPermissionState.limited;
    if (status.isRestricted) return LipPermissionState.restricted;
    return LipPermissionState.unknown;
  }

  Future<bool> openSystemSettings() async {
    return await openAppSettings();
  }
}
