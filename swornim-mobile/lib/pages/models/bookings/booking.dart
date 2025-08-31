import 'package:swornim/pages/models/bookings/service_package.dart';

class Booking {
  final String id;
  final String clientId;
  final String serviceProviderId;
  final String packageId; // NEW: Links to specific package
  final ServiceType serviceType;
  final DateTime eventDate;
  final String eventTime;
  final String eventLocation;
  final String eventType;
  final double totalAmount;
  final BookingStatus status;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PaymentStatus paymentStatus;
  final ServicePackage? packageSnapshot; // NEW: Stores package details at booking time
  // New: Associated objects from backend (optional)
  final Map<String, dynamic>? client;
  final Map<String, dynamic>? serviceProvider;
  final Map<String, dynamic>? package;

  const Booking({
    required this.id,
    required this.clientId,
    required this.serviceProviderId,
    required this.packageId,
    required this.serviceType,
    required this.eventDate,
    required this.eventTime,
    required this.eventLocation,
    required this.eventType,
    required this.totalAmount,
    required this.status,
    this.specialRequests,
    required this.createdAt,
    required this.updatedAt,
    this.paymentStatus = PaymentStatus.pending,
    this.packageSnapshot,
    this.client,
    this.serviceProvider,
    this.package,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    try {
      return Booking(
        id: json['id']?.toString() ?? '',
        clientId: json['client_id']?.toString() ?? json['clientId']?.toString() ?? '',
        serviceProviderId: json['service_provider_id']?.toString() ?? json['serviceProviderId']?.toString() ?? '',
        packageId: json['package_id']?.toString() ?? json['packageId']?.toString() ?? '',
        serviceType: _parseServiceType(json['service_type'] ?? json['serviceType']),
        eventDate: _parseDateTime(json['event_date'] ?? json['eventDate']),
        eventTime: json['event_time']?.toString() ?? json['eventTime']?.toString() ?? '',
        eventLocation: json['event_location']?.toString() ?? json['eventLocation']?.toString() ?? '',
        eventType: json['event_type']?.toString() ?? json['eventType']?.toString() ?? '',
        totalAmount: _parseDouble(json['total_amount'] ?? json['totalAmount']),
        status: _parseBookingStatus(json['status']),
        specialRequests: json['special_requests']?.toString() ?? json['specialRequests']?.toString(),
        createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
        updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
        paymentStatus: _parsePaymentStatus(json['payment_status'] ?? json['paymentStatus']),
        packageSnapshot: json['package_snapshot'] != null
            ? ServicePackage.fromJson(json['package_snapshot'])
            : null,
        client: json['client'],
        serviceProvider: json['serviceProvider'],
        package: json['package'],
      );
    } catch (e) {
      throw FormatException('Failed to parse Booking from JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'service_provider_id': serviceProviderId,
      'package_id': packageId, // NEW
      'service_type': serviceType.name,
      'event_date': eventDate.toIso8601String(),
      'event_time': eventTime,
      'event_location': eventLocation,
      'event_type': eventType,
      'total_amount': totalAmount,
      'status': status.name,
      'special_requests': specialRequests,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'payment_status': paymentStatus.name,
      'package_snapshot': packageSnapshot?.toJson(), // NEW
    };
  }

  // All your existing helper methods remain the same
  static ServiceType _parseServiceType(dynamic value) {
    if (value == null) return ServiceType.photography;
    try {
      return ServiceType.values.byName(value.toString().toLowerCase());
    } catch (e) {
      return ServiceType.photography;
    }
  }

  static BookingStatus _parseBookingStatus(dynamic value) {
    if (value == null) return BookingStatus.pending_provider_confirmation;
    try {
      return BookingStatus.values.byName(value.toString().toLowerCase());
    } catch (e) {
      return BookingStatus.pending_provider_confirmation;
    }
  }

  static PaymentStatus _parsePaymentStatus(dynamic value) {
    if (value == null) return PaymentStatus.pending;
    try {
      return PaymentStatus.values.byName(value.toString().toLowerCase());
    } catch (e) {
      return PaymentStatus.pending;
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

  // Updated copyWith to include new fields
  Booking copyWith({
    String? id,
    String? clientId,
    String? serviceProviderId,
    String? packageId,
    ServiceType? serviceType,
    DateTime? eventDate,
    String? eventTime,
    String? eventLocation,
    String? eventType,
    double? totalAmount,
    BookingStatus? status,
    String? specialRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
    PaymentStatus? paymentStatus,
    ServicePackage? packageSnapshot,
    Map<String, dynamic>? client,
    Map<String, dynamic>? serviceProvider,
    Map<String, dynamic>? package,
  }) {
    return Booking(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      packageId: packageId ?? this.packageId,
      serviceType: serviceType ?? this.serviceType,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      eventLocation: eventLocation ?? this.eventLocation,
      eventType: eventType ?? this.eventType,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      specialRequests: specialRequests ?? this.specialRequests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      packageSnapshot: packageSnapshot ?? this.packageSnapshot,
      client: client ?? this.client,
      serviceProvider: serviceProvider ?? this.serviceProvider,
      package: package ?? this.package,
    );
  }

  // All your existing utility methods
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Booking &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Booking{id: $id, clientId: $clientId, packageId: $packageId, serviceType: $serviceType, eventDate: $eventDate, status: $status}';
  }

  // All your existing business logic methods
  bool get isActive => status == BookingStatus.confirmed_paid || status == BookingStatus.in_progress;
  bool get isPending => status == BookingStatus.pending_provider_confirmation;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled_by_client || status == BookingStatus.cancelled_by_provider;
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isUpcoming => eventDate.isAfter(DateTime.now()) && !isCancelled;
  bool get isPast => eventDate.isBefore(DateTime.now());
  
  String get formattedAmount => 'Rs. ${totalAmount.toStringAsFixed(2)}';
  String get formattedEventDate => '${eventDate.day}/${eventDate.month}/${eventDate.year}';

  // NEW: Additional methods for package-based bookings
  String get packageName => packageSnapshot?.name ?? 'Unknown Package';
  double get packageBasePrice => packageSnapshot?.basePrice ?? 0.0;
  List<String> get packageFeatures => packageSnapshot?.features ?? [];
  
  bool get hasPriceChanged => packageSnapshot != null && 
      totalAmount != packageSnapshot!.basePrice;
}

// Keep your existing enums - they're perfect
enum ServiceType { 
  photography, 
  makeup, 
  decoration, 
  venue,
  catering,
  music,
  planning,
}

enum BookingStatus { 
  pending_provider_confirmation,
  pending_modification,
  modification_requested,
  confirmed_awaiting_payment,
  confirmed_paid,
  in_progress,
  completed,
  cancelled_by_client,
  cancelled_by_provider,
  rejected,
  refunded,
  dispute_raised,
  dispute_resolved,
}

enum PaymentStatus { 
  pending, 
  paid, 
  refunded, 
  failed,
  partiallyPaid,
}

// NEW: Booking request class for creating bookings
class BookingRequest {
  final String serviceProviderId;
  final String packageId;
  final ServiceType serviceType;
  final DateTime eventDate;
  final String eventTime;
  final String eventLocation;
  final String eventType;
  final double totalAmount;
  final String? specialRequests;

  const BookingRequest({
    required this.serviceProviderId,
    required this.packageId,
    required this.serviceType,
    required this.eventDate,
    required this.eventTime,
    required this.eventLocation,
    required this.eventType,
    required this.totalAmount,
    this.specialRequests,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'serviceProviderId': serviceProviderId,
      'packageId': packageId,
      'serviceType': serviceType.name,
      'eventDate': eventDate.toIso8601String(),
      'eventTime': eventTime,
      'eventLocation': eventLocation,
      'eventType': eventType,
      'totalAmount': totalAmount,
      'specialRequests': specialRequests,
    };
    print('[BookingRequest.toJson] Outgoing booking request: ' + map.toString());
    return map;
  }
}