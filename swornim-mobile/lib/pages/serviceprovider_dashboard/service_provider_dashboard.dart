import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swornim/pages/auth/login.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/models/bookings/service_package.dart';
import 'package:swornim/pages/providers/bookings/bookings_provider.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/layouts/main_layout.dart';
import 'package:swornim/pages/widgets/auth/auth_navigation_wrapper.dart';
import 'package:swornim/pages/widgets/common/booking_card.dart';
import 'package:swornim/pages/serviceprovider_dashboard/widgets/dashboard_overview.dart';
import 'package:swornim/pages/serviceprovider_dashboard/widgets/bookings_management.dart';
import 'package:swornim/pages/serviceprovider_dashboard/widgets/package_management.dart';
import 'package:swornim/pages/serviceprovider_dashboard/widgets/calendar_view.dart';
import 'package:swornim/pages/serviceprovider_dashboard/widgets/revenue_analytics.dart';
import 'package:swornim/pages/serviceprovider_dashboard/widgets/profile_management.dart';
import 'package:swornim/pages/serviceprovider_dashboard/dashboard_stats_provider.dart';
import 'package:swornim/pages/serviceprovider_dashboard/providers/analytics_provider.dart';
import 'package:swornim/pages/components/common/common/profile/profile_panel.dart';
import 'package:swornim/pages/introduction/welcome_screen.dart';
import 'package:swornim/pages/services/service_provider_profile_service.dart';
import 'package:swornim/pages/serviceprovider_dashboard/widgets/event_management.dart';
import 'package:swornim/pages/serviceprovider_dashboard/scan_ticket_screen.dart';

class ServiceProviderDashboard extends ConsumerStatefulWidget {
  final User provider;
  const ServiceProviderDashboard({required this.provider, Key? key}) : super(key: key);

  @override
  ConsumerState<ServiceProviderDashboard> createState() => _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends ConsumerState<ServiceProviderDashboard> 
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;

  List<BottomNavigationBarItem> getNavItems(UserType userType) {
    return [
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
      if (userType != UserType.eventOrganizer)
        const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
      if (userType == UserType.eventOrganizer) ...[
        const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
        const BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
      ] else
        const BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Packages'),
      const BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  List<Widget> getDashboardPages(User provider) {
    return [
      DashboardOverview(provider: provider),
      if (provider.userType != UserType.eventOrganizer)
        BookingsManagement(provider: provider),
      if (provider.userType == UserType.eventOrganizer) ...[
        EventManagement(provider: provider),
        ScanTicketScreen(eventId: ''), // Pass eventId if needed
      ] else
        PackageManagement(provider: provider),
      RevenueAnalytics(provider: provider),
      ProfileManagement(provider: provider),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = widget.provider;
    print('[DEBUG] Provider userType:  [1m${provider.userType} [0m (${provider.userType.name})');
    final navItems = getNavItems(provider.userType);
    final dashboardPages = getDashboardPages(provider);

    return Scaffold(
      body: Column(
        children: [
          // App Bar - Show for all tabs except Profile (index 4), Event Management (index 1), and Scan Ticket (index 2) for event organizers
          if (_shouldShowAppBar(_currentIndex, provider.userType))
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2563EB), // primary-600 (blue)
                    Color(0xFF7C3AED), // violet-600 (purple)
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header Row - Only show for Dashboard Overview
                      if (_currentIndex == 0) ...[
                        Row(
                          children: [
                            // Profile Avatar with gradient border
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Colors.white70],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.business,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Title and Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.provider.name} Dashboard',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Manage your business and bookings',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Notification Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: _handleNotificationTap,
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                ),
                                tooltip: 'Notifications',
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Menu Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'settings':
                                      _handleSettingsTap();
                                      break;
                                    case 'logout':
                                      _handleLogout();
                                      break;
                                  }
                                },
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'settings',
                                    child: Row(
                                      children: [
                                        Icon(Icons.settings, size: 20, color: colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 12),
                                        const Text('Settings'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.logout, size: 20, color: Colors.red),
                                        const SizedBox(width: 12),
                                        const Text('Logout', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                      
                      // Simplified Page Title - For all tabs except Profile
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getPageTitle(_currentIndex),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Dashboard Content with enhanced background
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
              ),
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: dashboardPages,
              ),
            ),
          ),
        ],
      ),
      
      // Enhanced Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC), // slate-50
              Color(0xFFFFFFFF), // white
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(navItems.length, (index) {
                final isSelected = _currentIndex == index;
                final item = navItems[index];
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onNavTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF2563EB), // primary-600
                                  Color(0xFF7C3AED), // violet-600
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              (item.icon as Icon).icon,
                              key: ValueKey(isSelected),
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: theme.textTheme.labelSmall!.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 11,
                            ),
                            child: Text(
                              item.label!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  String _getPageTitle(int index) {
    final provider = widget.provider;
    if (provider.userType == UserType.eventOrganizer) {
      switch (index) {
        case 0:
          return 'Dashboard Overview';
        case 1:
          return 'Event Management';
        case 2:
          return 'Scan Ticket';
        case 3:
          return 'Revenue Analytics';
        case 4:
          return 'Profile Management';
        default:
          return 'Dashboard';
      }
    } else {
      switch (index) {
        case 0:
          return 'Dashboard Overview';
        case 1:
          return 'Bookings Management';
        case 2:
          return 'Package Management';
        case 3:
          return 'Revenue Analytics';
        case 4:
          return 'Profile Management';
        default:
          return 'Dashboard';
      }
    }
  }

  void _handleNotificationTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Notifications'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleProfileTap() {
    showDialog(
      context: context,
      builder: (context) => const ProfilePanel(),
    );
  }

  void _handleSettingsTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.settings, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Dashboard Settings'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleLogout() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.redAccent],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Are you sure you want to sign out of your account?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () async {
                // Close confirmation dialog
                Navigator.of(context).pop();
                
                // Handle logout using auth provider (same as ProfilePage)
                await ref.read(authProvider.notifier).logout();
                
                // Navigate to login using named route (same as ProfilePage)
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      );
    },
  );
}

  bool _shouldShowAppBar(int currentIndex, UserType userType) {
    if (userType == UserType.eventOrganizer) {
      // Hide AppBar for Event Management (1), Scan Ticket (2), and Profile (4)
      return !(currentIndex == 1 || currentIndex == 2 || currentIndex == 4);
    } else {
      // Hide AppBar for Profile (4)
      return currentIndex != 4;
    }
  }
}