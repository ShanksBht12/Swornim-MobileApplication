import 'package:swornim/pages/models/bookings/booking.dart';

class ServicePackage {
  final String id;
  final String serviceProviderId;
  final ServiceType serviceType;
  final String name;
  final String description;
  final double basePrice;
  final int durationHours;
  final List<String> features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServicePackage({
    required this.id,
    required this.serviceProviderId,
    required this.serviceType,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.durationHours,
    this.features = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    return ServicePackage(
      id: json['id']?.toString() ?? '',
      serviceProviderId: json['service_provider_id']?.toString() ?? json['serviceProviderId']?.toString() ?? '',
      serviceType: _parseServiceType(json['service_type'] ?? json['serviceType']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      basePrice: _parseDouble(json['base_price'] ?? json['basePrice']),
      durationHours: json['duration_hours'] ?? json['durationHours'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson({bool forCreation = false}) {
    final map = {
      'serviceProviderId': serviceProviderId,
      'serviceType': serviceType.name,
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'durationHours': durationHours,
      'features': features,
      'isActive': isActive,
    };
    if (!forCreation) {
      map['createdAt'] = createdAt.toIso8601String();
      map['updatedAt'] = updatedAt.toIso8601String();
    }
    return map;
  }

  // Method specifically for update operations - excludes fields that shouldn't be changed
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'durationHours': durationHours,
      'features': features,
      'isActive': isActive,
    };
  }

  // Helper methods (reuse from your Booking class)
  static ServiceType _parseServiceType(dynamic value) {
    if (value == null) return ServiceType.photography;
    try {
      return ServiceType.values.byName(value.toString().toLowerCase());
    } catch (e) {
      return ServiceType.photography;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.parse(value);
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  String get formattedPrice => 'Rs. ${basePrice.toStringAsFixed(2)}';
}