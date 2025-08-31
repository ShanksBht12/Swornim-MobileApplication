import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:swornim/pages/providers/bookings/bookings_provider.dart';
import 'package:swornim/pages/serviceprovider_dashboard/widgets/booking_detail_page.dart';
import 'package:swornim/pages/widgets/common/custom_text_field.dart'; // Added import for CustomTextField
import 'package:swornim/pages/widgets/review/review_form_dialog.dart'; // Added import for ReviewFormDialog

class BookingCard extends ConsumerWidget {
  final Booking booking;
  final User currentUser;

  const BookingCard({
    Key? key,
    required this.booking,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isProvider = currentUser.userType != UserType.client;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8), // horizontal margin removed
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16), // Slightly smaller radius
        child: InkWell(
          onTap: () => _navigateToDetailPage(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFFCFCFD),
                ],
              ),
              border: Border.all(
                color: _getStatusColor(booking.status).withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(booking.status).withOpacity(0.08),
                  offset: const Offset(0, 4), // Reduced shadow
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Status indicator line
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3, // Slightly thinner
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                
                // Main content
                Padding(
                  padding: const EdgeInsets.all(12), // Reduced padding
                  child: Row( // Changed from Column to Row for horizontal layout
                    children: [
                      // Left side - Event info
                      Expanded(
                        flex: 2,
                        child: _buildEventInfo(theme, colorScheme),
                      ),
                      
                      // Middle - Event details in compact format
                      Expanded(
                        flex: 2,
                        child: _buildCompactDetails(theme, colorScheme),
                      ),
                      
                      // Right side - Status and actions
                      Expanded(
                        flex: 1,
                        child: _buildStatusAndActions(context, ref, isProvider, theme, colorScheme),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventInfo(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Event icon - smaller
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getStatusColor(booking.status),
                _getStatusColor(booking.status).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getEventIcon(booking.eventType),
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        // Event details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                booking.eventType,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'ID: ${booking.id.substring(0, 6).toUpperCase()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDetails(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactDetailRow(
          Icons.calendar_today_rounded,
          booking.formattedEventDate,
          theme,
        ),
        const SizedBox(height: 4),
        _buildCompactDetailRow(
          Icons.access_time_rounded,
          booking.eventTime,
          theme,
        ),
        const SizedBox(height: 4),
        _buildCompactDetailRow(
          Icons.location_on_rounded,
          booking.eventLocation,
          theme,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildCompactDetailRow(
    IconData icon,
    String value,
    ThemeData theme, {
    int maxLines = 1,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: _getStatusColor(booking.status),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusAndActions(
    BuildContext context,
    WidgetRef ref,
    bool isProvider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status badge - smaller
        Container(
          constraints: const BoxConstraints(maxWidth: 70),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _getStatusColor(booking.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _getStatusDisplayName(booking.status),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 9,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Actions - compact buttons
        _buildCompactActions(context, ref, isProvider, theme, colorScheme),
      ],
    );
  }

  Widget _buildCompactActions(
    BuildContext context,
    WidgetRef ref,
    bool isProvider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final actions = _getActionsForStatus(isProvider);
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    if (actions.length == 1) {
      final action = actions.first;
      return _buildCompactActionButton(context, ref, action);
    }

    // For multiple actions, stack them vertically
    return Column(
      children: actions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildCompactActionButton(context, ref, action),
        );
      }).toList(),
    );
  }

  Widget _buildCompactActionButton(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> action,
  ) {
    final isPrimary = action['isPrimary'] == true;
    final color = action['color'] as Color;
    final isProviderCancel = action['providerCancel'] == true;
    
    return SizedBox(
      height: 24, // Fixed small height
      child: ElevatedButton(
        onPressed: () async {
          // Stop event propagation to prevent card navigation
          if (action['action'] == 'view_details') {
            _navigateToDetailPage(context);
          } else if (isProviderCancel) {
            final reason = await _showCancelReasonDialog(context);
            if (reason != null && reason.trim().isNotEmpty) {
              ref.read(bookingsProvider.notifier).updateBookingStatus(
                booking.id,
                action['status']!,
                reason: reason.trim(),
              );
            }
          } else {
            ref.read(bookingsProvider.notifier).updateBookingStatus(
              booking.id,
              action['status']!,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.white,
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: color.withOpacity(0.3), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          action['label']!,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Future<String?> _showCancelReasonDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancellation Reason'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Use CustomTextField for consistency
                  CustomTextField(
                    label: 'Reason',
                    hintText: 'Enter reason for cancellation',
                    controller: controller,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showReviewDialog(BuildContext context, WidgetRef ref) async {
    // Get service provider name from booking data
    final serviceProviderName = booking.serviceProvider?['name'] ?? 'Service Provider';
    final serviceProviderId = booking.serviceProviderId;
    
    await showDialog<bool>(
      context: context,
      builder: (context) => ReviewFormDialog(
        booking: booking,
        serviceProviderName: serviceProviderName,
        serviceProviderId: serviceProviderId,
      ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return Icons.favorite_rounded;
      case 'birthday':
        return Icons.cake_rounded;
      case 'corporate':
        return Icons.business_center_rounded;
      case 'party':
        return Icons.celebration_rounded;
      case 'conference':
        return Icons.groups_rounded;
      case 'meeting':
        return Icons.handshake_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String _getStatusDisplayName(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
        return 'PENDING';
      case BookingStatus.confirmed_awaiting_payment:
        return 'CONFIRMED';
      case BookingStatus.confirmed_paid:
        return 'PAID';
      case BookingStatus.in_progress:
        return 'IN PROGRESS';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled_by_client:
      case BookingStatus.cancelled_by_provider:
        return 'CANCELLED';
      case BookingStatus.rejected:
        return 'REJECTED';
      case BookingStatus.pending_modification:
      case BookingStatus.modification_requested:
        return 'MODIFICATION';
      case BookingStatus.dispute_raised:
        return 'DISPUTE';
      case BookingStatus.dispute_resolved:
        return 'RESOLVED';
      case BookingStatus.refunded:
        return 'REFUNDED';
      default:
        return status.name.toUpperCase();
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
      case BookingStatus.pending_modification:
      case BookingStatus.modification_requested:
        return const Color(0xFFEA580C); // Professional orange
      case BookingStatus.confirmed_awaiting_payment:
        return const Color(0xFF2563EB); // Your theme blue
      case BookingStatus.confirmed_paid:
        return const Color(0xFF059669); // Green for PAID
      case BookingStatus.in_progress:
        return const Color(0xFF0891B2); // Professional cyan
      case BookingStatus.completed:
        return const Color(0xFF059669); // Professional green
      case BookingStatus.cancelled_by_client:
      case BookingStatus.cancelled_by_provider:
      case BookingStatus.rejected:
        return const Color(0xFFDC2626); // Your theme red
      case BookingStatus.dispute_raised:
        return const Color(0xFFF59E0B); // Warning yellow
      case BookingStatus.dispute_resolved:
      case BookingStatus.refunded:
        return const Color(0xFF059669); // Success green
      default:
        return const Color(0xFF64748B); // Your theme gray
    }
  }

  List<Map<String, dynamic>> _getActionsForStatus(bool isProvider) {
    final status = booking.status;
    final actions = <Map<String, dynamic>>[];
    
    if (isProvider) {
      if (status == BookingStatus.pending_provider_confirmation) {
        actions.addAll([
          {
            'label': 'Accept',
            'status': 'confirmed_awaiting_payment',
            'color': const Color(0xFF059669),
            'icon': Icons.check_rounded,
            'isPrimary': true,
          },
          {
            'label': 'Reject',
            'status': 'rejected',
            'color': const Color(0xFFDC2626),
            'icon': Icons.close_rounded,
            'isPrimary': false,
          },
        ]);
      }
      if (status == BookingStatus.confirmed_paid) {
        actions.addAll([
          {
            'label': 'Start',
            'status': 'in_progress',
            'color': const Color(0xFF2563EB),
            'icon': Icons.play_arrow_rounded,
            'isPrimary': true,
          },
        ]);
      }
      if (status == BookingStatus.in_progress) {
        actions.addAll([
          {
            'label': 'Complete',
            'status': 'completed',
            'color': const Color(0xFF059669),
            'icon': Icons.check_circle_rounded,
            'isPrimary': true,
          },
        ]);
      }
      // Add cancel for provider on confirmed bookings
      if (status == BookingStatus.confirmed_awaiting_payment || status == BookingStatus.confirmed_paid) {
        actions.add({
          'label': 'Cancel',
          'status': 'cancelled_by_provider',
          'color': const Color(0xFFDC2626),
          'icon': Icons.cancel_rounded,
          'isPrimary': false,
          'providerCancel': true,
        });
      }
    } else {
      if (status == BookingStatus.pending_provider_confirmation || 
          status == BookingStatus.confirmed_awaiting_payment) {
        actions.addAll([
          {
            'label': 'Cancel',
            'status': 'cancelled_by_client',
            'color': const Color(0xFFDC2626),
            'icon': Icons.cancel_rounded,
            'isPrimary': false,
          },
        ]);
      }
    }

    // Add View Details action for all statuses
    actions.add({
      'label': 'Details',
      'action': 'view_details',
      'color': const Color(0xFF64748B),
      'icon': Icons.visibility_rounded,
      'isPrimary': false,
    });

    return actions;
  }

  void _navigateToDetailPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailPage(
          booking: booking,
          provider: currentUser,
        ),
      ),
    );
  }
}