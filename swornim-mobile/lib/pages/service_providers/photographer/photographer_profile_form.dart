import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:swornim/pages/serviceprovider_dashboard/service_provider_dashboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/widgets/common/location_selector.dart';
import 'package:swornim/pages/widgets/common/simple_image_picker.dart';
import 'package:swornim/pages/widgets/common/simple_portfolio_gallery.dart';
import 'package:geolocator/geolocator.dart';
import 'package:swornim/config/app_config.dart';

class PhotographerProfileForm extends ConsumerStatefulWidget {
  const PhotographerProfileForm({super.key});

  @override
  ConsumerState<PhotographerProfileForm> createState() => _PhotographerProfileFormState();
}

class _PhotographerProfileFormState extends ConsumerState<PhotographerProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
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

  bool _loading = false;
  String? _error;
  LocationData? _selectedLocation;
  String? _profileImageUrl;
  List<String> _portfolioImages = [];

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
    final url = Uri.parse('${AppConfig.photographersUrl}/profile');
    final specializations = _specializationsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final Map<String, dynamic> bodyMap = {
      "businessName": _businessNameController.text,
      "description": _descriptionController.text,
      "hourlyRate": double.tryParse(_hourlyRateController.text) ?? 0,
      "experience": _experienceController.text,
      "specializations": specializations,
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
    if (_portfolioImagesController.text.isNotEmpty) {
      bodyMap["portfolioImages"] = _portfolioImagesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
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
      appBar: AppBar(title: const Text('Create Photographer Profile')),
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
                controller: _hourlyRateController,
                decoration: const InputDecoration(labelText: 'Hourly Rate'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: 'Experience'),
              ),
              TextFormField(
                controller: _specializationsController,
                decoration: const InputDecoration(labelText: 'Specializations (comma separated)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
              const SizedBox(height: 16),
              
              // Profile Image Picker
              Center(
                child: SimpleProfileImagePicker(
                  currentImageUrl: _profileImageUrl,
                  serviceProviderType: 'photographers',
                  onImageSelected: (file) {
                    // Handle selected file
                  },
                  onImageUploaded: (url) {
                    setState(() {
                      _profileImageUrl = url;
                    });
                  },
                  onImageRemoved: () {
                    setState(() {
                      _profileImageUrl = null;
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Portfolio Gallery
              SimplePortfolioGallery(
                images: _portfolioImages,
                serviceProviderType: 'photographers',
                isEditable: true,
                onImageAdded: (url) {
                  setState(() {
                    _portfolioImages.add(url);
                  });
                },
                onImageRemoved: (url) {
                  setState(() {
                    _portfolioImages.remove(url);
                  });
                },
              ),
              
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