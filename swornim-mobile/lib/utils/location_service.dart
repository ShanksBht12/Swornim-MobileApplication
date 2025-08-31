import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../pages/models/location.dart' as app_location;

class LocationService {
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Future<List<app_location.Location>> searchLocation(String query) async {
    final locations = await locationFromAddress(query);
    return locations.map((loc) => app_location.Location(
      name: query,
      latitude: loc.latitude,
      longitude: loc.longitude,
      address: query,
      city: '',
      state: '',
      country: '',
    )).toList();
  }

  static Future<String> reverseGeocode(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      return "${p.street}, ${p.locality}, ${p.administrativeArea}, ${p.country}";
    }
    return '';
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0; // in km
  }
} 