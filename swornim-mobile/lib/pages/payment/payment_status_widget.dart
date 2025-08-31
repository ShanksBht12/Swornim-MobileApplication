import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/payment/payment_transaction.dart';
import 'package:swornim/pages/providers/payments/payment_provider.dart';

class PaymentStatusWidget extends ConsumerWidget {
  final String bookingId;
  final double amount;

  const PaymentStatusWidget({
    Key? key,
    required this.bookingId,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentStatusAsync = ref.watch(paymentStatusProvider(bookingId));

    return paymentStatusAsync.when(
      data: (data) {
        final latestTransaction = data['latestTransaction'];
        final paymentStatus = data['paymentStatus'] ?? 'pending';
        final totalAmount = data['totalAmount'] ?? amount;
        final bookingId = this.bookingId;

        return Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPaymentStatusIcon(paymentStatus),
                          color: _getPaymentStatusColor(paymentStatus),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Status',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                _getPaymentStatusText(paymentStatus),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _getPaymentStatusColor(paymentStatus),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'NPR ${(totalAmount is num ? totalAmount : amount).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (latestTransaction != null) ...[
                      const SizedBox(height: 16),
                      _buildTransactionDetails(context, latestTransaction),
                    ],
                  ],
                ),
              ),
            ),
            if (paymentStatus.toLowerCase() != 'paid' && paymentStatus.toLowerCase() != 'completed')
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Manually refetch payment status
                    final paymentNotifier = ref.read(paymentProvider.notifier);
                    await paymentNotifier.getPaymentStatus(bookingId);
                    // Optionally, show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment status refreshed.')),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Payment Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading payment status...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to load payment status: $error',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(BuildContext context, Map<String, dynamic> transaction) {
    final status = transaction['status']?.toString().toLowerCase() ?? 'pending';
    final createdAt = DateTime.tryParse(transaction['created_at'] ?? transaction['createdAt'] ?? '');
    final completedAt = DateTime.tryParse(transaction['completed_at'] ?? transaction['completedAt'] ?? '');
    final failureReason = transaction['failure_reason'] ?? transaction['failureReason'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Transaction',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTransactionStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getTransactionStatusColor(status).withOpacity(0.3),
                ),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getTransactionStatusColor(status),
                ),
              ),
            ),
            const Spacer(),
            if (createdAt != null)
              Text(
                'Created: ${_formatDateTime(createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (completedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Completed: ${_formatDateTime(completedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (failureReason != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    failureReason,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      case 'refunded':
        return Icons.money_off;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Payment Completed';
      case 'pending':
        return 'Payment Pending';
      case 'failed':
        return 'Payment Failed';
      case 'refunded':
        return 'Payment Refunded';
      default:
        return 'Payment Status Unknown';
    }
  }

  Color _getTransactionStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 