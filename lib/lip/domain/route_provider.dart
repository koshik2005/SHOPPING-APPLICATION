import 'package:latlong2/latlong.dart';

class MapRoute {
  final List<LatLng> polyline;
  final double distanceMiles;
  final double durationMinutes;

  MapRoute({
    required this.polyline,
    required this.distanceMiles,
    required this.durationMinutes,
  });
}

abstract class RouteProvider {
  Future<MapRoute> calculateRoute(LatLng start, LatLng end);
}
