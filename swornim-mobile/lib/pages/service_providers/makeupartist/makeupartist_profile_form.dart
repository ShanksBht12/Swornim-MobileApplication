import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:swornim/pages/serviceprovider_dashboard/service_provider_dashboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/location.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/widgets/common/location_selector.dart';
import 'package:geolocator/geolocator.dart';
import 'package:swornim/config/app_config.dart';

class MakeupArtistProfileForm extends ConsumerStatefulWidget {
  const MakeupArtistProfileForm({super.key});

  @override
  ConsumerState<MakeupArtistProfileForm> createState() => _MakeupArtistProfileFormState();
}

class _MakeupArtistProfileFormState extends ConsumerState<MakeupArtistProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _sessionRateController = TextEditingController();
  final TextEditingController _bridalPackageRateController = TextEditingController();
  final TextEditingController _brandsController = TextEditingController();
  final TextEditingController _experienceYearsController = TextEditingController();
  final TextEditingController _specializationsController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _profileImageUrlController = TextEditingController();
  final TextEditingController _portfolioImagesController = TextEditingController();
  final TextEditingController _availableDatesController = TextEditingController();

  bool _offersHairServices = false;
  bool _travelsToClient = true;
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
    final url = Uri.parse('${AppConfig.makeupArtistsUrl}/profile');
    final specializations = _specializationsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final brands = _brandsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final portfolioImages = _portfolioImagesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final availableDates = _availableDatesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final Map<String, dynamic> bodyMap = {
      "businessName": _businessNameController.text,
      "description": _descriptionController.text,
      "sessionRate": double.tryParse(_sessionRateController.text) ?? 0,
      "bridalPackageRate": double.tryParse(_bridalPackageRateController.text) ?? 0,
      "brands": brands,
      "experienceYears": int.tryParse(_experienceYearsController.text) ?? 0,
      "specializations": specializations,
      "offersHairServices": _offersHairServices,
      "travelsToClient": _travelsToClient,
      "availableDates": availableDates,
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
      bodyMap["profileImage"] = _profileImageUrlController.text;
    }
    if (portfolioImages.isNotEmpty) {
      bodyMap["portfolioImages"] = portfolioImages;
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
      appBar: AppBar(title: const Text('Create Makeup Artist Profile')),
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
                controller: _sessionRateController,
                decoration: const InputDecoration(labelText: 'Session Rate'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _bridalPackageRateController,
                decoration: const InputDecoration(labelText: 'Bridal Package Rate'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _brandsController,
                decoration: const InputDecoration(labelText: 'Brands (comma separated)'),
              ),
              TextFormField(
                controller: _experienceYearsController,
                decoration: const InputDecoration(labelText: 'Experience Years'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _specializationsController,
                decoration: const InputDecoration(labelText: 'Specializations (comma separated)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SwitchListTile(
                title: const Text('Offers Hair Services'),
                value: _offersHairServices,
                onChanged: (val) => setState(() => _offersHairServices = val),
              ),
              SwitchListTile(
                title: const Text('Travels to Client'),
                value: _travelsToClient,
                onChanged: (val) => setState(() => _travelsToClient = val),
              ),
              TextFormField(
                controller: _availableDatesController,
                decoration: const InputDecoration(labelText: 'Available Dates (comma separated)'),
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
              TextFormField(
                controller: _profileImageUrlController,
                decoration: const InputDecoration(labelText: 'Profile Image URL (optional)'),
              ),
              TextFormField(
                controller: _portfolioImagesController,
                decoration: const InputDecoration(labelText: 'Portfolio Image URLs (comma separated, optional)'),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _loading ? null : _submitForm,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 