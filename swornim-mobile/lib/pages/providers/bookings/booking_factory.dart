import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/models/bookings/service_package.dart';

class BookingFactory {
  // Parse Booking from JSON
  static Booking fromJson(Map<String, dynamic> json) {
    return Booking.fromJson(json);
  }

  // Serialize Booking to JSON
  static Map<String, dynamic> toJson(Booking booking) {
    return booking.toJson();
  }

  // Parse ServicePackage from JSON
  static ServicePackage servicePackageFromJson(Map<String, dynamic> json) {
    return ServicePackage.fromJson(json);
  }

  // Serialize ServicePackage to JSON
  static Map<String, dynamic> servicePackageToJson(ServicePackage package) {
    return package.toJson();
  }

  // Optional: Normalize backend data if needed (add methods here)
} 