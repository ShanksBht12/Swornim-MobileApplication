import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/models/location.dart';

class Photographer extends ServiceProvider {
  final List<String> specializations; // ['wedding', 'portrait', 'event', 'commercial']
  final List<String> equipment;
  final double hourlyRate;
  final double eventRate;
  final List<String> portfolio; // Image URLs
  final int experienceYears;
  final bool offersVideoServices;
  final List<String> availableDates;

  const Photographer({
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
    this.specializations = const [],
    this.equipment = const [],
    required this.hourlyRate,
    required this.eventRate,
    this.portfolio = const [],
    this.experienceYears = 0,
    this.offersVideoServices = false,
    this.availableDates = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    final baseJson = toBaseJson();
    baseJson.addAll({
      'type': 'photographer',
      'specializations': specializations,
      'equipment': equipment,
      'hourly_rate': hourlyRate,
      'event_rate': eventRate,
      'portfolio': portfolio,
      'experience_years': experienceYears,
      'offers_video_services': offersVideoServices,
      'available_dates': availableDates,
    });
    return baseJson;
  }

  factory Photographer.fromJson(Map<String, dynamic> json) {
    // Defensive: strip 'search' prefix if present in id
    String rawId = json['id'] ?? '';
    String cleanId = rawId.startsWith('search') && rawId.length > 6
        ? rawId.substring(6)
        : rawId;
    return Photographer(
      id: cleanId,
      userId: json['user_id'],
      businessName: json['business_name'],
      image: json['image'],
      description: json['description'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      isAvailable: json['is_available'] ?? true,
      reviews: (json['reviews'] as List<dynamic>?)?.map((r) => Review.fromJson(r)).toList() ?? [],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      specializations: List<String>.from(json['specializations'] ?? []),
      equipment: List<String>.from(json['equipment'] ?? []),
      hourlyRate: (json['hourly_rate'] ?? 0.0).toDouble(),
      eventRate: (json['event_rate'] ?? 0.0).toDouble(),
      portfolio: List<String>.from(json['portfolio'] ?? []),
      experienceYears: json['experience_years'] ?? 0,
      offersVideoServices: json['offers_video_services'] ?? false,
      availableDates: List<String>.from(json['available_dates'] ?? []),
    );
  }

  @override
  Photographer copyWith({
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
    List<String>? specializations,
    List<String>? equipment,
    double? hourlyRate,
    double? eventRate,
    List<String>? portfolio,
    int? experienceYears,
    bool? offersVideoServices,
    List<String>? availableDates,
  }) {
    return Photographer(
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
      specializations: specializations ?? this.specializations,
      equipment: equipment ?? this.equipment,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      eventRate: eventRate ?? this.eventRate,
      portfolio: portfolio ?? this.portfolio,
      experienceYears: experienceYears ?? this.experienceYears,
      offersVideoServices: offersVideoServices ?? this.offersVideoServices,
      availableDates: availableDates ?? this.availableDates,
    );
  }
}