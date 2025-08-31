// lib/pages/models/service_provider.dart
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/models/location.dart';

abstract class ServiceProvider {
  final String id;
  final String name;
  final String image;
  final String description;
  final double rating;
  final int totalReviews;
  final bool isAvailable;
  final List<Review> reviews;
  final Location? location;
  final String contactPhone;
  final String contactEmail;

  const ServiceProvider({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isAvailable = true,
    this.reviews = const [],
    this.location,
    this.contactPhone = '',
    this.contactEmail = '',
  });

  Map<String, dynamic> toBaseJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_available': isAvailable,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'location': location?.toJson(),
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
    };
  }

  // Abstract method that must be implemented by subclasses
  Map<String, dynamic> toJson();
}