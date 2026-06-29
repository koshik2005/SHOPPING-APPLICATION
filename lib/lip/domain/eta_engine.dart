import 'package:latlong2/latlong.dart';

class EtaResult {
  final double distanceMiles;
  final double durationMinutes;
  final DateTime expectedArrivalTime;

  EtaResult({
    required this.distanceMiles,
    required this.durationMinutes,
    required this.expectedArrivalTime,
  });
}

abstract class EtaEngine {
  Future<EtaResult> calculateEta(LatLng current, LatLng destination, {double trafficFactor = 1.0});
}
