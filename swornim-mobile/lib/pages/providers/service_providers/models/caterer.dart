import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/models/location.dart';

class Caterer extends ServiceProvider {
  final List<String> cuisineTypes; // ['nepali', 'indian', 'chinese', 'continental']
  final List<String> serviceTypes; // ['buffet', 'plated', 'family_style']
  final double pricePerPerson;
  final int minGuests;
  final int maxGuests;
  final List<String> menuItems;
  final List<String> dietaryOptions; // ['vegetarian', 'vegan', 'halal', 'jain']
  final bool offersEquipment; // Tables, chairs, serving equipment
  final bool offersWaiters;
  final List<String> availableDates;
  final int experienceYears;
  final List<String> portfolio; // Portfolio images

  const Caterer({
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
    this.cuisineTypes = const [],
    this.serviceTypes = const [],
    required this.pricePerPerson,
    this.minGuests = 10,
    this.maxGuests = 500,
    this.menuItems = const [],
    this.dietaryOptions = const [],
    this.offersEquipment = false,
    this.offersWaiters = false,
    this.availableDates = const [],
    this.experienceYears = 0,
    this.portfolio = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    final baseJson = toBaseJson();
    baseJson.addAll({
      'type': 'caterer',
      'cuisine_types': cuisineTypes,
      'service_types': serviceTypes,
      'price_per_person': pricePerPerson,
      'min_guests': minGuests,
      'max_guests': maxGuests,
      'menu_items': menuItems,
      'dietary_options': dietaryOptions,
      'offers_equipment': offersEquipment,
      'offers_waiters': offersWaiters,
      'available_dates': availableDates,
      'experience_years': experienceYears,
      'portfolio': portfolio,
    });
    return baseJson;
  }

  factory Caterer.fromJson(Map<String, dynamic> json) {
    return Caterer(
      id: json['id'],
      userId: json['userId'],
      businessName: json['businessName'],
      image: json['image'] ?? '',
      description: json['description'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      reviews: (json['reviews'] as List<dynamic>?)?.map((r) => Review.fromJson(r)).toList() ?? [],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      cuisineTypes: List<String>.from(json['cuisineTypes'] ?? []),
      serviceTypes: List<String>.from(json['serviceTypes'] ?? []),
      pricePerPerson: double.tryParse(json['pricePerPerson']?.toString() ?? '0') ?? 0.0,
      minGuests: json['minGuests'] ?? 10,
      maxGuests: json['maxGuests'] ?? 500,
      menuItems: List<String>.from(json['menuItems'] ?? []),
      dietaryOptions: List<String>.from(json['dietaryOptions'] ?? []),
      offersEquipment: json['offersEquipment'] ?? false,
      offersWaiters: json['offersWaiters'] ?? false,
      availableDates: List<String>.from(json['availableDates'] ?? []),
      experienceYears: json['experienceYears'] ?? 0,
      portfolio: List<String>.from(json['portfolio'] ?? []),
    );
  }

  @override
  Caterer copyWith({
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
    List<String>? cuisineTypes,
    List<String>? serviceTypes,
    double? pricePerPerson,
    int? minGuests,
    int? maxGuests,
    List<String>? menuItems,
    List<String>? dietaryOptions,
    bool? offersEquipment,
    bool? offersWaiters,
    List<String>? availableDates,
    int? experienceYears,
    List<String>? portfolio,
  }) {
    return Caterer(
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
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      minGuests: minGuests ?? this.minGuests,
      maxGuests: maxGuests ?? this.maxGuests,
      menuItems: menuItems ?? this.menuItems,
      dietaryOptions: dietaryOptions ?? this.dietaryOptions,
      offersEquipment: offersEquipment ?? this.offersEquipment,
      offersWaiters: offersWaiters ?? this.offersWaiters,
      availableDates: availableDates ?? this.availableDates,
      experienceYears: experienceYears ?? this.experienceYears,
      portfolio: portfolio ?? this.portfolio,
    );
  }
}