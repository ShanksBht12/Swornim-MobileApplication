import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/config/app_config.dart';

class ReviewService {
  final AuthNotifier _authNotifier;
  final String _baseUrl = AppConfig.baseUrl;

  ReviewService(this._authNotifier);

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      ..._authNotifier.getAuthHeaders(),
    };
  }

  // Create a new review
  Future<Review> createReview({
    required String bookingId,
    required String serviceProviderId,
    required double rating,
    required String comment,
    List<String>? images,
  }) async {
    try {
      print('DEBUG: Creating review with data:');
      print('DEBUG: bookingId: $bookingId');
      print('DEBUG: serviceProviderId: $serviceProviderId');
      print('DEBUG: rating: $rating');
      print('DEBUG: comment: $comment');
      
      final requestBody = {
        'bookingId': bookingId,
        'serviceProviderId': serviceProviderId,
        'rating': rating,
        'comment': comment,
        if (images != null) 'images': images,
      };
      
      print('DEBUG: Request body: $requestBody');
      print('DEBUG: Headers: $_headers');
      print('DEBUG: URL: $_baseUrl/reviews');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/reviews'),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('DEBUG: Request timed out after 30 seconds');
          throw Exception('Request timed out');
        },
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return Review.fromJson(json['data']);
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error'] ?? 'Failed to create review';
        final errorStatus = error['status'] ?? '';
        
        // Throw specific error messages based on backend response
        if (errorStatus == 'REVIEW_ALREADY_EXISTS') {
          throw Exception('Review already exists for this booking');
        } else if (errorStatus == 'INVALID_BOOKING_STATUS') {
          throw Exception('Can only review completed bookings');
        } else if (errorStatus == 'BOOKING_NOT_FOUND') {
          throw Exception('Booking not found');
        } else {
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      print('DEBUG: Error in createReview: $e');
      throw Exception('Error creating review: $e');
    }
  }

  // Get reviews for a service provider
  Future<Map<String, dynamic>> getProviderReviews(
    String serviceProviderId, {
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    try {
      print('=== [DEBUG] ReviewService.getProviderReviews called ===');
      print('Service provider ID: $serviceProviderId');
      print('Page: $page');
      print('Limit: $limit');
      
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      final uri = Uri.parse('$_baseUrl/reviews/provider/$serviceProviderId')
          .replace(queryParameters: queryParams);
      
      print('Request URL: $uri');
      print('Headers: $_headers');

      final response = await http.get(uri, headers: _headers);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final reviewsData = json['data']['reviews'] as List;
        final reviews = reviewsData.map((data) => Review.fromJson(data)).toList();
        
        final result = {
          'reviews': reviews,
          'total': json['data']['total'],
          'page': json['data']['page'],
          'totalPages': json['data']['totalPages'],
        };
        
        print('=== [DEBUG] Service result ===');
        print('Reviews count: ${reviews.length}');
        print('Total: ${result['total']}');
        print('Page: ${result['page']}');
        print('Total pages: ${result['totalPages']}');
        
        return result;
      } else {
        final error = jsonDecode(response.body);
        print('=== [DEBUG] Error response ===');
        print('Error: $error');
        throw Exception(error['error'] ?? 'Failed to fetch reviews');
      }
    } catch (e) {
      print('=== [DEBUG] Exception in getProviderReviews ===');
      print('Error: $e');
      throw Exception('Error fetching provider reviews: $e');
    }
  }

  // Get reviews by the authenticated client
  Future<Map<String, dynamic>> getClientReviews({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$_baseUrl/reviews/client')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final reviewsData = json['data']['reviews'] as List;
        final reviews = reviewsData.map((data) => Review.fromJson(data)).toList();
        
        return {
          'reviews': reviews,
          'total': json['data']['total'],
          'page': json['data']['page'],
          'totalPages': json['data']['totalPages'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch client reviews');
      }
    } catch (e) {
      throw Exception('Error fetching client reviews: $e');
    }
  }

  // Update a review
  Future<Review> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
    List<String>? images,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/reviews/$reviewId'),
        headers: _headers,
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
          if (images != null) 'images': images,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Review.fromJson(json['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update review');
      }
    } catch (e) {
      throw Exception('Error updating review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/reviews/$reviewId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete review');
      }
    } catch (e) {
      throw Exception('Error deleting review: $e');
    }
  }

  // Get review statistics for a service provider
  Future<Map<String, dynamic>> getReviewStatistics(String serviceProviderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reviews/statistics/$serviceProviderId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch review statistics');
      }
    } catch (e) {
      throw Exception('Error fetching review statistics: $e');
    }
  }
} 