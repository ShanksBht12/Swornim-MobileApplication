import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/models/bookings/service_package.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/config/app_config.dart';
import 'booking_factory.dart';

class BookingManager {
  final Ref ref;
  BookingManager(this.ref);

  // For Android emulator - 10.0.2.2 maps to host's localhost
  final String baseUrl = AppConfig.bookingsUrl;

  // Enhanced test method with better debugging
  Future<bool> testServerConnection() async {
    try {
      print('BookingManager: Testing server connection...');
      print('BookingManager: Testing URL: $baseUrl');
      
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      print('BookingManager: Test headers: $headers');
      
      // First, try a simple health check without auth
      try {
        print('BookingManager: Attempting basic connectivity test...');
        final basicResponse = await http.get(
          Uri.parse('${AppConfig.bookingsUrl}'),
        ).timeout(const Duration(seconds: 5));
        print('BookingManager: Basic connectivity test - Status: ${basicResponse.statusCode}');
      } catch (e) {
        print('BookingManager: Basic connectivity failed: $e');
        print('BookingManager: This suggests the backend server is not running or not accessible');
        return false;
      }
      
      // Now try the actual endpoint
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      print('BookingManager: Server test response: ${response.statusCode}');
      print('BookingManager: Response headers: ${response.headers}');
      print('BookingManager: Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      
      // Consider both 200 (success) and 401 (unauthorized but server reachable) as good
      final isReachable = response.statusCode == 200 || response.statusCode == 401;
      print('BookingManager: Server is reachable: $isReachable');
      return isReachable;
      
    } on SocketException catch (e) {
      print('BookingManager: Socket error - Backend server is likely not running');
      print('BookingManager: Error details: $e');
      return false;
    } on HttpException catch (e) {
      print('BookingManager: HTTP error: $e');
      return false;
    } on FormatException catch (e) {
      print('BookingManager: Format error: $e');
      return false;
    } catch (e) {
      print('BookingManager: Server connection test failed: $e');
      print('BookingManager: Error type: ${e.runtimeType}');
      return false;
    }
  }

  Future<Booking> createBooking(BookingRequest request) async {
    try {
      print('BookingManager: Starting createBooking request');
      print('BookingManager: URL: $baseUrl');
      print('BookingManager: Request body: ${jsonEncode(request.toJson())}');
      
      final headers = ref.read(authProvider.notifier).getAuthHeaders();
      print('BookingManager: Headers: $headers');
      
      print('BookingManager: Sending HTTP POST request...');
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('BookingManager: Request timed out after 30 seconds');
          throw Exception('Request timed out. Please check if your backend server is running and accessible.');
        },
      );
      
      print('BookingManager: Response status: ${response.statusCode}');
      print('BookingManager: Response headers: ${response.headers}');
      print('BookingManager: Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        print('BookingManager: Successfully created booking');
        return BookingFactory.fromJson(json);
      } else {
        print('BookingManager: Failed to create booking - status: ${response.statusCode}, body: ${response.body}');
        throw Exception('Failed to create booking: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('BookingManager: Socket exception - Backend server is not running');
      print('BookingManager: Error details: $e');
      throw Exception('Cannot connect to backend server. Please ensure your backend is running on port 9009.');
    } on HttpException catch (e) {
      print('BookingManager: HTTP exception: $e');
      throw Exception('HTTP error: $e');
    } catch (e) {
      print('BookingManager: Exception during createBooking: $e');
      if (e is http.ClientException) {
        print('BookingManager: Network error - is the backend running?');
        throw Exception('Network error: Unable to connect to backend server. Please check if the server is running on port 9009.');
      }
      rethrow;
    }
  }

  /// Fetches all bookings for the currently authenticated user.
  /// The backend will automatically filter bookings based on the user's token.
  Future<List<Booking>> fetchMyBookings() async {
    final headers = ref.read(authProvider.notifier).getAuthHeaders();
    final currentUser = ref.read(authProvider).user;
    print('[BookingManager.fetchMyBookings] Outgoing token: ${headers['Authorization']}');
    print('[BookingManager.fetchMyBookings] Current user: ${currentUser?.id} (${currentUser?.userType})');
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => BookingFactory.fromJson(json)).toList();
    } else {
      print('Fetch my bookings failed: status=${response.statusCode}, body=${response.body}');
      throw Exception('Failed to fetch bookings for the user');
    }
  }

  /// Updates the status of a specific booking.
  Future<Booking> updateBookingStatus(String bookingId, String newStatus, {String? reason}) async {
    final headers = ref.read(authProvider.notifier).getAuthHeaders();
    final body = <String, dynamic>{'status': newStatus};
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }
    final response = await http.patch(
      Uri.parse('$baseUrl/$bookingId/status'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return BookingFactory.fromJson(json);
    } else {
      print('Update booking status failed: status= [200m${response.statusCode} [0m, body=${response.body}');
      throw Exception('Failed to update booking status: ${response.body}');
    }
  }

  Future<Booking> updateBooking(String id, Map<String, dynamic> updates) async {
    final headers = ref.read(authProvider.notifier).getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode(updates),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return BookingFactory.fromJson(json);
    } else {
      throw Exception('Failed to update booking');
    }
  }

  Future<void> deleteBooking(String id) async {
    final headers = ref.read(authProvider.notifier).getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete booking');
    }
  }
}