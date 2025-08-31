// File: lib/services/auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/user/user_types.dart' as types;

class AuthService {
  static String hashPassword(String password) {
    // Add a random salt for better security
    final salt = 'your_app_salt_here'; // Use a proper salt in production
    var bytes = utf8.encode(password + salt);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  static User signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required types.UserType userType,
  }) {
    return User(
      id: _generateId(),
      name: name,
      email: email,
      phone: phone,
      userType: userType,
      passwordHash: hashPassword(password),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      isEmailVerified: false,
    );
  }

  static User? login(String email, String password, List<User> users) {
    try {
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      
      if (!user.canLogin()) {
        throw Exception('Account not active or email not verified');
      }
      
      if (user.passwordHash != null && 
          verifyPassword(password, user.passwordHash!)) {
        return user;
      }
      
      throw Exception('Invalid password');
    } catch (e) {
      return null;
    }
  }

  static String _generateId() {
    // Simple ID generation - use UUID in production
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(9999).toString();
  }

  // Helper method to check if user can access service provider features
  static bool canAccessServiceProviderFeatures(User user) {
    return user.userType != types.UserType.client && user.isActive;
  }

  // Helper method to check if user can access event organizer features
  static bool canAccessEventOrganizerFeatures(User user) {
    return user.userType == types.UserType.eventOrganizer && user.isActive;
  }

  // Helper method to check if user can create events
  static bool canCreateEvents(User user) {
    return user.userType == types.UserType.eventOrganizer && user.isActive && user.isEmailVerified;
  }

  // Get user role display name
  static String getUserRoleDisplayName(types.UserType userType) {
    switch (userType) {
      case types.UserType.client:
        return 'Client';
      case types.UserType.photographer:
        return 'Photographer';
      case types.UserType.makeupArtist:
        return 'Makeup Artist';
      case types.UserType.decorator:
        return 'Decorator';
      case types.UserType.venue:
        return 'Venue Owner';
      case types.UserType.caterer:
        return 'Caterer';
      case types.UserType.eventOrganizer:
        return 'Event Organizer';
    }
  }

  // Get user capabilities based on user type
  static List<String> getUserCapabilities(types.UserType userType) {
    switch (userType) {
      case types.UserType.client:
        return [
          'Book services',
          'Write reviews',
          'View events',
          'Contact service providers',
        ];
      case types.UserType.photographer:
        return [
          'Manage photography services',
          'Accept bookings',
          'Upload portfolio',
          'Set pricing',
        ];
      case types.UserType.makeupArtist:
        return [
          'Manage makeup services',
          'Accept bookings',
          'Upload portfolio',
          'Set pricing',
        ];
      case types.UserType.decorator:
        return [
          'Manage decoration services',
          'Accept bookings',
          'Upload portfolio',
          'Set pricing',
        ];
      case types.UserType.venue:
        return [
          'Manage venue listings',
          'Accept bookings',
          'Upload venue images',
          'Set pricing',
        ];
      case types.UserType.caterer:
        return [
          'Manage catering services',
          'Accept bookings',
          'Upload menu items',
          'Set pricing',
        ];
      case types.UserType.eventOrganizer:
        return [
          'Create and manage events',
          'Book service providers',
          'Manage event bookings',
          'Event analytics',
          'Create event templates',
          'Publish public events',
        ];
    }
  }
}

// Usage example:
void exampleUsage() {
  // Signup as Event Organizer
  final newEventOrganizer = AuthService.signup(
    name: 'Raj Event Management',
    email: 'raj@eventmanagement.com',
    phone: '9876543210',
    password: 'securePassword123',
    userType: types.UserType.eventOrganizer,
  );

  print('Event Organizer created: ${newEventOrganizer.name} as ${AuthService.getUserRoleDisplayName(newEventOrganizer.userType)}');

  // Check capabilities
  final capabilities = AuthService.getUserCapabilities(newEventOrganizer.userType);
  print('Capabilities: ${capabilities.join(', ')}');

  // Login
  List<User> users = [newEventOrganizer];
  
  // This would fail because email is not verified
  var loginResult = AuthService.login('raj@eventmanagement.com', 'securePassword123', users);
  print('Login result: ${loginResult != null ? 'Success' : 'Failed (email not verified)'}');

  // Simulate email verification
  final verifiedEventOrganizer = User(
    id: newEventOrganizer.id,
    name: newEventOrganizer.name,
    email: newEventOrganizer.email,
    phone: newEventOrganizer.phone,
    userType: newEventOrganizer.userType,
    passwordHash: newEventOrganizer.passwordHash,
    createdAt: newEventOrganizer.createdAt,
    updatedAt: DateTime.now(),
    isActive: true,
    isEmailVerified: true, // Now verified
  );

  users = [verifiedEventOrganizer];
  loginResult = AuthService.login('raj@eventmanagement.com', 'securePassword123', users);
  print('Login after verification: ${loginResult != null ? 'Success' : 'Failed'}');

  // Check event organizer specific permissions
  if (loginResult != null) {
    final canAccessEventFeatures = AuthService.canAccessEventOrganizerFeatures(loginResult);
    final canCreateEvents = AuthService.canCreateEvents(loginResult);
    print('Can access event organizer features: $canAccessEventFeatures');
    print('Can create events: $canCreateEvents');
  }
}