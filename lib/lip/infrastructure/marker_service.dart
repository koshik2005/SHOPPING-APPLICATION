import 'package:latlong2/latlong.dart';
import '../domain/map_provider.dart';

class MarkerService {
  final Map<String, MapMarker> _cachedMarkers = {};

  MarkerService();

  void updateMarker(MapMarker marker) {
    _cachedMarkers[marker.id] = marker;
  }

  void removeMarker(String id) {
    _cachedMarkers.remove(id);
  }

  List<MapMarker> getMarkers() {
    return _cachedMarkers.values.toList();
  }

  List<MapMarker> clusterMarkers(List<MapMarker> source, double zoomLevel) {
    if (zoomLevel > 14) return source;
    final Map<String, List<MapMarker>> clusters = {};
    for (final m in source) {
      final gridLat = (m.position.latitude * 10).round() / 10;
      final gridLng = (m.position.longitude * 10).round() / 10;
      final key = '${gridLat}_${gridLng}';
      clusters.putIfAbsent(key, () => []).add(m);
    }

    final List<MapMarker> output = [];
    clusters.forEach((key, list) {
      if (list.length == 1) {
        output.add(list.first);
      } else {
        double sumLat = 0.0;
        double sumLng = 0.0;
        for (final m in list) {
          sumLat += m.position.latitude;
          sumLng += m.position.longitude;
        }
        final avgPos = LatLng(sumLat / list.length, sumLng / list.length);
        output.add(MapMarker(
          id: 'cluster_$key',
          position: avgPos,
          type: MarkerType.branch,
          title: '${list.length} Markers',
          snippet: 'Group of nearby markers',
        ));
      }
    });

    return output;
  }
}
