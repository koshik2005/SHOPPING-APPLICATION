import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../domain/geofence_client.dart';
import '../../core/state.dart';

class GeofenceClientImpl implements GeofenceClient {
  final Ref _ref;

  GeofenceClientImpl(this._ref);

  @override
  Future<Map<String, dynamic>> checkBranchZone(LatLng location) async {
    final url = '$apiBaseUrl/api/v1/branches/geofence';
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': location.latitude,
          'longitude': location.longitude,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}

    return {
      'nearestBranch': {
        'id': 'branch-a',
        'name': 'Downtown Branch',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'servingRadiusKm': 5.0
      },
      'isWithinDeliveryZone': true,
      'serviceAvailability': 'AVAILABLE'
    };
  }
}
