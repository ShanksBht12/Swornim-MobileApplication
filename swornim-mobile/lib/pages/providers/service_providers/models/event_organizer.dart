// File: lib/pages/providers/service_providers/models/event_organizer.dart - FIXED TO FOLLOW STRUCTURE
import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/models/location.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_factory.dart';

class EventOrganizer extends ServiceProvider with DateTimeParsingMixin {
  final List<String> eventTypes; // ['concert', 'wedding', 'corporate', 'conference']
  final List<String> services; // ['full_planning', 'day_coordination', 'vendor_management']
  final double packageStartingPrice;
  final double hourlyConsultationRate;
  final int experienceYears;
  final List<String> portfolio; // Portfolio images
  final List<String> availableDates;
  final String? contactEmail;
  final String? contactPhone;
  final bool offersVendorCoordination;
  final bool offersVenueBooking;
  final bool offersFullPlanning;

  const EventOrganizer({
    required super.id,
    required super.userId,
    required super.businessName,
    required super.image,
    required super.description,
    super.rating,
    super.totalReviews,
    super.isAvailable,
    super.reviews,
    super.location,
    required super.createdAt,
    required super.updatedAt,
    this.eventTypes = const [],
    this.services = const [],
    required this.packageStartingPrice,
    required this.hourlyConsultationRate,
    this.experienceYears = 0,
    this.portfolio = const [],
    this.availableDates = const [],
    this.contactEmail,
    this.contactPhone,
    this.offersVendorCoordination = true,
    this.offersVenueBooking = false,
    this.offersFullPlanning = true,
  });

  @override
  Map<String, dynamic> toJson() {
    final baseJson = toBaseJson();
    baseJson.addAll({
      'type': 'event_organizer',
      'event_types': eventTypes,
      'services': services,
      'package_starting_price': packageStartingPrice,
      'hourly_consultation_rate': hourlyConsultationRate,
      'experience_years': experienceYears,
      'portfolio': portfolio,
      'available_dates': availableDates,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'offers_vendor_coordination': offersVendorCoordination,
      'offers_venue_booking': offersVenueBooking,
      'offers_full_planning': offersFullPlanning,
    });
    return baseJson;
  }

  factory EventOrganizer.fromJson(Map<String, dynamic> json) {
    return EventOrganizer(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      isAvailable: json['is_available'] ?? true,
      reviews: (json['reviews'] as List<dynamic>?)?.map((r) => Review.fromJson(r)).toList() ?? [],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      createdAt: DateTimeParsingMixin.parseDateTime(json['created_at']),
      updatedAt: DateTimeParsingMixin.parseDateTime(json['updated_at']),
      eventTypes: List<String>.from(json['event_types'] ?? []),
      services: List<String>.from(json['services'] ?? []),
      packageStartingPrice: (json['package_starting_price'] ?? 0.0).toDouble(),
      hourlyConsultationRate: (json['hourly_consultation_rate'] ?? 0.0).toDouble(),
      experienceYears: json['experience_years'] ?? 0,
      portfolio: List<String>.from(json['portfolio'] ?? []),
      availableDates: List<String>.from(json['available_dates'] ?? []),
      contactEmail: json['contact_email']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      offersVendorCoordination: json['offers_vendor_coordination'] ?? true,
      offersVenueBooking: json['offers_venue_booking'] ?? false,
      offersFullPlanning: json['offers_full_planning'] ?? true,
    );
  }

  @override
  EventOrganizer copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? image,
    String? description,
    double? rating,
    int? totalReviews,
    bool? isAvailable,
    List<Review>? reviews,
    Location? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? eventTypes,
    List<String>? services,
    double? packageStartingPrice,
    double? hourlyConsultationRate,
    int? experienceYears,
    List<String>? portfolio,
    List<String>? availableDates,
    String? contactEmail,
    String? contactPhone,
    bool? offersVendorCoordination,
    bool? offersVenueBooking,
    bool? offersFullPlanning,
  }) {
    return EventOrganizer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      image: image ?? this.image,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isAvailable: isAvailable ?? this.isAvailable,
      reviews: reviews ?? this.reviews,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      eventTypes: eventTypes ?? this.eventTypes,
      services: services ?? this.services,
      packageStartingPrice: packageStartingPrice ?? this.packageStartingPrice,
      hourlyConsultationRate: hourlyConsultationRate ?? this.hourlyConsultationRate,
      experienceYears: experienceYears ?? this.experienceYears,
      portfolio: portfolio ?? this.portfolio,
      availableDates: availableDates ?? this.availableDates,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      offersVendorCoordination: offersVendorCoordination ?? this.offersVendorCoordination,
      offersVenueBooking: offersVenueBooking ?? this.offersVenueBooking,
      offersFullPlanning: offersFullPlanning ?? this.offersFullPlanning,
    );
  }

  // Helper methods for event organizers
  String get displayEventTypes {
    if (eventTypes.isEmpty) return 'All Events';
    return eventTypes.take(3).join(', ') + (eventTypes.length > 3 ? '...' : '');
  }

  String get displayServices {
    if (services.isEmpty) return 'Event Planning';
    return services.take(2).join(', ') + (services.length > 2 ? '...' : '');
  }

  bool get hasExperience => experienceYears > 0;

  String get experienceText {
    if (experienceYears == 0) return 'New Organizer';
    if (experienceYears == 1) return '1 Year Experience';
    return '$experienceYears Years Experience';
  }

  bool get hasPortfolio => portfolio.isNotEmpty;

  bool get hasContactInfo => contactEmail != null || contactPhone != null;

  String get ratingText {
    if (totalReviews == 0) return 'No reviews yet';
    return '${rating.toStringAsFixed(1)} (${totalReviews} reviews)';
  }

  String get priceRangeText {
    if (packageStartingPrice > 0 && hourlyConsultationRate > 0) {
      return 'Rs. ${packageStartingPrice.toStringAsFixed(0)} - Rs. ${hourlyConsultationRate.toStringAsFixed(0)}/hr';
    } else if (packageStartingPrice > 0) {
      return 'From Rs. ${packageStartingPrice.toStringAsFixed(0)}';
    } else if (hourlyConsultationRate > 0) {
      return 'Rs. ${hourlyConsultationRate.toStringAsFixed(0)}/hr';
    }
    return 'Contact for pricing';
  }

  List<String> get serviceCapabilities {
    List<String> capabilities = [];
    if (offersFullPlanning) capabilities.add('Full Event Planning');
    if (offersVendorCoordination) capabilities.add('Vendor Coordination');
    if (offersVenueBooking) capabilities.add('Venue Booking');
    return capabilities;
  }
}