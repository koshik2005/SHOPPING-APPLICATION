import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

abstract class MapProvider {
  Widget buildMapWidget({
    required LatLng initialCenter,
    required double initialZoom,
    required List<LatLng> routePolyline,
    required List<MapMarker> markers,
    required Function(LatLng) onCameraMove,
    Widget? floatingControls,
  });
}

enum MarkerType {
  customer,
  deliveryPartner,
  branch,
  shop,
  warehouse,
  office,
  pickup,
  drop,
  driver,
  admin,
}

class MapMarker {
  final String id;
  final LatLng position;
  final MarkerType type;
  final String title;
  final String? snippet;

  MapMarker({
    required this.id,
    required this.position,
    required this.type,
    required this.title,
    this.snippet,
  });
}
