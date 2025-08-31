// File: lib/pages/providers/service_providers/service_provider_factory.dart - COMPLETE VERSION

import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';
import 'package:swornim/pages/providers/service_providers/models/caterer.dart';
import 'package:swornim/pages/providers/service_providers/models/decorator.dart';
import 'package:swornim/pages/providers/service_providers/models/event_organizer.dart';
import 'package:swornim/pages/providers/service_providers/models/makeup_artist.dart';
import 'package:swornim/pages/providers/service_providers/models/photographer.dart';
import 'package:swornim/pages/providers/service_providers/models/venue.dart';

enum ServiceProviderType {
  makeupArtist,
  photographer,
  venue,
  caterer,
  decorator,
  eventOrganizer,
}

extension ServiceProviderTypeExtension on ServiceProviderType {
  String get name {
    switch (this) {
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

  String get displayName {
    switch (this) {
      case ServiceProviderType.makeupArtist:
        return 'Makeup Artist';
      case ServiceProviderType.photographer:
        return 'Photographer';
      case ServiceProviderType.venue:
        return 'Venue';
      case ServiceProviderType.caterer:
        return 'Caterer';
      case ServiceProviderType.decorator:
        return 'Decorator';
      case ServiceProviderType.eventOrganizer:
        return 'Event Organizer';
    }
  }
}

class ServiceProviderFactory {
  /// Helper method to safely parse string to double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Helper method to safely parse string to int
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// Helper method to safely parse string
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// Helper method to safely parse boolean
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  /// Helper method to safely parse list of strings
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Helper method to normalize JSON data from Django API
  static Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    
    // Map camelCase backend fields to expected snake_case fields
    if (normalized.containsKey('userId')) normalized['user_id'] = normalized['userId'];
    if (normalized.containsKey('businessName')) normalized['business_name'] = normalized['businessName'];
    if (normalized.containsKey('profileImage')) normalized['image'] = normalized['profileImage'];
    if (normalized.containsKey('profileImagePublicId')) normalized['image_public_id'] = normalized['profileImagePublicId'];
    if (normalized.containsKey('portfolioImages')) normalized['portfolio'] = normalized['portfolioImages'];
    if (normalized.containsKey('hourlyRate')) normalized['hourly_rate'] = double.tryParse(normalized['hourlyRate'].toString()) ?? 0.0;
    if (normalized.containsKey('eventRate')) normalized['event_rate'] = double.tryParse(normalized['eventRate'].toString()) ?? 0.0;
    if (normalized.containsKey('totalReviews')) normalized['total_reviews'] = normalized['totalReviews'];
    if (normalized.containsKey('isAvailable')) normalized['is_available'] = normalized['isAvailable'];
    if (normalized.containsKey('experience')) normalized['experience_years'] = int.tryParse(normalized['experience'].toString()) ?? 0;
    if (normalized.containsKey('experienceYears')) normalized['experience_years'] = normalized['experienceYears'];
    if (normalized.containsKey('packageStartingPrice')) normalized['package_starting_price'] = normalized['packageStartingPrice'];
    if (normalized.containsKey('hourlyConsultationRate')) normalized['hourly_consultation_rate'] = normalized['hourlyConsultationRate'];
    if (normalized.containsKey('offersFlowerArrangements')) normalized['offers_flower_arrangements'] = normalized['offersFlowerArrangements'];
    if (normalized.containsKey('offersLighting')) normalized['offers_lighting'] = normalized['offersLighting'];
    if (normalized.containsKey('offersRentals')) normalized['offers_rentals'] = normalized['offersRentals'];
    if (normalized.containsKey('offersVendorCoordination')) normalized['offers_vendor_coordination'] = normalized['offersVendorCoordination'];
    if (normalized.containsKey('offersVenueBooking')) normalized['offers_venue_booking'] = normalized['offersVenueBooking'];
    if (normalized.containsKey('offersFullPlanning')) normalized['offers_full_planning'] = normalized['offersFullPlanning'];
    if (normalized.containsKey('availableItems')) normalized['available_items'] = normalized['availableItems'];
    if (normalized.containsKey('availableDates')) normalized['available_dates'] = normalized['availableDates'];
    if (normalized.containsKey('eventTypes')) normalized['event_types'] = normalized['eventTypes'];
    if (normalized.containsKey('contactEmail')) normalized['contact_email'] = normalized['contactEmail'];
    if (normalized.containsKey('contactPhone')) normalized['contact_phone'] = normalized['contactPhone'];
    if (normalized.containsKey('createdAt')) normalized['created_at'] = normalized['createdAt'];
    if (normalized.containsKey('updatedAt')) normalized['updated_at'] = normalized['updatedAt'];
    if (normalized.containsKey('venueTypes')) normalized['venue_types'] = normalized['venueTypes'];
    
    // Map Django field names to expected field names
    if (normalized.containsKey('user') && !normalized.containsKey('user_id')) {
      normalized['user_id'] = normalized['user'];
    }
    
    // Handle rating fields - Django returns string decimals
    if (normalized.containsKey('rating')) {
      normalized['rating'] = _parseDouble(normalized['rating']);
    }
    if (normalized.containsKey('average_rating')) {
      normalized['rating'] = _parseDouble(normalized['average_rating']);
    }
    
    // Handle decimal price fields
    final priceFields = [
      'session_rate', 'bridal_package_rate', 'hourly_rate', 'event_rate',
      'price_per_hour', 'price_per_person', 'package_starting_price',
      'hourly_consultation_rate'
    ];
    
    for (final field in priceFields) {
      if (normalized.containsKey(field)) {
        normalized[field] = _parseDouble(normalized[field]);
      }
    }
    
    // Handle integer fields
    final intFields = ['total_reviews', 'reviews_count', 'capacity', 'experience_years'];
    for (final field in intFields) {
      if (normalized.containsKey(field)) {
        normalized[field] = _parseInt(normalized[field]);
      }
    }
    
    // Handle boolean fields - EXPANDED for event organizer
    final boolFields = [
      'is_available', 'is_owner', 'offers_vendor_coordination', 
      'offers_venue_booking', 'offers_full_planning'
    ];
    for (final field in boolFields) {
      if (normalized.containsKey(field)) {
        normalized[field] = _parseBool(normalized[field]);
      }
    }
    
    // Handle string fields that might be null
    final stringFields = [
      'business_name', 'image', 'description', 'address', 'venue_type',
      'contact_phone', 'contact_email'
    ];
    for (final field in stringFields) {
      if (normalized.containsKey(field)) {
        normalized[field] = _parseString(normalized[field]);
      }
    }
    
    // Handle list fields - EXPANDED for event organizer
    final listFields = [
      'specializations', 'available_dates', 'amenities', 'images', 
      'gallery', 'services', 'cuisine_types', 'service_types', 'event_types', 
      'venue_types', 'portfolio'
    ];
    for (final field in listFields) {
      if (normalized.containsKey(field)) {
        normalized[field] = _parseStringList(normalized[field]);
      }
    }
    
    // Handle reviews count vs total_reviews
    if (normalized.containsKey('reviews_count') && !normalized.containsKey('total_reviews')) {
      normalized['total_reviews'] = normalized['reviews_count'];
    }
    
    return normalized;
  }

  /// Create a service provider from JSON data
  static ServiceProvider? fromJson(Map<String, dynamic> json, ServiceProviderType type) {
    try {
      // Extract data from response if it's wrapped
      final rawData = json['data'] ?? json;
      
      // Normalize the JSON data
      final data = _normalizeJson(Map<String, dynamic>.from(rawData));
      
      print('Normalized data for ${type.name}: $data');
      
      switch (type) {
        case ServiceProviderType.makeupArtist:
          return MakeupArtist.fromJson(data);
        case ServiceProviderType.photographer:
          return Photographer.fromJson(data);
        case ServiceProviderType.venue:
          return Venue.fromJson(data);
        case ServiceProviderType.caterer:
          return Caterer.fromJson(data);
        case ServiceProviderType.decorator:
          return Decorator.fromJson(data);
        case ServiceProviderType.eventOrganizer:
          return EventOrganizer.fromJson(data);
      }
    } catch (e, stackTrace) {
      print('Error parsing service provider: $e');
      print('Stack trace: $stackTrace');
      print('Raw JSON: $json');
      return null;
    }
  }

  /// Get ServiceProviderType from string
  static ServiceProviderType? getTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'makeup_artist':
        return ServiceProviderType.makeupArtist;
      case 'photographer':
        return ServiceProviderType.photographer;
      case 'venue':
        return ServiceProviderType.venue;
      case 'caterer':
        return ServiceProviderType.caterer;
      case 'decorator':
        return ServiceProviderType.decorator;
      case 'event_organizer':
        return ServiceProviderType.eventOrganizer;
      default:
        return null;
    }
  }

  /// Get all available service provider types
  static List<ServiceProviderType> getAllTypes() {
    return ServiceProviderType.values;
  }

  /// Create an empty service provider instance for forms
  static ServiceProvider createEmpty(ServiceProviderType type, {
    required String userId,
    String? locationId,
  }) {
    final baseData = {
      'id': '',
      'user_id': userId,
      'business_name': '',
      'image': '',
      'description': '',
      'rating': 0.0,
      'total_reviews': 0,
      'is_available': true,
      'location_id': locationId,
      'provider_type': type.name,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (type) {
      case ServiceProviderType.makeupArtist:
        return MakeupArtist.fromJson({
          ...baseData,
          'session_rate': 0.0,
          'bridal_package_rate': 0.0,
          'specializations': <String>[],
          'experience_years': 0,
          'available_dates': <String>[],
        });

      case ServiceProviderType.photographer:
        return Photographer.fromJson({
          ...baseData,
          'hourly_rate': 0.0,
          'event_rate': 0.0,
          'specializations': <String>[],
          'experience_years': 0,
          'available_dates': <String>[],
        });

      case ServiceProviderType.venue:
        return Venue.fromJson({
          ...baseData,
          'capacity': 0,
          'price_per_hour': 0.0,
          'amenities': <String>[],
          'images': <String>[],
          'venue_types': <String>[],
          'location': null,
        });

      case ServiceProviderType.caterer:
        return Caterer.fromJson({
          ...baseData,
          'price_per_person': 0.0,
          'cuisine_types': <String>[],
          'service_types': <String>[],
          'experience_years': 0,
          'available_dates': <String>[],
        });

      case ServiceProviderType.decorator:
        return Decorator.fromJson({
          ...baseData,
          'package_starting_price': 0.0,
          'hourly_rate': 0.0,
          'specializations': <String>[],
          'experience_years': 0,
          'available_dates': <String>[],
        });

      case ServiceProviderType.eventOrganizer:
        return EventOrganizer.fromJson({
          ...baseData,
          'event_types': <String>[],
          'services': <String>[],
          'package_starting_price': 0.0,
          'hourly_consultation_rate': 0.0,
          'experience_years': 0,
          'portfolio': <String>[],
          'available_dates': <String>[],
          'contact_email': '',
          'contact_phone': '',
          'offers_vendor_coordination': true,
          'offers_venue_booking': false,
          'offers_full_planning': true,
        });
    }
  }

  /// Convert service provider to JSON for API calls
  static Map<String, dynamic> toJson(ServiceProvider provider) {
    Map<String, dynamic> json;
    
    if (provider is MakeupArtist) {
      json = provider.toJson();
    } else if (provider is Photographer) {
      json = provider.toJson();
    } else if (provider is Venue) {
      json = provider.toJson();
    } else if (provider is Caterer) {
      json = provider.toJson();
    } else if (provider is Decorator) {
      json = provider.toJson();
    } else if (provider is EventOrganizer) {
      json = provider.toJson();
    } else {
      throw UnsupportedError('Unknown service provider type: ${provider.runtimeType}');
    }
    
    // Convert field names back to Django API format
    final apiJson = Map<String, dynamic>.from(json);
    
    // Map user_id back to user for Django API
    if (apiJson.containsKey('user_id')) {
      apiJson['user'] = apiJson.remove('user_id');
    }
    
    return apiJson;
  }

  /// Get the API endpoint for a service provider type - UPDATED
  static String getApiEndpoint(ServiceProviderType type) {
    switch (type) {
      case ServiceProviderType.makeupArtist:
        return '/makeup-artists/search';
      case ServiceProviderType.photographer:
        return '/photographers/search';
      case ServiceProviderType.venue:
        return '/venues/search';
      case ServiceProviderType.caterer:
        return '/caterers/search';
      case ServiceProviderType.decorator:
        return '/decorators/search';
      case ServiceProviderType.eventOrganizer:
        return '/event-organizers/search';
    }
  }

  /// Get the detail API endpoint for a service provider type - UPDATED
  static String getDetailApiEndpoint(ServiceProviderType type) {
    switch (type) {
      case ServiceProviderType.makeupArtist:
        return '/makeup-artists/';
      case ServiceProviderType.photographer:
        return '/photographers/';
      case ServiceProviderType.venue:
        return '/venues/';
      case ServiceProviderType.caterer:
        return '/caterers/';
      case ServiceProviderType.decorator:
        return '/decorators/';
      case ServiceProviderType.eventOrganizer:
        return '/event-organizers/';
    }
  }

  /// Get the review endpoint for a service provider type
  static String getReviewEndpoint(ServiceProviderType type) {
    switch (type) {
      case ServiceProviderType.makeupArtist:
        return '/makeup-artists/reviews/';
      case ServiceProviderType.photographer:
        return '/photographers/reviews/';
      case ServiceProviderType.venue:
        return '/venues/reviews/';
      case ServiceProviderType.caterer:
        return '/caterers/reviews/';
      case ServiceProviderType.decorator:
        return '/decorators/reviews/';
      case ServiceProviderType.eventOrganizer:
        return '/event-organizers/reviews/';
    }
  }

  /// Get service provider type from provider instance
  static ServiceProviderType getTypeFromProvider(ServiceProvider provider) {
    if (provider is MakeupArtist) return ServiceProviderType.makeupArtist;
    if (provider is Photographer) return ServiceProviderType.photographer;
    if (provider is Venue) return ServiceProviderType.venue;
    if (provider is Caterer) return ServiceProviderType.caterer;
    if (provider is Decorator) return ServiceProviderType.decorator;
    if (provider is EventOrganizer) return ServiceProviderType.eventOrganizer;
    throw UnsupportedError('Unknown service provider type: ${provider.runtimeType}');
  }

  /// Validate required fields for a service provider type - COMPLETE
  static List<String> validateProvider(ServiceProvider provider) {
    List<String> errors = [];

    // Common validations
    if (provider.businessName.trim().isEmpty) {
      errors.add('Business name is required');
    }
    if (provider.description.trim().isEmpty) {
      errors.add('Description is required');
    }

    // Type-specific validations
    if (provider is MakeupArtist) {
      if (provider.sessionRate <= 0) {
        errors.add('Session rate must be greater than 0');
      }
      if (provider.bridalPackageRate <= 0) {
        errors.add('Bridal package rate must be greater than 0');
      }
    } else if (provider is Photographer) {
      if (provider.hourlyRate <= 0) {
        errors.add('Hourly rate must be greater than 0');
      }
      if (provider.eventRate <= 0) {
        errors.add('Event rate must be greater than 0');
      }
    } else if (provider is Venue) {
      if (provider.capacity <= 0) {
        errors.add('Capacity must be greater than 0');
      }
      if (provider.pricePerHour <= 0) {
        errors.add('Price per hour must be greater than 0');
      }
      if (provider.venueTypes.isEmpty) {
        errors.add('At least one venue type is required');
      }
    } else if (provider is Caterer) {
      if (provider.pricePerPerson <= 0) {
        errors.add('Price per person must be greater than 0');
      }
    } else if (provider is Decorator) {
      if (provider.packageStartingPrice <= 0) {
        errors.add('Package starting price must be greater than 0');
      }
      if (provider.hourlyRate <= 0) {
        errors.add('Hourly rate must be greater than 0');
      }
    } else if (provider is EventOrganizer) {
      if (provider.packageStartingPrice <= 0) {
        errors.add('Package starting price must be greater than 0');
      }
      if (provider.hourlyConsultationRate <= 0) {
        errors.add('Hourly consultation rate must be greater than 0');
      }
      if (provider.eventTypes.isEmpty) {
        errors.add('At least one event type specialization is required');
      }
      if (provider.services.isEmpty) {
        errors.add('At least one service type is required');
      }
    }

    return errors;
  }

  /// Helper method to get service provider type display name
  static String getServiceProviderDisplayName(ServiceProviderType type) {
    switch (type) {
      case ServiceProviderType.makeupArtist:
        return 'Makeup Artist';
      case ServiceProviderType.photographer:
        return 'Photographer';
      case ServiceProviderType.venue:
        return 'Venue';
      case ServiceProviderType.caterer:
        return 'Caterer';
      case ServiceProviderType.decorator:
        return 'Decorator';
      case ServiceProviderType.eventOrganizer:
        return 'Event Organizer';
    }
  }

  /// Helper method to get service provider capabilities
  static List<String> getServiceProviderCapabilities(ServiceProviderType type) {
    switch (type) {
      case ServiceProviderType.makeupArtist:
        return [
          'Bridal makeup',
          'Party makeup',
          'Hair services',
          'Travel to client location',
        ];
      case ServiceProviderType.photographer:
        return [
          'Event photography',
          'Portrait photography',
          'Video services',
          'Equipment rental',
        ];
      case ServiceProviderType.venue:
        return [
          'Event space rental',
          'Catering facilities',
          'Parking availability',
          'Audio/Visual equipment',
        ];
      case ServiceProviderType.caterer:
        return [
          'Menu customization',
          'Equipment rental',
          'Waiter services',
          'Dietary accommodations',
        ];
      case ServiceProviderType.decorator:
        return [
          'Event decoration',
          'Flower arrangements',
          'Lighting setup',
          'Rental items',
        ];
      case ServiceProviderType.eventOrganizer:
        return [
          'Full event planning',
          'Vendor coordination',
          'Event management',
          'Custom event creation',
          'Timeline management',
          'Budget planning',
        ];
    }
  }
}

// =============================================================================
// UTILITY MIXIN for DateTime parsing (for other service provider models)
// =============================================================================

mixin DateTimeParsingMixin {
  /// Helper method to safely parse DateTime from either DateTime or String
  static DateTime parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Failed to parse DateTime from string: $value, error: $e');
        return DateTime.now();
      }
    }
    print('Unknown DateTime type: ${value.runtimeType}, value: $value');
    return DateTime.now();
  }
}