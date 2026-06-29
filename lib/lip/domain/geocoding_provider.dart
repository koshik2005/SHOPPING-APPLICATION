import 'package:latlong2/latlong.dart';

abstract class GeocodingProvider {
  Future<String> reverseGeocode(double lat, double lng);
  Future<LatLng?> geocode(String address);
  Future<List<String>> getSuggestions(String query);
}
