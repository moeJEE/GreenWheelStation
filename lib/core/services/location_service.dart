import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  Future<LatLng?> getCityLocation(String cityName) async {
    try {
      final locations = await locationFromAddress(cityName);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
      return null;
    } catch (e) {
      print('Error getting city location: $e');
      return null;
    }
  }
}
