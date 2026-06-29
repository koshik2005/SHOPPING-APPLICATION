import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../domain/cache_manager.dart';
import '../../../domain/map_provider.dart' as lip;
import '../../../lip_di.dart';

class OsmMapProvider implements lip.MapProvider {
  final Ref _ref;

  OsmMapProvider(this._ref);

  @override
  Widget buildMapWidget({
    required LatLng initialCenter,
    required double initialZoom,
    required List<LatLng> routePolyline,
    required List<lip.MapMarker> markers,
    required Function(LatLng) onCameraMove,
    Widget? floatingControls,
  }) {
    final cacheManager = _ref.read(offlineCacheManagerProvider);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            onPositionChanged: (position, hasGesture) {
              if (position.center != null) {
                onCameraMove(position.center!);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hyperlocal.enterprise',
              tileProvider: CachedTileProvider(cacheManager),
            ),
            if (routePolyline.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePolyline,
                    color: const Color(0xFFFF6D00),
                    strokeWidth: 4.5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: markers.map((m) {
                return Marker(
                  point: m.position,
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () {},
                    child: _buildMarkerIcon(m.type, m.title),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        if (floatingControls != null)
          Positioned(
            bottom: 24,
            right: 16,
            child: floatingControls,
          ),
      ],
    );
  }

  Widget _buildMarkerIcon(lip.MarkerType type, String title) {
    IconData icon;
    Color color;

    switch (type) {
      case lip.MarkerType.branch:
        icon = Icons.storefront;
        color = const Color(0xFF006D5B);
        break;
      case lip.MarkerType.shop:
        icon = Icons.shopping_bag;
        color = const Color(0xFFFF6D00);
        break;
      case lip.MarkerType.deliveryPartner:
      case lip.MarkerType.driver:
        icon = Icons.local_shipping;
        color = const Color(0xFF0061A4);
        break;
      case lip.MarkerType.customer:
        icon = Icons.person_pin_circle;
        color = const Color(0xFFBA1A1A);
        break;
      case lip.MarkerType.warehouse:
        icon = Icons.warehouse;
        color = const Color(0xFF5A4338);
        break;
      default:
        icon = Icons.location_on;
        color = const Color(0xFF52443C);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(icon, size: 28, color: color),
      ],
    );
  }
}

class CachedTileProvider extends TileProvider {
  final OfflineCacheManager cacheManager;

  CachedTileProvider(this.cacheManager);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CachedTileImageProvider(url, cacheManager);
  }
}

class CachedTileImageProvider extends ImageProvider<CachedTileImageProvider> {
  final String url;
  final OfflineCacheManager cacheManager;

  CachedTileImageProvider(this.url, this.cacheManager);

  @override
  Future<CachedTileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CachedTileImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(CachedTileImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<CachedTileImageProvider>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(CachedTileImageProvider key, ImageDecoderCallback decode) async {
    try {
      final cachedBytes = await cacheManager.getCachedTile(url);
      if (cachedBytes != null && cachedBytes.isNotEmpty) {
        final buffer = await ui.ImmutableBuffer.fromUint8List(Uint8List.fromList(cachedBytes));
        return decode(buffer);
      }
    } catch (_) {}

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await cacheManager.cacheTile(url, bytes);
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      }
    } catch (_) {}

    // Fallback transparent 1x1 image
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0D, 0x49, 0x44, 0x41, 0x54, 0x18, 0x57, 0x63, 0x60, 0x60, 0x60, 0x00,
        0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00, 0x00,
        0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ]),
    );
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is CachedTileImageProvider && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
