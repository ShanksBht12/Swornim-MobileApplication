import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';

import '../utils/location_service.dart';

class ProviderInfoPopup extends StatelessWidget {
  final ServiceProvider provider;
  final LatLng? userLocation;
  const ProviderInfoPopup({required this.provider, this.userLocation, Key? key}) : super(key: key);

  String _getProviderType() {
    final type = provider.runtimeType.toString().toLowerCase();
    if (type.contains('photographer')) return 'Photographer';
    if (type.contains('venue')) return 'Venue';
    if (type.contains('caterer')) return 'Caterer';
    if (type.contains('decorator')) return 'Decorator';
    if (type.contains('makeup')) return 'Makeup Artist';
    if (type.contains('event')) return 'Event Organizer';
    return 'Service Provider';
  }

  @override
  Widget build(BuildContext context) {
    final loc = provider.location;
    final distance = (userLocation != null && loc != null)
        ? LocationService.calculateDistance(
            userLocation!.latitude, userLocation!.longitude,
            loc.latitude, loc.longitude)
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.businessName, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_getProviderType()),
            if (loc != null) Text('${loc.address}, ${loc.city}'),
            if (distance != null) Text('Distance: ${distance.toStringAsFixed(2)} km'),
          ],
        ),
      ),
    );
  }
} 