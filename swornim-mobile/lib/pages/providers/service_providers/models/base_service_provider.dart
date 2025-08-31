import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/models/location.dart';

abstract class ServiceProvider {
  final String id;
  final String userId;
  final String businessName;
  final String image;
  final String description;
  final double rating;
  final int totalReviews;
  final bool isAvailable;
  final List<Review> reviews;
  final Location? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceProvider({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.image,
    required this.description,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isAvailable = true,
    this.reviews = const [],
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toBaseJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName,
      'image': image,
      'description': description,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_available': isAvailable,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'location': location?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson();
  ServiceProvider copyWith({
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
  });
}