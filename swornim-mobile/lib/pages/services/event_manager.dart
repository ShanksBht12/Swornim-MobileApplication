// File: lib/services/event_manager.dart - COMPLETELY FIXED VERSION
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/models/events/event.dart';
import 'package:swornim/config/app_config.dart';

// Exception handling for events
class EventException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  EventException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'EventException: $message';
}

// Result wrapper for better error handling
class EventResult<T> {
  final T? data;
  final bool success;
  final String? error;
  final int? statusCode;

  const EventResult._({
    this.data,
    required this.success,
    this.error,
    this.statusCode,
  });

  factory EventResult.success(T data) => EventResult._(data: data, success: true);
  factory EventResult.error(String error, {int? statusCode}) => 
    EventResult._(success: false, error: error, statusCode: statusCode);

  bool get isError => !success;
}

// COMPLETELY FIXED Event Manager Service - No WidgetRef dependencies
class EventManager {
  // Use the most basic Ref type to avoid any casting issues
  final ProviderRef ref;
  static bool _isRefreshing = false;
  
  String get baseUrl => AppConfig.baseUrl;

  // Constructor that accepts ProviderRef directly
  EventManager(this.ref);

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

    print('[DEBUG] API REQUEST: $method $uri');
    if (body != null) print('[DEBUG] Request Body: $body');

    final authState = ref.read(authProvider);
    
    if (!authState.isLoggedIn || authState.accessToken == null) {
      await ref.read(authProvider.notifier).checkAndRestoreAuth();
      final updatedAuthState = ref.read(authProvider);
      if (!updatedAuthState.isLoggedIn || updatedAuthState.accessToken == null) {
        throw EventException('Not authenticated');
      }
      
      final headers = _getAuthHeaders(updatedAuthState.accessToken!);
      return await _executeRequest(method, uri, headers, body);
    }

    try {
      final headers = _getAuthHeaders(authState.accessToken!);
      http.Response response = await _executeRequest(method, uri, headers, body);

      print('[DEBUG] API RESPONSE: ${response.statusCode} ${response.body}');

      if (response.statusCode == 401 && !isRetry) {
        final newToken = await _refreshTokenSafely();
        
        if (newToken != null) {
          final newHeaders = _getAuthHeaders(newToken);
          response = await _executeRequest(method, uri, newHeaders, body);
          
          if (response.statusCode == 401) {
            await ref.read(authProvider.notifier).logout();
            throw EventException('Session expired. Please login again.');
          }
        } else {
          await ref.read(authProvider.notifier).logout();
          throw EventException('Session expired. Please login again.');
        }
      } else if (response.statusCode == 403) {
        throw EventException('Access denied. Insufficient permissions.');
      }

      return response;
    } catch (e) {
      print('[DEBUG] API ERROR: $e');
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

    print('[DEBUG] Executing HTTP $method $uri');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('[DEBUG] Raw HTTP Response: ${response.statusCode} ${response.body}');
    return response;
  }

  // Handle API response
  T _handleResponse<T>(http.Response response, T Function(dynamic) parser) {
    final int statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      try {
        final responseData = jsonDecode(response.body);
        return parser(responseData);
      } catch (e) {
        throw EventException('Failed to parse response: ${e.toString()}');
      }
    } else {
      Map<String, dynamic>? errorData;
      try {
        errorData = jsonDecode(response.body);
      } catch (e) {
        errorData = {'message': response.body};
      }
      
      throw EventException(
        errorData?['message'] ?? 'Request failed with status $statusCode',
        statusCode: statusCode,
        errors: errorData,
      );
    }
  }

  // CORE EVENT OPERATIONS

  // Create a new event
  Future<EventResult<Event>> createEvent(Event event) async {
    try {
      final response = await _makeRequest('POST', '/events/', body: event.toJson());
      
      final createdEvent = _handleResponse<Event?>(response, (data) {
        final eventData = data is Map ? data['data'] ?? data : data;
        return Event.fromJson(eventData);
      });

      if (createdEvent == null) {
        return EventResult.error('Failed to parse created event');
      }

      return EventResult.success(createdEvent);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to create event: ${e.toString()}');
    }
  }

  // Get organizer's events
  Future<EventResult<List<Event>>> getMyEvents({
    EventStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.name;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      
      final response = await _makeRequest('GET', '/events/my/', queryParams: queryParams);
      
      final events = _handleResponse<List<Event>>(response, (data) {
        final List<dynamic> results = data is Map ? data['results'] ?? data['data'] ?? data : data;
        return results.map((json) => Event.fromJson(json)).toList();
      });
      
      return EventResult.success(events);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to get my events: ${e.toString()}');
    }
  }

  // Get a single event by ID
  Future<EventResult<Event>> getEvent(String eventId) async {
    try {
      final response = await _makeRequest('GET', '/events/$eventId/');
      
      final event = _handleResponse<Event?>(response, (data) {
        final eventData = data is Map ? data['data'] ?? data : data;
        return Event.fromJson(eventData);
      });

      if (event == null) {
        return EventResult.error('Event not found');
      }

      return EventResult.success(event);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to fetch event: ${e.toString()}');
    }
  }

  // Update an existing event
  Future<EventResult<Event>> updateEvent(Event event) async {
    try {
      final response = await _makeRequest('PUT', '/events/${event.id}/', body: event.toJson());
      
      final updatedEvent = _handleResponse<Event?>(response, (data) {
        final eventData = data is Map ? data['data'] ?? data : data;
        return Event.fromJson(eventData);
      });

      if (updatedEvent == null) {
        return EventResult.error('Failed to parse updated event');
      }

      return EventResult.success(updatedEvent);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to update event: ${e.toString()}');
    }
  }

  // Delete an event
  Future<EventResult<void>> deleteEvent(String eventId) async {
    try {
      final response = await _makeRequest('DELETE', '/events/$eventId/');
      _handleResponse<void>(response, (data) => null);
      return EventResult.success(null);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to delete event: ${e.toString()}');
    }
  }

  // Get public events (for clients to browse and book tickets)
  Future<EventResult<List<Event>>> getPublicEvents({
    EventType? eventType,
    String? location,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'visibility': 'public',
        'status': 'published',
      };
      
      if (eventType != null) queryParams['event_type'] = eventType.name;
      if (location != null) queryParams['location'] = location;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      
      final response = await _makeRequest('GET', '/events/search', queryParams: queryParams);
      
      final events = _handleResponse<List<Event>>(response, (data) {
        final List<dynamic> results = data is Map ? data['results'] ?? data['data'] ?? data : data;
        return results.map((json) => Event.fromJson(json)).toList();
      });
      
      return EventResult.success(events);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to get public events: ${e.toString()}');
    }
  }

  // Search events (for clients to find events to book)
  Future<EventResult<List<Event>>> searchEvents({
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
        'visibility': 'public',
        'status': 'published',
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
      
      return EventResult.success(events);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to search events: ${e.toString()}');
    }
  }

  // EVENT MANAGEMENT OPERATIONS

  // Publish event (make it available for clients to book tickets)
  Future<EventResult<Event>> publishEvent(String eventId) async {
    try {
      final body = {
        'status': 'published',
        'visibility': 'public',
      };
      
      final response = await _makeRequest('PATCH', '/events/$eventId/', body: body);
      
      final event = _handleResponse<Event?>(response, (data) {
        final eventData = data is Map ? data['data'] ?? data : data;
        return Event.fromJson(eventData);
      });

      if (event == null) {
        return EventResult.error('Failed to publish event');
      }

      return EventResult.success(event);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to publish event: ${e.toString()}');
    }
  }

  // Cancel event
  Future<EventResult<Event>> cancelEvent(String eventId, {String? reason}) async {
    try {
      final body = {
        'status': 'cancelled',
        'cancellation_reason': reason,
      };
      
      final response = await _makeRequest('PATCH', '/events/$eventId/', body: body);
      
      final event = _handleResponse<Event?>(response, (data) {
        final eventData = data is Map ? data['data'] ?? data : data;
        return Event.fromJson(eventData);
      });

      if (event == null) {
        return EventResult.error('Failed to cancel event');
      }

      return EventResult.success(event);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to cancel event: ${e.toString()}');
    }
  }

  // Complete event
  Future<EventResult<Event>> completeEvent(String eventId) async {
    try {
      final body = {'status': 'completed'};
      
      final response = await _makeRequest('PATCH', '/events/$eventId/', body: body);
      
      final event = _handleResponse<Event?>(response, (data) {
        final eventData = data is Map ? data['data'] ?? data : data;
        return Event.fromJson(eventData);
      });

      if (event == null) {
        return EventResult.error('Failed to complete event');
      }

      return EventResult.success(event);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to complete event: ${e.toString()}');
    }
  }

  // Update event ticket information
  Future<EventResult<Event>> updateEventTicketInfo({
    required String eventId,
    int? maxCapacity,
    double? ticketPrice,
    bool? isTicketed,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (maxCapacity != null) body['max_capacity'] = maxCapacity;
      if (ticketPrice != null) body['ticket_price'] = ticketPrice;
      if (isTicketed != null) body['is_ticketed'] = isTicketed;
      
      final response = await _makeRequest('PATCH', '/events/$eventId/ticket-info/', body: body);
      
      final event = _handleResponse<Event?>(response, (data) {
        final eventData = data is Map ? data['data'] ?? data : data;
        return Event.fromJson(eventData);
      });

      if (event == null) {
        return EventResult.error('Failed to update ticket info');
      }

      return EventResult.success(event);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to update ticket info: ${e.toString()}');
    }
  }

  // ANALYTICS AND STATS

  // Get event statistics for organizer
  Future<EventResult<Map<String, dynamic>>> getEventStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();
      
      final response = await _makeRequest('GET', '/events/stats/', queryParams: queryParams);
      
      final stats = _handleResponse<Map<String, dynamic>>(response, (data) {
        return data is Map ? Map<String, dynamic>.from(data['data'] ?? data) : {};
      });
      
      return EventResult.success(stats);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to get event stats: ${e.toString()}');
    }
  }

  // Get event with booking statistics
  Future<EventResult<Map<String, dynamic>>> getEventWithBookingStats(String eventId) async {
    try {
      final response = await _makeRequest('GET', '/events/$eventId/with-stats/');
      
      final eventData = _handleResponse<Map<String, dynamic>>(response, (data) {
        return data is Map ? Map<String, dynamic>.from(data['data'] ?? data) : {};
      });
      
      return EventResult.success(eventData);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to fetch event with stats: ${e.toString()}');
    }
  }

  // Get event capacity and booking status
  Future<EventResult<Map<String, dynamic>>> getEventCapacityStatus(String eventId) async {
    try {
      final response = await _makeRequest('GET', '/events/$eventId/capacity/');
      
      final capacityData = _handleResponse<Map<String, dynamic>>(response, (data) {
        return data is Map ? Map<String, dynamic>.from(data['data'] ?? data) : {};
      });
      
      return EventResult.success(capacityData);
    } catch (e) {
      if (e is EventException) {
        return EventResult.error(e.message, statusCode: e.statusCode);
      }
      return EventResult.error('Failed to fetch capacity status: ${e.toString()}');
    }
  }

  // Create event with multipart/form-data (image/gallery upload)
  Future<void> createEventMultipart(Map<String, dynamic> data, {File? imageFile, List<File>? galleryFiles}) async {
    final authState = ref.read(authProvider);
    if (!authState.isLoggedIn || authState.accessToken == null) {
      throw EventException('Not authenticated');
    }
    final uri = Uri.parse('${AppConfig.baseUrl}/events/');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${authState.accessToken!}';
    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    if (galleryFiles != null && galleryFiles.isNotEmpty) {
      for (final file in galleryFiles) {
        request.files.add(await http.MultipartFile.fromPath('gallery', file.path));
      }
    }
    print('[DEBUG] Multipart Request: $uri');
    print('[DEBUG] Fields: ${request.fields}');
    print('[DEBUG] Files: ${request.files.map((f) => f.filename).toList()}');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('[DEBUG] Multipart Response: ${response.statusCode} ${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EventException('Failed to create event: ${response.body}');
    }
  }

  // Update event with multipart/form-data (image/gallery upload)
  Future<void> updateEventMultipart(String eventId, Map<String, dynamic> data, {File? imageFile, List<File>? galleryFiles}) async {
    final authState = ref.read(authProvider);
    if (!authState.isLoggedIn || authState.accessToken == null) {
      throw EventException('Not authenticated');
    }
    final uri = Uri.parse('${AppConfig.baseUrl}/events/$eventId/');
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer ${authState.accessToken!}';
    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    if (galleryFiles != null && galleryFiles.isNotEmpty) {
      for (final file in galleryFiles) {
        request.files.add(await http.MultipartFile.fromPath('gallery', file.path));
      }
    }
    print('[DEBUG] Multipart Request: $uri');
    print('[DEBUG] Fields: ${request.fields}');
    print('[DEBUG] Files: ${request.files.map((f) => f.filename).toList()}');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('[DEBUG] Multipart Response: ${response.statusCode} ${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EventException('Failed to update event: ${response.body}');
    }
  }
}

// COMPLETELY FIXED PROVIDER - Uses explicit ProviderRef type
final eventManagerProvider = Provider<EventManager>((ProviderRef ref) => EventManager(ref));

// State providers for event operations
final myEventsProvider = FutureProvider.family<List<Event>, Map<String, dynamic>>((ref, params) async {
  final manager = ref.read(eventManagerProvider);
  final result = await manager.getMyEvents(
    status: params['status'],
    limit: params['limit'],
    offset: params['offset'],
  );
  
  if (result.isError) {
    throw EventException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? [];
});

final publicEventsProvider = FutureProvider.family<List<Event>, Map<String, dynamic>>((ref, params) async {
  final manager = ref.read(eventManagerProvider);
  final result = await manager.getPublicEvents(
    eventType: params['eventType'],
    location: params['location'],
    fromDate: params['fromDate'],
    toDate: params['toDate'],
    limit: params['limit'],
    offset: params['offset'],
  );
  
  if (result.isError) {
    throw EventException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? [];
});

final eventSearchProvider = FutureProvider.family<List<Event>, Map<String, dynamic>>((ref, params) async {
  final manager = ref.read(eventManagerProvider);
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
    throw EventException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? [];
});

final eventStatsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final manager = ref.read(eventManagerProvider);
  final result = await manager.getEventStats(
    fromDate: params['fromDate'],
    toDate: params['toDate'],
  );
  
  if (result.isError) {
    throw EventException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? {};
});

final singleEventProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final manager = ref.read(eventManagerProvider);
  final result = await manager.getEvent(eventId);
  
  if (result.isError) {
    throw EventException(result.error ?? 'Unknown error');
  }
  
  return result.data;
});