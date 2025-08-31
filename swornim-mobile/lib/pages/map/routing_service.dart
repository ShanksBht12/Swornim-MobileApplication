import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Routing service using OSRM API
class OSMRoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';
  
  // Get route between two points
  static Future<RouteResult?> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'driving', // driving, walking, cycling
  }) async {
    try {
      final url = '$_baseUrl/$profile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&steps=true';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'EventPlannerApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return RouteResult.fromJson(route);
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting route: $e');
      return null;
    }
  }
  
  // Get multiple route options
  static Future<List<RouteResult>> getRouteAlternatives({
    required LatLng start,
    required LatLng end,
    String profile = 'driving',
    int alternatives = 3,
  }) async {
    try {
      final url = '$_baseUrl/$profile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&steps=true&alternatives=$alternatives';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'EventPlannerApp/1.0',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null) {
          return (data['routes'] as List)
              .map((route) => RouteResult.fromJson(route))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error getting route alternatives: $e');
      return [];
    }
  }
}

// Route result model
class RouteResult {
  final List<LatLng> coordinates;
  final double distance; // in meters
  final double duration; // in seconds
  final List<RouteStep> steps;
  final String geometry;
  
  RouteResult({
    required this.coordinates,
    required this.distance,
    required this.duration,
    required this.steps,
    required this.geometry,
  });
  
  factory RouteResult.fromJson(Map<String, dynamic> json) {
    // Parse coordinates from GeoJSON geometry
    List<LatLng> coordinates = [];
    if (json['geometry'] != null && json['geometry']['coordinates'] != null) {
      final coords = json['geometry']['coordinates'] as List;
      coordinates = coords.map((coord) => LatLng(coord[1], coord[0])).toList();
    }
    
    // Parse steps
    List<RouteStep> steps = [];
    if (json['legs'] != null && json['legs'].isNotEmpty) {
      final legs = json['legs'] as List;
      for (final leg in legs) {
        if (leg['steps'] != null) {
          final legSteps = leg['steps'] as List;
          steps.addAll(legSteps.map((step) => RouteStep.fromJson(step)));
        }
      }
    }
    
    return RouteResult(
      coordinates: coordinates,
      distance: (json['distance'] ?? 0.0).toDouble(),
      duration: (json['duration'] ?? 0.0).toDouble(),
      steps: steps,
      geometry: json['geometry']?.toString() ?? '',
    );
  }
  
  // Format duration as human readable
  String get formattedDuration {
    final minutes = (duration / 60).round();
    if (minutes < 60) {
      return '${minutes} min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }
  
  // Format distance as human readable
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
}

// Route step model for turn-by-turn navigation
class RouteStep {
  final String instruction;
  final double distance;
  final double duration;
  final String maneuver;
  final LatLng? location;
  
  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
    this.location,
  });
  
  factory RouteStep.fromJson(Map<String, dynamic> json) {
    LatLng? location;
    if (json['maneuver'] != null && json['maneuver']['location'] != null) {
      final coords = json['maneuver']['location'] as List;
      location = LatLng(coords[1], coords[0]);
    }
    
    return RouteStep(
      instruction: json['maneuver']?['instruction'] ?? 'Continue',
      distance: (json['distance'] ?? 0.0).toDouble(),
      duration: (json['duration'] ?? 0.0).toDouble(),
      maneuver: json['maneuver']?['type'] ?? 'straight',
      location: location,
    );
  }
  
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
}

// Alternative routing services (if OSRM is not available)
class AlternativeRoutingService {
  // Using OpenRouteService (requires API key)
  static Future<RouteResult?> getRouteORS({
    required LatLng start,
    required LatLng end,
    String apiKey = 'your_api_key_here',
    String profile = 'driving-car',
  }) async {
    try {
      final url = 'https://api.openrouteservice.org/v2/directions/$profile';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'coordinates': [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude],
          ],
          'format': 'geojson',
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Parse ORS response (similar to OSRM but different format)
        // Implementation would depend on ORS API response format
      }
      
      return null;
    } catch (e) {
      print('Error getting ORS route: $e');
      return null;
    }
  }
  
  // Using MapBox (requires API key)
  static Future<RouteResult?> getRouteMapbox({
    required LatLng start,
    required LatLng end,
    String accessToken = 'your_mapbox_token_here',
    String profile = 'driving',
  }) async {
    try {
      final url = 'https://api.mapbox.com/directions/v5/mapbox/$profile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&access_token=$accessToken';
      
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Parse Mapbox response
        // Implementation would depend on Mapbox API response format
      }
      
      return null;
    } catch (e) {
      print('Error getting Mapbox route: $e');
      return null;
    }
  }
} 