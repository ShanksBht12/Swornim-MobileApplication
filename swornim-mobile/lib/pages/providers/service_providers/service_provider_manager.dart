// File: lib/services/service_provider_manager.dart - UPDATED FOR EVENT ORGANIZER
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_factory.dart';
import 'package:swornim/config/app_config.dart';

// Exception handling
class ServiceProviderException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ServiceProviderException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'ServiceProviderException: $message';
}

// Result wrapper for better error handling
class ServiceResult<T> {
  final T? data;
  final bool success;
  final String? error;
  final int? statusCode;

  const ServiceResult._({
    this.data,
    required this.success,
    this.error,
    this.statusCode,
  });

  factory ServiceResult.success(T data) => ServiceResult._(data: data, success: true);
  factory ServiceResult.error(String error, {int? statusCode}) => 
    ServiceResult._(success: false, error: error, statusCode: statusCode);

  bool get isError => !success;
}

// Unified Service Provider Manager
class ServiceProviderManager {
  final Ref ref;
  static bool _isRefreshing = false;
  
  // Use centralized config for base URL
  String get baseUrl => AppConfig.baseUrl;

  ServiceProviderManager(this.ref);

  // Get auth headers with proper token format
  Map<String, String> _getAuthHeaders(String token) {
    print('Getting auth headers with token: ${token.substring(0, 10)}...');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Refresh token with proper locking
  Future<String?> _refreshTokenSafely() async {
    // Prevent concurrent refresh attempts
    if (_isRefreshing) {
      // Wait for ongoing refresh to complete
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Return the current token after waiting
      final authState = ref.read(authProvider);
      return authState.accessToken;
    }

    _isRefreshing = true;
    try {
      print('Attempting to refresh token...');
      final authNotifier = ref.read(authProvider.notifier);
      final refreshSuccess = await authNotifier.refreshToken();
      
      if (refreshSuccess) {
        // Get the updated token
        final updatedState = ref.read(authProvider);
        print('Token refresh successful');
        return updatedState.accessToken;
      } else {
        print('Token refresh failed');
        // Try to restore session
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

  // Make HTTP request with proper token handling and retry logic
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool isRetry = false,
  }) async {
    // Ensure endpoint starts with /
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    var uri = Uri.parse('$baseUrl$cleanEndpoint');
    
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    print('Making request to: $uri');
    print('Method: $method');

    // Get current auth state
    final authState = ref.read(authProvider);
    print('Auth state: ${authState.isLoggedIn}');
    print('Access token exists: ${authState.accessToken != null}');
    
    if (!authState.isLoggedIn || authState.accessToken == null) {
      print('Not logged in or no access token, attempting to restore session...');
      // Try to restore session
      await ref.read(authProvider.notifier).checkAndRestoreAuth();
      
      // Get updated auth state
      final updatedAuthState = ref.read(authProvider);
      if (!updatedAuthState.isLoggedIn || updatedAuthState.accessToken == null) {
        print('Failed to restore session');
        throw ServiceProviderException('Not authenticated');
      }
      
      print('Session restored successfully');
      final headers = _getAuthHeaders(updatedAuthState.accessToken!);
      return await _executeRequest(method, uri, headers, body);
    }

    try {
      print('Using existing access token');
      final headers = _getAuthHeaders(authState.accessToken!);
      print('Request headers: $headers');
      http.Response response = await _executeRequest(method, uri, headers, body);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle 401 Unauthorized
      if (response.statusCode == 401 && !isRetry) {
        print('Received 401, attempting token refresh...');
        
        // Try to refresh token
        final newToken = await _refreshTokenSafely();
        
        if (newToken != null) {
          print('Token refreshed successfully, retrying request...');
          // Retry request with new token
          final newHeaders = _getAuthHeaders(newToken);
          response = await _executeRequest(method, uri, newHeaders, body);
          print('Retry response status: ${response.statusCode}');
          print('Retry response body: ${response.body}');
          
          if (response.statusCode == 401) {
            print('Retry failed with 401, logging out...');
            await ref.read(authProvider.notifier).logout();
            throw ServiceProviderException('Session expired. Please login again.');
          }
        } else {
          print('Token refresh failed, logging out...');
          await ref.read(authProvider.notifier).logout();
          throw ServiceProviderException('Session expired. Please login again.');
        }
      } else if (response.statusCode == 403) {
        print('Received 403 Forbidden');
        print('Response body: ${response.body}');
        throw ServiceProviderException('Access denied. Insufficient permissions.');
      }

      return response;
    } catch (e) {
      print('Request error: $e');
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
    print('Making $method request to: ${uri.toString()}');
    print('Headers: $headers');
    if (body != null) {
      print('Body: $body');
    }

    final request = http.Request(method, uri);
    request.headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    return response;
  }

  // Handle API response
  T _handleResponse<T>(http.Response response, T Function(dynamic) parser) {
    final int statusCode = response.statusCode;
    
    print('Response status: $statusCode');
    print('Response body: ${response.body}');
    
    if (statusCode >= 200 && statusCode < 300) {
      try {
        final responseData = jsonDecode(response.body);
        return parser(responseData);
      } catch (e) {
        throw ServiceProviderException('Failed to parse response: ${e.toString()}');
      }
    } else {
      Map<String, dynamic>? errorData;
      try {
        errorData = jsonDecode(response.body);
      } catch (e) {
        errorData = {'message': response.body};
      }
      
      throw ServiceProviderException(
        errorData?['message'] ?? 'Request failed with status $statusCode',
        statusCode: statusCode,
        errors: errorData,
      );
    }
  }

  // Get all service providers of a specific type
  Future<ServiceResult<List<ServiceProvider>>> getServiceProviders(
    ServiceProviderType type, {
    Map<String, String>? filters,
  }) async {
    try {
      final endpoint = ServiceProviderFactory.getApiEndpoint(type);
      print('Making request to: $baseUrl$endpoint');
      
      final response = await _makeRequest('GET', endpoint, queryParams: filters);
      print('Raw API response for type: ${type.name}\n${response.body}');
      
      final providers = _handleResponse<List<ServiceProvider>>(response, (data) {
        // For venues, handle nested structure
        if (type == ServiceProviderType.venue) {
          if (data is Map && data['data'] != null && data['data']['venues'] != null) {
            final venuesData = data['data']['venues'];
            if (venuesData is List) {
              return venuesData
                  .map((json) => ServiceProviderFactory.fromJson(json, type))
                  .where((provider) => provider != null)
                  .cast<ServiceProvider>()
                  .toList();
            } else {
              return <ServiceProvider>[];
            }
          } else {
            // Try alternative structure
            if (data is Map && data['data'] != null && data['data'] is List) {
              return (data['data'] as List)
                  .map((json) => ServiceProviderFactory.fromJson(json, type))
                  .where((provider) => provider != null)
                  .cast<ServiceProvider>()
                  .toList();
            }
          }
        }
        // For photographers, handle nested structure
        if (type == ServiceProviderType.photographer) {
          if (data is Map && data['data'] != null && data['data']['photographers'] != null) {
            return (data['data']['photographers'] as List<dynamic>)
                .map((json) => ServiceProviderFactory.fromJson(json, type))
                .where((provider) => provider != null)
                .cast<ServiceProvider>()
                .toList();
          }
        }
        // For makeup artists, handle nested structure
        if (type == ServiceProviderType.makeupArtist) {
          print('Raw data for makeupArtist:');
          print(data);
          if (data is Map && data['data'] != null && data['data']['makeupArtists'] != null) {
            print('Found data["data"]["makeupArtists"]:');
            print(data['data']['makeupArtists']);
            return (data['data']['makeupArtists'] as List<dynamic>)
                .map((json) {
                  final parsed = ServiceProviderFactory.fromJson(json, type);
                  print('Parsed makeupArtist: $parsed');
                  return parsed;
                })
                .where((provider) => provider != null)
                .cast<ServiceProvider>()
                .toList();
          }
          // fallback for snake_case
          if (data is Map && data['data'] != null && data['data']['makeup_artists'] != null) {
            print('Found data["data"]["makeup_artists"]:');
            print(data['data']['makeup_artists']);
            return (data['data']['makeup_artists'] as List<dynamic>)
                .map((json) {
                  final parsed = ServiceProviderFactory.fromJson(json, type);
                  print('Parsed makeupArtist: $parsed');
                  return parsed;
                })
                .where((provider) => provider != null)
                .cast<ServiceProvider>()
                .toList();
          }
        }
        // For decorators, handle nested structure
        if (type == ServiceProviderType.decorator) {
          if (data is Map && data['data'] != null && data['data']['decorators'] != null) {
            return (data['data']['decorators'] as List<dynamic>)
                .map((json) => ServiceProviderFactory.fromJson(json, type))
                .where((provider) => provider != null)
                .cast<ServiceProvider>()
                .toList();
          }
        }
        // For caterers, handle nested structure
        if (type == ServiceProviderType.caterer) {
          if (data is Map && data['data'] != null && data['data']['caterers'] != null) {
            return (data['data']['caterers'] as List<dynamic>)
                .map((json) => ServiceProviderFactory.fromJson(json, type))
                .where((provider) => provider != null)
                .cast<ServiceProvider>()
                .toList();
          }
        }
        // For event organizers, handle nested structure - ADDED
        if (type == ServiceProviderType.eventOrganizer) {
          if (data is Map && data['data'] != null && data['data']['eventOrganizers'] != null) {
            return (data['data']['eventOrganizers'] as List<dynamic>)
                .map((json) => ServiceProviderFactory.fromJson(json, type))
                .where((provider) => provider != null)
                .cast<ServiceProvider>()
                .toList();
          }
          // fallback for snake_case
          if (data is Map && data['data'] != null && data['data']['event_organizers'] != null) {
            return (data['data']['event_organizers'] as List<dynamic>)
                .map((json) => ServiceProviderFactory.fromJson(json, type))
                .where((provider) => provider != null)
                .cast<ServiceProvider>()
                .toList();
          }
        }
        // Default for other types
        final List<dynamic> results = data is Map ? data['results'] ?? data['data'] ?? data : data;
        return results
            .map((json) => ServiceProviderFactory.fromJson(json, type))
            .where((provider) => provider != null)
            .cast<ServiceProvider>()
            .toList();
      });
      
      return ServiceResult.success(providers);
    } catch (e) {
      print('Error getting service providers: $e');
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to get service providers');
    }
  }

  // Get a single service provider by ID
  Future<ServiceResult<ServiceProvider>> getServiceProvider(
    ServiceProviderType type, 
    String id,
  ) async {
    try {
      final endpoint = '${ServiceProviderFactory.getDetailApiEndpoint(type)}$id/';
      final response = await _makeRequest('GET', endpoint);
      
      final provider = _handleResponse<ServiceProvider?>(response, (data) {
        final providerData = data is Map ? data['data'] ?? data : data;
        return ServiceProviderFactory.fromJson(providerData, type);
      });

      if (provider == null) {
        return ServiceResult.error('Service provider not found');
      }

      return ServiceResult.success(provider);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to fetch service provider: ${e.toString()}');
    }
  }

  // Create a new service provider
  Future<ServiceResult<ServiceProvider>> createServiceProvider(
    ServiceProvider provider,
  ) async {
    try {
      final type = ServiceProviderFactory.getTypeFromProvider(provider);
      final endpoint = ServiceProviderFactory.getApiEndpoint(type);
      final body = ServiceProviderFactory.toJson(provider);
      
      final response = await _makeRequest('POST', endpoint, body: body);
      
      final createdProvider = _handleResponse<ServiceProvider?>(response, (data) {
        final providerData = data is Map ? data['data'] ?? data : data;
        return ServiceProviderFactory.fromJson(providerData, type);
      });

      if (createdProvider == null) {
        return ServiceResult.error('Failed to parse created service provider');
      }

      return ServiceResult.success(createdProvider);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to create service provider: ${e.toString()}');
    }
  }

  // Update an existing service provider
  Future<ServiceResult<ServiceProvider>> updateServiceProvider(
    ServiceProvider provider,
  ) async {
    try {
      final type = ServiceProviderFactory.getTypeFromProvider(provider);
      final endpoint = '${ServiceProviderFactory.getApiEndpoint(type)}${provider.id}/';
      final body = ServiceProviderFactory.toJson(provider);
      
      final response = await _makeRequest('PUT', endpoint, body: body);
      
      final updatedProvider = _handleResponse<ServiceProvider?>(response, (data) {
        final providerData = data is Map ? data['data'] ?? data : data;
        return ServiceProviderFactory.fromJson(providerData, type);
      });

      if (updatedProvider == null) {
        return ServiceResult.error('Failed to parse updated service provider');
      }

      return ServiceResult.success(updatedProvider);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to update service provider: ${e.toString()}');
    }
  }

  // Delete a service provider
  Future<ServiceResult<void>> deleteServiceProvider(
    ServiceProviderType type, 
    String id,
  ) async {
    try {
      final endpoint = '${ServiceProviderFactory.getApiEndpoint(type)}$id/';
      final response = await _makeRequest('DELETE', endpoint);
      
      _handleResponse<void>(response, (data) => null);
      return ServiceResult.success(null);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to delete service provider: ${e.toString()}');
    }
  }

  // SEARCH FUNCTIONALITY

  // Search across all provider types
  Future<ServiceResult<Map<String, List<ServiceProvider>>>> searchAllProviders({
    required String query,
    String? location,
    double? minRating,
    String? providerType,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
      };
      
      if (location != null) queryParams['location'] = location;
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (providerType != null) queryParams['provider_type'] = providerType;
      
      final response = await _makeRequest('GET', '/search/', queryParams: queryParams);
      
      final results = _handleResponse<Map<String, List<ServiceProvider>>>(response, (data) {
        final Map<String, List<ServiceProvider>> searchResults = {};
        final searchData = data is Map ? data['data'] ?? data : data;
        
        for (final entry in searchData.entries) {
          final String typeKey = entry.key;
          final List<dynamic> providerList = entry.value;
          
          // Map type key to ServiceProviderType
          ServiceProviderType? type = _mapTypeKeyToEnum(typeKey);
          
          if (type != null) {
            searchResults[typeKey] = providerList
                .map((json) => ServiceProviderFactory.fromJson(json, type!))
                .where((provider) => provider != null)
                .cast<ServiceProvider>()
                .toList();
          }
        }
        
        return searchResults;
      });

      return ServiceResult.success(results);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Search failed: ${e.toString()}');
    }
  }

  // USER SERVICE OPERATIONS

  // Get user's own services
  Future<ServiceResult<Map<String, List<ServiceProvider>>>> getUserServices() async {
    try {
      final response = await _makeRequest('GET', '/user/services/');
      
      final results = _handleResponse<Map<String, List<ServiceProvider>>>(response, (data) {
        final Map<String, List<ServiceProvider>> userServices = {};
        final serviceData = data is Map ? data['data'] ?? data : data;
        
        for (final entry in serviceData.entries) {
          final String typeKey = entry.key;
          final List<dynamic> providerList = entry.value;
          
          ServiceProviderType? type = _mapTypeKeyToEnum(typeKey);
          
          if (type != null) {
            userServices[typeKey] = providerList
                .map((json) => ServiceProviderFactory.fromJson(json, type!))
                .where((provider) => provider != null)
                .cast<ServiceProvider>()
                .toList();
          }
        }
        
        return userServices;
      });

      return ServiceResult.success(results);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to fetch user services: ${e.toString()}');
    }
  }

  // STATISTICS

  // Get provider statistics
  Future<ServiceResult<Map<String, int>>> getProviderStats() async {
    try {
      final response = await _makeRequest('GET', '/stats/');
      
      final stats = _handleResponse<Map<String, int>>(response, (data) {
        final statsData = data is Map ? data['data'] ?? data : data;
        return Map<String, int>.from(statsData);
      });

      return ServiceResult.success(stats);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to fetch statistics: ${e.toString()}');
    }
  }

  // REVIEW OPERATIONS

  // Create a review for a service provider
  Future<ServiceResult<void>> createReview({
    required ServiceProviderType type,
    required String providerId,
    required int rating,
    required String comment,
  }) async {
    try {
      final endpoint = ServiceProviderFactory.getReviewEndpoint(type);
      final body = {
        _getProviderIdField(type): providerId,
        'rating': rating,
        'comment': comment,
      };
      
      final response = await _makeRequest('POST', endpoint, body: body);
      _handleResponse<void>(response, (data) => null);
      
      return ServiceResult.success(null);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to create review: ${e.toString()}');
    }
  }

  // LOCATION OPERATIONS

  // Get all locations
  Future<ServiceResult<List<Map<String, dynamic>>>> getLocations() async {
    try {
      final response = await _makeRequest('GET', '/locations/');
      
      final locations = _handleResponse<List<Map<String, dynamic>>>(response, (data) {
        final locationData = data is Map ? data['data'] ?? data : data;
        return List<Map<String, dynamic>>.from(locationData);
      });

      return ServiceResult.success(locations);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to fetch locations: ${e.toString()}');
    }
  }

  // Create a new location
  Future<ServiceResult<Map<String, dynamic>>> createLocation(
    Map<String, dynamic> locationData,
  ) async {
    try {
      final response = await _makeRequest('POST', '/locations/', body: locationData);
      
      final location = _handleResponse<Map<String, dynamic>>(response, (data) {
        return data is Map ? data['data'] ?? data : data;
      });

      return ServiceResult.success(location);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to create location: ${e.toString()}');
    }
  }

  // MULTIPART FILE UPLOAD SUPPORT

  // Upload service provider with images
  Future<ServiceResult<ServiceProvider>> createServiceProviderWithImages({
    required ServiceProvider provider,
    List<File>? images,
    File? profileImage,
  }) async {
    try {
      final type = ServiceProviderFactory.getTypeFromProvider(provider);
      final endpoint = ServiceProviderFactory.getApiEndpoint(type);
      
      // Get current auth token
      final authState = ref.read(authProvider);
      if (authState.accessToken == null) {
        throw ServiceProviderException('Not authenticated');
      }
      
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      
      // Add auth headers
      request.headers.addAll(_getAuthHeaders(authState.accessToken!));
      request.headers['Accept'] = 'application/json';
      
      // Add form fields
      final providerJson = ServiceProviderFactory.toJson(provider);
      for (final entry in providerJson.entries) {
        if (entry.value != null) {
          request.fields[entry.key] = entry.value.toString();
        }
      }
      
      // Add profile image
      if (profileImage != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          'profileImage', 
          profileImage.path,
        );
        request.files.add(multipartFile);
      }
      
      // Add other images
      if (images != null) {
        for (int i = 0; i < images.length; i++) {
          final multipartFile = await http.MultipartFile.fromPath(
            'images[$i]', 
            images[i].path,
          );
          request.files.add(multipartFile);
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Handle 401 for multipart requests
      if (response.statusCode == 401) {
        final newToken = await _refreshTokenSafely();
        if (newToken != null) {
          // Recreate request with new token
          final retryRequest = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
          retryRequest.headers.addAll(_getAuthHeaders(newToken));
          retryRequest.headers['Accept'] = 'application/json';
          retryRequest.fields.addAll(request.fields);
          retryRequest.files.addAll(request.files);
          
          final retryStreamedResponse = await retryRequest.send();
          final retryResponse = await http.Response.fromStream(retryStreamedResponse);
          
          if (retryResponse.statusCode == 401) {
            await ref.read(authProvider.notifier).logout();
            throw ServiceProviderException('Session expired. Please login again.');
          }
          
          // Use retry response for parsing
          final createdProvider = _handleResponse<ServiceProvider?>(retryResponse, (data) {
            final providerData = data is Map ? data['data'] ?? data : data;
            return ServiceProviderFactory.fromJson(providerData, type);
          });

          if (createdProvider == null) {
            return ServiceResult.error('Failed to parse created service provider');
          }

          return ServiceResult.success(createdProvider);
        }
      }
      
      final createdProvider = _handleResponse<ServiceProvider?>(response, (data) {
        final providerData = data is Map ? data['data'] ?? data : data;
        return ServiceProviderFactory.fromJson(providerData, type);
      });

      if (createdProvider == null) {
        return ServiceResult.error('Failed to parse created service provider');
      }

      return ServiceResult.success(createdProvider);
    } catch (e) {
      if (e is ServiceProviderException) {
        return ServiceResult.error(e.message, statusCode: e.statusCode);
      }
      return ServiceResult.error('Failed to create service provider with images: ${e.toString()}');
    }
  }

  // Helper methods
  ServiceProviderType? _mapTypeKeyToEnum(String typeKey) {
    switch (typeKey) {
      case 'makeup_artists':
        return ServiceProviderType.makeupArtist;
      case 'photographers':
        return ServiceProviderType.photographer;
      case 'venues':
        return ServiceProviderType.venue;
      case 'caterers':
        return ServiceProviderType.caterer;
      case 'decorators':
        return ServiceProviderType.decorator;
      case 'event_organizers':
        return ServiceProviderType.eventOrganizer;
      default:
        return null;
    }
  }

  String _getProviderIdField(ServiceProviderType type) {
    switch (type) {
      case ServiceProviderType.makeupArtist:
        return 'makeup_artist';
      case ServiceProviderType.photographer:
        return 'photographer';
      case ServiceProviderType.venue:
        return 'venue';
      case ServiceProviderType.caterer:
        return 'caterer';
      case ServiceProviderType.decorator:
        return 'decorator';
      case ServiceProviderType.eventOrganizer:
        return 'event_organizer';
    }
  }
}

// Provider for ServiceProviderManager
final serviceProviderManagerProvider = Provider<ServiceProviderManager>((ref) {
  return ServiceProviderManager(ref);
});

// State providers for different service provider operations
final serviceProvidersProvider = FutureProvider.family<List<ServiceProvider>, ServiceProviderType>((ref, type) async {
  final manager = ref.read(serviceProviderManagerProvider);
  final result = await manager.getServiceProviders(type);
  
  if (result.isError) {
    throw ServiceProviderException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? [];
});

final searchResultsProvider = FutureProvider.family<Map<String, List<ServiceProvider>>, Map<String, dynamic>>((ref, params) async {
  final manager = ref.read(serviceProviderManagerProvider);
  final result = await manager.searchAllProviders(
    query: params['query'] ?? '',
    location: params['location'],
    minRating: params['minRating'],
    providerType: params['providerType'],
  );
  
  if (result.isError) {
    throw ServiceProviderException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? {};
});

final userServicesProvider = FutureProvider<Map<String, List<ServiceProvider>>>((ref) async {
  final manager = ref.read(serviceProviderManagerProvider);
  final result = await manager.getUserServices();
  
  if (result.isError) {
    throw ServiceProviderException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? {};
});

final statsProvider = FutureProvider<Map<String, int>>((ref) async {
  final manager = ref.read(serviceProviderManagerProvider);
  final result = await manager.getProviderStats();
  
  if (result.isError) {
    throw ServiceProviderException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? {};
});

final locationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final manager = ref.read(serviceProviderManagerProvider);
  final result = await manager.getLocations();
  
  if (result.isError) {
    throw ServiceProviderException(result.error ?? 'Unknown error');
  }
  
  return result.data ?? [];
});

// Add an auth state listener provider
final authStateListenerProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (!next.isLoggedIn && previous?.isLoggedIn == true) {
      // Clear any cached service provider data when logged out
      ref.invalidate(serviceProvidersProvider);
      ref.invalidate(userServicesProvider);
      ref.invalidate(statsProvider);
      ref.invalidate(locationsProvider);
    }
  });
});