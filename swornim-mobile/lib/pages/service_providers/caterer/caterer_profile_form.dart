import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:swornim/pages/serviceprovider_dashboard/service_provider_dashboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/widgets/common/location_selector.dart';
import 'package:geolocator/geolocator.dart';
import 'package:swornim/config/app_config.dart';

class CatererProfileForm extends ConsumerStatefulWidget {
  const CatererProfileForm({super.key});

  @override
  ConsumerState<CatererProfileForm> createState() => _CatererProfileFormState();
}

class _CatererProfileFormState extends ConsumerState<CatererProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pricePerPersonController = TextEditingController();
  final TextEditingController _cuisineTypesController = TextEditingController();
  final TextEditingController _serviceTypesController = TextEditingController();
  final TextEditingController _minGuestsController = TextEditingController();
  final TextEditingController _maxGuestsController = TextEditingController();
  final TextEditingController _dietaryOptionsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _profileImageUrlController = TextEditingController();

  bool _loading = false;
  String? _error;
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
    final url = Uri.parse('${AppConfig.caterersUrl}/profile');
    final cuisineTypes = _cuisineTypesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final serviceTypes = _serviceTypesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final dietaryOptions = _dietaryOptionsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final Map<String, dynamic> bodyMap = {
      "businessName": _businessNameController.text,
      "description": _descriptionController.text,
      "pricePerPerson": double.tryParse(_pricePerPersonController.text) ?? 0,
      "cuisineTypes": cuisineTypes,
      "serviceTypes": serviceTypes,
      "minGuests": int.tryParse(_minGuestsController.text) ?? 10,
      "maxGuests": int.tryParse(_maxGuestsController.text) ?? 500,
      "dietaryOptions": dietaryOptions,
      "experienceYears": int.tryParse(_experienceController.text) ?? 0,
      "location": {
        "name": _locationNameController.text,
        "latitude": double.tryParse(_latitudeController.text) ?? 0,
        "longitude": double.tryParse(_longitudeController.text) ?? 0,
        "address": _addressController.text,
        "city": _cityController.text,
        "state": _stateController.text,
        "country": _countryController.text,
      }
    };
    if (_profileImageUrlController.text.isNotEmpty) {
      bodyMap["image"] = _profileImageUrlController.text;
    }
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
            const SnackBar(content: Text('Profile created successfully!')),
          );
          final currentUser = ref.read(authProvider).user;
          if (currentUser != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ServiceProviderDashboard(provider: currentUser)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Could not get current user.')),
            );
          }
        }
      } else {
        setState(() {
          _error = 'Failed to create profile: ' + response.body;
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
      appBar: AppBar(title: const Text('Create Caterer Profile')),
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
                controller: _pricePerPersonController,
                decoration: const InputDecoration(labelText: 'Price Per Person'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _cuisineTypesController,
                decoration: const InputDecoration(labelText: 'Cuisine Types (comma separated)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _serviceTypesController,
                decoration: const InputDecoration(labelText: 'Service Types (comma separated)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _minGuestsController,
                decoration: const InputDecoration(labelText: 'Minimum Guests'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _maxGuestsController,
                decoration: const InputDecoration(labelText: 'Maximum Guests'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _dietaryOptionsController,
                decoration: const InputDecoration(labelText: 'Dietary Options (comma separated)'),
              ),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: 'Experience Years'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
              LocationSelector(
                onLocationSelected: (location) {
                  _selectedLocation = location;
                  _locationNameController.text = location.name;
                  _addressController.text = location.address;
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
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
                TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _loading ? null : _submitForm,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
