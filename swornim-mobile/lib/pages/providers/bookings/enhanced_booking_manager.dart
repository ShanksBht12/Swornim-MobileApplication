import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/providers/bookings/booking_factory.dart';
import 'package:swornim/config/app_config.dart';

class EnhancedBookingManager {
  final Ref ref;
  EnhancedBookingManager(this.ref);

  final String baseUrl = AppConfig.bookingsUrl;

  // Provider confirms booking
  Future<Booking> confirmBooking(String bookingId) async {
    try {
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      print('Confirming booking: $bookingId');
      print('Headers: $headers');
      
      final response = await http.post(
        Uri.parse('$baseUrl/$bookingId/confirm'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Success response: $json');
        return BookingFactory.fromJson(json['data']);
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to confirm booking: ${response.body}');
      }
    } catch (e) {
      print('Exception during confirm booking: $e');
      throw Exception('Error confirming booking: $e');
    }
  }

  // Provider rejects booking
  Future<Booking> rejectBooking(String bookingId, String reason) async {
    try {
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$bookingId/reject'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BookingFactory.fromJson(json['data']);
      } else {
        throw Exception('Failed to reject booking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error rejecting booking: $e');
    }
  }

  // Provider requests modifications
  Future<Booking> requestModification(String bookingId, Map<String, dynamic> modificationRequest) async {
    try {
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$bookingId/request-modification'),
        headers: headers,
        body: jsonEncode({'modificationRequest': modificationRequest}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BookingFactory.fromJson(json['data']);
      } else {
        throw Exception('Failed to request modification: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error requesting modification: $e');
    }
  }

  // Client responds to modification request
  Future<Booking> respondToModification(String bookingId, bool accepted, {Map<String, dynamic>? modifications}) async {
    try {
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$bookingId/respond-modification'),
        headers: headers,
        body: jsonEncode({
          'response': {
            'accepted': accepted,
            'modifications': modifications,
          }
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BookingFactory.fromJson(json['data']);
      } else {
        throw Exception('Failed to respond to modification: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error responding to modification: $e');
    }
  }

  // Cancel booking
  Future<Booking> cancelBooking(String bookingId, String reason) async {
    try {
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$bookingId/cancel'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BookingFactory.fromJson(json['data']);
      } else {
        throw Exception('Failed to cancel booking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error cancelling booking: $e');
    }
  }

  // Start service
  Future<Booking> startService(String bookingId) async {
    try {
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$bookingId/start-service'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BookingFactory.fromJson(json['data']);
      } else {
        throw Exception('Failed to start service: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error starting service: $e');
    }
  }

  // Complete service
  Future<Booking> completeService(String bookingId) async {
    try {
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$bookingId/complete-service'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BookingFactory.fromJson(json['data']);
      } else {
        throw Exception('Failed to complete service: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error completing service: $e');
    }
  }

  // Raise dispute
  Future<Booking> raiseDispute(String bookingId, Map<String, dynamic> disputeDetails) async {
    try {
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$bookingId/raise-dispute'),
        headers: headers,
        body: jsonEncode({'disputeDetails': disputeDetails}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BookingFactory.fromJson(json['data']);
      } else {
        throw Exception('Failed to raise dispute: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error raising dispute: $e');
    }
  }

  // Get booking statistics
  Future<Map<String, dynamic>> getBookingStats() async {
    try {
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      } else {
        throw Exception('Failed to get booking stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting booking stats: $e');
    }
  }
}

// Provider
final enhancedBookingManagerProvider = Provider<EnhancedBookingManager>((ref) {
  return EnhancedBookingManager(ref);
}); 