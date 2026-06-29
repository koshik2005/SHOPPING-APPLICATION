import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../domain/eta_engine.dart';
import '../lip_di.dart';

class EtaEngineImpl implements EtaEngine {
  final Ref _ref;

  EtaEngineImpl(this._ref);

  @override
  Future<EtaResult> calculateEta(LatLng current, LatLng destination, {double trafficFactor = 1.0}) async {
    try {
      final route = await _ref.read(routeProvider).calculateRoute(current, destination);
      final double duration = route.durationMinutes * trafficFactor;
      return EtaResult(
        distanceMiles: route.distanceMiles,
        durationMinutes: duration,
        expectedArrivalTime: DateTime.now().add(Duration(seconds: (duration * 60).round())),
      );
    } catch (_) {}

    final dist = const Distance().as(LengthUnit.Mile, current, destination);
    final dur = dist * 3.0 * trafficFactor;
    return EtaResult(
      distanceMiles: dist,
      durationMinutes: dur,
      expectedArrivalTime: DateTime.now().add(Duration(seconds: (dur * 60).round())),
    );
  }
}
