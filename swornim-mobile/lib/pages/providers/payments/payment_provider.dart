import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/payment/payment_transaction.dart';
import 'package:swornim/pages/providers/payments/payment_manager.dart';

// Payment Manager Provider
final paymentManagerProvider = Provider<PaymentManager>((ref) {
  return PaymentManager(ref);
});

// Payment State
class PaymentState {
  final bool isLoading;
  final String? error;
  final PaymentTransaction? currentTransaction;
  final List<Map<String, dynamic>> paymentHistory;
  final String? paymentUrl;
  final bool isPaymentReady;
  final String? pidx;

  PaymentState({
    this.isLoading = false,
    this.error,
    this.currentTransaction,
    this.paymentHistory = const [],
    this.paymentUrl,
    this.isPaymentReady = false,
    this.pidx,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    PaymentTransaction? currentTransaction,
    List<Map<String, dynamic>>? paymentHistory,
    String? paymentUrl,
    bool? isPaymentReady,
    String? pidx,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentTransaction: currentTransaction ?? this.currentTransaction,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      isPaymentReady: isPaymentReady ?? this.isPaymentReady,
      pidx: pidx ?? this.pidx,
    );
  }
}

// Payment Notifier
class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentManager _paymentManager;

  PaymentNotifier(this._paymentManager) : super(PaymentState());

  // Initialize Khalti payment
  Future<void> initializePayment(String bookingId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _paymentManager.initializeKhaltiPayment(bookingId);
      // Fix: Extract paymentUrl from nested structure if needed
      String? paymentUrl = result['paymentUrl'];
      if (paymentUrl == null && result['data'] != null && result['data']['paymentUrl'] != null) {
        paymentUrl = result['data']['paymentUrl'];
      }
      print('PaymentNotifier: Extracted paymentUrl: $paymentUrl');
      state = state.copyWith(
        isLoading: false,
        paymentUrl: paymentUrl,
        pidx: result['pidx']?.toString() ?? '',
        isPaymentReady: true,
        currentTransaction: PaymentTransaction(
          id: result['transactionId']?.toString() ?? '',
          bookingId: bookingId,
          khaltiTransactionId: result['pidx']?.toString() ?? '',
          khaltiPaymentUrl: paymentUrl ?? '',
          amount: 0.0, // Will be updated when we get the transaction details
          status: PaymentTransactionStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Initialize Khalti payment with parameters for SDK
  Future<Map<String, dynamic>> initializePaymentWithParams({
    required String bookingId,
    required double amount,
    required String productName,
    required String productIdentity,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final result = await _paymentManager.initializeKhaltiPaymentWithParams(
        bookingId: bookingId,
        amount: amount,
        productName: productName,
        productIdentity: productIdentity,
      );
      
      if (result['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          paymentUrl: result['paymentUrl'],
          pidx: result['pidx'],
          isPaymentReady: true,
          currentTransaction: PaymentTransaction(
            id: result['transactionId'],
            bookingId: bookingId,
            khaltiTransactionId: result['pidx'],
            khaltiPaymentUrl: result['paymentUrl'],
            amount: amount,
            status: PaymentTransactionStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        return result;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Failed to initialize payment',
        );
        throw Exception(result['message'] ?? 'Failed to initialize payment');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Verify payment
  Future<void> verifyPayment(String pidx) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final result = await _paymentManager.verifyKhaltiPayment(pidx);
      
      if (result['success']) {
        // Update current transaction
        final transaction = state.currentTransaction?.copyWith(
          status: PaymentTransactionStatus.completed,
          completedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        state = state.copyWith(
          isLoading: false,
          currentTransaction: transaction,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Payment verification failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Get payment status
  Future<void> getPaymentStatus(String bookingId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final result = await _paymentManager.getPaymentStatus(bookingId);
      
      PaymentTransaction? transaction;
      if (result['latestTransaction'] != null) {
        transaction = PaymentTransaction.fromJson(result['latestTransaction']);
      }
      
      state = state.copyWith(
        isLoading: false,
        currentTransaction: transaction,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Check payment status (returns status string for polling)
  Future<String> checkPaymentStatus(String bookingId) async {
    try {
      final result = await _paymentManager.getPaymentStatus(bookingId);
      
      if (result['latestTransaction'] != null) {
        final transaction = PaymentTransaction.fromJson(result['latestTransaction']);
        return transaction.status.toString().split('.').last; // Returns 'completed', 'failed', etc.
      }
      
      return 'pending';
    } catch (e) {
      print('PaymentManager: Error checking payment status: $e');
      return 'error';
    }
  }

  // Get payment history
  Future<void> getPaymentHistory() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final history = await _paymentManager.getPaymentHistory();
      
      state = state.copyWith(
        isLoading: false,
        paymentHistory: history,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear current transaction
  void clearCurrentTransaction() {
    state = state.copyWith(
      currentTransaction: null,
      paymentUrl: null,
      isPaymentReady: false,
      pidx: null,
    );
  }

  // Reset state
  void reset() {
    state = PaymentState();
  }
}

// Payment Provider
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final paymentManager = ref.watch(paymentManagerProvider);
  return PaymentNotifier(paymentManager);
});

// Payment Status Provider (for specific booking)
final paymentStatusProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, bookingId) async {
  final paymentManager = ref.read(paymentManagerProvider);
  return await paymentManager.getPaymentStatus(bookingId);
});

// Payment History Provider
final paymentHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final paymentManager = ref.read(paymentManagerProvider);
  return await paymentManager.getPaymentHistory();
}); 