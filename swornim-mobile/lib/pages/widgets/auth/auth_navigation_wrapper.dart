// lib/pages/widgets/auth/auth_navigation_wrapper.dart

// Replace your AuthNavigationWrapper with this version that waits for tokens to settle:

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:swornim/pages/auth/login.dart';
import 'package:swornim/pages/Client_Dashboard/ClientDashboard.dart';
import 'package:swornim/pages/serviceprovider_dashboard/service_provider_dashboard.dart';

class AuthNavigationWrapper extends ConsumerStatefulWidget {
  const AuthNavigationWrapper({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthNavigationWrapper> createState() => _AuthNavigationWrapperState();
}

class _AuthNavigationWrapperState extends ConsumerState<AuthNavigationWrapper> {
  String? _lastUserId; // Add this to track user changes
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    print('🏠 AuthNavigationWrapper: isInitialized=${authState.isInitialized}, isLoggedIn=${authState.isLoggedIn}, isLoading=${authState.isLoading}');
    print('🏠 User: ${authState.user?.email}');

    // Show loading while auth is initializing
    if (!authState.isInitialized || authState.isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2563EB),
                Color(0xFF7C3AED),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Navigate based on auth state
    if (authState.isLoggedIn && authState.user != null) {
      final user = authState.user!;
      final currentUserId = user.id;
      
      print('🏠 User is logged in: ${user.email}, type: ${user.userType}');
      
      // ADD THIS - Check if user has changed
      if (_lastUserId != null && _lastUserId != currentUserId) {
        print('🔄 User changed from $_lastUserId to $currentUserId - clearing caches');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Force a refresh by invalidating providers
          ref.read(authProvider.notifier).clearAllProviderCaches();
        });
      }
      _lastUserId = currentUserId;
      
      // Route to different dashboards based on user type
      switch (user.userType) {
        case UserType.client:
          print('🏠 ✅ Routing CLIENT to ClientDashboard');
          return const ClientDashboard();
        
        case UserType.photographer:
          print('🏠 ✅ Routing PHOTOGRAPHER to ServiceProviderDashboard');
          return ServiceProviderDashboard(provider: user);
        
        case UserType.venue:
          print('🏠 ✅ Routing VENUE to ServiceProviderDashboard');
          return ServiceProviderDashboard(provider: user);
        
        case UserType.makeupArtist:
          print('🏠 ✅ Routing MAKEUP_ARTIST to ServiceProviderDashboard');
          return ServiceProviderDashboard(provider: user);
        
        case UserType.caterer:
          print('🏠 ✅ Routing CATERER to ServiceProviderDashboard');
          return ServiceProviderDashboard(provider: user);
        
        case UserType.decorator:
          print('🏠 ✅ Routing DECORATOR to ServiceProviderDashboard');
          return ServiceProviderDashboard(provider: user);
        
        case UserType.eventOrganizer:
          print('🏠 ✅ Routing EVENT_ORGANIZER to ServiceProviderDashboard');
          return ServiceProviderDashboard(provider: user);
        
        default:
          print('🏠 ❌ UNKNOWN user type: ${user.userType}, defaulting to ClientDashboard');
          return const ClientDashboard();
      }
    } else {
      // ADD THIS - Reset tracking when user logs out
      _lastUserId = null;
      print('🏠 User not logged in, showing login');
      return LoginPage(onSignupClicked: () {});
    }
  }
}

// 2. Create auth state listener: lib/widgets/auth_state_listener.dart

