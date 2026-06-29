import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/tracking_engine.dart';

class TrackingEngineImpl implements TrackingEngine {
  final Ref _ref;
  StreamSubscription<Position>? _sub;

  TrackingEngineImpl(this._ref);

  @override
  void startLiveTracking(String trackId, Function(Position) onUpdate) {
    stopLiveTracking();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      onUpdate(pos);
    });
  }

  @override
  void stopLiveTracking() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  bool isTracking() {
    return _sub != null;
  }

  @override
  double getSpeedMph(Position pos) {
    return pos.speed * 2.23694;
  }

  @override
  double getHeading(Position pos) {
    return pos.heading;
  }
}
