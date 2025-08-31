import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/services/review_service.dart';

// Review State
class ReviewState {
  final List<Review> reviews;
  final bool isLoading;
  final String? error;
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingDistribution;

  const ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
    this.totalReviews = 0,
    this.averageRating = 0.0,
    this.ratingDistribution = const {},
  });

  ReviewState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    String? error,
    int? totalReviews,
    double? averageRating,
    Map<int, int>? ratingDistribution,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalReviews: totalReviews ?? this.totalReviews,
      averageRating: averageRating ?? this.averageRating,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
    );
  }
}

// Review Notifier
class ReviewNotifier extends StateNotifier<ReviewState> {
  final ReviewService _reviewService;
  final Ref _ref;

  ReviewNotifier(this._reviewService, this._ref) : super(const ReviewState());

  // Get reviews for a service provider
  Future<void> getProviderReviews(String serviceProviderId, {int page = 1, int limit = 10, bool append = false}) async {
    print('=== [DEBUG] ReviewProvider.getProviderReviews called ===');
    print('Service provider ID: $serviceProviderId');
    print('Page: $page');
    print('Limit: $limit');
    print('Append: $append');
    print('Current reviews count: ${state.reviews.length}');
    
    if (!append) {
      state = state.copyWith(isLoading: true, error: null);
    }
    
    try {
      final result = await _reviewService.getProviderReviews(serviceProviderId, page: page, limit: limit);
      print('=== [DEBUG] Service result ===');
      print('Result: $result');
      
      final newReviews = (result['reviews'] as List?)?.cast<Review>() ?? <Review>[];
      final updatedReviews = append ? [...state.reviews, ...newReviews] : newReviews;
      
      print('New reviews count: ${newReviews.length}');
      print('Updated reviews count: ${updatedReviews.length}');
      
      state = state.copyWith(
        reviews: updatedReviews,
        totalReviews: result['total'] ?? 0,
        isLoading: false,
      );
      print('=== [DEBUG] State updated successfully ===');
    } catch (e) {
      print('=== [DEBUG] Error in getProviderReviews ===');
      print('Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Get reviews by the authenticated client
  Future<void> getClientReviews({int page = 1, int limit = 10}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _reviewService.getClientReviews(page: page, limit: limit);
      
      state = state.copyWith(
        reviews: result['reviews'] ?? [],
        totalReviews: result['total'] ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Create a new review
  Future<bool> createReview({
    required String bookingId,
    required String serviceProviderId,
    required double rating,
    required String comment,
    List<String>? images,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final review = await _reviewService.createReview(
        bookingId: bookingId,
        serviceProviderId: serviceProviderId,
        rating: rating,
        comment: comment,
        images: images,
      );
      
      // Add the new review to the list
      final updatedReviews = [review, ...state.reviews];
      
      state = state.copyWith(
        reviews: updatedReviews,
        totalReviews: state.totalReviews + 1,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Update a review
  Future<bool> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
    List<String>? images,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedReview = await _reviewService.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
        images: images,
      );
      
      // Update the review in the list
      final updatedReviews = state.reviews.map((review) {
        return review.id == reviewId ? updatedReview : review;
      }).toList();
      
      state = state.copyWith(
        reviews: updatedReviews,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Delete a review
  Future<bool> deleteReview(String reviewId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _reviewService.deleteReview(reviewId);
      
      // Remove the review from the list
      final updatedReviews = state.reviews.where((review) => review.id != reviewId).toList();
      
      state = state.copyWith(
        reviews: updatedReviews,
        totalReviews: state.totalReviews - 1,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Get review statistics for a service provider
  Future<void> getReviewStatistics(String serviceProviderId) async {
    try {
      final statistics = await _reviewService.getReviewStatistics(serviceProviderId);
      
      state = state.copyWith(
        totalReviews: statistics['totalReviews'] ?? 0,
        averageRating: statistics['averageRating'] ?? 0.0,
        ratingDistribution: Map<int, int>.from(statistics['ratingDistribution'] ?? {}),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear reviews
  void clearReviews() {
    state = state.copyWith(
      reviews: [],
      totalReviews: 0,
      averageRating: 0.0,
      ratingDistribution: {},
    );
  }
}

// Review Service Provider
final reviewServiceProvider = Provider<ReviewService>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return ReviewService(authNotifier);
});

// Review State Provider
final reviewProvider = StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  final reviewService = ref.watch(reviewServiceProvider);
  return ReviewNotifier(reviewService, ref);
});

// Provider-specific review providers
final providerReviewsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, serviceProviderId) async {
  final reviewService = ref.read(reviewServiceProvider);
  return await reviewService.getProviderReviews(serviceProviderId);
});

final clientReviewsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final reviewService = ref.read(reviewServiceProvider);
  return await reviewService.getClientReviews();
});

final reviewStatisticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, serviceProviderId) async {
  final reviewService = ref.read(reviewServiceProvider);
  return await reviewService.getReviewStatistics(serviceProviderId);
}); 