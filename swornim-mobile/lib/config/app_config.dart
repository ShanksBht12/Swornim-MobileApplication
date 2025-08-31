import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class AppConfig {
  // Auto-detection variables
  static String? _detectedIP;
  static DateTime? _lastDetection;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  static bool _isInitialized = false;
  
  // Known server IPs for auto-detection (add your new IP here)
  static const List<String> _possibleServerIPs = [
    '2b12c0022ef9.ngrok-free.app', // Your ngrok URL (highest priority)
    '10.253.234.187',  // Your current server IP
    '192.168.1.188',   // Your old WiFi at home
    '10.47.136.176',   // Your Ethernet at previous location
    '192.168.0.188',   // Alternative networks
    '10.0.0.188',
    'localhost', 
        // For local testing
  ];

  // Base URLs for different environments
  static const String _emulatorBaseUrl = 'http://10.0.2.2:9009/api/v1';
  static const String _productionBaseUrl = 'https://your-production-domain.com/api/v1';

  // Current device base URL (will be updated by auto-detection)
  static String _currentDeviceBaseUrl = 'https://f0f8ba2ec8cd.ngrok-free.app/api/v1'; // Updated default for ngrok

  // Auto-detect the correct server IP
  static Future<String> _getServerIP() async {
    // Return cached IP if still valid
    if (_detectedIP != null && 
        _lastDetection != null && 
        DateTime.now().difference(_lastDetection!) < _cacheTimeout) {
      return _detectedIP!;
    }

    print('🔍 Auto-detecting server IP...');
    
    // Get device's current network to generate smart guesses
    List<String> deviceIPs = await _getDeviceIPs();
    Set<String> ipsToTry = <String>{};
    
    // Add known server IPs first (higher priority)
    ipsToTry.addAll(_possibleServerIPs);
    
    // Add IPs from same subnet as device
    for (String deviceIP in deviceIPs) {
      List<String> parts = deviceIP.split('.');
      if (parts.length == 4) {
        String subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
        
        // Try common server IPs in this subnet
        for (int i = 1; i <= 255; i++) {
          // Focus on common server IP patterns
          if ([1, 100, 101, 176, 187, 188, 200].contains(i)) {
            ipsToTry.add('$subnet.$i');
          }
        }
      }
    }
    
    print('🎯 Testing ${ipsToTry.length} potential IPs...');
    print('📍 Device IPs: $deviceIPs');
    
    // Test each IP with faster timeout and parallel testing
    List<Future<String?>> tests = ipsToTry.map((ip) => _testIP(ip)).toList();
    
    // Wait for first successful connection
    for (Future<String?> test in tests) {
      String? result = await test;
      if (result != null) {
        _detectedIP = result;
        _lastDetection = DateTime.now();
        print('✅ Found server at: $result');
        return result;
      }
    }
    
    // If all fail, try localhost as last resort
    if (await _testServerConnection('localhost')) {
      _detectedIP = 'localhost';
      _lastDetection = DateTime.now();
      print('✅ Found server at localhost');
      return 'localhost';
    }
    
    // Fallback to the ngrok URL
    print('⚠️ Auto-detection failed, using fallback ngrok URL');
    return 'f0f8ba2ec8cd.ngrok-free.app';
  }

  static Future<String?> _testIP(String ip) async {
    if (await _testServerConnection(ip)) {
      return ip;
    }
    return null;
  }

  static Future<List<String>> _getDeviceIPs() async {
    List<String> ips = [];
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            ips.add(addr.address);
            print('📱 Device IP found: ${addr.address} on ${interface.name}');
          }
        }
      }
    } catch (e) {
      print('❌ Error getting device IPs: $e');
    }
    return ips;
  }

  static Future<bool> _testServerConnection(String ip) async {
    try {
      String url;
      
      // Handle different types of IPs/URLs
      if (ip.contains('ngrok') || ip.contains('.app')) {
        url = 'https://$ip/api/v1/auth/login'; // HTTPS for ngrok, no port
      } else if (ip == 'localhost') {
        url = 'http://localhost:9009/api/v1/auth/login'; // HTTP for localhost with port
      } else {
        url = 'http://$ip:9009/api/v1/auth/login'; // HTTP for local IPs with port
      }
          
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 2)); // Reduced timeout for faster detection
      
      print('🧪 Testing $ip: ${response.statusCode}');
      return response.statusCode < 500;
    } catch (e) {
      print('❌ Failed to connect to $ip: ${e.toString().split(' ').take(5).join(' ')}');
      return false;
    }
  }

  // Initialize method - call this once at app startup
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (kDebugMode) {
      print('🚀 Initializing AppConfig...');
      final detectedIP = await _getServerIP();
      
      // Set the base URL based on detected IP type
      if (detectedIP.contains('ngrok') || detectedIP.contains('.app')) {
        _currentDeviceBaseUrl = 'https://$detectedIP/api/v1'; // HTTPS for ngrok
      } else if (detectedIP == 'localhost') {
        _currentDeviceBaseUrl = 'http://localhost:9009/api/v1';
      } else {
        _currentDeviceBaseUrl = 'http://$detectedIP:9009/api/v1';
      }
      
      print('🎯 AppConfig initialized with: $_currentDeviceBaseUrl');
    }
    
    _isInitialized = true;
  }

  // Get the appropriate base URL based on environment
  static String get baseUrl {
    if (kDebugMode) {
      // For real device testing, use auto-detected device URL
      // For emulator testing, use emulator URL
      return _currentDeviceBaseUrl; // Auto-detected IP
      // return _emulatorBaseUrl; // Use this for emulator testing
    } else {
      // In release mode, use production URL
      return _productionBaseUrl;
    }
  }

  // Auth endpoints
  static String get authBaseUrl => '$baseUrl/auth';
  
  // Service provider endpoints
  static String get photographersUrl => '$baseUrl/photographers';
  static String get makeupArtistsUrl => '$baseUrl/makeup-artists';
  static String get decoratorsUrl => '$baseUrl/decorators';
  static String get venuesUrl => '$baseUrl/venues';
  static String get caterersUrl => '$baseUrl/caterers';
  static String get eventOrganizersUrl => '$baseUrl/event-organizers';
  
  // Booking endpoints
  static String get bookingsUrl => '$baseUrl/bookings';
  static String get packagesUrl => '$baseUrl/packages';
  
  // Payment endpoints
  static String get paymentsUrl => '$baseUrl/payments';
  
  // User endpoints
  static String get usersUrl => '$baseUrl/users';

  // Helper method to get service provider URL by type
  static String getServiceProviderUrl(String type) {
    switch (type.toLowerCase()) {
      case 'photographers':
        return photographersUrl;
      case 'makeup-artists':
        return makeupArtistsUrl;
      case 'decorators':
        return decoratorsUrl;
      case 'venues':
        return venuesUrl;
      case 'caterers':
        return caterersUrl;
      case 'event-organizers':
      case 'eventorganizers':
      case 'event_organizers':
        return eventOrganizersUrl;
      default:
        return '$baseUrl/$type';
    }
  }

  // Helper method to get service provider type from URL
  static String getServiceProviderType(String url) {
    if (url.contains('photographers')) return 'photographers';
    if (url.contains('makeup-artists')) return 'makeup-artists';
    if (url.contains('decorators')) return 'decorators';
    if (url.contains('venues')) return 'venues';
    if (url.contains('caterers')) return 'caterers';
    return 'unknown';
  }

  // Utility methods for debugging
  static void clearCache() {
    _detectedIP = null;
    _lastDetection = null;
    _isInitialized = false;
    print('🗑️ IP cache cleared');
  }

  // FIXED forceIP method to handle ngrok URLs properly
  static void forceIP(String ip) {
    _detectedIP = ip;
    _lastDetection = DateTime.now();
    
    // Check if it's an ngrok URL
    if (ip.contains('ngrok') || ip.contains('.app')) {
      _currentDeviceBaseUrl = 'https://$ip/api/v1'; // Use HTTPS for ngrok, no port
    } else if (ip == 'localhost') {
      _currentDeviceBaseUrl = 'http://localhost:9009/api/v1';
    } else {
      _currentDeviceBaseUrl = 'http://$ip:9009/api/v1'; // Regular local IP with port
    }
    
    _isInitialized = true;
    print('🔧 Forced server IP to: $ip');
    print('🎯 Base URL updated to: $_currentDeviceBaseUrl');
  }

  // Method to refresh/re-detect IP (useful when changing networks)
  static Future<void> refresh() async {
    print('🔄 Refreshing network configuration...');
    clearCache();
    await initialize();
  }

  // Method to get current server status
  static Future<Map<String, dynamic>> getServerStatus() async {
    return {
      'current_base_url': _currentDeviceBaseUrl,
      'detected_ip': _detectedIP,
      'last_detection': _lastDetection?.toIso8601String(),
      'is_initialized': _isInitialized,
      'cache_valid': _detectedIP != null && 
          _lastDetection != null && 
          DateTime.now().difference(_lastDetection!) < _cacheTimeout,
    };
  }
}