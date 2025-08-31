import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/models/location.dart';

class MakeupArtist extends ServiceProvider {
  final List<String> specializations; // ['bridal', 'party', 'editorial', 'sfx']
  final List<String> brands; // Makeup brands they use
  final double sessionRate;
  final double bridalPackageRate;
  final List<String> portfolio;
  final int experienceYears;
  final bool offersHairServices;
  final bool travelsToClient;
  final List<String> availableDates;

  const MakeupArtist({
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
    this.brands = const [],
    required this.sessionRate,
    required this.bridalPackageRate,
    this.portfolio = const [],
    this.experienceYears = 0,
    this.offersHairServices = false,
    this.travelsToClient = true,
    this.availableDates = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    final baseJson = toBaseJson();
    baseJson.addAll({
      'type': 'makeup_artist',
      'specializations': specializations,
      'brands': brands,
      'session_rate': sessionRate,
      'bridal_package_rate': bridalPackageRate,
      'portfolio': portfolio,
      'experience_years': experienceYears,
      'offers_hair_services': offersHairServices,
      'travels_to_client': travelsToClient,
      'available_dates': availableDates,
    });
    return baseJson;
  }

  // FIXED: Handle both DateTime and String types for created_at and updated_at
  factory MakeupArtist.fromJson(Map<String, dynamic> json) {
    return MakeupArtist(
      id: json['id'],
      userId: json['user_id'],
      businessName: json['business_name'],
      image: json['image'],
      description: json['description'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      isAvailable: json['is_available'] ?? true,
      reviews: (json['reviews'] as List<dynamic>?)?.map((r) => Review.fromJson(r)).toList() ?? [],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      // Fixed DateTime parsing to handle both DateTime objects and Strings
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      specializations: List<String>.from(json['specializations'] ?? []),
      brands: List<String>.from(json['brands'] ?? []),
      sessionRate: (json['session_rate'] ?? 0.0).toDouble(),
      bridalPackageRate: (json['bridal_package_rate'] ?? 0.0).toDouble(),
      portfolio: List<String>.from(json['portfolio'] ?? []),
      experienceYears: json['experience_years'] ?? 0,
      offersHairServices: json['offers_hair_services'] ?? false,
      travelsToClient: json['travels_to_client'] ?? true,
      availableDates: List<String>.from(json['available_dates'] ?? []),
    );
  }

  // Helper method to safely parse DateTime from either DateTime or String
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  MakeupArtist copyWith({
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
    List<String>? brands,
    double? sessionRate,
    double? bridalPackageRate,
    List<String>? portfolio,
    int? experienceYears,
    bool? offersHairServices,
    bool? travelsToClient,
    List<String>? availableDates,
  }) {
    return MakeupArtist(
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
      brands: brands ?? this.brands,
      sessionRate: sessionRate ?? this.sessionRate,
      bridalPackageRate: bridalPackageRate ?? this.bridalPackageRate,
      portfolio: portfolio ?? this.portfolio,
      experienceYears: experienceYears ?? this.experienceYears,
      offersHairServices: offersHairServices ?? this.offersHairServices,
      travelsToClient: travelsToClient ?? this.travelsToClient,
      availableDates: availableDates ?? this.availableDates,
    );
  }
}