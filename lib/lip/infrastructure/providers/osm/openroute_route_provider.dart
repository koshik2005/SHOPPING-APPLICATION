import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../domain/route_provider.dart';
import '../../../lip_config.dart';

class OpenRouteRouteProvider implements RouteProvider {
  final Ref _ref;

  OpenRouteRouteProvider(this._ref);

  @override
  Future<MapRoute> calculateRoute(LatLng start, LatLng end) async {
    final cfg = _ref.read(lipConfigProvider);
    if (cfg.openRouteServiceApiKey.isEmpty) {
      return MapRoute(
        polyline: [start, end],
        distanceMiles: const Distance().as(LengthUnit.Mile, start, end),
        durationMinutes: const Distance().as(LengthUnit.Mile, start, end) * 3.0,
      );
    }

    final url = '${cfg.openRouteServiceUrl}/v2/directions/driving-car';
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': cfg.openRouteServiceApiKey,
        },
        body: json.encode({
          'coordinates': [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude]
          ]
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final routes = data['routes'] as List<dynamic>;
        if (routes.isNotEmpty) {
          final first = routes[0];
          final summary = first['summary'] as Map<String, dynamic>;
          final double distanceMeters = summary['distance']?.toDouble() ?? 0.0;
          final double durationSeconds = summary['duration']?.toDouble() ?? 0.0;

          return MapRoute(
            polyline: [start, end],
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
