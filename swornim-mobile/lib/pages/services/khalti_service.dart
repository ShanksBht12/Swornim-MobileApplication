import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/config/app_config.dart';

// Callback function types for better type safety
typedef PaymentResultCallback = void Function(PaymentResult result, String? error);
typedef PaymentMessageCallback = void Function(String event, String? description);
typedef PaymentReturnCallback = void Function();

class KhaltiService {
  final Ref ref;
  
  KhaltiService(this.ref);

  final String baseUrl = AppConfig.paymentsUrl;

  // Initialize Khalti payment
  Future<Map<String, dynamic>> initializeKhaltiPayment({
    required String bookingId,
    required double amount,
    required String productName,
    required String productIdentity,
  }) async {
    if (bookingId.isEmpty) {
      throw Exception('Invalid booking ID for payment initialization');
    }
    try {
      print('KhaltiService: Initializing Khalti payment for booking: $bookingId');
      
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final url = '$baseUrl/$bookingId/init-khalti';
      
      // Backend handles the Khalti API call, so we don't need to send these parameters
      // The backend will create the proper Khalti request
      final requestBody = {};
      
      print('KhaltiService: POST $url');
      print('KhaltiService: Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('KhaltiService: Request timed out');
          throw Exception('Request timed out. Please check your connection.');
        },
      );
      
      print('KhaltiService: Response status: ${response.statusCode}');
      print('KhaltiService: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('KhaltiService: Payment initialized successfully');
        return json['data'];
      } else {
        String errorMsg = 'Failed to initialize payment';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {}
        
        print('KhaltiService: Failed to initialize payment: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('KhaltiService: Error initializing payment: $e');
      rethrow;
    }
  }

  // Start Khalti payment using Flutter SDK with enhanced callbacks
  Future<Map<String, dynamic>> startKhaltiPayment({
    required String pidx,
    required double amount,
    required String productName,
    required String productIdentity,
    required String bookingId,
    PaymentResultCallback? onPaymentResult,
    PaymentMessageCallback? onMessage,
    PaymentReturnCallback? onReturn,
  }) async {
    try {
      print('KhaltiService: Starting Khalti payment with pidx: $pidx');
      
      // Configure Khalti payment using the SDK
      final payConfig = KhaltiPayConfig(
        publicKey: 'dff4ba2bd4c54bfcad7962d4d4cd4717', // TODO: Replace with your actual Khalti sandbox public key
        pidx: pidx,
        openInKhalti: false, // Use WebView for better control
        environment: Environment.test, // Use test for sandbox testing
      );

      // Create Khalti instance with enhanced callbacks
      final khalti = await Khalti.init(
        payConfig: payConfig,
        onPaymentResult: (paymentResult, khalti) async {
          print('KhaltiService: Payment result received: $paymentResult');
          
          try {
            // Instant user feedback based on SDK result
            final status = paymentResult.payload?.status;
            final pidx = paymentResult.payload?.pidx;
            
            if (status == 'Completed' && pidx != null) {
              print('KhaltiService: Payment completed successfully in SDK');
              
              // Call the callback for instant UI feedback
              onPaymentResult?.call(paymentResult, null);
              
              // Verify with backend for final confirmation
              await _verifyPaymentWithBackend(pidx, bookingId);
              
            } else if (status == 'Failed') {
              print('KhaltiService: Payment failed in SDK');
              onPaymentResult?.call(paymentResult, 'Payment was cancelled or failed');
              
            } else if (status == 'Pending') {
              print('KhaltiService: Payment is pending');
              onPaymentResult?.call(paymentResult, 'Payment is being processed');
              
            } else {
              print('KhaltiService: Unknown payment status: $status');
              onPaymentResult?.call(paymentResult, 'Payment status unclear');
            }
          } catch (e) {
            print('KhaltiService: Error handling payment result: $e');
            onPaymentResult?.call(paymentResult, 'Error processing payment result');
          }
        },
        onMessage: (khalti, {statusCode, description, event, needsPaymentConfirmation}) async {
          print('KhaltiService: Message received - Event: $event, Description: $description');
          
          // Handle specific events for better user feedback
          final eventString = event?.toString() ?? 'UNKNOWN';
          final descriptionString = description?.toString();
          
          switch (eventString) {
            case 'PAYMENT_INITIATED':
              onMessage?.call('PAYMENT_INITIATED', 'Payment process started');
              break;
            case 'PAYMENT_PROCESSING':
              onMessage?.call('PAYMENT_PROCESSING', 'Payment is being processed');
              break;
            case 'PAYMENT_COMPLETED':
              onMessage?.call('PAYMENT_COMPLETED', 'Payment completed successfully');
              break;
            case 'PAYMENT_FAILED':
              onMessage?.call('PAYMENT_FAILED', descriptionString ?? 'Payment failed');
              break;
            case 'PAYMENT_CANCELLED':
              onMessage?.call('PAYMENT_CANCELLED', 'Payment was cancelled');
              break;
            default:
              onMessage?.call(eventString, descriptionString);
          }
        },
        onReturn: () async {
          print('KhaltiService: Return callback triggered');
          onReturn?.call();
        },
        enableDebugging: true,
      );

      return {
        'khalti': khalti,
        'pidx': pidx,
        'success': true,
      };
    } catch (e) {
      print('KhaltiService: Error starting payment: $e');
      rethrow;
    }
  }

  // Enhanced backend verification with proper error handling
  Future<Map<String, dynamic>> _verifyPaymentWithBackend(String pidx, String bookingId) async {
    try {
      print('KhaltiService: Verifying payment with backend - pidx: $pidx, bookingId: $bookingId');
      
      // First verify with Khalti's verification endpoint
      final verificationResult = await verifyKhaltiPayment(pidx);
      
      if (verificationResult['success'] == true) {
        print('KhaltiService: Payment verified successfully with Khalti');
        
        // Update booking status in our backend
        await _updateBookingPaymentStatus(bookingId, 'completed', pidx);
        
        return {
          'success': true,
          'message': 'Payment verified and booking updated successfully',
          'data': verificationResult['data'],
        };
      } else {
        print('KhaltiService: Payment verification failed');
        return {
          'success': false,
          'message': 'Payment verification failed',
          'data': verificationResult,
        };
      }
    } catch (e) {
      print('KhaltiService: Error in backend verification: $e');
      return {
        'success': false,
        'message': 'Error verifying payment: $e',
        'data': null,
      };
    }
  }

  // Update booking payment status in backend
  Future<void> _updateBookingPaymentStatus(String bookingId, String status, String pidx) async {
    try {
      print('KhaltiService: Updating booking payment status - bookingId: $bookingId, status: $status');
      
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final url = '$baseUrl/$bookingId/update-status';
      
      final requestBody = {
        'status': status,
        'pidx': pidx,
        'verified_at': DateTime.now().toIso8601String(),
      };
      
      print('KhaltiService: POST $url');
      print('KhaltiService: Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('KhaltiService: Update status request timed out');
          throw Exception('Update status request timed out.');
        },
      );
      
      print('KhaltiService: Update status response: ${response.statusCode}');
      print('KhaltiService: Update status body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('KhaltiService: Booking payment status updated successfully');
      } else {
        print('KhaltiService: Failed to update booking payment status');
        // Don't throw here as the payment is already verified with Khalti
      }
    } catch (e) {
      print('KhaltiService: Error updating booking payment status: $e');
      // Don't throw here as the payment is already verified with Khalti
    }
  }

  // Verify Khalti payment
  Future<Map<String, dynamic>> verifyKhaltiPayment(String pidx) async {
    try {
      print('KhaltiService: Verifying Khalti payment with pidx: $pidx');
      
      final url = '$baseUrl/verify';
      
      print('KhaltiService: POST $url');
      print('KhaltiService: Body: {"pidx": "$pidx"}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pidx': pidx}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('KhaltiService: Verification request timed out');
          throw Exception('Verification request timed out.');
        },
      );
      
      print('KhaltiService: Verification response status: ${response.statusCode}');
      print('KhaltiService: Verification response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('KhaltiService: Payment verification completed');
        return {
          'success': true,
          'data': json['data'],
        };
      } else {
        String errorMsg = 'Failed to verify payment';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {}
        
        print('KhaltiService: Failed to verify payment: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('KhaltiService: Error verifying payment: $e');
      return {
        'success': false,
        'message': 'Error verifying payment: $e',
      };
    }
  }

  // Get payment status for a booking
  Future<Map<String, dynamic>> getPaymentStatus(String bookingId) async {
    try {
      print('KhaltiService: Getting payment status for booking: $bookingId');
      
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final url = '$baseUrl/$bookingId/status';
      
      print('KhaltiService: GET $url');
      print('KhaltiService: Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('KhaltiService: Status request timed out');
          throw Exception('Status request timed out.');
        },
      );
      
      print('KhaltiService: Status response status: ${response.statusCode}');
      print('KhaltiService: Status response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('KhaltiService: Payment status retrieved successfully');
        return json['data'];
      } else {
        String errorMsg = 'Failed to get payment status';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {}
        
        print('KhaltiService: Failed to get payment status: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('KhaltiService: Error getting payment status: $e');
      rethrow;
    }
  }
}

// Provider for KhaltiService
final khaltiServiceProvider = Provider<KhaltiService>((ref) {
  return KhaltiService(ref);
}); 