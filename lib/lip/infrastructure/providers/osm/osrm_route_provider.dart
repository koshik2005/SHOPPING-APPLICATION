import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../domain/route_provider.dart';
import '../../../lip_config.dart';

class OsrmRouteProvider implements RouteProvider {
  final Ref _ref;

  OsrmRouteProvider(this._ref);

  @override
  Future<MapRoute> calculateRoute(LatLng start, LatLng end) async {
    final cfg = _ref.read(lipConfigProvider);
    final url = '${cfg.osrmUrl}/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final routes = data['routes'] as List<dynamic>;
        if (routes.isNotEmpty) {
          final first = routes[0];
          final geometry = first['geometry'] as Map<String, dynamic>;
          final coords = geometry['coordinates'] as List<dynamic>;

          final List<LatLng> polyline = coords.map((c) {
            final List<dynamic> point = c;
            return LatLng(point[1].toDouble(), point[0].toDouble());
          }).toList();

          final double distanceMeters = first['distance']?.toDouble() ?? 0.0;
          final double durationSeconds = first['duration']?.toDouble() ?? 0.0;

          return MapRoute(
            polyline: polyline,
            distanceMiles: distanceMeters / 1609.34,
            durationMinutes: durationSeconds / 60.0,
          );
        }
      }
    } catch (_) {}

    return MapRoute(
      polyline: [start, end],
      distanceMiles: const Distance().as(LengthUnit.Mile, start, end),
      durationMinutes: const Distance().as(LengthUnit.Mile, start, end) * 3.0,
    );
  }
}
