// File: lib/services/event_booking_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/events/event_booking.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/models/events/event.dart';
// import 'package:swornim/pages/models/events/event_booking.dart'; // Commented out because file does not exist
import 'package:swornim/config/app_config.dart';

// Exception handling for event bookings
class EventBookingException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  EventBookingException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'EventBookingException: $message';
}

// Result wrapper for better error handling
class EventBookingResult<T> {
  final T? data;
  final String? bookingId; // <-- add this
  final bool success;
  final String? error;
  final int? statusCode;

  const EventBookingResult._({
    this.data,
    this.bookingId,
    required this.success,
    this.error,
    this.statusCode,
  });

  factory EventBookingResult.success(T data, {String? bookingId}) =>
      EventBookingResult._(data: data, bookingId: bookingId, success: true);

  factory EventBookingResult.error(String error, {int? statusCode}) =>
      EventBookingResult._(success: false, error: error, statusCode: statusCode);

  bool get isError => !success;
}

// Event Booking Manager Service
class EventBookingManager {
  final Ref ref;
  static bool _isRefreshing = false;
  
  String get baseUrl => AppConfig.baseUrl;

  EventBookingManager(this.ref);

  // Get auth headers with proper token format
  Map<String, String> _getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Refresh token safely
  Future<String?> _refreshTokenSafely() async {
    if (_isRefreshing) {
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      final authState = ref.read(authProvider);
      return authState.accessToken;
    }

    _isRefreshing = true;
    try {
      final authNotifier = ref.read(authProvider.notifier);
      final refreshSuccess = await authNotifier.refreshToken();
      
      if (refreshSuccess) {
        final updatedState = ref.read(authProvider);
        return updatedState.accessToken;
      } else {
        await authNotifier.checkAndRestoreAuth();
        final restoredState = ref.read(authProvider);
        return restoredState.accessToken;
      }
    } catch (e) {
      print('Error during token refresh: $e');
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  // Make HTTP request with proper token handling
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool isRetry = false,
  }) async {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    var uri = Uri.parse('$baseUrl$cleanEndpoint');
    
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final authState = ref.read(authProvider);
    
    if (!authState.isLoggedIn || authState.accessToken == null) {
      await ref.read(authProvider.notifier).checkAndRestoreAuth();
      final updatedAuthState = ref.read(authProvider);
      if (!updatedAuthState.isLoggedIn || updatedAuthState.accessToken == null) {
        throw EventBookingException('Not authenticated');
      }
      
      final headers = _getAuthHeaders(updatedAuthState.accessToken!);
      return await _executeRequest(method, uri, headers, body);
    }

    try {
      final headers = _getAuthHeaders(authState.accessToken!);
      http.Response response = await _executeRequest(method, uri, headers, body);

      if (response.statusCode == 401 && !isRetry) {
        final newToken = await _refreshTokenSafely();
        
        if (newToken != null) {
          final newHeaders = _getAuthHeaders(newToken);
          response = await _executeRequest(method, uri, newHeaders, body);
          
          if (response.statusCode == 401) {
            await ref.read(authProvider.notifier).logout();
            throw EventBookingException('Session expired. Please login again.');
          }
        } else {
          await ref.read(authProvider.notifier).logout();
          throw EventBookingException('Session expired. Please login again.');
        }
      } else if (response.statusCode == 403) {
        throw EventBookingException('Access denied. Insufficient permissions.');
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Execute the actual HTTP request
  Future<http.Response> _executeRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
    final request = http.Request(method, uri);
    request.headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // Handle API response
  T _handleResponse<T>(http.Response response, T Function(dynamic) parser) {
    final int statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      try {
        final responseData = jsonDecode(response.body);
        return parser(responseData);
      } catch (e) {
        throw EventBookingException('Failed to parse response: ${e.toString()}');
      }
    } else {
      Map<String, dynamic>? errorData;
      try {
        errorData = jsonDecode(response.body);
      } catch (e) {
        errorData = {'message': response.body};
      }
      
      throw EventBookingException(
        errorData?['message'] ?? 'Request failed with status $statusCode',
        statusCode: statusCode,
        errors: errorData,
      );
    }
  }

  // BOOKING OPERATIONS

  // Book an event (create booking)
  Future<EventBookingResult<EventBooking?>> bookEvent({
    required String eventId,
    required EventTicketType ticketType,
    required int numberOfTickets,
    String? discountCode,
    String? specialRequests,
    Map<String, dynamic>? ticketHolderDetails,
  }) async {
    try {
      final body = {
        'event_id': eventId,
        'ticket_type': ticketType.name,
        'number_of_tickets': numberOfTickets,
        'discount_code': discountCode,
        'special_requests': specialRequests,
        'ticket_holder_details': ticketHolderDetails ?? {},
      };
      final response = await _makeRequest('POST', '/events/bookings/', body: body);
      print('[bookEvent] Backend response: ${response.body}');
      // First check if the response is successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        print('[bookEvent] Parsed response data: $responseData');
        // Check if we have a full booking object
        if (responseData is Map && 
            (responseData['data'] != null || 
             responseData['event_id'] != null || 
             responseData['id'] != null)) {
          try {
            final bookingData = responseData['data'] ?? responseData;
            final booking = EventBooking.fromJson(bookingData);
            return EventBookingResult.success(booking);
          } catch (parseError) {
            print('[bookEvent] Failed to parse as EventBooking: $parseError');
            // If parsing fails, check if we at least have a bookingId
            if (responseData['bookingId'] != null || responseData['id'] != null) {
              final bookingId = responseData['bookingId']?.toString() ?? 
                               responseData['id']?.toString();
              print('[bookEvent] Using bookingId: $bookingId');
              return EventBookingResult.success(null, bookingId: bookingId);
            }
          }
        } 
        // Check if only bookingId is present
        else if (responseData is Map && 
                 (responseData['bookingId'] != null || responseData['id'] != null)) {
          final bookingId = responseData['bookingId']?.toString() ?? 
                           responseData['id']?.toString();
          print('[bookEvent] Only bookingId returned: $bookingId');
          return EventBookingResult.success(null, bookingId: bookingId);
        }
        // Check for success message without full data
        else if (responseData is Map && 
                 (responseData['success'] == true || 
                  responseData['message']?.toString().toLowerCase().contains('success') == true)) {
          print('[bookEvent] Booking successful but minimal data returned');
          return EventBookingResult.success(null, bookingId: responseData['bookingId']?.toString());
        }
        // If we get here, we have a successful response but unexpected format
        print('[bookEvent] Unexpected successful response format: $responseData');
        return EventBookingResult.success(null, bookingId: responseData['id']?.toString());
      } else {
        // Handle error responses
        Map<String, dynamic>? errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {'message': response.body};
        }
        final errorMessage = errorData?['message'] ?? 
                            errorData?['error'] ?? 
                            'Request failed with status ${response.statusCode}';
        return EventBookingResult.error(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      print('[bookEvent] Exception caught: $e');
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to book event: ${e.toString()}');
    }
  }

  // Get client's bookings
  Future<EventBookingResult<List<EventBooking>>> getMyBookings({
    EventBookingStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.name;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      
      final response = await _makeRequest('GET', '/events/bookings/my/', queryParams: queryParams);
      
      final bookings = _handleResponse<List<EventBooking>>(response, (data) {
        final List<dynamic> results = data is Map ? data['results'] ?? data['data'] ?? data : data;
        return results.map((json) => EventBooking.fromJson(json)).toList();
      });
      
      return EventBookingResult.success(bookings);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to get bookings: ${e.toString()}');
    }
  }

  // Get single booking
  Future<EventBookingResult<EventBooking>> getBooking(String bookingId) async {
    try {
      final response = await _makeRequest('GET', '/events/bookings/$bookingId/');
      
      final booking = _handleResponse<EventBooking?>(response, (data) {
        final bookingData = data is Map ? data['data'] ?? data : data;
        return EventBooking.fromJson(bookingData);
      });

      if (booking == null) {
        return EventBookingResult.error('Booking not found');
      }

      return EventBookingResult.success(booking);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to fetch booking: ${e.toString()}');
    }
  }

  // Cancel booking
  Future<EventBookingResult<EventBooking>> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final body = {
        'status': 'cancelled',
        'cancellation_reason': reason,
      };
      
      final response = await _makeRequest('PATCH', '/events/bookings/$bookingId/', body: body);
      
      final booking = _handleResponse<EventBooking?>(response, (data) {
        final bookingData = data is Map ? data['data'] ?? data : data;
        return EventBooking.fromJson(bookingData);
      });

      if (booking == null) {
        return EventBookingResult.error('Failed to cancel booking');
      }

      return EventBookingResult.success(booking);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to cancel booking: ${e.toString()}');
    }
  }

  // PAYMENT OPERATIONS

  // Process payment for booking
  Future<EventBookingResult<EventBooking>> processPayment({
    required String bookingId,
    required String paymentMethod, // 'esewa', 'khalti', 'bank_transfer'
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final body = {
        'payment_method': paymentMethod,
        'payment_details': paymentDetails ?? {},
      };
      
      final response = await _makeRequest('POST', '/events/bookings/$bookingId/payment/', body: body);
      
      final booking = _handleResponse<EventBooking?>(response, (data) {
        final bookingData = data is Map ? data['data'] ?? data : data;
        return EventBooking.fromJson(bookingData);
      });

      if (booking == null) {
        return EventBookingResult.error('Failed to process payment');
      }

      return EventBookingResult.success(booking);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to process payment: ${e.toString()}');
    }
  }

  // Verify payment status
  Future<EventBookingResult<EventBooking>> verifyPayment(String bookingId) async {
    try {
      final response = await _makeRequest('GET', '/events/bookings/$bookingId/payment/verify/');
      
      final booking = _handleResponse<EventBooking?>(response, (data) {
        final bookingData = data is Map ? data['data'] ?? data : data;
        return EventBooking.fromJson(bookingData);
      });

      if (booking == null) {
        return EventBookingResult.error('Failed to verify payment');
      }

      return EventBookingResult.success(booking);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to verify payment: ${e.toString()}');
    }
  }

  // EVENT DISCOVERY FOR CLIENTS

  // Get available events for booking
  Future<EventBookingResult<List<Event>>> getAvailableEvents({
    EventType? eventType,
    String? location,
    DateTime? fromDate,
    DateTime? toDate,
    double? maxPrice,
    double? minPrice,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'status': 'published',
        'visibility': 'public',
      };
      
      if (eventType != null) queryParams['event_type'] = eventType.name;
      if (location != null) queryParams['location'] = location;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      
      final response = await _makeRequest('GET', '/events/available/', queryParams: queryParams);
      
      final events = _handleResponse<List<Event>>(response, (data) {
        final List<dynamic> results = data is Map ? data['results'] ?? data['data'] ?? data : data;
        return results.map((json) => Event.fromJson(json)).toList();
      });
      
      return EventBookingResult.success(events);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to get available events: ${e.toString()}');
    }
  }

  // Search events
  Future<EventBookingResult<List<Event>>> searchEvents({
    required String query,
    EventType? eventType,
    String? location,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
        'status': 'published',
        'visibility': 'public',
      };
      
      if (eventType != null) queryParams['event_type'] = eventType.name;
      if (location != null) queryParams['location'] = location;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      
      final response = await _makeRequest('GET', '/events/search/', queryParams: queryParams);
      
      final events = _handleResponse<List<Event>>(response, (data) {
        final List<dynamic> results = data is Map ? data['results'] ?? data['data'] ?? data : data;
        return results.map((json) => Event.fromJson(json)).toList();
      });
      
      return EventBookingResult.success(events);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to search events: ${e.toString()}');
    }
  }

  // Get event details with booking info
  Future<EventBookingResult<Map<String, dynamic>>> getEventBookingDetails(String eventId) async {
    try {
      final response = await _makeRequest('GET', '/events/$eventId/booking-details/');
      
      final details = _handleResponse<Map<String, dynamic>>(response, (data) {
        return data is Map ? Map<String, dynamic>.from(data['data'] ?? data) : {};
      });
      
      return EventBookingResult.success(details);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to get event booking details: ${e.toString()}');
    }
  }

  // NEW: Get paginated event booking details
  Future<EventBookingResult<Map<String, dynamic>>> getPaginatedEventBookingDetails(
    String eventId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _makeRequest(
        'GET',
        '/events/$eventId/booking-details/',
        queryParams: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final details = _handleResponse<Map<String, dynamic>>(response, (data) {
        return data is Map ? Map<String, dynamic>.from(data) : {};
      });

      return EventBookingResult.success(details);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to get paginated event booking details:  [${e.toString()}');
    }
  }

  // TICKET OPERATIONS

  // Get QR code for booking
  Future<EventBookingResult<String>> getTicketQRCode(String bookingId) async {
    try {
      final response = await _makeRequest('GET', '/events/bookings/$bookingId/qr-code/');
      
      final qrCode = _handleResponse<String>(response, (data) {
        return data is Map ? data['qr_code'] ?? '' : data.toString();
      });
      
      return EventBookingResult.success(qrCode);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to get QR code: ${e.toString()}');
    }
  }

  // Download ticket PDF
  Future<EventBookingResult<List<int>>> downloadTicket(String bookingId) async {
    try {
      final response = await _makeRequest('GET', '/events/bookings/$bookingId/ticket/');
      
      if (response.statusCode == 200) {
        return EventBookingResult.success(response.bodyBytes);
      } else {
        return EventBookingResult.error('Failed to download ticket');
      }
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to download ticket: ${e.toString()}');
    }
  }

  // ORGANIZER OPERATIONS (for event organizers to manage bookings)

  // Get bookings for organizer's events
  Future<EventBookingResult<List<EventBooking>>> getEventBookings({
    String? eventId,
    EventBookingStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (eventId != null) queryParams['event_id'] = eventId;
      if (status != null) queryParams['status'] = status.name;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      
      final response = await _makeRequest('GET', '/events/bookings/organizer/', queryParams: queryParams);
      
      final bookings = _handleResponse<List<EventBooking>>(response, (data) {
        final List<dynamic> results = data is Map ? data['results'] ?? data['data'] ?? data : data;
        return results.map((json) => EventBooking.fromJson(json)).toList();
      });
      
      return EventBookingResult.success(bookings);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to get event bookings: ${e.toString()}');
    }
  }

  // Update booking status (for organizers)
  Future<EventBookingResult<EventBooking>> updateBookingStatus({
    required String bookingId,
    required EventBookingStatus status,
    String? notes,
  }) async {
    try {
      final body = {
        'status': status.name,
        'notes': notes,
      };
      
      final response = await _makeRequest('PATCH', '/events/bookings/$bookingId/status/', body: body);
      
      final booking = _handleResponse<EventBooking?>(response, (data) {
        final bookingData = data is Map ? data['data'] ?? data : data;
        return EventBooking.fromJson(bookingData);
      });

      if (booking == null) {
        return EventBookingResult.error('Failed to update booking status');
      }

      return EventBookingResult.success(booking);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to update booking status: ${e.toString()}');
    }
  }

  // Check-in attendee (scan QR code)
  Future<EventBookingResult<EventBooking>> checkInAttendee({
    required String bookingId,
    required String qrCode,
  }) async {
    try {
      final body = {
        'qr_code': qrCode,
        'status': 'attended',
      };
      
      final response = await _makeRequest('POST', '/events/bookings/$bookingId/checkin/', body: body);
      
      final booking = _handleResponse<EventBooking?>(response, (data) {
        final bookingData = data is Map ? data['data'] ?? data : data;
        return EventBooking.fromJson(bookingData);
      });

      if (booking == null) {
        return EventBookingResult.error('Failed to check-in attendee');
      }

      return EventBookingResult.success(booking);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to check-in attendee: ${e.toString()}');
    }
  }

  // Get booking analytics for event
  Future<EventBookingResult<Map<String, dynamic>>> getBookingAnalytics(String eventId) async {
    try {
      final response = await _makeRequest('GET', '/events/$eventId/booking-analytics/');
      
      final analytics = _handleResponse<Map<String, dynamic>>(response, (data) {
        return data is Map ? Map<String, dynamic>.from(data['data'] ?? data) : {};
      });
      
      return EventBookingResult.success(analytics);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to get booking analytics: ${e.toString()}');
    }
  }

  // DISCOUNT OPERATIONS

  // Apply discount code
  Future<EventBookingResult<Map<String, dynamic>>> applyDiscountCode({
    required String eventId,
    required String discountCode,
    required int numberOfTickets,
  }) async {
    try {
      final body = {
        'event_id': eventId,
        'discount_code': discountCode,
        'number_of_tickets': numberOfTickets,
      };
      
      final response = await _makeRequest('POST', '/events/discount/apply/', body: body);
      
      final discountInfo = _handleResponse<Map<String, dynamic>>(response, (data) {
        return data is Map ? Map<String, dynamic>.from(data['data'] ?? data) : {};
      });
      
      return EventBookingResult.success(discountInfo);
    } catch (e) {
      if (e is EventBookingException) {
        return EventBookingResult.error(e.message, statusCode: e.statusCode);
      }
      return EventBookingResult.error('Failed to apply discount code: ${e.toString()}');
    }
  }
}

// Provider for EventBookingManager
final eventBookingManagerProvider = Provider<EventBookingManager>((ref) {
  return EventBookingManager(ref);
});

// State providers for event booking operations
final myBookingsProvider = FutureProvider.family<List<EventBooking>, Map<String, dynamic>>((ref, params) async {
  final manager = ref.read(eventBookingManagerProvider);
  final result = await manager.getMyBookings(
    status: params['status'],
    limit: params['limit'],
    offset: params['offset'],
  );
  
  if (result.isError) {
    throw EventBookingException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? [];
});

final availableEventsProvider = FutureProvider.family<List<Event>, Map<String, dynamic>>((ref, params) async {
  final manager = ref.read(eventBookingManagerProvider);
  final result = await manager.getAvailableEvents(
    eventType: params['eventType'],
    location: params['location'],
    fromDate: params['fromDate'],
    toDate: params['toDate'],
    maxPrice: params['maxPrice'],
    minPrice: params['minPrice'],
    limit: params['limit'],
    offset: params['offset'],
  );
  
  if (result.isError) {
    throw EventBookingException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? [];
});

final eventSearchProvider = FutureProvider.family<List<Event>, Map<String, dynamic>>((ref, params) async {
  final manager = ref.read(eventBookingManagerProvider);
  final result = await manager.searchEvents(
    query: params['query'] ?? '',
    eventType: params['eventType'],
    location: params['location'],
    fromDate: params['fromDate'],
    toDate: params['toDate'],
    limit: params['limit'],
    offset: params['offset'],
  );
  
  if (result.isError) {
    throw EventBookingException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? [];
});

final singleBookingProvider = FutureProvider.family<EventBooking?, String>((ref, bookingId) async {
  final manager = ref.read(eventBookingManagerProvider);
  final result = await manager.getBooking(bookingId);
  
  if (result.isError) {
    throw EventBookingException(result.error ?? 'Unknown error');
  }
  
  return result.data;
});

final eventBookingDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, eventId) async {
  final manager = ref.read(eventBookingManagerProvider);
  final result = await manager.getEventBookingDetails(eventId);
  
  if (result.isError) {
    throw EventBookingException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? {};
});

// NEW: Provider for paginated event booking details
final paginatedEventBookingDetailsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final manager = ref.read(eventBookingManagerProvider);
  final result = await manager.getPaginatedEventBookingDetails(
    params['eventId'],
    page: params['page'] ?? 1,
    limit: params['limit'] ?? 20,
  );

  if (result.isError) {
    throw EventBookingException(result.error ?? 'Unknown error');
  }

  return result.data ?? {};
});

// For organizers - get bookings for their events
final organizerBookingsProvider = FutureProvider.family<List<EventBooking>, Map<String, dynamic>>((ref, params) async {
  final manager = ref.read(eventBookingManagerProvider);
  final result = await manager.getEventBookings(
    eventId: params['eventId'],
    status: params['status'],
    limit: params['limit'],
    offset: params['offset'],
  );
  
  if (result.isError) {
    throw EventBookingException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? [];
});

final bookingAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, eventId) async {
  final manager = ref.read(eventBookingManagerProvider);
  final result = await manager.getBookingAnalytics(eventId);
  
  if (result.isError) {
    throw EventBookingException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? {};
});