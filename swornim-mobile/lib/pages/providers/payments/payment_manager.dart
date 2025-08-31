import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:swornim/pages/models/payment/payment_transaction.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/config/app_config.dart';

class PaymentManager {
  final Ref ref;
  PaymentManager(this.ref);

  String get baseUrl => AppConfig.paymentsUrl;

  // Initialize Khalti payment for a booking
  Future<Map<String, dynamic>> initializeKhaltiPayment(String bookingId) async {
    if (bookingId.isEmpty) {
      throw Exception('Invalid booking ID for payment initialization');
    }
    try {
      print('PaymentManager: Initializing Khalti payment for booking: $bookingId');
      
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final url = '$baseUrl/$bookingId/init-khalti';
      
      print('PaymentManager: POST $url');
      print('PaymentManager: Headers: $headers');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('PaymentManager: Request timed out');
          throw Exception('Request timed out. Please check your connection.');
        },
      );
      
      print('PaymentManager: Response status: ${response.statusCode}');
      print('PaymentManager: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('PaymentManager: Payment initialized successfully');
        return json['data'];
      } else {
        String errorMsg = 'Failed to initialize payment';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {}
        
        print('PaymentManager: Failed to initialize payment: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('PaymentManager: Error initializing payment: $e');
      rethrow;
    }
  }

  // Initialize Khalti payment with additional parameters for SDK
  Future<Map<String, dynamic>> initializeKhaltiPaymentWithParams({
    required String bookingId,
    required double amount,
    required String productName,
    required String productIdentity,
  }) async {
    if (bookingId.isEmpty) {
      throw Exception('Invalid booking ID for payment initialization');
    }
    try {
      print('PaymentManager: Initializing Khalti payment for booking: $bookingId');
      
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final url = '$baseUrl/$bookingId/init-khalti';
      
      final requestBody = {
        'amount': (amount * 100).toInt(), // Convert to paisa
        'product_name': productName,
        'product_identity': productIdentity,
        'customer_info': {
          'name': 'Customer',
          'email': 'customer@example.com',
          'phone': '9800000000',
        },
        'merchant_extra': {
          'booking_id': bookingId,
        },
      };
      
      print('PaymentManager: POST $url');
      print('PaymentManager: Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('PaymentManager: Request timed out');
          throw Exception('Request timed out. Please check your connection.');
        },
      );
      
      print('PaymentManager: Response status: ${response.statusCode}');
      print('PaymentManager: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('PaymentManager: Payment initialized successfully');
        return json['data'];
      } else {
        String errorMsg = 'Failed to initialize payment';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {}
        
        print('PaymentManager: Failed to initialize payment: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('PaymentManager: Error initializing payment: $e');
      rethrow;
    }
  }

  // Verify Khalti payment
  Future<Map<String, dynamic>> verifyKhaltiPayment(String pidx) async {
    try {
      print('PaymentManager: Verifying Khalti payment with pidx: $pidx');
      
      final url = '$baseUrl/verify';
      
      print('PaymentManager: POST $url');
      print('PaymentManager: Body: {"pidx": "$pidx"}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pidx': pidx}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('PaymentManager: Verification request timed out');
          throw Exception('Verification request timed out.');
        },
      );
      
      print('PaymentManager: Verification response status: ${response.statusCode}');
      print('PaymentManager: Verification response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('PaymentManager: Payment verification completed');
        return json['data'];
      } else {
        String errorMsg = 'Failed to verify payment';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {}
        
        print('PaymentManager: Failed to verify payment: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('PaymentManager: Error verifying payment: $e');
      rethrow;
    }
  }

  // Get payment status for a booking
  Future<Map<String, dynamic>> getPaymentStatus(String bookingId) async {
    try {
      print('PaymentManager: Getting payment status for booking: $bookingId');
      
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final url = '$baseUrl/$bookingId/status';
      
      print('PaymentManager: GET $url');
      print('PaymentManager: Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('PaymentManager: Status request timed out');
          throw Exception('Status request timed out.');
        },
      );
      
      print('PaymentManager: Status response status: ${response.statusCode}');
      print('PaymentManager: Status response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('PaymentManager: Payment status retrieved successfully');
        return json['data'];
      } else {
        String errorMsg = 'Failed to get payment status';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {}
        
        print('PaymentManager: Failed to get payment status: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('PaymentManager: Error getting payment status: $e');
      rethrow;
    }
  }

  // Get payment history for a user
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      print('PaymentManager: Getting payment history');
      
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final url = '$baseUrl/history';
      
      print('PaymentManager: GET $url');
      print('PaymentManager: Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('PaymentManager: History request timed out');
          throw Exception('History request timed out.');
        },
      );
      
      print('PaymentManager: History response status: ${response.statusCode}');
      print('PaymentManager: History response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('PaymentManager: Payment history retrieved successfully');
        return List<Map<String, dynamic>>.from(json['data']);
      } else {
        String errorMsg = 'Failed to get payment history';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {}
        
        print('PaymentManager: Failed to get payment history: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('PaymentManager: Error getting payment history: $e');
      rethrow;
    }
  }

  // Test server connection
  Future<bool> testServerConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.paymentsUrl}/history'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('PaymentManager: Server connection test failed: $e');
      return false;
    }
  }
} 