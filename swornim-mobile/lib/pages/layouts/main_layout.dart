// layouts/main_layout.dart

//THis format will be used for the main layout of the app, which includes a custom app bar, a footer, and optional floating action buttons.
import 'package:flutter/material.dart';
import 'package:swornim/pages/components/common/app_bar/custom_app_bar.dart';
import '../components/common/navigation/bottom_navigation.dart';
import 'package:swornim/pages/map/map_screen.dart';
import 'package:swornim/pages/bookings/bookings_page.dart';
import 'package:swornim/pages/Client_Dashboard/profile/profile_page.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final bool showFooter;
  final bool showAppBar;
  final String? title;
  final List<Widget>? appBarActions;
  final bool showNotification;
  final bool showProfile;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final Widget? appBarLeading;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;

  const MainLayout({
    super.key,
    required this.child,
    this.showFooter = true,
    this.showAppBar = true,
    this.title,
    this.appBarActions,
    this.showNotification = true,
    this.showProfile = true,
    this.onNotificationTap,
    this.onProfileTap,
    this.appBarLeading,
    this.resizeToAvoidBottomInset = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: drawer,
      endDrawer: endDrawer,
      appBar: showAppBar
          ? CustomAppBar(
              title: title,
              actions: appBarActions,
              showNotification: showNotification,
              showProfile: showProfile,
              onNotificationTap: onNotificationTap,
              onProfileTap: onProfileTap,
              leading: appBarLeading,
            )
          : null,
      body: Column(
        children: [
          Expanded(child: child),
          if (showFooter)
            AppBottomNavigation(
              currentIndex: 0, // This should be updated based on the current page
              onTap: (int index) {
                switch (index) {
                  case 1: // Map
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const MapScreen()),
                    );
                    break;
                  case 2: // Bookings
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const BookingsPage()),
                    );
                    break;
                  case 3: // Profile
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                    break;
                }
              },
            ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

// Alternative layout for pages that need scrollable content with footer
class ScrollableMainLayout extends StatelessWidget {
  final Widget child;
  final bool showFooter;
  final bool showAppBar;
  final String? title;
  final List<Widget>? appBarActions;
  final bool showNotification;
  final bool showProfile;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final Widget? appBarLeading;
  final EdgeInsets? padding;

  const ScrollableMainLayout({
    super.key,
    required this.child,
    this.showFooter = true,
    this.showAppBar = true,
    this.title,
    this.appBarActions,
    this.showNotification = true,
    this.showProfile = true,
    this.onNotificationTap,
    this.onProfileTap,
    this.appBarLeading,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: showAppBar
          ? CustomAppBar(
              title: title,
              actions: appBarActions,
              showNotification: showNotification,
              showProfile: showProfile,
              onNotificationTap: onNotificationTap,
              onProfileTap: onProfileTap,
              leading: appBarLeading,
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
            if (showFooter)
              AppBottomNavigation(
                currentIndex: 0, // Set to the appropriate index
                onTap: (int index) {
                  switch (index) {
                    case 1: // Map
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const MapScreen()),
                      );
                      break;
                    case 2: // Bookings
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const BookingsPage()),
                      );
                      break;
                    case 3: // Profile
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                      break;
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}