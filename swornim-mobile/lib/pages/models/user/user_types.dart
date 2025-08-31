import 'package:swornim/pages/models/bookings/booking.dart';

enum UserType {
  client,
  photographer,
  venue,
  caterer,
  makeupArtist,
  decorator,
  eventOrganizer,
}

enum UserStatus {
  pending,
  approved,
  active,
  suspended,
  rejected,
  inactive
}

// Convert frontend UserType enum to backend-expected string format
String userTypeToBackendFormat(UserType userType) {
  switch (userType) {
    case UserType.client:
      return 'client';
    case UserType.photographer:
      return 'photographer';
    case UserType.makeupArtist:
      return 'makeup_artist';
    case UserType.decorator:
      return 'decorator';
    case UserType.venue:
      return 'venue';
    case UserType.caterer:
      return 'caterer';
    case UserType.eventOrganizer:
      return 'event_organizer';
  }
}

// Helper to map UserType to ServiceType
ServiceType? serviceTypeFromUserType(UserType userType) {
  switch (userType) {
    case UserType.photographer:
      return ServiceType.photography;
    case UserType.makeupArtist:
      return ServiceType.makeup;
    case UserType.decorator:
      return ServiceType.decoration;
    case UserType.venue:
      return ServiceType.venue;
    case UserType.caterer:
      return ServiceType.catering;
    case UserType.eventOrganizer:
      return ServiceType.planning;
    default:
      return null;
  }
}