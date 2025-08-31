import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swornim/config/app_config.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:swornim/pages/services/simple_image_service.dart';

class ServiceProviderProfileService {
  // Get service provider profile
  static Future<Map<String, dynamic>?> getProfile({
    required UserType userType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final endpoint = _getProfileEndpoint(userType);
      final response = await http.get(
        Uri.parse('$endpoint/profile/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data'];
      } else if (response.statusCode == 404) {
        // Profile doesn't exist yet
        return null;
      } else {
        throw Exception('Failed to get profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting profile: $e');
      rethrow;
    }
  }

  // Update service provider profile
  static Future<Map<String, dynamic>> updateProfile({
    required UserType userType,
    required Map<String, dynamic> profileData,
    File? profileImage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final endpoint = _getProfileEndpoint(userType);
      
      if (profileImage != null) {
        // Upload with image
        var request = http.MultipartRequest('PUT', Uri.parse('$endpoint/profile'));
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';

        // Add profile image
        print('DEBUG: Adding profile image to request:');
        print('  - File path: ${profileImage.path}');
        print('  - File exists: ${await profileImage.exists()}');
        print('  - File size: ${await profileImage.length()} bytes');
        
        // Determine content type based on file extension
        MediaType contentType = MediaType('image', 'jpeg'); // default
        final extension = profileImage.path.split('.').last.toLowerCase();
        switch (extension) {
          case 'png':
            contentType = MediaType('image', 'png');
            break;
          case 'gif':
            contentType = MediaType('image', 'gif');
            break;
          case 'webp':
            contentType = MediaType('image', 'webp');
            break;
          case 'bmp':
            contentType = MediaType('image', 'bmp');
            break;
          case 'jpg':
          case 'jpeg':
          default:
            contentType = MediaType('image', 'jpeg');
            break;
        }
        
        // Determine the correct field name based on user type
        String imageFieldName = 'profileImage'; // default
        if (userType == UserType.venue) {
          imageFieldName = 'image';
        }
        
        final multipartFile = await http.MultipartFile.fromPath(
          imageFieldName,
          profileImage.path,
          contentType: contentType,
        );
        
        print('DEBUG: MultipartFile created:');
        print('  - Field name: ${multipartFile.field}');
        print('  - File name: ${multipartFile.filename}');
        print('  - Content type: ${multipartFile.contentType}');
        print('  - Length: ${multipartFile.length}');
        
        request.files.add(multipartFile);

        // Add other fields
        profileData.forEach((key, value) {
          if (value != null) {
            if (value is List) {
              // Handle arrays by converting to JSON string
              request.fields[key] = json.encode(value);
            } else {
              request.fields[key] = value.toString();
            }
          }
        });

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          return jsonData['data'];
        } else {
          throw Exception('Failed to update profile: ${response.statusCode} - ${response.body}');
        }
      } else {
        // Update without image
        final response = await http.put(
          Uri.parse('$endpoint/profile'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(profileData),
        );

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          return jsonData['data'];
        } else {
          throw Exception('Failed to update profile: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Add portfolio image
  static Future<String?> addPortfolioImage({
    required UserType userType,
    required File imageFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final endpoint = _getProfileEndpoint(userType);
      
      var request = http.MultipartRequest('POST', Uri.parse('$endpoint/portfolio/images'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Determine content type based on file extension
      MediaType contentType = MediaType('image', 'jpeg'); // default
      final extension = imageFile.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'png':
          contentType = MediaType('image', 'png');
          break;
        case 'gif':
          contentType = MediaType('image', 'gif');
          break;
        case 'webp':
          contentType = MediaType('image', 'webp');
          break;
        case 'bmp':
          contentType = MediaType('image', 'bmp');
          break;
        case 'jpg':
        case 'jpeg':
        default:
          contentType = MediaType('image', 'jpeg');
          break;
      }

      // Add portfolio image
      request.files.add(
        await http.MultipartFile.fromPath(
          'portfolioImage',
          imageFile.path,
          contentType: contentType,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('DEBUG: Portfolio upload response: $jsonData');
        
        // Get the portfolio images array based on user type
        List<dynamic>? portfolioImages;
        
        if (userType == UserType.venue) {
          // Venues store portfolio images in 'images' field
          portfolioImages = jsonData['data']['images'] as List<dynamic>?;
          print('DEBUG: Checking images array for venue: $portfolioImages');
        } else {
          // Other service providers use 'portfolioImages' or 'portfolio'
          portfolioImages = jsonData['data']['portfolioImages'] as List<dynamic>?;
          print('DEBUG: Checking portfolioImages array: $portfolioImages');
          
          // Fallback to portfolio field if portfolioImages doesn't exist
          if (portfolioImages == null) {
            portfolioImages = jsonData['data']['portfolio'] as List<dynamic>?;
            print('DEBUG: Checking portfolio array (fallback): $portfolioImages');
          }
        }
        
        if (portfolioImages != null && portfolioImages.isNotEmpty) {
          return portfolioImages.last.toString();
        }
        
        throw Exception('No portfolio images found in response');
      } else {
        throw Exception('Failed to add portfolio image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error adding portfolio image: $e');
      rethrow;
    }
  }

  // Remove portfolio image
  static Future<bool> removePortfolioImage({
    required UserType userType,
    required String imageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final endpoint = _getProfileEndpoint(userType);
      
      final response = await http.delete(
        Uri.parse('$endpoint/portfolio/images'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'imageUrl': imageUrl}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error removing portfolio image: $e');
      return false;
    }
  }

  // Update availability
  static Future<bool> updateAvailability({
    required UserType userType,
    required bool isAvailable,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final endpoint = _getProfileEndpoint(userType);
      
      final response = await http.patch(
        Uri.parse('$endpoint/availability'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'isAvailable': isAvailable}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating availability: $e');
      return false;
    }
  }

  // Update hourly rate
  static Future<bool> updateHourlyRate({
    required UserType userType,
    required double hourlyRate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final endpoint = _getProfileEndpoint(userType);
      
      final response = await http.patch(
        Uri.parse('$endpoint/hourly-rate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'hourlyRate': hourlyRate}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating hourly rate: $e');
      return false;
    }
  }

  // Add specialization
  static Future<bool> addSpecialization({
    required UserType userType,
    required String specialization,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final endpoint = _getProfileEndpoint(userType);
      
      final response = await http.post(
        Uri.parse('$endpoint/specializations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'specialization': specialization}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error adding specialization: $e');
      return false;
    }
  }

  // Remove specialization
  static Future<bool> removeSpecialization({
    required UserType userType,
    required String specialization,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final endpoint = _getProfileEndpoint(userType);
      
      final response = await http.delete(
        Uri.parse('$endpoint/specializations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'specialization': specialization}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error removing specialization: $e');
      return false;
    }
  }

  // Get profile fields based on user type
  static Map<String, dynamic> getProfileFields(UserType userType) {
    switch (userType) {
      case UserType.photographer:
        return {
          'businessName': '',
          'description': '',
          'specializations': <String>[],
          'hourlyRate': 0.0,
          'experience': '',
          'rating': 0.0,
          'totalReviews': 0,
          'isAvailable': true,
          'portfolioImages': <String>[],
          'profileImage': '',
          'location': null,
        };
      case UserType.makeupArtist:
        return {
          'businessName': '',
          'description': '',
          'specializations': <String>[],
          'brands': <String>[],
          'sessionRate': 0.0,
          'bridalPackageRate': 0.0,
          'experienceYears': 0,
          'offersHairServices': false,
          'travelsToClient': true,
          'availableDates': <String>[],
          'portfolioImages': <String>[],
          'location': null,
        };
      case UserType.decorator:
        return {
          'businessName': '',
          'description': '',
          'specializations': <String>[],
          'themes': <String>[],
          'packageStartingPrice': 0.0,
          'hourlyRate': 0.0,
          'experienceYears': 0,
          'offersFlowerArrangements': false,
          'offersLighting': false,
          'offersRentals': false,
          'availableItems': <String>[],
          'availableDates': <String>[],
          'location': null,
        };
      case UserType.venue:
        return {
          'businessName': '',
          'description': '',
          'capacity': 0,
          'pricePerHour': 0.0,
          'amenities': <String>[],
          'venueTypes': <String>[],
          'location': null,
        };
      case UserType.caterer:
        return {
          'businessName': '',
          'description': '',
          'cuisineTypes': <String>[],
          'serviceTypes': <String>[],
          'pricePerPerson': 0.0,
          'minGuests': 10,
          'maxGuests': 500,
          'menuItems': <String>[],
          'dietaryOptions': <String>[],
          'offersEquipment': false,
          'offersWaiters': false,
          'availableDates': <String>[],
          'experienceYears': 0,
          'location': null,
        };
      default:
        return {
          'businessName': '',
          'description': '',
          'location': null,
        };
    }
  }

  // Get field labels based on user type
  static Map<String, String> getFieldLabels(UserType userType) {
    switch (userType) {
      case UserType.photographer:
        return {
          'businessName': 'Studio Name',
          'description': 'About Your Photography',
          'specializations': 'Photography Styles',
          'hourlyRate': 'Hourly Rate (Rs)',
          'experience': 'Experience',
          'rating': 'Rating',
          'totalReviews': 'Total Reviews',
          'isAvailable': 'Available for Bookings',
          'portfolioImages': 'Portfolio Images',
          'profileImage': 'Profile Image',
        };
      case UserType.makeupArtist:
        return {
          'businessName': 'Business Name',
          'description': 'About Your Services',
          'specializations': 'Makeup Styles',
          'brands': 'Brands You Work With',
          'sessionRate': 'Session Rate (Rs)',
          'bridalPackageRate': 'Bridal Package Rate (Rs)',
          'experienceYears': 'Years of Experience',
          'offersHairServices': 'Offer Hair Services',
          'travelsToClient': 'Travel to Client',
          'portfolioImages': 'Portfolio Images',
        };
      case UserType.decorator:
        return {
          'businessName': 'Business Name',
          'description': 'About Your Services',
          'specializations': 'Decoration Styles',
          'themes': 'Event Themes',
          'packageStartingPrice': 'Package Starting Price (Rs)',
          'hourlyRate': 'Hourly Rate (Rs)',
          'experienceYears': 'Years of Experience',
          'offersFlowerArrangements': 'Offer Flower Arrangements',
          'offersLighting': 'Offer Lighting Services',
          'offersRentals': 'Offer Equipment Rentals',
          'availableItems': 'Available Items',
        };
      case UserType.venue:
        return {
          'businessName': 'Venue Name',
          'description': 'About Your Venue',
          'capacity': 'Capacity',
          'pricePerHour': 'Price Per Hour (Rs)',
          'amenities': 'Amenities',
          'venueTypes': 'Venue Types',
        };
      case UserType.caterer:
        return {
          'businessName': 'Business Name',
          'description': 'About Your Services',
          'cuisineTypes': 'Cuisine Types',
          'serviceTypes': 'Service Types',
          'pricePerPerson': 'Price Per Person (Rs)',
          'minGuests': 'Minimum Guests',
          'maxGuests': 'Maximum Guests',
          'menuItems': 'Menu Items',
          'dietaryOptions': 'Dietary Options',
          'offersEquipment': 'Offer Equipment',
          'offersWaiters': 'Offer Waiters',
          'experienceYears': 'Years of Experience',
        };
      default:
        return {
          'businessName': 'Business Name',
          'description': 'Description',
        };
    }
  }

  // Get field types for validation
  static Map<String, String> getFieldTypes(UserType userType) {
    switch (userType) {
      case UserType.photographer:
        return {
          'businessName': 'text',
          'description': 'textarea',
          'specializations': 'list',
          'hourlyRate': 'number',
          'experience': 'text',
          'rating': 'number',
          'totalReviews': 'number',
          'isAvailable': 'boolean',
          'portfolioImages': 'list',
          'profileImage': 'text',
        };
      case UserType.makeupArtist:
        return {
          'businessName': 'text',
          'description': 'textarea',
          'specializations': 'list',
          'brands': 'list',
          'sessionRate': 'number',
          'bridalPackageRate': 'number',
          'experienceYears': 'number',
          'offersHairServices': 'boolean',
          'travelsToClient': 'boolean',
          'portfolioImages': 'list',
        };
      case UserType.decorator:
        return {
          'businessName': 'text',
          'description': 'textarea',
          'specializations': 'list',
          'themes': 'list',
          'packageStartingPrice': 'number',
          'hourlyRate': 'number',
          'experienceYears': 'number',
          'offersFlowerArrangements': 'boolean',
          'offersLighting': 'boolean',
          'offersRentals': 'boolean',
          'availableItems': 'list',
        };
      case UserType.venue:
        return {
          'businessName': 'text',
          'description': 'textarea',
          'capacity': 'number',
          'pricePerHour': 'number',
          'amenities': 'list',
          'venueTypes': 'list',
        };
      case UserType.caterer:
        return {
          'businessName': 'text',
          'description': 'textarea',
          'cuisineTypes': 'list',
          'serviceTypes': 'list',
          'pricePerPerson': 'number',
          'minGuests': 'number',
          'maxGuests': 'number',
          'menuItems': 'list',
          'dietaryOptions': 'list',
          'offersEquipment': 'boolean',
          'offersWaiters': 'boolean',
          'experienceYears': 'number',
        };
      default:
        return {
          'businessName': 'text',
          'description': 'textarea',
        };
    }
  }

  // Helper method to get endpoint based on user type
  static String _getProfileEndpoint(UserType userType) {
    switch (userType) {
      case UserType.photographer:
        return AppConfig.photographersUrl;
      case UserType.makeupArtist:
        return AppConfig.makeupArtistsUrl;
      case UserType.decorator:
        return AppConfig.decoratorsUrl;
      case UserType.venue:
        return AppConfig.venuesUrl;
      case UserType.caterer:
        return AppConfig.caterersUrl;
      case UserType.eventOrganizer:
        return AppConfig.eventOrganizersUrl;
      default:
        return AppConfig.photographersUrl;
    }
  }
} 