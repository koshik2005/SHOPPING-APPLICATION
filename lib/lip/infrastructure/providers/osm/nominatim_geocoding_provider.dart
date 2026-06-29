import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../domain/geocoding_provider.dart';
import '../../../lip_config.dart';
import '../../../lip_di.dart';

class NominatimGeocodingProvider implements GeocodingProvider {
  final Ref _ref;

  NominatimGeocodingProvider(this._ref);

  @override
  Future<String> reverseGeocode(double lat, double lng) async {
    final cacheManager = _ref.read(offlineCacheManagerProvider);
    final cacheKey = 'rev_${lat}_${lng}';
    final cached = await cacheManager.getCachedAddress(cacheKey);
    if (cached != null) return cached;

    final cfg = _ref.read(lipConfigProvider);
    final url = '${cfg.nominatimUrl}/reverse?lat=$lat&lon=$lng&format=json';

    try {
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'HyperLocalEnterpriseClient'
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final displayName = data['display_name'] as String? ?? 'Unknown Location';
        await cacheManager.cacheAddress(cacheKey, displayName);
        return displayName;
      }
    } catch (_) {}

    return 'Coordinates: $lat, $lng';
  }

  @override
  Future<LatLng?> geocode(String address) async {
    final cacheManager = _ref.read(offlineCacheManagerProvider);
    final cacheKey = 'geo_$address';
    final cached = await cacheManager.getCachedAddress(cacheKey);
    if (cached != null) {
      final parts = cached.split(',');
      if (parts.length == 2) {
        return LatLng(double.parse(parts[0]), double.parse(parts[1]));
      }
    }

    final cfg = _ref.read(lipConfigProvider);
    final url = '${cfg.nominatimUrl}/search?q=${Uri.encodeComponent(address)}&format=json&limit=1';

    try {
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'HyperLocalEnterpriseClient'
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final first = data[0];
          final lat = double.parse(first['lat']);
          final lon = double.parse(first['lon']);
          await cacheManager.cacheAddress(cacheKey, '$lat,$lon');
          return LatLng(lat, lon);
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<List<String>> getSuggestions(String query) async {
    final cfg = _ref.read(lipConfigProvider);
    final url = '${cfg.nominatimUrl}/search?q=${Uri.encodeComponent(query)}&format=json&limit=5';

    try {
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'HyperLocalEnterpriseClient'
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List<dynamic>;
        return data.map((item) => item['display_name'] as String).toList();
      }
    } catch (_) {}

    return [];
  }
}
