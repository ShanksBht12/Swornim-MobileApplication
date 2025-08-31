import 'user_types.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final UserType userType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  
  // Auth fields
  final String? passwordHash;
  final String? resetToken;
  final DateTime? resetTokenExpiry;
  final bool isEmailVerified;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.passwordHash,
    this.resetToken,
    this.resetTokenExpiry,
    this.isEmailVerified = false,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both camelCase and snake_case field names
      final userTypeRaw = json['user_type'] ?? json['userType'];
      final userTypeParsed = _parseUserType(userTypeRaw);
      print('[DEBUG] User.fromJson userType: $userTypeRaw -> $userTypeParsed');
      return User(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        profileImage: json['profile_image'] ?? json['profileImage'],
        userType: userTypeParsed,
        createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']) ?? DateTime.now(),
        isActive: json['is_active'] ?? json['isActive'] ?? true,
        passwordHash: json['password_hash'] ?? json['passwordHash'],
        resetToken: json['reset_token'] ?? json['resetToken'],
        resetTokenExpiry: _parseDateTime(json['reset_token_expiry'] ?? json['resetTokenExpiry']),
        isEmailVerified: json['is_email_verified'] ?? json['isEmailVerified'] ?? false,
        lastLoginAt: _parseDateTime(json['last_login_at'] ?? json['lastLoginAt']),
      );
    } catch (e, stack) {
      print('Error parsing User JSON: $e');
      print('Stack trace: $stack');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return value is DateTime ? value : DateTime.parse(value.toString());
    } catch (e) {
      print('Error parsing date: $value');
      return null;
    }
  }

  static UserType _parseUserType(dynamic type) {
    if (type == null) return UserType.client;
    
    final typeStr = type.toString().toLowerCase();
    switch (typeStr) {
      case 'photographer':
        return UserType.photographer;
      case 'makeup_artist':
      case 'makeupartist':
        return UserType.makeupArtist;
      case 'decorator':
        return UserType.decorator;
      case 'venue':
        return UserType.venue;
      case 'caterer':
        return UserType.caterer;
      case 'event_organizer':
      case 'eventorganizer':
        return UserType.eventOrganizer;
      case 'client':
      default:
        return UserType.client;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'user_type': userType.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSafeJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'user_type': userType.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
    };
  }

  bool canLogin() {
    return isActive && isEmailVerified;
  }

  bool isPasswordResetTokenValid() {
    return resetToken != null && 
           resetTokenExpiry != null && 
           resetTokenExpiry!.isAfter(DateTime.now());
  }
}

