import 'package:flutter/material.dart';
import 'package:swornim/pages/models/events/event.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EventFormDialog extends StatefulWidget {
  final Event? initialEvent;
  final void Function(Map<String, dynamic> eventData) onSubmit;
  final bool isEdit;

  const EventFormDialog({
    Key? key,
    this.initialEvent,
    required this.onSubmit,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _expectedGuestsController;
  late TextEditingController _ticketPriceController;
  late TextEditingController _maxCapacityController;
  late TextEditingController _eventTimeController;
  late TextEditingController _eventEndTimeController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  DateTime? _eventDate;
  DateTime? _eventEndDate;
  EventType _eventType = EventType.other;
  bool _isTicketed = false;
  File? _imageFile;
  List<File> _galleryFiles = [];

  @override
  void initState() {
    super.initState();
    final e = widget.initialEvent;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _venueController = TextEditingController(text: e?.venue ?? '');
    _expectedGuestsController = TextEditingController(text: e?.expectedGuests.toString() ?? '');
    _ticketPriceController = TextEditingController(text: e?.ticketPrice?.toString() ?? '');
    _maxCapacityController = TextEditingController(text: e?.maxCapacity?.toString() ?? '');
    _eventTimeController = TextEditingController(text: e?.eventTime ?? '');
    _eventEndTimeController = TextEditingController(text: e?.eventEndTime ?? '');
    _contactEmailController = TextEditingController(text: e?.contactEmail ?? '');
    _contactPhoneController = TextEditingController(text: e?.contactPhone ?? '');
    _eventDate = e?.eventDate;
    _eventEndDate = e?.eventEndDate;
    _eventType = e?.eventType ?? EventType.other;
    _isTicketed = e?.isTicketed ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _expectedGuestsController.dispose();
    _ticketPriceController.dispose();
    _maxCapacityController.dispose();
    _eventTimeController.dispose();
    _eventEndTimeController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _galleryFiles = picked.map((x) => File(x.path)).toList();
      });
    }
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
                    Icon(Icons.event, color: colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      widget.isEdit ? 'Edit Event' : 'Create Event',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(_titleController, 'Event Title', Icons.label, validator: (v) => v == null || v.isEmpty ? 'Title required' : null),
                const SizedBox(height: 12),
                _buildTextField(_descriptionController, 'Description', Icons.description, minLines: 1, maxLines: 3),
                const SizedBox(height: 12),
                DropdownButtonFormField<EventType>(
                  value: _eventType,
                  items: EventType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                  )).toList(),
                  onChanged: (val) => setState(() => _eventType = val ?? EventType.other),
                  decoration: InputDecoration(
                    labelText: 'Event Type',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField('Event Date', _eventDate, (date) => setState(() => _eventDate = date)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateField('End Date', _eventEndDate, (date) => setState(() => _eventEndDate = date)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_eventTimeController, 'Start Time', Icons.access_time)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_eventEndTimeController, 'End Time', Icons.access_time)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(_venueController, 'Venue', Icons.location_on),
                const SizedBox(height: 12),
                _buildTextField(_expectedGuestsController, 'Expected Guests', Icons.people, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField(_ticketPriceController, 'Ticket Price', Icons.monetization_on, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField(_maxCapacityController, 'Max Capacity', Icons.confirmation_number, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isTicketed,
                  onChanged: (val) => setState(() => _isTicketed = val),
                  title: const Text('Is Ticketed Event?'),
                  activeColor: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _buildTextField(_contactEmailController, 'Contact Email', Icons.email),
                const SizedBox(height: 12),
                _buildTextField(_contactPhoneController, 'Contact Phone', Icons.phone),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Main Image'),
                        onPressed: _pickImage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_imageFile != null)
                      Image.file(_imageFile!, width: 56, height: 56, fit: BoxFit.cover),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick Gallery Images'),
                        onPressed: _pickGalleryImages,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_galleryFiles.isNotEmpty)
                      Text('${_galleryFiles.length} selected'),
                  ],
                ),
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
                          final eventData = <String, dynamic>{
                            'title': _titleController.text.trim(),
                            'description': _descriptionController.text.trim(),
                            'eventType': _eventType.name,
                            'eventDate': _eventDate?.toIso8601String(),
                            'eventEndDate': _eventEndDate?.toIso8601String(),
                            'eventTime': _eventTimeController.text.trim(),
                            'eventEndTime': _eventEndTimeController.text.trim(),
                            'venue': _venueController.text.trim(),
                            'expectedGuests': int.tryParse(_expectedGuestsController.text) ?? 0,
                            'ticketPrice': double.tryParse(_ticketPriceController.text),
                            'maxCapacity': int.tryParse(_maxCapacityController.text),
                            'isTicketed': _isTicketed,
                            'contactEmail': _contactEmailController.text.trim(),
                            'contactPhone': _contactPhoneController.text.trim(),
                            'imageFile': _imageFile,
                            'galleryFiles': _galleryFiles,
                          };
                          widget.onSubmit(eventData);
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int minLines = 1, int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
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

  Widget _buildDateField(String label, DateTime? value, void Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(value != null ? value.toLocal().toString().split(' ')[0] : 'Select date'),
      ),
    );
  }
} 