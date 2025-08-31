import 'package:flutter/material.dart';
import 'package:swornim/pages/models/bookings/service_package.dart';
import 'package:swornim/pages/models/bookings/booking.dart';

class PackageFormDialog extends StatefulWidget {
  final ServicePackage? initialPackage;
  final void Function(ServicePackage package) onSubmit;
  final bool isEdit;
  final ServiceType? fixedServiceType;
  final String? providerId;

  const PackageFormDialog({
    Key? key,
    this.initialPackage,
    required this.onSubmit,
    this.isEdit = false,
    this.fixedServiceType,
    this.providerId,
  }) : super(key: key);

  @override
  State<PackageFormDialog> createState() => _PackageFormDialogState();
}

class _PackageFormDialogState extends State<PackageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _featuresController;
  ServiceType _serviceType = ServiceType.photography;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final pkg = widget.initialPackage;
    _nameController = TextEditingController(text: pkg?.name ?? '');
    _descriptionController = TextEditingController(text: pkg?.description ?? '');
    _priceController = TextEditingController(text: pkg?.basePrice.toString() ?? '');
    _durationController = TextEditingController(text: pkg?.durationHours.toString() ?? '');
    _featuresController = TextEditingController(text: pkg?.features.join(', ') ?? '');
    _serviceType = widget.fixedServiceType ?? pkg?.serviceType ?? ServiceType.photography;
    _isActive = pkg?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      widget.isEdit ? 'Edit Package' : 'Create Package',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Basic Info', theme, colorScheme, Icons.info_outline),
                const SizedBox(height: 12),
                _buildTextField(_nameController, 'Package Name', Icons.label, validator: (v) => v == null || v.isEmpty ? 'Name required' : null),
                const SizedBox(height: 12),
                _buildTextField(_descriptionController, 'Description', Icons.description, minLines: 1, maxLines: 3),
                const SizedBox(height: 24),
                _buildSectionHeader('Pricing & Duration', theme, colorScheme, Icons.attach_money),
                const SizedBox(height: 12),
                _buildTextField(_priceController, 'Base Price', Icons.monetization_on, keyboardType: TextInputType.number, validator: (v) => v == null || double.tryParse(v) == null ? 'Valid price required' : null),
                const SizedBox(height: 12),
                _buildTextField(_durationController, 'Duration (hours)', Icons.timer, keyboardType: TextInputType.number, validator: (v) => v == null || int.tryParse(v) == null ? 'Valid duration required' : null),
                const SizedBox(height: 24),
                _buildSectionHeader('Features & Type', theme, colorScheme, Icons.star_outline),
                const SizedBox(height: 12),
                _buildTextField(_featuresController, 'Features (comma separated)', Icons.list),
                const SizedBox(height: 12),
                if (widget.fixedServiceType != null)
                  TextFormField(
                    enabled: false,
                    initialValue: _serviceType.name[0].toUpperCase() + _serviceType.name.substring(1),
                    decoration: InputDecoration(
                      labelText: 'Service Type',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  DropdownButtonFormField<ServiceType>(
                    value: _serviceType,
                    items: ServiceType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                    )).toList(),
                    onChanged: (val) => setState(() => _serviceType = val ?? ServiceType.photography),
                    decoration: InputDecoration(
                      labelText: 'Service Type',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                if (widget.isEdit) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader('Status', theme, colorScheme, Icons.toggle_on),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    title: const Text('Active'),
                    contentPadding: EdgeInsets.zero,
                    activeColor: colorScheme.primary,
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final features = _featuresController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          final pkg = ServicePackage(
                            id: widget.initialPackage?.id ?? '',
                            serviceProviderId: widget.providerId ?? widget.initialPackage?.serviceProviderId ?? '',
                            serviceType: _serviceType,
                            name: _nameController.text.trim(),
                            description: _descriptionController.text.trim(),
                            basePrice: double.parse(_priceController.text),
                            durationHours: int.parse(_durationController.text),
                            features: features,
                            isActive: _isActive,
                            createdAt: widget.initialPackage?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          widget.onSubmit(pkg);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        elevation: 2,
                      ),
                      child: Text(widget.isEdit ? 'Update' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme, ColorScheme colorScheme, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int minLines = 1,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
} 