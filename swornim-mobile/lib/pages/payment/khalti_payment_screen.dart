import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'package:swornim/pages/providers/payments/payment_provider.dart';
import 'package:swornim/pages/models/payment/payment_transaction.dart';
import 'package:swornim/pages/services/khalti_service.dart';
import 'dart:async';

class KhaltiPaymentScreen extends ConsumerStatefulWidget {
  final String paymentUrl;
  final String bookingId;
  final double amount;

  const KhaltiPaymentScreen({
    Key? key,
    required this.paymentUrl,
    required this.bookingId,
    required this.amount,
  }) : super(key: key);

  @override
  ConsumerState<KhaltiPaymentScreen> createState() => _KhaltiPaymentScreenState();
}

class _KhaltiPaymentScreenState extends ConsumerState<KhaltiPaymentScreen> {
  bool _isLoading = true;
  String? _error;
  Khalti? _khalti;
  bool _hasAttemptedVerification = false;
  Timer? _pollingTimer;
  bool _isPolling = false;
  
  // New state variables for instant feedback
  String? _currentStatus;
  String? _statusMessage;
  bool _showInstantFeedback = false;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePayment() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentStatus = null;
        _statusMessage = null;
        _showInstantFeedback = false;
      });

      final khaltiService = ref.read(khaltiServiceProvider);
      
      // Initialize payment with backend
      final initResult = await khaltiService.initializeKhaltiPayment(
        bookingId: widget.bookingId,
        amount: widget.amount,
        productName: 'Swornim Booking',
        productIdentity: widget.bookingId,
      );

      if (initResult['success'] == true) {
        // Start Khalti payment using SDK with enhanced callbacks
        final paymentResult = await khaltiService.startKhaltiPayment(
          pidx: initResult['pidx'],
          amount: widget.amount,
          productName: 'Swornim Booking',
          productIdentity: widget.bookingId,
          bookingId: widget.bookingId,
          onPaymentResult: _handlePaymentResult,
          onMessage: _handlePaymentMessage,
          onReturn: _handlePaymentReturn,
        );

        if (paymentResult['success'] == true) {
          setState(() {
            _khalti = paymentResult['khalti'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = paymentResult['error'] ?? 'Failed to start payment';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = initResult['message'] ?? 'Failed to initialize payment';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Enhanced callback handlers for instant user feedback
  void _handlePaymentResult(PaymentResult result, String? error) {
    print('KhaltiPaymentScreen: Payment result received - Status:  [38;5;2m${result.payload?.status} [0m, Error: $error');
    
    if (!mounted) return;
    
    setState(() {
      _showInstantFeedback = true;
      _isPolling = false;
    });
    
    if (error != null) {
      setState(() {
        _currentStatus = 'error';
        _statusMessage = error;
      });
      _showPaymentFailureDialog(error);
    } else {
      final status = result.payload?.status;
      if (status == 'Completed') {
        setState(() {
          _currentStatus = 'success';
          _statusMessage = 'Payment completed successfully!';
        });
        _showPaymentSuccessDialog();
      } else if (status == 'Failed') {
        setState(() {
          _currentStatus = 'error';
          _statusMessage = 'Payment failed';
        });
        _showPaymentFailureDialog('Payment was cancelled or failed');
      } else if (status == 'Pending') {
        setState(() {
          _currentStatus = 'pending';
          _statusMessage = 'Payment is being processed...';
        });
        // Start polling for status updates
        _startPolling();
      } else {
        setState(() {
          _currentStatus = 'unknown';
          _statusMessage = 'Payment status unclear';
        });
        _showPaymentFailureDialog('Payment status unclear');
      }
    }
  }

  void _handlePaymentMessage(String event, String? description) {
    print('KhaltiPaymentScreen: Payment message - Event: $event, Description: $description');
    
    if (!mounted) return;
    
    setState(() {
      _currentStatus = event.toLowerCase().contains('completed') ? 'success' : 
                      event.toLowerCase().contains('failed') ? 'error' : 
                      event.toLowerCase().contains('pending') ? 'pending' : 'info';
      _statusMessage = description ?? event;
    });
  }

  void _handlePaymentReturn() {
    print('KhaltiPaymentScreen: Payment return callback triggered');
    
    if (!mounted) return;
    
    // If we haven't received a payment result yet, start polling
    if (!_showInstantFeedback) {
      setState(() {
        _currentStatus = 'pending';
        _statusMessage = 'Checking payment status...';
        _isPolling = true;
      });
      _startPolling();
    }
  }

  void _startPayment() {
    if (_khalti != null) {
      setState(() {
        _currentStatus = 'processing';
        _statusMessage = 'Opening payment gateway...';
        _showInstantFeedback = false;
      });
      _khalti!.open(context);
    }
  }

  Future<void> _startPolling() async {
    if (_isPolling || _hasAttemptedVerification) return;
    
    setState(() {
      _isPolling = true;
    });
    
    print('PaymentManager: Starting payment status polling');
    int attempts = 0;
    const maxAttempts = 30; // 30 seconds max (reduced from 60)
    
    while (attempts < maxAttempts && mounted) {
      try {
        await Future.delayed(const Duration(seconds: 2)); // Poll every 2 seconds
        print('PaymentManager: Polling attempt ${attempts + 1}');
        
        final paymentNotifier = ref.read(paymentProvider.notifier);
        final status = await paymentNotifier.checkPaymentStatus(widget.bookingId);
        print('PaymentManager: Current payment status: $status');
        
        if (status == 'completed' || status == 'paid') {
          _hasAttemptedVerification = true;
          setState(() {
            _currentStatus = 'success';
            _statusMessage = 'Payment verified successfully!';
            _isPolling = false;
          });
          _showPaymentSuccessDialog();
          return;
        } else if (status == 'failed' || status == 'cancelled') {
          _hasAttemptedVerification = true;
          setState(() {
            _currentStatus = 'error';
            _statusMessage = 'Payment failed or was cancelled';
            _isPolling = false;
          });
          _showPaymentFailureDialog('Payment failed or was cancelled');
          return;
        }
        attempts++;
      } catch (e) {
        print('PaymentManager: Polling error: $e');
        attempts++;
      }
    }
    
    print('PaymentManager: Polling completed without definitive result');
    _hasAttemptedVerification = true;
    setState(() {
      _isPolling = false;
      _currentStatus = 'pending';
      _statusMessage = 'Payment status unclear - please check your booking';
    });
    _showPaymentSuccessWithManualCheck();
  }

  void _showPaymentSuccessDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful!'),
          ],
        ),
        content: const Text('Your payment has been processed and verified successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccessWithManualCheck() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.orange),
            SizedBox(width: 8),
            Text('Payment Processing'),
          ],
        ),
        content: const Text(
          'Your payment is still being processed. Please check your booking status in a few minutes. If you have any issues, please contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true); // Return success
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailureDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _refreshPayment() {
    setState(() {
      _error = null;
      _isLoading = true;
      _hasAttemptedVerification = false;
      _isPolling = false;
      _currentStatus = null;
      _statusMessage = null;
      _showInstantFeedback = false;
    });
    _pollingTimer?.cancel();
    _initializePayment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khalti Payment'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          if (_khalti != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshPayment,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced payment info header with instant feedback
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Amount: NPR ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_currentStatus != null)
                        Text(
                          _statusMessage ?? 'Processing payment...',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (_isLoading)
                        const Text(
                          'Initializing payment...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      if (_isPolling)
                        const Text(
                          'Checking payment status...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isPolling || _currentStatus == 'pending')
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.purple,
                    ),
                  ),
              ],
            ),
          ),
          // Payment content
          Expanded(
            child: _buildPaymentContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_currentStatus) {
      case 'success':
        return const Icon(Icons.check_circle, color: Colors.green, size: 24);
      case 'error':
        return const Icon(Icons.error, color: Colors.red, size: 24);
      case 'pending':
        return const Icon(Icons.pending, color: Colors.orange, size: 24);
      case 'processing':
        return const Icon(Icons.payment, color: Colors.purple, size: 24);
      default:
        return const Icon(Icons.payment, color: Colors.purple, size: 24);
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPaymentContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.purple,
            ),
            SizedBox(height: 16),
            Text(
              'Initializing Khalti payment...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    // Show instant feedback if available
    if (_showInstantFeedback && _currentStatus != null) {
      return _buildInstantFeedbackWidget();
    }

    // Payment ready to start
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.payment,
            size: 80,
            color: Colors.purple,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to Pay',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Click the button below to proceed with Khalti payment',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              onPressed: _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Pay with Khalti',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _startPolling,
            child: const Text('Check Payment Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstantFeedbackWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusIcon(),
          const SizedBox(height: 24),
          Text(
            _getStatusTitle(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _statusMessage ?? 'Processing payment...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_currentStatus == 'success')
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            )
          else if (_currentStatus == 'error')
            ElevatedButton(
              onPressed: _refreshPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  String _getStatusTitle() {
    switch (_currentStatus) {
      case 'success':
        return 'Payment Successful!';
      case 'error':
        return 'Payment Failed';
      case 'pending':
        return 'Payment Pending';
      case 'processing':
        return 'Processing Payment';
      default:
        return 'Payment Status';
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'The payment could not be initialized.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshPayment,
            child: const Text('Retry'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}