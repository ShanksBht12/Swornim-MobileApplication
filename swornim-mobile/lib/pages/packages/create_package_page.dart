import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/bookings/service_package.dart';
import 'package:swornim/pages/providers/bookings/bookings.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/models/user/user_types.dart';

class CreatePackagePage extends ConsumerStatefulWidget {
  final User provider;
  final ServicePackage? package;
  const CreatePackagePage({super.key, required this.provider, this.package});

  @override
  ConsumerState<CreatePackagePage> createState() => _CreatePackagePageState();
}

class _CreatePackagePageState extends ConsumerState<CreatePackagePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _durationController;
  late final TextEditingController _featuresController;
  bool _isLoading = false;
  bool get isEdit => widget.package != null;

  @override
  void initState() {
    super.initState();
    final pkg = widget.package;
    _nameController = TextEditingController(text: pkg?.name ?? '');
    _descriptionController = TextEditingController(text: pkg?.description ?? '');
    _basePriceController = TextEditingController(text: pkg?.basePrice.toString() ?? '');
    _durationController = TextEditingController(text: pkg?.durationHours.toString() ?? '');
    _featuresController = TextEditingController(text: pkg?.features.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _durationController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  ServiceType? serviceTypeFromUserType(UserType userType) {
    switch (userType) {
      case UserType.photographer:
        return ServiceType.photography;
      case UserType.makeupArtist:
        return ServiceType.makeup;
      case UserType.decorator:
        return ServiceType.decoration;
      case UserType.venue:
        return ServiceType.venue;
      case UserType.caterer:
        return ServiceType.catering;
      default:
        return null;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final serviceType = serviceTypeFromUserType(widget.provider.userType);

      if (serviceType == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This user type cannot create packages.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      try {
        final basePriceText = _basePriceController.text.trim();
        final durationText = _durationController.text.trim();
        final basePrice = double.tryParse(basePriceText) ?? 0.0;
        final durationHours = int.tryParse(durationText) ?? 0;
        if (isEdit) {
          // Update existing package
          final updates = {
            'name': _nameController.text,
            'description': _descriptionController.text,
            'basePrice': basePrice,
            'durationHours': durationHours,
            'features': _featuresController.text.split(',').map((e) => e.trim()).toList(),
            'isActive': true,
          };
          await ref.read(packageManagerProvider).updatePackage(widget.package!.id, updates);
          ref.invalidate(packagesProvider(widget.provider.id));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Package updated successfully!')),
            );
            Navigator.of(context).pop();
          }
        } else {
          // Create new package
          final newPackage = ServicePackage(
            id: '', // The backend will generate this
            serviceProviderId: widget.provider.id,
            serviceType: serviceType,
            name: _nameController.text,
            description: _descriptionController.text,
            basePrice: basePrice,
            durationHours: durationHours,
            features: _featuresController.text.split(',').map((e) => e.trim()).toList(),
            isActive: true,
            createdAt: DateTime.now(), // Dummy value, server will set this
            updatedAt: DateTime.now(), // Dummy value, server will set this
          );
          await ref.read(packageManagerProvider).createPackage(newPackage);
          ref.invalidate(packagesProvider(widget.provider.id));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Package created successfully!')),
            );
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to ${isEdit ? 'update' : 'create'} package: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Package' : 'Create New Package'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Package Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _basePriceController,
                decoration: const InputDecoration(labelText: 'Base Price (\$)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter a price';
                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) return 'Enter a valid positive price';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (Hours)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter a duration';
                  final duration = int.tryParse(value.trim());
                  if (duration == null || duration <= 0) return 'Enter a valid positive duration';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _featuresController,
                decoration: const InputDecoration(
                  labelText: 'Features (comma-separated)',
                  hintText: 'e.g., 100 photos, 2-day delivery, online gallery',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(isEdit ? 'Update Package' : 'Create Package'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 