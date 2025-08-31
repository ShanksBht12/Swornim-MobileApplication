import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:swornim/pages/models/bookings/service_package.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/config/app_config.dart';

class PackageManager {
  final Ref ref;
  PackageManager(this.ref);

  final String baseUrl = AppConfig.packagesUrl;

  Future<List<ServicePackage>> fetchPackagesForProvider(String serviceProviderId) async {
    print('🔐 PackageManager: Starting fetchPackagesForProvider for: $serviceProviderId');
    print('🔐 PackageManager: Auth state before fetch - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
    
    final headers = ref.read(authProvider.notifier).getAuthHeaders();
    final url = '$baseUrl?service_provider_id=$serviceProviderId';
    print('[PackageManager] Fetching packages for provider: $serviceProviderId');
    print('[PackageManager] GET $url');
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    print('[PackageManager] Status: ${response.statusCode}');
    print('[PackageManager] Body: ${response.body}');
    
    print('🔐 PackageManager: Auth state after fetch - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
    
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        final packages = decoded.map((json) => ServicePackage.fromJson(json)).toList();
        print('🔐 PackageManager: Successfully parsed ${packages.length} packages');
        return packages;
      } else if (decoded is Map && decoded['data'] is List) {
        // Fallback for wrapped array
        final packages = (decoded['data'] as List).map((json) => ServicePackage.fromJson(json)).toList();
        print('🔐 PackageManager: Successfully parsed ${packages.length} packages from wrapped data');
        return packages;
      } else {
        print('[PackageManager] Unexpected response format');
        return [];
      }
    } else {
      print('Fetch packages failed: status=${response.statusCode}, body=${response.body}');
      throw Exception('Failed to fetch packages');
    }
  }

  Future<ServicePackage> createPackage(ServicePackage pkg) async {
    print('🔐 PackageManager: Starting createPackage');
    print('🔐 PackageManager: Package data: ${jsonEncode(pkg.toJson(forCreation: true))}');
    
    final headers = ref.read(authProvider.notifier).getAuthHeaders();
    print('🔐 PackageManager: Auth headers: ${headers['Authorization']}');
    print('🔐 PackageManager: Current auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
    print('🔐 PackageManager: Current auth state - user: ${ref.read(authProvider).user?.name}');
    
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(pkg.toJson(forCreation: true)),
    );
    
    print('🔐 PackageManager: Response status: ${response.statusCode}');
    print('🔐 PackageManager: Response body: ${response.body}');
    print('🔐 PackageManager: Auth state after request - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
    
    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      print('🔐 PackageManager: Package created successfully');
      print('🔐 PackageManager: Final auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
      return ServicePackage.fromJson(json);
    } else {
      String backendMsg = '';
      try {
        backendMsg = jsonDecode(response.body)['error'] ?? '';
      } catch (_) {}
      print('🔐 PackageManager: Failed to create package: $backendMsg');
      print('🔐 PackageManager: Auth state after error - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
      throw Exception('Failed to create package: $backendMsg');
    }
  }

  Future<ServicePackage> updatePackage(String id, Map<String, dynamic> updates) async {
    final headers = ref.read(authProvider.notifier).getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode(updates),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ServicePackage.fromJson(json);
    } else {
      String backendMsg = '';
      try {
        backendMsg = jsonDecode(response.body)['error'] ?? '';
      } catch (_) {}
      throw Exception('Failed to update package: $backendMsg');
    }
  }

  Future<void> deletePackage(String id) async {
    final headers = ref.read(authProvider.notifier).getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete package');
    }
  }
} 