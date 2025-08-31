import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/widgets/common/location_selector.dart';
import 'package:geolocator/geolocator.dart';
import 'package:swornim/config/app_config.dart';

class VenueProfileForm extends ConsumerStatefulWidget {
  const VenueProfileForm({super.key});

  @override
  ConsumerState<VenueProfileForm> createState() => _VenueProfileFormState();
}

class _VenueProfileFormState extends ConsumerState<VenueProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _pricePerHourController = TextEditingController();
  final TextEditingController _amenitiesController = TextEditingController();
  final TextEditingController _imagesController = TextEditingController();
  final TextEditingController _venueTypeController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _locAddressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  bool _loading = false;
  String? _error;

  final List<String> _venueTypeOptions = ['wedding', 'conference', 'party', 'exhibition', 'other'];
  List<String> _selectedVenueTypes = [];
  LocationData? _selectedLocation;

  Future<String> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = await getAccessToken();
    final url = Uri.parse('${AppConfig.venuesUrl}/profile');
    final amenities = _amenitiesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final images = _imagesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final Map<String, dynamic> bodyMap = {
      "businessName": _businessNameController.text,
      "description": _descriptionController.text,
      "capacity": int.tryParse(_capacityController.text) ?? 0,
      "pricePerHour": double.tryParse(_pricePerHourController.text) ?? 0,
      "amenities": amenities,
      "images": images,
      "venueTypes": _selectedVenueTypes.where((type) => _venueTypeOptions.contains(type)).toList(),
      "location": {
        "name": _locationNameController.text,
        "latitude": double.tryParse(_latitudeController.text) ?? 0,
        "longitude": double.tryParse(_longitudeController.text) ?? 0,
        "address": _locAddressController.text,
        "city": _cityController.text,
        "state": _stateController.text,
        "country": _countryController.text,
      }
    };
    final body = jsonEncode(bodyMap);
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venue profile created successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _error = 'Failed to create venue profile: ' + response.body;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Venue Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: 'Business Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _pricePerHourController,
                decoration: const InputDecoration(labelText: 'Price Per Hour'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _amenitiesController,
                decoration: const InputDecoration(labelText: 'Amenities (comma separated)'),
              ),
              TextFormField(
                controller: _imagesController,
                decoration: const InputDecoration(labelText: 'Images (comma separated URLs)'),
              ),
              const SizedBox(height: 16),
              Text('Venue Types', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._venueTypeOptions.map((type) => CheckboxListTile(
                title: Text(type[0].toUpperCase() + type.substring(1)),
                value: _selectedVenueTypes.contains(type),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      if (!_selectedVenueTypes.contains(type) && _venueTypeOptions.contains(type)) {
                        _selectedVenueTypes.add(type);
                      }
                    } else {
                      _selectedVenueTypes.remove(type);
                    }
                  });
                },
              )),
              const SizedBox(height: 16),
              const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
              LocationSelector(
                onLocationSelected: (location) {
                  _selectedLocation = location;
                  _locationNameController.text = location.name;
                  _locAddressController.text = location.address;
                  _cityController.text = (location.city.isNotEmpty ? location.city : '-');
                  _stateController.text = (location.state.isNotEmpty ? location.state : '-');
                  _countryController.text = (location.country.isNotEmpty ? location.country : '-');
                  _latitudeController.text = location.latitude.toString();
                  _longitudeController.text = location.longitude.toString();
                  setState(() {});
                },
                initialLocation: _selectedLocation,
              ),
              if (_selectedLocation == null) ...[
                TextFormField(
                  controller: _locationNameController,
                  decoration: const InputDecoration(labelText: 'Location Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _locAddressController,
                  decoration: const InputDecoration(labelText: 'Location Address'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _loading ? null : _submitForm,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Create Venue Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 