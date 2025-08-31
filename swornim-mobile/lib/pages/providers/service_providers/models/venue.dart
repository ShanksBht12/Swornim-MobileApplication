import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/models/location.dart';

class Venue extends ServiceProvider {
  final int capacity;
  final double pricePerHour;
  final List<String> amenities;
  final List<String> images; // Merged gallery into images
  final List<String> venueTypes;

  const Venue({
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
    required this.capacity,
    required this.pricePerHour,
    this.amenities = const [],
    this.images = const [],
    this.venueTypes = const [],
  });

  // Convenience getter for address
  String get address => location?.address ?? '';

  // Helper method to parse price from various types
  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = toBaseJson();
    baseJson.addAll({
      'type': 'venue',
      'capacity': capacity,
      'price_per_hour': pricePerHour,
      'amenities': amenities,
      'images': images,
      'venue_types': venueTypes,
    });
    return baseJson;
  }

  factory Venue.fromJson(Map<String, dynamic> json) {
    final venue = Venue(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      businessName: json['businessName'] ?? json['business_name'],
      image: json['image'],
      description: json['description'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? json['total_reviews'] ?? 0,
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
      reviews: (json['reviews'] as List<dynamic>?)?.map((r) => Review.fromJson(r)).toList() ?? [],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
      capacity: json['capacity'] ?? 0,
      pricePerHour: _parsePrice(json['pricePerHour'] ?? json['price_per_hour']),
      amenities: List<String>.from(json['amenities'] ?? []),
      images: [
        ...List<String>.from(json['images'] ?? []),
        ...List<String>.from(json['gallery'] ?? []), // Merge gallery for backward compatibility
      ],
      venueTypes: List<String>.from(json['venueTypes'] ?? json['venue_types'] ?? []),
    );
    
    return venue;
  }
  
  @override
  Venue copyWith({
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
    int? capacity,
    double? pricePerHour,
    List<String>? amenities,
    List<String>? images,
    List<String>? venueTypes,
  }) {
    return Venue(
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
      capacity: capacity ?? this.capacity,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      venueTypes: venueTypes ?? this.venueTypes,
    );
  }
}