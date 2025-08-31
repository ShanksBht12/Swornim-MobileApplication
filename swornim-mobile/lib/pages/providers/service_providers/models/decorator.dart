import 'package:swornim/pages/models/location.dart';
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';

class Decorator extends ServiceProvider {
  final List<String> specializations;
  final List<String> themes;
  final double packageStartingPrice;
  final double hourlyRate;
  final List<String> portfolio;
  final int experienceYears;
  final bool offersFlowerArrangements;
  final bool offersLighting;
  final bool offersRentals;
  final List<String> availableItems;
  final List<String> availableDates;

  const Decorator({
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
    this.themes = const [],
    this.packageStartingPrice = 0.0,
    this.hourlyRate = 0.0,
    this.portfolio = const [],
    this.experienceYears = 0,
    this.offersFlowerArrangements = false,
    this.offersLighting = false,
    this.offersRentals = false,
    this.availableItems = const [],
    this.availableDates = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    final baseJson = toBaseJson();
    baseJson.addAll({
      'type': 'decorator',
      'specializations': specializations,
      'themes': themes,
      'package_starting_price': packageStartingPrice,
      'hourly_rate': hourlyRate,
      'portfolio': portfolio,
      'experience_years': experienceYears,
      'offers_flower_arrangements': offersFlowerArrangements,
      'offers_lighting': offersLighting,
      'offers_rentals': offersRentals,
      'available_items': availableItems,
      'available_dates': availableDates,
    });
    return baseJson;
  }

  factory Decorator.fromJson(Map<String, dynamic> json) {
    return Decorator(
      id: json['id'],
      userId: json['user_id'],
      businessName: json['business_name'],
      image: json['image'] ?? '',
      description: json['description'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] ?? false,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((r) => Review.fromJson(r))
              .toList() ??
          [],
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      specializations: List<String>.from(json['specializations'] ?? []),
      themes: List<String>.from(json['themes'] ?? []),
      packageStartingPrice:
          (json['package_starting_price'] as num?)?.toDouble() ?? 0.0,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      portfolio: List<String>.from(json['portfolio'] ?? []),
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      offersFlowerArrangements: json['offers_flower_arrangements'] ?? false,
      offersLighting: json['offers_lighting'] ?? false,
      offersRentals: json['offers_rentals'] ?? false,
      availableItems: List<String>.from(json['available_items'] ?? []),
      availableDates: List<String>.from(json['available_dates'] ?? []),
    );
  }

  @override
  Decorator copyWith({
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
    List<String>? themes,
    double? packageStartingPrice,
    double? hourlyRate,
    List<String>? portfolio,
    int? experienceYears,
    bool? offersFlowerArrangements,
    bool? offersLighting,
    bool? offersRentals,
    List<String>? availableItems,
    List<String>? availableDates,
  }) {
    return Decorator(
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
      themes: themes ?? this.themes,
      packageStartingPrice: packageStartingPrice ?? this.packageStartingPrice,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      portfolio: portfolio ?? this.portfolio,
      experienceYears: experienceYears ?? this.experienceYears,
      offersFlowerArrangements:
          offersFlowerArrangements ?? this.offersFlowerArrangements,
      offersLighting: offersLighting ?? this.offersLighting,
      offersRentals: offersRentals ?? this.offersRentals,
      availableItems: availableItems ?? this.availableItems,
      availableDates: availableDates ?? this.availableDates,
    );
  }
}