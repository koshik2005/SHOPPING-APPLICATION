import 'package:geolocator/geolocator.dart';

abstract class TrackingEngine {
  void startLiveTracking(String trackId, Function(Position) onUpdate);
  void stopLiveTracking();
  bool isTracking();
  double getSpeedMph(Position pos);
  double getHeading(Position pos);
}
