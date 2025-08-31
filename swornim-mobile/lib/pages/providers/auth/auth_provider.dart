import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:swornim/config/app_config.dart';

// Add at the top of file
const bool _debugAuth = true; // Toggle debug logging

void _debugLog(String message, [Object? error, StackTrace? stackTrace]) {
  if (_debugAuth) {
    print('🔐 Auth: $message');
    if (error != null) {
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }
}

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
  final bool isInitialized;
  final String? sessionId; // Add session ID

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.isRefreshing = false,
    this.isInitialized = false,
    this.sessionId, // Initialize session ID
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
    bool? isInitialized,
    String? sessionId, // Add session ID to copyWith
  }) {
    final newState = AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isInitialized: isInitialized ?? this.isInitialized,
      sessionId: sessionId ?? this.sessionId, // Copy session ID
    );
    
    // Log state changes for debugging
    if (isLoggedIn != null && isLoggedIn != this.isLoggedIn) {
      print('🔐 Auth: isLoggedIn changed from ${this.isLoggedIn} to $isLoggedIn');
    }
    if (user != null && user != this.user) {
      print('🔐 Auth: user changed from ${this.user?.name} to ${user.name}');
    }
    if (error != null && error != this.error) {
      print('🔐 Auth: error changed from ${this.error} to $error');
    }
    
    return newState;
  }

  // Check if token is expired or about to expire (within 2 minutes) - less aggressive
  bool get isTokenExpired {
    final expiresAt = tokenExpiresAt;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 2)));
  }

  // More conservative check - only refresh if actually needed
  bool get needsRefresh {
    final expiresAt = tokenExpiresAt;
    if (expiresAt == null || refreshToken == null) return false;
    // Only refresh if within 2 minutes of expiration or already expired
    return DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 2)));
  }

  // Check if token is actually expired (past expiration time)
  bool get isActuallyExpired {
    final expiresAt = tokenExpiresAt;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt);
  }
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

// Enhanced Auth Notifier with better persistence
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initializeAuth();
  }

  static String get baseUrl => AppConfig.authBaseUrl;
  
  // Token refresh mutex to prevent multiple simultaneous refresh attempts
  bool _isRefreshingToken = false;
  bool _isInitializing = false;


  // Add this to your AuthNotifier class
Future<void> clearAllProviderCaches() async {
  try {
    _debugLog('Clearing all provider caches');
    
    // Clear SharedPreferences user-specific data
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.contains('user_') || key.contains('dashboard_') || 
          key.contains('booking_') || key.contains('analytics_')) {
        await prefs.remove(key);
      }
    }
    
    _debugLog('All provider caches cleared successfully');
  } catch (e) {
    _debugLog('Error clearing provider caches', e);
  }
}
  // Initialize auth state - this ensures proper loading order
  Future<void> _initializeAuth() async {
    if (_isInitializing) return; // Prevent multiple initialization calls
    _isInitializing = true;
    
    state = state.copyWith(isLoading: true);
    try {
      _debugLog('Initializing auth state');
      await _loadStoredAuth();
      
      // Only try to refresh if we have both tokens and user seems valid
      if (state.accessToken != null && 
          state.refreshToken != null && 
          state.user != null &&
          !state.isLoggedIn) {
        _debugLog('Found stored tokens, attempting to restore session');
        
        // First, set logged in if user can login
        if (state.user!.canLogin()) {
          state = state.copyWith(isLoggedIn: true);
          _debugLog('Auth restored from stored data - user can login');
        }
        
        // Then check if token needs refresh (but don't fail auth if refresh fails)
        if (state.needsRefresh) {
          _debugLog('Token needs refresh, attempting refresh');
          final refreshed = await refreshToken();
          if (!refreshed) {
            _debugLog('Token refresh failed, but keeping user logged in with current token');
            // Don't clear auth here - let the API calls handle token refresh as needed
          }
        }
      }
    } catch (e, stack) {
      _debugLog('Error during auth initialization', e, stack);
      // Only clear auth if there's a critical error, not just parsing issues
      if (e.toString().contains('critical') || e.toString().contains('invalid_format')) {
        await _clearStoredAuth();
      }
    } finally {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
      );
      _isInitializing = false;
    }
  }

  // Enhanced method to load stored authentication with better error handling
  Future<void> _loadStoredAuth() async {
    try {
      _debugLog('Loading stored authentication');
      final prefs = await SharedPreferences.getInstance();
      
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');
      final userJson = prefs.getString('user');
      final expiresAtStr = prefs.getString('token_expires_at');
      final sessionId = prefs.getString('session_id');

      _debugLog('Loaded tokens:');
      _debugLog('- Access token: ${accessToken != null ? "exists" : "null"}');
      _debugLog('- Refresh token: ${refreshToken != null ? "exists" : "null"}');
      _debugLog('- Session ID: ${sessionId != null ? "exists" : "null"}');
      _debugLog('- Expires at: $expiresAtStr');
      _debugLog('- User data: ${userJson != null ? "exists" : "null"}');

      if (accessToken != null && userJson != null) {
        try {
          final user = User.fromJson(json.decode(userJson));
          _debugLog('Parsed user data: ${user.email}');
          
          final canLogin = user.canLogin();
          _debugLog('User can login: $canLogin');

          DateTime? expiresAt;
          if (expiresAtStr != null) {
            expiresAt = DateTime.tryParse(expiresAtStr);
            _debugLog('Parsed expiration: $expiresAt');
          }

          // Set the state with all auth data - be more permissive about login status
          state = state.copyWith(
            user: user,
            isLoggedIn: canLogin, // Set based on user's ability to login
            accessToken: accessToken,
            refreshToken: refreshToken,
            sessionId: sessionId,
            tokenExpiresAt: expiresAt,
            isInitialized: true,
          );

          _debugLog('Auth state loaded successfully - isLoggedIn: ${state.isLoggedIn}');
        } catch (e, stack) {
          _debugLog('Error parsing stored user data - keeping tokens', e, stack);
          // Don't clear everything, just set what we can
          state = state.copyWith(
            accessToken: accessToken,
            refreshToken: refreshToken,
            sessionId: sessionId,
            isLoggedIn: false,
            isInitialized: true,
          );
        }
      } else {
        _debugLog('No complete auth data found');
        state = state.copyWith(isInitialized: true);
      }
    } catch (e, stack) {
      _debugLog('Error loading stored auth', e, stack);
      state = state.copyWith(isInitialized: true);
    }
  }

  // Improved app lifecycle handling
  Future<void> handleAppLifecycleChange(AppLifecycleState lifecycleState) async {
    _debugLog('App lifecycle state changed to: $lifecycleState');
    
    switch (lifecycleState) {
      case AppLifecycleState.resumed:
        _debugLog('App resumed, checking auth state');
        // Don't reinitialize, just validate current state
        await _validateCurrentAuth();
        break;
        
      case AppLifecycleState.paused:
        _debugLog('App paused, ensuring auth data is saved');
        if (state.isLoggedIn) {
          await _persistCurrentAuth();
        }
        break;
        
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Handle other states if needed
        break;
    }
  }

  // New method to validate current auth without full reinitialization
  Future<void> _validateCurrentAuth() async {
    if (!state.isInitialized) {
      await _initializeAuth();
      return;
    }

    // If we have a user and tokens, validate the session
    if (state.user != null && state.accessToken != null) {
      _debugLog('Validating current auth session');
      
      // Check if user can still login
      if (!state.user!.canLogin()) {
        _debugLog('User can no longer login, logging out');
        await logout();
        return;
      }
      
      // If not logged in but should be, restore login state
      if (!state.isLoggedIn && state.user!.canLogin()) {
        _debugLog('Restoring login state');
        state = state.copyWith(isLoggedIn: true);
      }
      
      // Only refresh token if it's actually expired (not just close to expiring)
      if (state.isActuallyExpired && state.refreshToken != null) {
        _debugLog('Token is expired, attempting refresh');
        final refreshed = await refreshToken();
        if (!refreshed) {
          _debugLog('Token refresh failed on app resume');
          // Let API calls handle the refresh, don't logout immediately
        }
      }
    }
  }

  // New method to persist current auth state
  Future<void> _persistCurrentAuth() async {
    try {
      if (state.accessToken != null && state.user != null) {
        await _storeTokens({
          'accessToken': state.accessToken,
          'refreshToken': state.refreshToken,
          'sessionId': state.sessionId,
        }, state.user);
        _debugLog('Auth state persisted on app pause');
      }
    } catch (e) {
      _debugLog('Error persisting auth state', e);
    }
  }

  // Method to manually check and restore auth (call this on app resume)
  Future<void> checkAndRestoreAuth() async {
    _debugLog('Manual auth check and restore called');
    await _validateCurrentAuth();
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

        final response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: _getDefaultHeaders(),
          body: json.encode(requestBody),
        );

        _logResponse(response, 'JSON Signup');

        if (response.statusCode == 201) {
          return await _handleSignupSuccess(response);
        } else {
          final error = _extractErrorMessage(response);
          print('JSON Signup Error: $error');
          state = state.copyWith(isLoading: false, error: error);
          return AuthResult.error(error);
        }
      } else {
        // Use multipart for file upload
        print('Using multipart request with file');
        
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/register'));
        
        // Add Accept header for multipart requests
        request.headers['Accept'] = 'application/json';
        
        // Add form fields
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
        final response = await http.Response.fromStream(streamedResponse);

        _logResponse(response, 'Multipart Signup');

        if (response.statusCode == 201) {
          return await _handleSignupSuccess(response);
        } else {
          final error = _extractErrorMessage(response);
          print('Multipart Signup Error: $error');
          state = state.copyWith(isLoading: false, error: error);
          return AuthResult.error(error);
        }
      }
      
    } catch (e) {
      print('Signup Exception: $e');
      print('Signup Exception Stack Trace: ${StackTrace.current}');
      final error = 'Network error: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: error);
      return AuthResult.error(error);
    }
  }

  Future<AuthResult> _handleSignupSuccess(http.Response response) async {
    try {
      final responseData = json.decode(response.body);
      print('Signup response data: ${json.encode(responseData)}');
      
      if (responseData['data'] != null) {
        try {
          final userData = responseData['data'];
          print('User data before parsing: ${json.encode(responseData['data'])}');
          
          final user = User.fromJson(userData);
          print('User parsed successfully: ${user.email}');
          
          // IMPORTANT: Never handle tokens or set isLoggedIn during signup
          state = state.copyWith(
            user: null,
            isLoading: false,
            isLoggedIn: false,
            error: null,
          );
          
          // Check if user needs email verification
          if (!user.isEmailVerified) {
            print('User needs email verification');
            return AuthResult.needsVerification(user: user);
          }
          
          print('Registration successful, user can now login');
          return AuthResult.success(user: user);
          
        } catch (userParseError) {
          print('Error parsing user data: $userParseError');
          final dataStr = responseData['data'] != null ? json.encode(responseData['data']) : 'null';
          print('User data that failed to parse: $dataStr');
          
          final message = responseData['message']?.toString() ?? '';
          if (message.toLowerCase().contains('registered successfully')) {
            state = state.copyWith(isLoading: false, error: null);
            return AuthResult.success();
          } else {
            state = state.copyWith(isLoading: false, error: 'Error processing user data: $userParseError');
            return AuthResult.error('Error processing user data');
          }
        }
      } else {
        print('No data field in response');
        state = state.copyWith(isLoading: false, error: 'Invalid response format');
        return AuthResult.error('Invalid response format');
      }
    } catch (e) {
      print('Error in _handleSignupSuccess: $e');
      state = state.copyWith(isLoading: false, error: 'Error processing signup response: $e');
      return AuthResult.error('Error processing signup response');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await clearAllProviderCaches();
      final requestBody = {
        'email': email.toLowerCase().trim(),
        'password': password.trim(),
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
        final data = responseData['data'];
        
        if (data != null) {
          try {
            final userData = data['user'] as Map<String, dynamic>?;
            final tokens = data['tokens'] as Map<String, dynamic>?;
            
            if (userData == null || tokens == null) {
              throw Exception('Invalid response data structure');
            }

            // Create user object
            final user = User.fromJson(userData);
            
            // Store tokens
            final tokenData = {
              'accessToken': tokens['accessToken']?.toString(),
              'refreshToken': tokens['refreshToken']?.toString(),
              'sessionId': tokens['sessionId']?.toString(),
            };
            
            await _storeTokens(tokenData, user);

            final canLogin = user.canLogin();
            if (!canLogin) {
              throw Exception('Account is not active or email not verified');
            }

            state = state.copyWith(
              user: user,
              isLoading: false,
              isLoggedIn: true,
              accessToken: tokenData['accessToken'],
              refreshToken: tokenData['refreshToken'],
              sessionId: tokenData['sessionId'],
              tokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
              error: null,
            );
            
            return AuthResult.success(user: user);
          } catch (e) {
            _debugLog('Error processing login response', e);
            throw Exception(e.toString());
          }
        }
        throw Exception('Invalid response format');
      }
      
      throw Exception(_extractErrorMessage(response));
      
    } catch (e) {
      _debugLog('Login failed', e);
      
      // Always reset loading state
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
        isLoggedIn: false,
      );
      
      return AuthResult.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
  try {
    _debugLog('Starting logout process');
    
    // 1. Clear all cached data FIRST
    await clearAllProviderCaches();
    
    // 2. Clear server session
    final currentAccessToken = state.accessToken;
    if (currentAccessToken != null) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            ..._getDefaultHeaders(),
            'Authorization': 'Bearer $currentAccessToken',
          },
        );
        _logResponse(response, 'Logout');
      } catch (e) {
        _debugLog('Server logout failed (continuing anyway)', e);
      }
    }

    // 3. Clear all local storage
    await _clearStoredAuth();
    
    // 4. Reset state completely - THIS IS KEY
    state = const AuthState(
      isInitialized: true,
      isLoggedIn: false,
      user: null,
      accessToken: null,
      refreshToken: null,
      sessionId: null,
      tokenExpiresAt: null,
      error: null,
      isLoading: false,
      isRefreshing: false,
    );
    
    _debugLog('Logout completed - state completely reset');
    
  } catch (e) {
    _debugLog('Logout Error', e);
    
    // Even if logout fails, ensure we clear local state
    await _clearStoredAuth();
    state = const AuthState(
      isInitialized: true,
      isLoggedIn: false,
      user: null,
      accessToken: null,
      refreshToken: null,
      sessionId: null,
      tokenExpiresAt: null,
      error: null,
      isLoading: false,
      isRefreshing: false,
    );
  }
}

  Future<void> logoutAllSessions() async {
    try {
      final currentAccessToken = state.accessToken;
      if (currentAccessToken != null) {
        final response = await http.post(
          Uri.parse('$baseUrl/logout-all'),
          headers: {
            ..._getDefaultHeaders(),
            'Authorization': 'Bearer $currentAccessToken',
          },
        );
        _logResponse(response, 'Logout All Sessions');
      }
    } catch (e) {
      print('Logout All Sessions Error: $e');
    }

    await _clearStoredAuth();
    state = const AuthState(isInitialized: true); // Keep initialized state
  }

  Future<bool> refreshToken() async {
    if (_isRefreshingToken) {
      _debugLog('Token refresh already in progress');
      return false;
    }

    _isRefreshingToken = true;
    try {
      _debugLog('Attempting token refresh');
      final refreshToken = state.refreshToken;
      
      if (refreshToken == null) {
        _debugLog('No refresh token available');
        return false;
      }

      _debugLog('Sending refresh token request');
      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      _debugLog('Refresh token response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['data']['accessToken'];
        
        if (newAccessToken == null) {
          _debugLog('Invalid token response');
          return false;
        }

        _debugLog('Token refreshed successfully');
        
        // Store tokens and update state
        await _storeTokens({
          'accessToken': newAccessToken,
          'refreshToken': refreshToken, // Keep the same refresh token
          'sessionId': state.sessionId, // Keep the same session ID
        }, state.user);
        
        state = state.copyWith(
          accessToken: newAccessToken,
          tokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
          isLoggedIn: true,
        );
        
        return true;
      } else {
        _debugLog('Refresh failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _debugLog('Refresh token error', e);
      return false;
    } finally {
      _isRefreshingToken = false;
    }
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
        
        final data = responseData['data'];
        if (data != null) {
          final updatedUser = User.fromJson(data);

          state = state.copyWith(
            isLoading: false,
            isLoggedIn: false,
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
      final currentAccessToken = state.accessToken;
      if (currentAccessToken == null) {
        state = state.copyWith(isLoading: false, error: 'Not authenticated');
        return AuthResult.error('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          ..._getDefaultHeaders(),
          'Authorization': 'Bearer $currentAccessToken',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      _logResponse(response, 'Change Password');

      if (response.statusCode == 200) {
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
    final currentAccessToken = state.accessToken;
    if (currentAccessToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          ..._getDefaultHeaders(),
          'Authorization': 'Bearer $currentAccessToken',
        },
      );

      _logResponse(response, 'Get Profile');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        final data = responseData['data'];
        if (data != null) {
          final user = User.fromJson(data);
          await _updateStoredUser(user);
          
          state = state.copyWith(
            user: user,
            isLoggedIn: user.canLogin(),
          );
        }
      } else if (response.statusCode == 401) {
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
      final errorData = json.decode(response.body);
      
      if (errorData is Map) {
        final message = errorData['message'];
        if (message != null) {
          return message.toString();
        }
        
        final error = errorData['error'];
        if (error != null) {
          return error.toString();
        }
        
        final status = errorData['status'];
        if (status is String) {
          final statusText = status.replaceAll('_', ' ').toLowerCase();
          return statusText.isNotEmpty 
            ? statusText[0].toUpperCase() + statusText.substring(1)
            : 'Unknown error';
        }
      }
    } catch (e) {
      // Fallback to status code based messages
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

  // Enhanced token storage with better logging
  Future<void> _storeTokens(Map<String, dynamic> tokens, User? user) async {
    try {
      _debugLog('Storing tokens');
      _debugLog('Tokens to store: ${json.encode(tokens)}');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Store session ID
      final sessionId = tokens['sessionId'];
      if (sessionId != null) {
        await prefs.setString('session_id', sessionId.toString());
        _debugLog('Stored session ID: $sessionId');
      } else {
        _debugLog('Warning: No session ID to store');
      }

      // Store access token
      final accessToken = tokens['accessToken'];
      if (accessToken != null) {
        await prefs.setString('access_token', accessToken.toString());
        _debugLog('Stored access token (masked): ${accessToken.toString().substring(0, 10)}...');
      } else {
        _debugLog('Warning: No access token to store');
      }
      
      // Store refresh token
      final refreshToken = tokens['refreshToken'];
      if (refreshToken != null) {
        await prefs.setString('refresh_token', refreshToken.toString());
        _debugLog('Stored refresh token (masked): ${refreshToken.toString().substring(0, 10)}...');
      } else {
        _debugLog('Warning: No refresh token to store');
      }
      
      // Store expiration
      final expiration = DateTime.now().add(const Duration(hours: 1));
      await prefs.setString('token_expires_at', expiration.toIso8601String());
      _debugLog('Stored token expiration: $expiration');
      
      // Store user data
      if (user != null) {
        final userJson = json.encode(user.toJson());
        await prefs.setString('user', userJson);
        _debugLog('Stored user data for: ${user.email}');
      } else {
        _debugLog('Warning: No user data to store');
      }

      // Ensure all data is committed
      await prefs.commit();
      _debugLog('All auth data committed to storage');
      
    } catch (e, stack) {
      _debugLog('Error storing tokens', e, stack);
      throw Exception('Failed to store authentication data: $e');
    }
  }

  Future<void> _updateStoredUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(user.toJson()));
      print('Updated stored user data for: ${user.email}');
    } catch (e) {
      print('Error updating stored user: $e');
    }
  }

  // Public method to update user data
  Future<void> updateUser(User user) async {
    await _updateStoredUser(user);
    state = state.copyWith(user: user);
  }

  Future<void> _clearStoredAuth() async {
    try {
      _debugLog('Clearing stored auth data');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user');
      await prefs.remove('token_expires_at');
      await prefs.remove('session_id');
      await prefs.commit();
      _debugLog('All auth data cleared');
    } catch (e) {
      _debugLog('Error clearing stored auth', e);
    }
  }

  // Debug logging methods
  void _logRequest(String method, String url, Map<String, dynamic> body) {
    print('=== REQUEST ===');
    print('$method $url');
    print('Headers: ${_getDefaultHeaders()}');
    print('Body: ${json.encode(body)}');
    print('===============');
  }

  void _logResponse(http.Response response, [String? operation]) {
    final opLabel = operation ?? 'Response';
    print('=== $opLabel ===');
    print('Status: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');
    print('===============');
  }

  // Clear error method
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // Method to check if user needs to complete profile
  bool get needsProfileCompletion {
    final user = state.user;
    if (user == null || !state.isLoggedIn) return false;
    
    // Add your profile completion logic here
    // For example, check if required fields are missing
    return user.name.isEmpty || 
           user.phone.isEmpty || 
           (user.profileImage?.isEmpty ?? true);
  }

  // Method to get current user safely
  User? get currentUser => state.isLoggedIn ? state.user : null;

  // Method to check if user has specific role/permission
  bool hasRole(UserType requiredRole) {
    final user = currentUser;
    return user != null && user.userType == requiredRole;
  }

  // Method to check authentication status
  bool get isAuthenticated => state.isLoggedIn && state.user != null;

  // Method to get authentication headers for API calls
  Map<String, String> getAuthHeaders() {
    final token = state.accessToken;
    if (token == null) return _getDefaultHeaders();
    
    return {
      ..._getDefaultHeaders(),
      'Authorization': 'Bearer $token',
    };
  }

  // Method to handle token expiration during API calls
  Future<Map<String, String>> getValidAuthHeaders() async {
    if (state.needsRefresh) {
      final refreshed = await refreshToken();
      if (!refreshed) {
        throw Exception('Token refresh failed');
      }
    }
    return getAuthHeaders();
  }

  @override
  set state(AuthState newState) {
    final oldState = super.state;
    super.state = newState;
    
    // Log state changes for debugging
    if (oldState.isLoggedIn != newState.isLoggedIn) {
      print('🔐 Auth: State changed - isLoggedIn: ${oldState.isLoggedIn} -> ${newState.isLoggedIn}');
      print('🔐 Auth: Stack trace: ${StackTrace.current}');
    }
    if (oldState.user != newState.user) {
      print('🔐 Auth: State changed - user: ${oldState.user?.name} -> ${newState.user?.name}');
    }
    if (oldState.error != newState.error) {
      print('🔐 Auth: State changed - error: ${oldState.error} -> ${newState.error}');
    }
  }
}

// Provider for the auth notifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Convenience providers for common auth state access
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isLoggedIn ? authState.user : null;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

final needsVerificationProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null && !user.isEmailVerified;
});

final isInitializedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isInitialized;
});

// User-related providers
final userProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

final authenticatedUserProvider = Provider<User>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) {
    throw UnauthorizedException('No authenticated user found');
  }
  return user;
});

final userTypeProvider = Provider<UserType?>((ref) {
  return ref.watch(userProvider)?.userType;
});

final userRoleProvider = Provider.family<bool, UserType>((ref, requiredRole) {
  final userType = ref.watch(userTypeProvider);
  return userType == requiredRole;
});

// Add this exception class at the top of the file with other exceptions
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => message;
}

// Usage example in widgets:
// final user = ref.watch(userProvider); // Nullable user
// final authenticatedUser = ref.watch(authenticatedUserProvider); // Non-null user or throws
// final userType = ref.watch(userTypeProvider);
// final isPhotographer = ref.watch(userRoleProvider(UserType.photographer));

// Helper extension for easier access in widgets
extension AuthStateExtension on AuthState {
  bool get hasError => error != null && error!.isNotEmpty;
  bool get isReady => isInitialized && !isLoading;
}