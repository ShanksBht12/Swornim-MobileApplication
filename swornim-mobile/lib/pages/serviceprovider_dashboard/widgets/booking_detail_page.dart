import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:swornim/pages/providers/bookings/bookings_provider.dart';
import 'package:swornim/pages/providers/payments/payment_provider.dart';
import 'package:swornim/pages/payment/khalti_payment_screen.dart';
import 'package:swornim/pages/payment/payment_status_widget.dart';
import 'package:swornim/pages/widgets/review/review_form_dialog.dart';
import 'package:swornim/pages/providers/reviews/review_provider.dart';
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/service_providers/common/reviews_tab.dart';

class BookingDetailPage extends ConsumerStatefulWidget {
  final Booking booking;
  final User provider;
  
  const BookingDetailPage({
    required this.booking,
    required this.provider,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends ConsumerState<BookingDetailPage> {
  bool _isUpdatingStatus = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Debug prints for review functionality (commented out for production)
    // print('DEBUG: Booking status: ${widget.booking.status}');
    // print('DEBUG: User type: ${widget.provider.userType}');
    // print('DEBUG: Is client: ${widget.provider.userType == UserType.client}');
    // print('DEBUG: Is completed: ${widget.booking.status == BookingStatus.completed}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking #${widget.booking.id.substring(0, 8)}'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showBookingMenu(context),
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Status Header
            _buildStatusHeader(theme, colorScheme),
            const SizedBox(height: 24),

            // Client Information
            _buildPartySection(theme, colorScheme),
            const SizedBox(height: 24),

            // Event Details
            _buildEventSection(theme, colorScheme),
            const SizedBox(height: 24),

            // Package Details
            _buildPackageSection(theme, colorScheme),
            const SizedBox(height: 24),

            // Payment Information
            _buildPaymentSection(theme, colorScheme),
            const SizedBox(height: 24),

            // Payment Summary Card (for clients, before payment button)
            if (widget.provider.userType == UserType.client)
              _buildPaymentSummaryCard(),
            if (widget.provider.userType == UserType.client)
              const SizedBox(height: 24),

            // Payment Status Widget (for clients)
            if (widget.provider.userType == UserType.client)
              PaymentStatusWidget(
                bookingId: widget.booking.id,
                amount: widget.booking.totalAmount,
              ),
            if (widget.provider.userType == UserType.client)
              const SizedBox(height: 24),

            // Booking Timeline
            _buildTimelineSection(theme, colorScheme),
            const SizedBox(height: 24),

            // Special Requests
            if (widget.booking.specialRequests != null && 
                widget.booking.specialRequests!.isNotEmpty)
              _buildSpecialRequestsSection(theme, colorScheme),
            if (widget.booking.specialRequests != null && 
                widget.booking.specialRequests!.isNotEmpty)
              const SizedBox(height: 24),

            // Review Section (for completed bookings)
            if (widget.booking.status == BookingStatus.completed)
              _buildReviewSection(theme, colorScheme),
            if (widget.booking.status == BookingStatus.completed)
              const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(theme, colorScheme),
    );
  }

  Widget _buildStatusHeader(ThemeData theme, ColorScheme colorScheme) {
    final isPaid = widget.booking.status == BookingStatus.confirmed_paid;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor(widget.booking.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(widget.booking.status).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.booking.status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(widget.booking.status),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isPaid ? 'PAID' : getStatusLabel(widget.booking.status),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(widget.booking.status),
                      ),
                    ),
                    if (isPaid)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PAID',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isPaid ? 'Payment received. This booking is ready to start.' : _getStatusDescription(widget.booking.status),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.booking.formattedAmount,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                'Total Amount',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartySection(ThemeData theme, ColorScheme colorScheme) {
    final isClient = widget.provider.userType == UserType.client;
    final info = isClient ? widget.booking.serviceProvider : widget.booking.client;
    final sectionTitle = isClient ? 'Vendor Information' : 'Client Information';
    final icon = isClient ? Icons.storefront_rounded : Icons.person_rounded;

    return _buildSection(
      theme: theme,
      colorScheme: colorScheme,
      title: sectionTitle,
      icon: icon,
      child: Column(
        children: [
          _buildInfoRow(
            'Name',
            isClient
              ? (info?['businessName'] ?? info?['name'] ?? 'N/A')
              : (info?['name'] ?? 'N/A'),
            theme,
            colorScheme,
          ),
          _buildInfoRow('Email', info?['email'] ?? 'N/A', theme, colorScheme),
          _buildInfoRow('Phone', info?['phone'] ?? 'N/A', theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildEventSection(ThemeData theme, ColorScheme colorScheme) {
    return _buildSection(
      theme: theme,
      colorScheme: colorScheme,
      title: 'Event Details',
      icon: Icons.event,
      child: Column(
        children: [
          _buildInfoRow('Event Type', widget.booking.eventType, theme, colorScheme),
          _buildInfoRow('Date', widget.booking.formattedEventDate, theme, colorScheme),
          _buildInfoRow('Time', widget.booking.eventTime, theme, colorScheme),
          _buildInfoRow('Location', widget.booking.eventLocation, theme, colorScheme),
          _buildInfoRow('Service Type', _getServiceTypeName(widget.booking.serviceType), theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPackageSection(ThemeData theme, ColorScheme colorScheme) {
    // Use packageSnapshot if available, otherwise fallback to package
    final package = widget.booking.packageSnapshot ?? widget.booking.package;

    String getField(String key) {
      if (package == null) return 'N/A';
      if (package is Map) {
        return (package as Map)[key]?.toString() ?? 'N/A';
      }
      if (package.runtimeType.toString().contains('ServicePackage')) {
        try {
          final value = (package as dynamic).toJson()[key];
          return value?.toString() ?? 'N/A';
        } catch (_) {
          return 'N/A';
        }
      }
      return 'N/A';
    }

    List<String> getFeatures() {
      if (package == null) return [];
      if (package is Map) {
        final features = (package as Map)['features'];
        if (features is List) {
          return features.map((e) => e.toString()).toList();
        }
        return [];
      }
      if (package.runtimeType.toString().contains('ServicePackage')) {
        try {
          final features = (package as dynamic).features;
          if (features is List<String>) return features;
          if (features is List) return features.map((e) => e.toString()).toList();
          return [];
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    return _buildSection(
      theme: theme,
      colorScheme: colorScheme,
      title: 'Package Details',
      icon: Icons.inventory_2,
      child: Column(
        children: [
          if (package != null) ...[
            _buildInfoRow('Package Name', getField('name'), theme, colorScheme),
            _buildInfoRow('Base Price', 'Rs.${getField('basePrice')}', theme, colorScheme),
            _buildInfoRow('Duration', '${getField('durationHours')} hours', theme, colorScheme),
            if (getFeatures().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Features:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              ...getFeatures().map((feature) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ] else ...[
            _buildInfoRow('Package ID', widget.booking.packageId, theme, colorScheme),
            _buildInfoRow('Package', 'Package details not available', theme, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSection(ThemeData theme, ColorScheme colorScheme) {
    return _buildSection(
      theme: theme,
      colorScheme: colorScheme,
      title: 'Payment Information',
      icon: Icons.payment,
      child: Column(
        children: [
          _buildInfoRow('Status', _getPaymentStatusText(widget.booking.paymentStatus), theme, colorScheme),
          _buildInfoRow('Amount', widget.booking.formattedAmount, theme, colorScheme),
          if (widget.booking.hasPriceChanged) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Price modified from original package',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    final booking = widget.booking;
    final provider = widget.provider;
    final packageName = booking.packageSnapshot?.name ?? booking.serviceType.name;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking & Payment Summary', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _infoRow('Service', packageName),
            _infoRow('Provider', provider.name),
            _infoRow('Event Date', booking.formattedEventDate),
            _infoRow('Event Time', booking.eventTime),
            _infoRow('Location', booking.eventLocation),
            _infoRow('Booking ID', booking.id),
            _infoRow('Total Amount', 'NPR ${booking.totalAmount.toStringAsFixed(2)}'),
            _infoRow('Booking Status', booking.status.name),
            _infoRow('Payment Status', booking.paymentStatus.name),
            if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty)
              _infoRow('Special Requests', booking.specialRequests!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );

  Widget _buildTimelineSection(ThemeData theme, ColorScheme colorScheme) {
    return _buildSection(
      theme: theme,
      colorScheme: colorScheme,
      title: 'Booking Timeline',
      icon: Icons.timeline,
      child: Column(
        children: [
          _buildTimelineItem(
            theme,
            colorScheme,
            'Booking Created',
            widget.booking.createdAt,
            Icons.add_circle,
            Colors.green,
            true,
          ),
          _buildTimelineItem(
            theme,
            colorScheme,
            'Last Updated',
            widget.booking.updatedAt,
            Icons.update,
            Colors.blue,
            true,
          ),
          if (widget.booking.status == BookingStatus.confirmed_awaiting_payment || 
              widget.booking.status == BookingStatus.confirmed_paid)
            _buildTimelineItem(
              theme,
              colorScheme,
              'Booking Confirmed',
              widget.booking.updatedAt,
              Icons.check_circle,
              Colors.green,
              true,
            ),
          if (widget.booking.status == BookingStatus.in_progress)
            _buildTimelineItem(
              theme,
              colorScheme,
              'Service Started',
              widget.booking.updatedAt,
              Icons.play_circle,
              Colors.orange,
              true,
            ),
          if (widget.booking.status == BookingStatus.completed)
            _buildTimelineItem(
              theme,
              colorScheme,
              'Service Completed',
              widget.booking.updatedAt,
              Icons.done_all,
              Colors.green,
              true,
            ),
          if (widget.booking.status == BookingStatus.cancelled_by_client ||
              widget.booking.status == BookingStatus.cancelled_by_provider)
            _buildTimelineItem(
              theme,
              colorScheme,
              'Booking Cancelled',
              widget.booking.updatedAt,
              Icons.cancel,
              Colors.red,
              true,
            ),
          _buildTimelineItem(
            theme,
            colorScheme,
            'Event Date',
            widget.booking.eventDate,
            Icons.event,
            widget.booking.isUpcoming ? Colors.blue : Colors.grey,
            widget.booking.isUpcoming,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialRequestsSection(ThemeData theme, ColorScheme colorScheme) {
    return _buildSection(
      theme: theme,
      colorScheme: colorScheme,
      title: 'Special Requests',
      icon: Icons.note,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.booking.specialRequests!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection(ThemeData theme, ColorScheme colorScheme) {
    final isClient = widget.provider.userType == UserType.client;
    
    // Fetch reviews for this booking
    final reviewsAsync = ref.watch(providerReviewsProvider(widget.booking.serviceProviderId));
    
    return _buildSection(
      theme: theme,
      colorScheme: colorScheme,
      title: 'Review',
      icon: Icons.rate_review_rounded,
      child: reviewsAsync.when(
        data: (reviewsData) {
          final reviews = reviewsData['reviews'] as List<Review>? ?? [];
          // Find review for this specific booking
          final bookingReview = reviews.where((review) => review.bookingId == widget.booking.id).firstOrNull;
          
          if (bookingReview != null) {
            // Show existing review
            return _buildExistingReview(bookingReview, theme, colorScheme);
          } else if (isClient) {
            // Show review button for clients who haven't reviewed yet
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How was your experience with this service?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showReviewDialog(context),
                    icon: const Icon(Icons.rate_review_rounded),
                    label: const Text('Write a Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Show message for service providers
            return Text(
              'Client reviews will appear here once submitted.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            );
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text(
          'Error loading reviews: $error',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildExistingReview(Review review, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating display
        Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < review.rating.floor()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: Colors.amber[600],
                size: 20,
              );
            }),
            const SizedBox(width: 8),
            Text(
              '${review.rating.toStringAsFixed(1)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Review comment
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            review.comment,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Review date
        Text(
          'Reviewed on ${_formatReviewDate(review.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _formatReviewDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSection({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // Replace currency symbol in info rows
  Widget _buildInfoRow(String label, String value, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(value.replaceAll(' 4', 'Rs.').replaceAll(' 4', 'Rs.'), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    DateTime date,
    IconData icon,
    Color color,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? color : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  _formatDateTime(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    final booking = widget.booking;
    final isClient = widget.provider.userType == UserType.client;
    final isConfirmed = booking.status == BookingStatus.confirmed_awaiting_payment;
    final isPaid = booking.paymentStatus == PaymentStatus.paid;
    final isCancelled = booking.status == BookingStatus.cancelled_by_client || booking.status == BookingStatus.cancelled_by_provider;

    // Fetch reviews to check if this booking has been reviewed
    final reviewsAsync = ref.watch(providerReviewsProvider(widget.booking.serviceProviderId));
    
    return reviewsAsync.when(
      data: (reviewsData) {
        final reviews = reviewsData['reviews'] as List<Review>? ?? [];
        final bookingReview = reviews.where((review) => review.bookingId == widget.booking.id).firstOrNull;
        final hasReview = bookingReview != null;

        List<Widget> actions = [];

        // Show Pay Now for all confirmed bookings from client side, if not paid or cancelled
        if (isClient && isConfirmed && !isPaid && !isCancelled) {
          actions.add(
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment_rounded, size: 22, color: Colors.white),
                  label: const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.green.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _isLoading ? null : _initiatePayment,
                ),
              ),
            ),
          );
        }

        // Cancel button
        if (isClient && !isCancelled && !isPaid) {
          actions.add(
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
                    label: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: _isLoading ? null : () {
                      // TODO: Implement cancel logic
                    },
                  ),
                ),
              ),
            ),
          );
        }

        // Review button for completed bookings (clients only) - only show if no review exists
        if (isClient && booking.status == BookingStatus.completed && !hasReview) {
          actions.add(
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.rate_review_rounded, size: 22, color: Colors.white),
                  label: const Text('Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.amber[200],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _isLoading ? null : () => _showReviewDialog(context),
                ),
              ),
            ),
          );
        }

        if (actions.isEmpty) return const SizedBox.shrink();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), // More top margin, less bottom
            child: Row(
              children: actions,
            ),
          ),
        );
      },
      loading: () => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: SizedBox.shrink(),
        ),
      ),
    );
  }

  void _showBookingMenu(BuildContext context) {
    final isClient = widget.provider.userType == UserType.client;
    
    // Fetch reviews to check if this booking has been reviewed
    final reviewsAsync = ref.read(providerReviewsProvider(widget.booking.serviceProviderId));
    
    reviewsAsync.when(
      data: (reviewsData) {
        final reviews = reviewsData['reviews'] as List<Review>? ?? [];
        final bookingReview = reviews.where((review) => review.bookingId == widget.booking.id).firstOrNull;
        final hasReview = bookingReview != null;
        
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isClient) ...[
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit Booking'),
                    onTap: () {
                      Navigator.pop(context);
                      _editBooking();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Reschedule'),
                    onTap: () {
                      Navigator.pop(context);
                      _rescheduleBooking();
                    },
                  ),
                  if (widget.booking.status == BookingStatus.completed && !hasReview)
                    ListTile(
                      leading: const Icon(Icons.rate_review_rounded, color: Colors.amber),
                      title: const Text('Write Review'),
                      onTap: () {
                        Navigator.pop(context);
                        _showReviewDialog(context);
                      },
                    ),
                ],
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Generate Invoice'),
                  onTap: () {
                    Navigator.pop(context);
                    _generateInvoice();
                  },
                ),
                if (widget.booking.status != BookingStatus.cancelled_by_client &&
                    widget.booking.status != BookingStatus.cancelled_by_provider)
                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.red),
                    title: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _cancelBooking();
                    },
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isClient) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Booking'),
                  onTap: () {
                    Navigator.pop(context);
                    _editBooking();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Reschedule'),
                  onTap: () {
                    Navigator.pop(context);
                    _rescheduleBooking();
                  },
                ),
                if (widget.booking.status == BookingStatus.completed)
                  ListTile(
                    leading: const Icon(Icons.rate_review_rounded, color: Colors.amber),
                    title: const Text('Write Review'),
                    onTap: () {
                      Navigator.pop(context);
                      _showReviewDialog(context);
                    },
                  ),
              ],
              ListTile(
                leading: const Icon(Icons.receipt),
                title: const Text('Generate Invoice'),
                onTap: () {
                  Navigator.pop(context);
                  _generateInvoice();
                },
              ),
              if (widget.booking.status != BookingStatus.cancelled_by_client &&
                  widget.booking.status != BookingStatus.cancelled_by_provider)
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _cancelBooking();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateBookingStatus(BookingStatus newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      // Call the provider to update the booking status
      await ref.read(bookingsProvider.notifier).updateBookingStatus(widget.booking.id, newStatus.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking status updated to ${newStatus.name.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update booking status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  void _editBooking() {
    // TODO: Navigate to booking edit form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to booking edit form')),
    );
  }

  void _rescheduleBooking() {
    // TODO: Show date/time picker for rescheduling
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Show reschedule dialog')),
    );
  }

  void _generateInvoice() {
    // TODO: Generate and show invoice
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generate invoice')),
    );
  }

  void _cancelBooking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateBookingStatus(BookingStatus.cancelled_by_client);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context) async {
    // Get service provider name from booking data
    final serviceProviderName = widget.booking.serviceProvider?['name'] ?? 'Service Provider';
    final serviceProviderId = widget.booking.serviceProviderId;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReviewFormDialog(
        booking: widget.booking,
        serviceProviderName: serviceProviderName,
        serviceProviderId: serviceProviderId,
      ),
    );
    
    // Handle the result
    if (result == true) {
      // Review submitted successfully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Refresh the booking data to show the new review
        await ref.read(bookingsProvider.notifier).fetchBookings();
        
        // Refresh the current page
        setState(() {});
        // Try to refresh review stats if ReviewsTab is present
        final reviewsTabState = context.findAncestorStateOfType<ConsumerState<ReviewsTab>>();
        if (reviewsTabState != null && reviewsTabState.mounted) {
          // ignore: invalid_use_of_protected_member
          (reviewsTabState as dynamic).refreshStats();
        }
      }
    }
  }

  // Helper methods
  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
      case BookingStatus.pending_modification:
      case BookingStatus.modification_requested:
        return Colors.orange;
      case BookingStatus.confirmed_awaiting_payment:
      case BookingStatus.confirmed_paid:
        return Colors.blue;
      case BookingStatus.in_progress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled_by_client:
      case BookingStatus.cancelled_by_provider:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.dispute_raised:
        return Colors.orange;
      case BookingStatus.dispute_resolved:
      case BookingStatus.refunded:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
        return Icons.schedule;
      case BookingStatus.confirmed_awaiting_payment:
      case BookingStatus.confirmed_paid:
        return Icons.check_circle;
      case BookingStatus.in_progress:
        return Icons.play_circle;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled_by_client:
      case BookingStatus.cancelled_by_provider:
        return Icons.cancel;
      case BookingStatus.rejected:
        return Icons.close;
      case BookingStatus.pending_modification:
      case BookingStatus.modification_requested:
        return Icons.edit;
      case BookingStatus.dispute_raised:
        return Icons.warning;
      case BookingStatus.dispute_resolved:
        return Icons.gavel;
      case BookingStatus.refunded:
        return Icons.money_off;
    }
  }

  String _getStatusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
        return 'Awaiting provider confirmation';
      case BookingStatus.confirmed_awaiting_payment:
        return 'Booking confirmed - payment required';
      case BookingStatus.confirmed_paid:
        return 'Booking confirmed and scheduled';
      case BookingStatus.in_progress:
        return 'Service is currently being provided';
      case BookingStatus.completed:
        return 'Service has been completed';
      case BookingStatus.cancelled_by_client:
      case BookingStatus.cancelled_by_provider:
        return 'Booking has been cancelled';
      case BookingStatus.rejected:
        return 'Booking has been rejected';
      case BookingStatus.pending_modification:
        return 'Modification request pending';
      case BookingStatus.modification_requested:
        return 'Modification requested by provider';
      case BookingStatus.dispute_raised:
        return 'Dispute has been raised';
      case BookingStatus.dispute_resolved:
        return 'Dispute has been resolved';
      case BookingStatus.refunded:
        return 'Payment has been refunded';
    }
  }

  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String _getServiceTypeName(ServiceType type) {
    switch (type) {
      case ServiceType.photography:
        return 'Photography';
      case ServiceType.makeup:
        return 'Makeup Artist';
      case ServiceType.decoration:
        return 'Decoration';
      case ServiceType.venue:
        return 'Venue';
      case ServiceType.catering:
        return 'Catering';
      case ServiceType.music:
        return 'Music';
      case ServiceType.planning:
        return 'Event Planning';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Import payment provider and navigate to payment screen
      final paymentNotifier = ref.read(paymentProvider.notifier);
      await paymentNotifier.initializePayment(widget.booking.id);
      
      final paymentState = ref.read(paymentProvider);
      
      if (paymentState.paymentUrl != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KhaltiPaymentScreen(
              paymentUrl: paymentState.paymentUrl!,
              bookingId: widget.booking.id,
              amount: widget.booking.totalAmount,
            ),
          ),
        );
        
        if (result == true) {
          // Payment successful - refresh bookings
          await ref.read(bookingsProvider.notifier).fetchBookings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment completed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Close booking detail page
          }
        } else {
          // Payment failed or cancelled
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment was cancelled or failed'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to get payment URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initialization failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
      case BookingStatus.pending_modification:
        return 'Pending';
      case BookingStatus.confirmed_awaiting_payment:
        return 'Confirmed';
      case BookingStatus.confirmed_paid:
        return 'Paid';
      case BookingStatus.in_progress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled_by_client:
      case BookingStatus.cancelled_by_provider:
        return 'Cancelled';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.refunded:
        return 'Refunded';
      case BookingStatus.dispute_raised:
        return 'Dispute Raised';
      case BookingStatus.dispute_resolved:
        return 'Dispute Resolved';
      default:
        return 'Unknown';
    }
  }
} 