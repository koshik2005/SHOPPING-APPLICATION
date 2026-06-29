import 'package:latlong2/latlong.dart';

abstract class GeofenceClient {
  Future<Map<String, dynamic>> checkBranchZone(LatLng location);
}
