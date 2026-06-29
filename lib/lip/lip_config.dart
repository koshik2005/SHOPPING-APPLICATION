import 'package:flutter_riverpod/flutter_riverpod.dart';

class LipConfig {
  final String activeMapProvider;      // 'osm' | 'google' | 'mapbox' | 'here'
  final String activeRouteProvider;    // 'osrm' | 'openrouteservice' | 'google' | 'here'
  final String activeGeocodingProvider;// 'nominatim' | 'google' | 'here'
  final String tileServerUrl;
  final String nominatimUrl;
  final String osrmUrl;
  final String openRouteServiceUrl;
  final String openRouteServiceApiKey;
  final int cacheMaxSizeBytes;
  final int trackingIntervalSeconds;
  final String locationAccuracy;       // 'low' | 'medium' | 'high' | 'best'

  LipConfig({
    required this.activeMapProvider,
    required this.activeRouteProvider,
    required this.activeGeocodingProvider,
    required this.tileServerUrl,
    required this.nominatimUrl,
    required this.osrmUrl,
    required this.openRouteServiceUrl,
    required this.openRouteServiceApiKey,
    required this.cacheMaxSizeBytes,
    required this.trackingIntervalSeconds,
    required this.locationAccuracy,
  });

  factory LipConfig.fromEnvironment() {
    return LipConfig(
      activeMapProvider: const String.fromEnvironment('LIP_MAP_PROVIDER', defaultValue: 'osm'),
      activeRouteProvider: const String.fromEnvironment('LIP_ROUTE_PROVIDER', defaultValue: 'osrm'),
      activeGeocodingProvider: const String.fromEnvironment('LIP_GEOCODING_PROVIDER', defaultValue: 'nominatim'),
      tileServerUrl: const String.fromEnvironment(
        'LIP_TILE_SERVER_URL',
        defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      ),
      nominatimUrl: const String.fromEnvironment(
        'LIP_NOMINATIM_URL',
        defaultValue: 'https://nominatim.openstreetmap.org',
      ),
      osrmUrl: const String.fromEnvironment(
        'LIP_OSRM_URL',
        defaultValue: 'https://router.project-osrm.org',
      ),
      openRouteServiceUrl: const String.fromEnvironment(
        'LIP_OPENROUTESERVICE_URL',
        defaultValue: 'https://api.openrouteservice.org',
      ),
      openRouteServiceApiKey: const String.fromEnvironment(
        'LIP_OPENROUTESERVICE_API_KEY',
        defaultValue: '',
      ),
      cacheMaxSizeBytes: const int.fromEnvironment('LIP_CACHE_MAX_SIZE_BYTES', defaultValue: 50 * 1024 * 1024), // 50MB
      trackingIntervalSeconds: const int.fromEnvironment('LIP_TRACKING_INTERVAL_SECONDS', defaultValue: 5),
      locationAccuracy: const String.fromEnvironment('LIP_LOCATION_ACCURACY', defaultValue: 'high'),
    );
  }
}

final lipConfigProvider = Provider<LipConfig>((ref) {
  return LipConfig.fromEnvironment();
});
