import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/map_provider.dart';
import 'domain/route_provider.dart';
import 'domain/geocoding_provider.dart';
import 'domain/location_repo.dart';
import 'domain/tracking_engine.dart';
import 'domain/eta_engine.dart';
import 'domain/geofence_client.dart';
import 'domain/cache_manager.dart';

import 'infrastructure/location_repo_impl.dart';
import 'infrastructure/permission_manager.dart';
import 'infrastructure/offline_cache_manager.dart';
import 'infrastructure/tracking_engine_impl.dart';
import 'infrastructure/eta_engine_impl.dart';
import 'infrastructure/geofence_client_impl.dart';
import 'infrastructure/marker_service.dart';

import 'infrastructure/providers/osm/osm_map_provider.dart';
import 'infrastructure/providers/osm/osrm_route_provider.dart';
import 'infrastructure/providers/osm/openroute_route_provider.dart';
import 'infrastructure/providers/osm/nominatim_geocoding_provider.dart';

import 'lip_config.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(ref);
});

final permissionManagerProvider = Provider<PermissionManager>((ref) {
  return PermissionManager(ref);
});

final offlineCacheManagerProvider = Provider<OfflineCacheManager>((ref) {
  return OfflineCacheManagerImpl();
});

final mapProvider = Provider<MapProvider>((ref) {
  final cfg = ref.watch(lipConfigProvider);
  if (cfg.activeMapProvider == 'osm') {
    return OsmMapProvider(ref);
  }
  throw UnimplementedError('MapProvider ${cfg.activeMapProvider} not implemented yet');
});

final routeProvider = Provider<RouteProvider>((ref) {
  final cfg = ref.watch(lipConfigProvider);
  if (cfg.activeRouteProvider == 'osrm') {
    return OsrmRouteProvider(ref);
  } else if (cfg.activeRouteProvider == 'openrouteservice') {
    return OpenRouteRouteProvider(ref);
  }
  throw UnimplementedError('RouteProvider ${cfg.activeRouteProvider} not implemented yet');
});

final geocodingProvider = Provider<GeocodingProvider>((ref) {
  final cfg = ref.watch(lipConfigProvider);
  if (cfg.activeGeocodingProvider == 'nominatim') {
    return NominatimGeocodingProvider(ref);
  }
  throw UnimplementedError('GeocodingProvider ${cfg.activeGeocodingProvider} not implemented yet');
});

final trackingEngineProvider = Provider<TrackingEngine>((ref) {
  return TrackingEngineImpl(ref);
});

final etaEngineProvider = Provider<EtaEngine>((ref) {
  return EtaEngineImpl(ref);
});

final geofenceClientProvider = Provider<GeofenceClient>((ref) {
  return GeofenceClientImpl(ref);
});

final markerServiceProvider = Provider<MarkerService>((ref) {
  return MarkerService();
});
