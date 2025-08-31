import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:swornim/config/app_config.dart';

// Enhanced Auth State with better error handling
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final bool isRefreshing;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.isRefreshing = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    bool? isRefreshing,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  // Check if token is expired or about to expire (within 5 minutes)
  bool get isTokenExpired {
    if (tokenExpiresAt == null) return false;
    return DateTime.now().isAfter(tokenExpiresAt!.subtract(const Duration(minutes: 5)));
  }

  bool get needsRefresh => isTokenExpired && refreshToken != null;
}

// Auth Result for better error handling
class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  final bool requiresVerification;

  const AuthResult({
    required this.success,
    this.error,
    this.user,
    this.requiresVerification = false,
  });

  factory AuthResult.success({User? user}) => AuthResult(success: true, user: user);
  factory AuthResult.error(String error) => AuthResult(success: false, error: error);
  factory AuthResult.needsVerification({User? user}) => 
    AuthResult(success: false, requiresVerification: true, user: user);
}

// Enhanced Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadStoredAuth();
  }

  static String get baseUrl => AppConfig.authBaseUrl;
  
  // Token refresh mutex to prevent multiple simultaneous refresh attempts
  bool _isRefreshingToken = false;

  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');
      final userJson = prefs.getString('user');
      final expiresAtStr = prefs.getString('token_expires_at');

      if (accessToken != null && userJson != null) {
        final user = User.fromJson(json.decode(userJson));
        DateTime? expiresAt;
        
        if (expiresAtStr != null) {
          expiresAt = DateTime.tryParse(expiresAtStr);
        }

        state = state.copyWith(
          user: user,
          isLoggedIn: user.canLogin(),
          accessToken: accessToken,
          refreshToken: refreshToken,
          tokenExpiresAt: expiresAt,
        );

        // Auto-refresh if token is expired/expiring
        if (state.needsRefresh) {
          await this.refreshToken();
        }
      }
    } catch (e) {
      print('Error loading stored auth: $e');
      await _clearStoredAuth();
    }
  }

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
    File? profileImage, 
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Validate inputs
      if (password != confirmPassword) {
        state = state.copyWith(isLoading: false, error: 'Passwords do not match');
        return AuthResult.error('Passwords do not match');
      }

      // Clean and validate input data
      final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      final cleanedEmail = email.toLowerCase().trim();
      
      if (cleanedPhone.length < 10) {
        state = state.copyWith(isLoading: false, error: 'Invalid phone number');
        return AuthResult.error('Invalid phone number');
      }

      print('=== SIGNUP DEBUG INFO ===');
      print('Original phone: $phone');
      print('Cleaned phone: $cleanedPhone');
      print('Email: $cleanedEmail');
      print('UserType: ${userType.name} -> ${userTypeToBackendFormat(userType)}');
      print('Has profile image: ${profileImage != null}');
      
      http.Response response;
      
      // Try JSON request first (without file)
      if (profileImage == null) {
        final requestBody = {
          'name': name.trim(),
          'email': cleanedEmail,
          'phone': cleanedPhone,
          'password': password,
          'confirmPassword': confirmPassword,
          'userType': userTypeToBackendFormat(userType),
        };

        print('Using JSON request');
        print('Request body: ${json.encode(requestBody)}');

        response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: _getDefaultHeaders(),
          body: json.encode(requestBody),
        );

        _logResponse(response, 'JSON Signup');
      } else {
        // Use multipart for file upload
        print('Using multipart request with file');
        
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/register'));
        
        // Add Accept header for multipart requests
        request.headers['Accept'] = 'application/json';
        
        // Add form fields - try both field name variations
        request.fields.addAll({
          'name': name.trim(),
          'email': cleanedEmail,
          'phone': cleanedPhone,
          'password': password,
          'confirmPassword': confirmPassword,
          'userType': userTypeToBackendFormat(userType),
        });

        print('Multipart fields: ${request.fields}');

        // Add profile image
        try {
          final multipartFile = await http.MultipartFile.fromPath(
            'profileImage', 
            profileImage.path,
          );
          request.files.add(multipartFile);
          print('Added file: ${multipartFile.filename}, Size: ${multipartFile.length}');
        } catch (fileError) {
          print('Error adding file: $fileError');
          state = state.copyWith(isLoading: false, error: 'Error processing image file');
          return AuthResult.error('Error processing image file');
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);

        _logResponse(response, 'Multipart Signup');
      }

      // Handle response - check for success status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        return await _handleSignupSuccess(response);
      } else {
        final error = _extractErrorMessage(response);
        print('Signup Error: $error');
        state = state.copyWith(isLoading: false, error: error);
        return AuthResult.error(error);
      }
      
    } catch (e) {
      print('Signup Exception: $e');
      final error = 'Network error: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
    }
  }

  Future<AuthResult> _handleSignupSuccess(http.Response response) async {
    try {
      print('Handling signup success response: ${response.body}');
      
      // Handle empty response body
      if (response.body.isEmpty) {
        state = state.copyWith(isLoading: false);
        return AuthResult.success();
      }

      final responseData = json.decode(response.body);
      
      // Handle different response structures
      if (responseData is Map<String, dynamic>) {
        // Case 1: Response has data field with user info
        if (responseData.containsKey('data') && responseData['data'] != null) {
          final userData = responseData['data'];
          final user = User.fromJson(userData);
          
          // Handle tokens if provided in signup response
          if (userData is Map && userData.containsKey('tokens') && userData['tokens'] != null) {
            final tokens = userData['tokens'];
            await _storeTokens(tokens, user);
            state = state.copyWith(
              user: user,
              isLoading: false,
              isLoggedIn: user.canLogin(),
              accessToken: tokens['accessToken']?.toString(),
              refreshToken: tokens['refreshToken']?.toString(),
            );
            return AuthResult.success(user: user);
          } else {
            // No tokens provided, user might need verification
            state = state.copyWith(
              user: user,
              isLoading: false,
              isLoggedIn: false,
            );
            
            if (!user.isEmailVerified) {
              return AuthResult.needsVerification(user: user);
            }
            return AuthResult.success(user: user);
          }
        }
        
        // Case 2: Direct user data without wrapper
        else if (responseData.containsKey('id') || responseData.containsKey('_id')) {
          final user = User.fromJson(responseData);
          state = state.copyWith(
            user: user,
            isLoading: false,
            isLoggedIn: false,
          );
          
          if (!user.isEmailVerified) {
            return AuthResult.needsVerification(user: user);
          }
          return AuthResult.success(user: user);
        }
        
        // Case 3: Success message without user data
        else if (responseData.containsKey('message') || responseData.containsKey('success')) {
          state = state.copyWith(isLoading: false);
          return AuthResult.success();
        }
      }
      
      // Fallback - assume success if we got here
      state = state.copyWith(isLoading: false);
      return AuthResult.success();
      
    } catch (e) {
      print('Error parsing signup success response: $e');
      print('Response body: ${response.body}');
      
      // Even if parsing fails, if we got a 200/201, consider it successful
      state = state.copyWith(isLoading: false);
      return AuthResult.success();
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requestBody = {
        'email': email.toLowerCase().trim(),
        'password': password,
      };

      _logRequest('POST', '$baseUrl/login', requestBody);

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _getDefaultHeaders(),
        body: json.encode(requestBody),
      );

      _logResponse(response, 'Login');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['data'] != null) {
          final user = User.fromJson(responseData['data']['user']);
          final tokens = responseData['data']['tokens'];

          await _storeTokens(tokens, user);

          state = state.copyWith(
            user: user,
            isLoading: false,
            isLoggedIn: user.canLogin(),
            accessToken: tokens['accessToken']?.toString(),
            refreshToken: tokens['refreshToken']?.toString(),
          );
          
          return AuthResult.success(user: user);
        }
      }
      
      final error = _extractErrorMessage(response);
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
      
    } catch (e) {
      final error = 'Network error: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
    }
  }

  Future<void> logout() async {
    try {
      if (state.accessToken != null) {
        final response = await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            ..._getDefaultHeaders(),
            'Authorization': 'Bearer ${state.accessToken}',
          },
        );
        _logResponse(response, 'Logout');
      }
    } catch (e) {
      print('Logout Error: $e');
    }

    await _clearStoredAuth();
    state = const AuthState();
  }

  Future<void> logoutAllSessions() async {
    try {
      if (state.accessToken != null) {
        final response = await http.post(
          Uri.parse('$baseUrl/logout-all'),
          headers: {
            ..._getDefaultHeaders(),
            'Authorization': 'Bearer ${state.accessToken}',
          },
        );
        _logResponse(response, 'Logout All Sessions');
      }
    } catch (e) {
      print('Logout All Sessions Error: $e');
    }

    await _clearStoredAuth();
    state = const AuthState();
  }

  Future<bool> refreshToken() async {
    if (state.refreshToken == null || _isRefreshingToken) {
      return false;
    }

    _isRefreshingToken = true;
    state = state.copyWith(isRefreshing: true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: _getDefaultHeaders(),
        body: json.encode({
          'refreshToken': state.refreshToken,
        }),
      );

      _logResponse(response, 'Refresh Token');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['data'] != null) {
          final tokens = responseData['data'];
          
          await _storeTokens(tokens, state.user);

          state = state.copyWith(
            accessToken: tokens['accessToken']?.toString(),
            refreshToken: tokens['refreshToken']?.toString() ?? state.refreshToken,
            isRefreshing: false,
          );
          
          return true;
        }
      } else {
        // Refresh token is invalid, logout user
        print('Refresh token failed: ${response.statusCode}');
        await logout();
        return false;
      }
    } catch (e) {
      print('Refresh Token Error: $e');
      await logout();
      return false;
    } finally {
      _isRefreshingToken = false;
      state = state.copyWith(isRefreshing: false);
    }
    
    return false;
  }

  Future<AuthResult> verifyEmail(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: _getDefaultHeaders(),
        body: json.encode({'token': token}),
      );

      _logResponse(response, 'Email Verification');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['data'] != null) {
          final updatedUser = User.fromJson(responseData['data']);

          // Update stored user data
          await _updateStoredUser(updatedUser);

          state = state.copyWith(
            user: updatedUser,
            isLoading: false,
            isLoggedIn: updatedUser.canLogin(),
          );
          
          return AuthResult.success(user: updatedUser);
        }
      }
      
      final error = _extractErrorMessage(response);
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
      
    } catch (e) {
      final error = 'Network error: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
    }
  }

  Future<AuthResult> resendVerificationEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-verification'),
        headers: _getDefaultHeaders(),
        body: json.encode({'email': email.toLowerCase().trim()}),
      );

      _logResponse(response, 'Resend Verification');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // If backend auto-activates, update user state
        if (responseData['data'] != null) {
          await getProfile();
        }
        
        state = state.copyWith(isLoading: false);
        return AuthResult.success();
      }
      
      final error = _extractErrorMessage(response);
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
      
    } catch (e) {
      final error = 'Network error: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: _getDefaultHeaders(),
        body: json.encode({'email': email.toLowerCase().trim()}),
      );

      _logResponse(response, 'Forgot Password');

      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        return AuthResult.success();
      }
      
      final error = _extractErrorMessage(response);
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
      
    } catch (e) {
      final error = 'Network error: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
    }
  }

  Future<AuthResult> resetPassword({
    required String token,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: _getDefaultHeaders(),
        body: json.encode({
          'token': token,
          'password': password,
        }),
      );

      _logResponse(response, 'Reset Password');

      if (response.statusCode == 200) {
        // Backend revokes all sessions after password reset
        await logout();
        return AuthResult.success();
      }
      
      final error = _extractErrorMessage(response);
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
      
    } catch (e) {
      final error = 'Network error: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
    }
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          ..._getDefaultHeaders(),
          'Authorization': 'Bearer ${state.accessToken}',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      _logResponse(response, 'Change Password');

      if (response.statusCode == 200) {
        // Backend revokes all other sessions for security
        await logout();
        return AuthResult.success();
      }
      
      final error = _extractErrorMessage(response);
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
      
    } catch (e) {
      final error = 'Network error: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
    }
  }

  Future<void> getProfile() async {
    if (state.accessToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          ..._getDefaultHeaders(),
          'Authorization': 'Bearer ${state.accessToken}',
        },
      );

      _logResponse(response, 'Get Profile');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['data'] != null) {
          final user = User.fromJson(responseData['data']);
          await _updateStoredUser(user);
          
          state = state.copyWith(
            user: user,
            isLoggedIn: user.canLogin(),
          );
        }
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        await refreshToken();
      }
    } catch (e) {
      print('Get Profile Error: $e');
    }
  }

  // Helper methods
  Map<String, String> _getDefaultHeaders() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String _extractErrorMessage(http.Response response) {
    try {
      final responseBody = response.body;
      if (responseBody.isEmpty) {
        return _getErrorMessageForStatusCode(response.statusCode);
      }

      final errorData = json.decode(responseBody);
      
      if (errorData is Map<String, dynamic>) {
        // Check for message field
        if (errorData.containsKey('message') && errorData['message'] != null) {
          return errorData['message'].toString();
        }
        
        // Check for error field
        if (errorData.containsKey('error') && errorData['error'] != null) {
          return errorData['error'].toString();
        }
        
        // Check for status field
        if (errorData.containsKey('status') && errorData['status'] != null) {
          final status = errorData['status'].toString().replaceAll('_', ' ').toLowerCase();
          return status.isNotEmpty ? 
            '${status[0].toUpperCase()}${status.substring(1)}' : 
            _getErrorMessageForStatusCode(response.statusCode);
        }

        // Check for errors array (validation errors)
        if (errorData.containsKey('errors') && errorData['errors'] is List) {
          final errors = errorData['errors'] as List;
          if (errors.isNotEmpty) {
            return errors.first.toString();
          }
        }

        // Check for detail field (common in some APIs)
        if (errorData.containsKey('detail') && errorData['detail'] != null) {
          return errorData['detail'].toString();
        }
      }
    } catch (e) {
      print('Error parsing response body: $e');
      print('Response body: ${response.body}');
    }
    
    return _getErrorMessageForStatusCode(response.statusCode);
  }

  String _getErrorMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request data';
      case 401:
        return 'Invalid credentials';
      case 403:
        return 'Account access denied';
      case 404:
        return 'User not found';
      case 409:
        return 'Email already exists';
      case 422:
        return 'Validation failed';
      case 429:
        return 'Too many requests. Please try again later';
      case 500:
        return 'Server error. Please try again later';
      default:
        return 'Request failed with status $statusCode';
    }
  }

  Future<void> _storeTokens(Map<String, dynamic> tokens, User? user) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (tokens['accessToken'] != null) {
      await prefs.setString('access_token', tokens['accessToken'].toString());
    }
    
    if (tokens['refreshToken'] != null) {
      await prefs.setString('refresh_token', tokens['refreshToken'].toString());
    }
    
    // Store token expiration if provided
    if (tokens['expiresAt'] != null) {
      await prefs.setString('token_expires_at', tokens['expiresAt'].toString());
    } else if (tokens['expiresIn'] != null) {
      // Calculate expiration time if only duration is provided
      final expiresAt = DateTime.now().add(Duration(seconds: int.tryParse(tokens['expiresIn'].toString()) ?? 3600));
      await prefs.setString('token_expires_at', expiresAt.toIso8601String());
    }
    
    if (user != null) {
      await prefs.setString('user', json.encode(user.toJson()));
    }
  }

  Future<void> _updateStoredUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
  }

  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('access_token'),
      prefs.remove('refresh_token'),
      prefs.remove('user'),
      prefs.remove('token_expires_at'),
    ]);
  }

  void _logRequest(String method, String url, dynamic body) {
    print('$method Request URL: $url');
    if (body is Map) {
      print('$method Request Body: ${json.encode(body)}');
    }
  }

  void _logResponse(http.Response response, [String? context]) {
    final prefix = context != null ? '$context ' : '';
    print('${prefix}Response Status: ${response.statusCode}');
    print('${prefix}Response Body: ${response.body}');
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Debug method to test backend endpoint expectations
  Future<void> testSignupEndpoint() async {
    try {
      print('=== TESTING SIGNUP ENDPOINT ===');
      
      // Test 1: Check if endpoint accepts JSON
      print('Test 1: JSON Request');
      final jsonResponse = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _getDefaultHeaders(),
        body: json.encode({
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '1234567890',
          'password': 'test123',
          'confirmPassword': 'test123',
          'userType': 'client',
        }),
      );
      print('JSON Response: ${jsonResponse.statusCode} - ${jsonResponse.body}');
      
      // Test 2: Check if endpoint accepts multipart
      print('\nTest 2: Multipart Request');
      var multipartRequest = http.MultipartRequest('POST', Uri.parse('$baseUrl/register'));
      multipartRequest.headers['Accept'] = 'application/json';
      multipartRequest.fields.addAll({
        'name': 'Test User 2',
        'email': 'test2@example.com',
        'phone': '1234567891',
        'password': 'test123',
        'confirmPassword': 'test123',
        'userType': 'client',
      });
      
      final multipartStreamedResponse = await multipartRequest.send();
      final multipartResponse = await http.Response.fromStream(multipartStreamedResponse);
      print('Multipart Response: ${multipartResponse.statusCode} - ${multipartResponse.body}');
      
    } catch (e) {
      print('Test Error: $e');
    }
  }
}

// Enhanced API Client with better error handling and token management
class ApiClient {
  static String get baseUrl => AppConfig.baseUrl;
  final Ref ref;

  ApiClient(this.ref);

  Future<http.Response> get(String endpoint) async {
    return _makeRequest(() async => http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
    ));
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _makeRequest(() async => http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: body != null ? json.encode(body) : null,
    ));
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    return _makeRequest(() async => http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: body != null ? json.encode(body) : null,
    ));
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    return _makeRequest(() async => http.patch(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: body != null ? json.encode(body) : null,
    ));
  }

  Future<http.Response> delete(String endpoint) async {
    return _makeRequest(() async => http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
    ));
  }Future<http.StreamedResponse> postMultipart(
    String endpoint, 
    Map<String, String> fields, 
    {List<http.MultipartFile>? files}
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/$endpoint'));
    
    // Add auth headers (excluding Content-Type for multipart)
    final authState = ref.read(authProvider);
    if (authState.accessToken != null) {
      request.headers['Authorization'] = 'Bearer ${authState.accessToken}';
    }
    request.headers['Accept'] = 'application/json';
    
    request.fields.addAll(fields);
    if (files != null) {
      request.files.addAll(files);
    }
    
    return await _makeMultipartRequest(() => request.send());
  }

  Future<http.Response> _makeRequest(Future<http.Response> Function() requestFunction) async {
    final authState = ref.read(authProvider);
    
    // Auto-refresh token if needed
    if (authState.needsRefresh && !authState.isRefreshing) {
      final refreshed = await ref.read(authProvider.notifier).refreshToken();
      if (!refreshed) {
        throw Exception('Authentication expired. Please login again.');
      }
    }
    
    try {
      final response = await requestFunction();
      
      // Handle 401 - token might be expired
      if (response.statusCode == 401) {
        final refreshed = await ref.read(authProvider.notifier).refreshToken();
        if (refreshed) {
          // Retry the request with new token
          return await requestFunction();
        } else {
          throw Exception('Authentication expired. Please login again.');
        }
      }
      
      return response;
    } catch (e) {
      print('API Request Error: $e');
      rethrow;
    }
  }

  Future<http.StreamedResponse> _makeMultipartRequest(
    Future<http.StreamedResponse> Function() requestFunction
  ) async {
    final authState = ref.read(authProvider);
    
    // Auto-refresh token if needed
    if (authState.needsRefresh && !authState.isRefreshing) {
      final refreshed = await ref.read(authProvider.notifier).refreshToken();
      if (!refreshed) {
        throw Exception('Authentication expired. Please login again.');
      }
    }
    
    try {
      final response = await requestFunction();
      
      // Handle 401 - token might be expired
      if (response.statusCode == 401) {
        final refreshed = await ref.read(authProvider.notifier).refreshToken();
        if (refreshed) {
          // For multipart requests, we need to recreate the request
          // This is a limitation - the caller should handle retry
          throw Exception('Token expired during multipart request. Please retry.');
        } else {
          throw Exception('Authentication expired. Please login again.');
        }
      }
      
      return response;
    } catch (e) {
      print('API Multipart Request Error: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final authState = ref.read(authProvider);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (authState.accessToken != null) {
      headers['Authorization'] = 'Bearer ${authState.accessToken}';
    }
    
    return headers;
  }
}

// Provider instances
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

// Helper providers for common auth checks
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

// Auto logout provider - watches for token expiration
final autoLogoutProvider = Provider<void>((ref) {
  final authState = ref.watch(authProvider);
  
  if (authState.isLoggedIn && authState.isTokenExpired && authState.refreshToken == null) {
    // No refresh token available and token is expired
    Future.microtask(() {
      ref.read(authProvider.notifier).logout();
    });
  }
});