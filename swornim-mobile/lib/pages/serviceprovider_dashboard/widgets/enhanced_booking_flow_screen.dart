import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/providers/bookings/enhanced_booking_manager.dart';
import 'package:swornim/pages/providers/payments/payment_provider.dart';
import 'package:swornim/pages/payment/khalti_payment_screen.dart';
import 'package:swornim/pages/providers/bookings/bookings_provider.dart';

class EnhancedBookingFlowScreen extends ConsumerStatefulWidget {
  final Booking booking;

  const EnhancedBookingFlowScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  ConsumerState<EnhancedBookingFlowScreen> createState() => _EnhancedBookingFlowScreenState();
}

class _EnhancedBookingFlowScreenState extends ConsumerState<EnhancedBookingFlowScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.read(authProvider).user;
    final isProvider = currentUser?.userType != UserType.client;
    final isClient = currentUser?.userType == UserType.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildBookingDetailsCard(),
            const SizedBox(height: 16),
            _buildActionButtons(isProvider, isClient),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final theme = Theme.of(context);
    final status = widget.booking.status;
    final paymentStatus = widget.booking.paymentStatus;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusDisplayText(status),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusDescription(status),
              style: theme.textTheme.bodyMedium,
            ),
            if (paymentStatus != PaymentStatus.pending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _getPaymentStatusIcon(paymentStatus),
                    color: _getPaymentStatusColor(paymentStatus),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Payment: ${_getPaymentStatusText(paymentStatus)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getPaymentStatusColor(paymentStatus),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    final theme = Theme.of(context);
    final booking = widget.booking;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Service Type', _getServiceTypeName(booking.serviceType)),
            _buildDetailRow('Event Date', booking.formattedEventDate),
            _buildDetailRow('Event Time', booking.eventTime),
            _buildDetailRow('Event Location', booking.eventLocation),
            _buildDetailRow('Event Type', booking.eventType),
            _buildDetailRow('Total Amount', booking.formattedAmount),
            if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty)
              _buildDetailRow('Special Requests', booking.specialRequests!),
            if (booking.packageSnapshot != null) ...[
              const SizedBox(height: 8),
              Text(
                'Package: ${booking.packageName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isProvider, bool isClient) {
    final status = widget.booking.status;
    final actions = <Widget>[];

    if (isProvider) {
      // Provider actions
      switch (status) {
        case BookingStatus.pending_provider_confirmation:
          actions.addAll([
            _buildActionButton(
              'Accept Booking',
              Icons.check_circle,
              Colors.green,
              () => _confirmBooking(),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Reject Booking',
              Icons.cancel,
              Colors.red,
              () => _rejectBooking(),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Request Modifications',
              Icons.edit,
              Colors.orange,
              () => _requestModification(),
            ),
          ]);
          break;
        case BookingStatus.confirmed_paid:
          actions.add(
            _buildActionButton(
              'Start Service',
              Icons.play_circle,
              Colors.blue,
              () => _startService(),
            ),
          );
          break;
        case BookingStatus.in_progress:
          actions.add(
            _buildActionButton(
              'Complete Service',
              Icons.check_circle,
              Colors.green,
              () => _completeService(),
            ),
          );
          break;
        default:
          break;
      }
    } else if (isClient) {
      // Client actions
      switch (status) {
        case BookingStatus.modification_requested:
          actions.addAll([
            _buildActionButton(
              'Accept Modifications',
              Icons.check_circle,
              Colors.green,
              () => _respondToModification(true),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Reject Modifications',
              Icons.cancel,
              Colors.red,
              () => _respondToModification(false),
            ),
          ]);
          break;
        case BookingStatus.confirmed_awaiting_payment:
          actions.add(
            _buildActionButton(
              'Pay Now',
              Icons.payment,
              Colors.green,
              () => _initiatePayment(),
            ),
          );
          break;
        default:
          break;
      }

      // Common client actions
      if ([
        BookingStatus.pending_provider_confirmation,
        BookingStatus.confirmed_awaiting_payment,
        BookingStatus.confirmed_paid,
      ].contains(status)) {
        actions.add(
          _buildActionButton(
            'Cancel Booking',
            Icons.cancel,
            Colors.red,
            () => _cancelBooking(),
          ),
        );
      }
    }

    // Common actions for both
    if ([
      BookingStatus.confirmed_paid,
      BookingStatus.in_progress,
      BookingStatus.completed,
    ].contains(status)) {
      actions.add(
        _buildActionButton(
          'Raise Dispute',
          Icons.warning,
          Colors.orange,
          () => _raiseDispute(),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actions,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final manager = ref.read(enhancedBookingManagerProvider);
      await manager.confirmBooking(widget.booking.id);
      // Force refetch bookings after confirmation
      await ref.read(bookingsProvider.notifier).fetchBookings();
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm booking: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectBooking() async {
    final reason = await _showReasonDialog('Rejection Reason');
    if (reason == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final manager = ref.read(enhancedBookingManagerProvider);
      await manager.rejectBooking(widget.booking.id, reason);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking rejected successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestModification() async {
    final modificationRequest = await _showModificationDialog();
    if (modificationRequest == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final manager = ref.read(enhancedBookingManagerProvider);
      await manager.requestModification(widget.booking.id, modificationRequest);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modification request sent successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _respondToModification(bool accepted) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final manager = ref.read(enhancedBookingManagerProvider);
      await manager.respondToModification(widget.booking.id, accepted);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accepted ? 'Modifications accepted' : 'Modifications rejected'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking() async {
    final reason = await _showReasonDialog('Cancellation Reason');
    if (reason == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final manager = ref.read(enhancedBookingManagerProvider);
      await manager.cancelBooking(widget.booking.id, reason);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startService() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final manager = ref.read(enhancedBookingManagerProvider);
      await manager.startService(widget.booking.id);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service started successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeService() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final manager = ref.read(enhancedBookingManagerProvider);
      await manager.completeService(widget.booking.id);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service completed successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initiatePayment() async {
    try {
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
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment completed successfully')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _raiseDispute() async {
    final disputeDetails = await _showDisputeDialog();
    if (disputeDetails == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final manager = ref.read(enhancedBookingManagerProvider);
      await manager.raiseDispute(widget.booking.id, disputeDetails);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute raised successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Dialog helpers
  Future<String?> _showReasonDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showModificationDialog() async {
    final controller = TextEditingController();
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Modifications'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Describe the modifications needed...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'description': controller.text.trim(),
              'requestedAt': DateTime.now().toIso8601String(),
            }),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showDisputeDialog() async {
    final controller = TextEditingController();
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raise Dispute'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Describe the issue...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'description': controller.text.trim(),
              'raisedAt': DateTime.now().toIso8601String(),
            }),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // Helper methods for status display
  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
        return Colors.orange;
      case BookingStatus.pending_modification:
        return Colors.amber;
      case BookingStatus.modification_requested:
        return Colors.deepOrange;
      case BookingStatus.confirmed_awaiting_payment:
        return Colors.blue;
      case BookingStatus.confirmed_paid:
        return Colors.green;
      case BookingStatus.in_progress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.teal;
      case BookingStatus.cancelled_by_client:
      case BookingStatus.cancelled_by_provider:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.refunded:
        return Colors.grey;
      case BookingStatus.dispute_raised:
        return Colors.orange;
      case BookingStatus.dispute_resolved:
        return Colors.indigo;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
        return Icons.schedule;
      case BookingStatus.pending_modification:
        return Icons.edit;
      case BookingStatus.modification_requested:
        return Icons.edit_note;
      case BookingStatus.confirmed_awaiting_payment:
        return Icons.payment;
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
      case BookingStatus.refunded:
        return Icons.money_off;
      case BookingStatus.dispute_raised:
        return Icons.warning;
      case BookingStatus.dispute_resolved:
        return Icons.gavel;
    }
  }

  String _getStatusDisplayText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
        return 'Pending Provider Confirmation';
      case BookingStatus.pending_modification:
        return 'Pending Modification';
      case BookingStatus.modification_requested:
        return 'Modification Requested';
      case BookingStatus.confirmed_awaiting_payment:
        return 'Confirmed - Awaiting Payment';
      case BookingStatus.confirmed_paid:
        return 'Confirmed & Paid';
      case BookingStatus.in_progress:
        return 'Service In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled_by_client:
        return 'Cancelled by Client';
      case BookingStatus.cancelled_by_provider:
        return 'Cancelled by Provider';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.refunded:
        return 'Refunded';
      case BookingStatus.dispute_raised:
        return 'Dispute Raised';
      case BookingStatus.dispute_resolved:
        return 'Dispute Resolved';
    }
  }

  String _getStatusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
        return 'Waiting for the service provider to review and confirm your booking request.';
      case BookingStatus.pending_modification:
        return 'The provider has requested modifications to your booking. Please review and respond.';
      case BookingStatus.modification_requested:
        return 'You have requested modifications to the booking. Waiting for client response.';
      case BookingStatus.confirmed_awaiting_payment:
        return 'Your booking has been confirmed! Please complete the payment to secure your booking.';
      case BookingStatus.confirmed_paid:
        return 'Payment completed! Your booking is confirmed and ready for service.';
      case BookingStatus.in_progress:
        return 'The service is currently being provided.';
      case BookingStatus.completed:
        return 'The service has been completed successfully.';
      case BookingStatus.cancelled_by_client:
        return 'This booking was cancelled by the client.';
      case BookingStatus.cancelled_by_provider:
        return 'This booking was cancelled by the service provider.';
      case BookingStatus.rejected:
        return 'This booking was rejected by the service provider.';
      case BookingStatus.refunded:
        return 'Payment has been refunded for this booking.';
      case BookingStatus.dispute_raised:
        return 'A dispute has been raised for this booking.';
      case BookingStatus.dispute_resolved:
        return 'The dispute has been resolved.';
    }
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.partiallyPaid:
        return Colors.amber;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.partiallyPaid:
        return Icons.payment;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.money_off;
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
} 