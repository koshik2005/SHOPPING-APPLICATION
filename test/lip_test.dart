import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shopping/lip/lip_di.dart';
import 'package:shopping/lip/domain/map_provider.dart';

void main() {
  test('LIP Provider Switching Test', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final provider = container.read(mapProvider);
    expect(provider, isNotNull);
  });

  test('LIP Marker Service Clustering Test', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(markerServiceProvider);
    
    service.updateMarker(MapMarker(
      id: 'marker_1',
      position: const LatLng(37.7749, -122.4194),
      type: MarkerType.customer,
      title: 'Customer 1',
    ));
    service.updateMarker(MapMarker(
      id: 'marker_2',
      position: const LatLng(37.7748, -122.4193),
      type: MarkerType.customer,
      title: 'Customer 2',
    ));

    final clustered = service.clusterMarkers(service.getMarkers(), 10.0);
    expect(clustered.length, equals(1));
    expect(clustered.first.id.startsWith('cluster_'), isTrue);
  });
}
