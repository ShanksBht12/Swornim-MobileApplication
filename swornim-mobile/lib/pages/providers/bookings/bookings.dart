export 'booking_factory.dart';
export 'booking_manager.dart';
export 'package_manager.dart';
export 'bookings_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'booking_manager.dart';
import 'package_manager.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/models/bookings/service_package.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';

final bookingManagerProvider = Provider<BookingManager>((ref) {
  return BookingManager(ref);
});

// The following providers are now obsolete and have been replaced by 
// the StateNotifierProvider in bookings_provider.dart
//
// final bookingsForClientProvider = ...
// final bookingsForServiceProviderProvider = ...

final packageManagerProvider = Provider<PackageManager>((ref) {
  return PackageManager(ref);
});

final packagesProvider = FutureProvider.family<List<ServicePackage>, String>((ref, serviceProviderId) async {
  print('🔐 packagesProvider: Starting fetch for provider: $serviceProviderId');
  print('🔐 packagesProvider: Current auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
  print('🔐 packagesProvider: Current auth state - user: ${ref.read(authProvider).user?.name}');
  
  try {
    final manager = ref.read(packageManagerProvider);
    final packages = await manager.fetchPackagesForProvider(serviceProviderId);
    
    print('🔐 packagesProvider: Fetched ${packages.length} packages successfully');
    print('🔐 packagesProvider: Final auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
    print('🔐 packagesProvider: Final auth state - user: ${ref.read(authProvider).user?.name}');
    
    return packages;
  } catch (e, st) {
    print('🔐 packagesProvider: Error fetching packages: $e');
    print('🔐 packagesProvider: Stack trace: $st');
    print('🔐 packagesProvider: Auth state after error - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
    rethrow;
  }
}); 