import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String state;
  final String country;
  final String name;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'name': name,
    };
  }
}

class LocationSelector extends StatefulWidget {
  final Function(LocationData) onLocationSelected;
  final LocationData? initialLocation;

  const LocationSelector({
    Key? key,
    required this.onLocationSelected,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  final TextEditingController _searchController = TextEditingController();
  LocationData? _selectedLocation;
  bool _isLoading = false;
  List<LocationData> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  static String extractFromAddress(String address, int indexFromEnd) {
    final parts = address.split(',').map((s) => s.trim()).toList();
    if (parts.length >= indexFromEnd) {
      return parts[parts.length - indexFromEnd];
    }
    return '';
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = _formatAddress(placemark);
        final city = placemark.locality?.isNotEmpty == true
            ? placemark.locality!
            : extractFromAddress(address, 3);
        final state = placemark.administrativeArea?.isNotEmpty == true
            ? placemark.administrativeArea!
            : extractFromAddress(address, 2);
        final country = placemark.country?.isNotEmpty == true
            ? placemark.country!
            : extractFromAddress(address, 1);
        final name = [
          placemark.street,
          placemark.subLocality
        ].where((part) => part != null && part.isNotEmpty).join(', ');
        final location = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
          city: city,
          state: state,
          country: country,
          name: name,
        );
        setState(() => _selectedLocation = location);
        widget.onLocationSelected(location);
      }
    } catch (e) {
      _showError('Failed to get current location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatAddress(Placemark placemark) {
    final parts = [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.country,
    ].where((part) => part != null && part.isNotEmpty);
    return parts.join(', ');
  }

  Future<void> _searchLocations(String query) async {
    if (query.length < 3) return;
    setState(() => _isLoading = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      List<LocationData> results = [];
      for (Location location in locations.take(5)) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final address = _formatAddress(placemark);
          final city = placemark.locality?.isNotEmpty == true
              ? placemark.locality!
              : extractFromAddress(address, 3);
          final state = placemark.administrativeArea?.isNotEmpty == true
              ? placemark.administrativeArea!
              : extractFromAddress(address, 2);
          final country = placemark.country?.isNotEmpty == true
              ? placemark.country!
              : extractFromAddress(address, 1);
          final name = [
            placemark.street,
            placemark.subLocality
          ].where((part) => part != null && part.isNotEmpty).join(', ');
          results.add(LocationData(
            latitude: location.latitude,
            longitude: location.longitude,
            address: address,
            city: city,
            state: state,
            country: country,
            name: name,
          ));
        }
      }
      setState(() => _searchResults = results);
    } catch (e) {
      _showError('Failed to search locations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _pickOnMap() async {
    final picked = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: _selectedLocation,
        ),
      ),
    );
    if (picked != null) {
      setState(() => _selectedLocation = picked);
      widget.onLocationSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Location',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _getCurrentLocation,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: const Text('Use Current Location'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickOnMap,
          icon: const Icon(Icons.map),
          label: const Text('Pick on Map'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search for a location',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              _searchLocations(value);
            } else {
              setState(() => _searchResults = []);
            }
          },
        ),
        const SizedBox(height: 16),
        if (_searchResults.isNotEmpty) ...[
          Text(
            'Search Results',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ..._searchResults.map((location) => ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(location.name),
                subtitle: Text(location.address),
                onTap: () {
                  setState(() {
                    _selectedLocation = location;
                    _searchResults = [];
                    _searchController.clear();
                  });
                  widget.onLocationSelected(location);
                },
              )),
        ],
        if (_selectedLocation != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Selected Location',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _selectedLocation = null);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_selectedLocation!.address),
                  Text(
                    '${_selectedLocation!.city}, ${_selectedLocation!.state}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class MapLocationPicker extends StatefulWidget {
  final LocationData? initialLocation;
  const MapLocationPicker({Key? key, this.initialLocation}) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _markerPosition;
  bool _loading = false;
  String? _address;

  @override
  void initState() {
    super.initState();
    _markerPosition = widget.initialLocation != null
        ? LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude)
        : LatLng(27.7172, 85.3240); // Default: Kathmandu
    _getAddress();
  }

  Future<void> _getAddress() async {
    setState(() => _loading = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _markerPosition.latitude,
        _markerPosition.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _address = [
            placemark.street,
            placemark.subLocality,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country,
          ].where((part) => part != null && part.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      setState(() => _address = null);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location on Map')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _markerPosition,
                zoom: 15,
                onTap: (tapPosition, point) {
                  setState(() {
                    _markerPosition = point;
                  });
                  _getAddress();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: ['a', 'b', 'c', 'd'],
                  retinaMode: true,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _markerPosition,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (_address != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_address!, textAlign: TextAlign.center),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Select This Location'),
              onPressed: () async {
                List<Placemark> placemarks = await placemarkFromCoordinates(
                  _markerPosition.latitude,
                  _markerPosition.longitude,
                );
                String address = '';
                String city = '';
                String state = '';
                String country = '';
                String name = '';
                if (placemarks.isNotEmpty) {
                  final placemark = placemarks.first;
                  address = [
                    placemark.street,
                    placemark.subLocality,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country,
                  ].where((part) => part != null && part.isNotEmpty).join(', ');
                  city = placemark.locality?.isNotEmpty == true
                      ? placemark.locality!
                      : _LocationSelectorState.extractFromAddress(address, 3);
                  state = placemark.administrativeArea?.isNotEmpty == true
                      ? placemark.administrativeArea!
                      : _LocationSelectorState.extractFromAddress(address, 2);
                  country = placemark.country?.isNotEmpty == true
                      ? placemark.country!
                      : _LocationSelectorState.extractFromAddress(address, 1);
                  name = [
                    placemark.street,
                    placemark.subLocality
                  ].where((part) => part != null && part.isNotEmpty).join(', ');
                }
                Navigator.pop(
                  context,
                  LocationData(
                    latitude: _markerPosition.latitude,
                    longitude: _markerPosition.longitude,
                    address: address,
                    city: city,
                    state: state,
                    country: country,
                    name: name,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 