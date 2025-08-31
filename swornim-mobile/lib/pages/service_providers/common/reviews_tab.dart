import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/providers/reviews/review_provider.dart';

class ReviewsTab extends ConsumerStatefulWidget {
  final String serviceProviderId;
  final String serviceProviderName;
  final String serviceProviderType;

  const ReviewsTab({
    Key? key,
    required this.serviceProviderId,
    required this.serviceProviderName,
    required this.serviceProviderType,
  }) : super(key: key);

  @override
  ConsumerState<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<ReviewsTab> {
  int _currentPage = 1;
  final int _pageSize = 5; // Show only 5 reviews initially
  bool _hasMoreReviews = true;

  @override
  void initState() {
    super.initState();
    // Load initial reviews
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewProvider.notifier).getProviderReviews(
        widget.serviceProviderId,
        page: _currentPage,
        limit: _pageSize,
      );
      // Also prefetch stats
      ref.refresh(reviewStatisticsProvider(widget.serviceProviderId));
    });
  }

    @override
  Widget build(BuildContext context) {
    try {
      final theme = Theme.of(context);
      final reviewsState = ref.watch(reviewProvider);
      final statisticsAsync = ref.watch(reviewStatisticsProvider(widget.serviceProviderId));

      print('=== [DEBUG] ReviewsTab build ===');
      print('Current page: $_currentPage');
      print('Reviews count: ${reviewsState.reviews.length}');
      print('Total reviews: ${reviewsState.totalReviews}');
      print('Is loading: ${reviewsState.isLoading}');
      print('Error: ${reviewsState.error}');

      return SliverToBoxAdapter(
      child: Container(
        key: const ValueKey('reviews'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: reviewsState.isLoading && reviewsState.reviews.isEmpty
            ? _buildLoadingState(theme)
            : reviewsState.error != null && reviewsState.reviews.isEmpty
                ? _buildErrorState(theme, reviewsState.error!)
                : reviewsState.reviews.isEmpty
                    ? _buildEmptyReviews(theme)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reviews Statistics
                          statisticsAsync.when(
                            data: (stats) => _buildReviewsStatistics(
                              theme,
                              _safeParseInt(stats['totalReviews'], reviewsState.totalReviews),
                              _safeParseDouble(stats['averageRating'], 0.0),
                              _safeParseRatingDistribution(stats['ratingDistribution']),
                            ),
                            loading: () => _buildLoadingState(theme),
                            error: (e, _) => _buildReviewsStatistics(
                              theme,
                              reviewsState.totalReviews,
                              0.0,
                              const {},
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Reviews List
                          ...reviewsState.reviews.map((review) => _buildReviewCard(review, theme)).toList(),
                          // Load More Button
                          if (reviewsState.reviews.length < reviewsState.totalReviews) ...[
                            const SizedBox(height: 16),
                            _buildLoadMoreButton(theme, _currentPage, (reviewsState.totalReviews / _pageSize).ceil()),
                          ],
                        ],
                      ),
      ),
    );
    } catch (e) {
      print('=== [DEBUG] Error in ReviewsTab build: $e ===');
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildReviewsStatistics(ThemeData theme, int totalReviews, double averageRating, Map<int, int> ratingDistribution) {
    // Use only the passed-in values from backend statistics
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rate_review_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Reviews',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Average Rating
          Row(
            children: [
              // Star rating display
              ...List.generate(5, (index) {
                return Icon(
                  index < averageRating.floor()
                      ? Icons.star_rounded
                      : index < averageRating
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded,
                  color: Colors.amber[600],
                  size: 24,
                );
              }),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$totalReviews reviews',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rating Distribution
          ...ratingDistribution.entries.map((entry) {
            final rating = entry.key;
            final count = entry.value;
            final percentage = totalReviews > 0 ? (count / totalReviews) * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '$rating',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review Header
          Row(
            children: [
              // Client Profile Image
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: review.clientProfileImage != null && review.clientProfileImage!.isNotEmpty
                      ? Image.network(
                          review.clientProfileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.clientName?.isNotEmpty == true 
                          ? review.clientName! 
                          : 'Client',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatReviewDate(review.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Star Rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating.floor()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber[600],
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Review Comment
          Text(
            review.comment,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          
          // Review Images (if any)
          if (review.images != null && review.images!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review.images![idx],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(ThemeData theme, int currentPage, int totalPages) {
    final remainingReviews = totalPages - currentPage;
    final reviewsToLoad = remainingReviews * _pageSize;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _loadMoreReviews(),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Show ${reviewsToLoad > 0 ? reviewsToLoad : 'more'} reviews',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReviews(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Reviews Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review ${widget.serviceProviderName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading reviews...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Reviews',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load reviews. Please try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _retryLoadingReviews(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _loadMoreReviews() {
    final nextPage = _currentPage + 1;
    print('=== [DEBUG] Loading more reviews ===');
    print('Current page: $_currentPage');
    print('Next page: $nextPage');
    print('Page size: $_pageSize');
    print('Service provider ID: ${widget.serviceProviderId}');
    
    ref.read(reviewProvider.notifier).getProviderReviews(
      widget.serviceProviderId,
      page: nextPage,
      limit: _pageSize,
      append: true, // Append to existing reviews instead of replacing
    );
    setState(() {
      _currentPage = nextPage;
    });
    print('=== [DEBUG] Load more request sent ===');
  }

  void _retryLoadingReviews() {
    ref.read(reviewProvider.notifier).getProviderReviews(
      widget.serviceProviderId,
      page: 1,
      limit: _pageSize,
    );
    setState(() {
      _currentPage = 1;
    });
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Helper methods for safe parsing of statistics data
  int _safeParseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  double _safeParseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  Map<int, int> _safeParseRatingDistribution(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      final Map<int, int> result = {};
      value.forEach((key, val) {
        final intKey = _safeParseInt(key, 0);
        final intVal = _safeParseInt(val, 0);
        if (intKey > 0) {
          result[intKey] = intVal;
        }
      });
      return result;
    }
    return {};
  }

  // Add this method to allow parent to trigger a refresh after review submission
  void refreshStats() {
    ref.refresh(reviewStatisticsProvider(widget.serviceProviderId));
    ref.read(reviewProvider.notifier).getProviderReviews(
      widget.serviceProviderId,
      page: 1,
      limit: _pageSize,
    );
    setState(() {
      _currentPage = 1;
    });
  }
}
