import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swornim/pages/Client_Dashboard/ClientDashboard.dart';
import 'package:swornim/pages/auth/login.dart';
import 'package:swornim/pages/widgets/auth/auth_navigation_wrapper.dart';
// import 'package:swornim/widgets/auth_state_listener.dart';
// import 'package:swornim/pages/introduction/userhomepage.dart';
import 'package:swornim/pages/introduction/welcome_screen.dart';

import 'package:swornim/pages/widgets/auth/auth_lifecycle_handler.dart';
import 'dart:async';
import 'package:swornim/pages/QRScreen/qr_ticket_screen.dart';
import 'package:swornim/pages/services/event_booking_manager.dart';
import 'package:swornim/config/app_config.dart';
import 'package:swornim/pages/serviceprovider_dashboard/service_provider_dashboard.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // AppConfig.forceIP('2b12c0022ef9.ngrok-free.app');
  
  // Initialize AppConfig to auto-detect server IP
  await AppConfig.initialize();
  runApp(ProviderScope(child: const MyApp()));
}

// Create a custom gradient theme class
class GradientTheme {
  // Primary gradient (blue to purple) - matches your web version
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB), // primary-600 (blue)
      Color(0xFF7C3AED), // violet-600 (purple)
    ],
    stops: [0.0, 1.0],
  );

  // Alternative gradient orientations
  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF2563EB), // primary-600 (blue)
      Color(0xFF7C3AED), // violet-600 (purple)
    ],
    stops: [0.0, 1.0],
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2563EB), // primary-600 (blue)
      Color(0xFF7C3AED), // violet-600 (purple)
    ],
    stops: [0.0, 1.0],
  );

  // Subtle gradient for cards/surfaces
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF), // white
      Color(0xFFF8FAFC), // slate-50
    ],
    stops: [0.0, 1.0],
  );

  // Success gradient
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF059669), // emerald-600
      Color(0xFF10B981), // emerald-500
    ],
    stops: [0.0, 1.0],
  );

  // Warning gradient
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD97706), // amber-600
      Color(0xFFF59E0B), // amber-500
    ],
    stops: [0.0, 1.0],
  );

  // Error gradient
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDC2626), // red-600
      Color(0xFFEF4444), // red-500
    ],
    stops: [0.0, 1.0],
  );
}

// Custom gradient widgets for common use cases
class GradientContainer extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final double? height;
  final double? width;

  const GradientContainer({
    Key? key,
    required this.child,
    this.gradient = GradientTheme.primaryGradient,
    this.borderRadius,
    this.padding,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final LinearGradient gradient;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;

  const GradientButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.gradient = GradientTheme.primaryGradient,
    this.padding,
    this.borderRadius,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Center(
              child: Text(
                text,
                style: textStyle ?? GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final LinearGradient gradient;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const GradientAppBar({
    Key? key,
    required this.title,
    this.gradient = GradientTheme.primaryGradient,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Example welcome card with gradient (like your web version)
class WelcomeCard extends StatelessWidget {
  final String userName;
  final String subtitle;

  const WelcomeCard({
    Key? key,
    required this.userName,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      gradient: GradientTheme.primaryGradient,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $userName!',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthLifecycleHandler(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Swornim',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC), // slate-50 from website

          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB), // primary-600 from website
            brightness: Brightness.light,
            primary: const Color(0xFF2563EB), // primary-600
            secondary: const Color(0xFF64748B), // slate-500
            tertiary: const Color(0xFF0F172A), // slate-900
            surface: const Color(0xFFFFFFFF), // white
            background: const Color(0xFFF8FAFC), // slate-50
            error: const Color(0xFFDC2626), // error-600
            onPrimary: const Color(0xFFFFFFFF), // white
            onSecondary: const Color(0xFFFFFFFF), // white
            onSurface: const Color(0xFF1E293B), // slate-800
            onBackground: const Color(0xFF1E293B), // slate-800
            // Additional semantic colors
            outline: const Color(0xFFCBD5E1), // slate-300
            surfaceVariant: const Color(0xFFF1F5F9), // slate-100
            onSurfaceVariant: const Color(0xFF475569), // slate-600
          ),

          textTheme: TextTheme(
            displayLarge: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF0F172A), // slate-900
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            displayMedium: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF1E293B), // slate-800
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            headlineLarge: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF1E293B), // slate-800
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            headlineMedium: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF0F172A), // slate-900
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            headlineSmall: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFFFFFFFF), // white
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            titleLarge: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF334155), // slate-700
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            titleMedium: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF475569), // slate-600
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            titleSmall: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF64748B), // slate-500
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            bodyLarge: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF334155), // slate-700
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            bodyMedium: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF475569), // slate-600
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            bodySmall: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF64748B), // slate-500
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            labelLarge: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF334155), // slate-700
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            labelMedium: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Color(0xFF475569), // slate-600
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB), // primary-600
              foregroundColor: const Color(0xFFFFFFFF), // white
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF2563EB).withOpacity(0.25),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFFFFFF), // white
              ),
            ),
          ),

          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB), // primary-600
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(
                color: Color(0xFF2563EB), // primary-600
                width: 1.5,
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2563EB), // primary-600
              ),
            ),
          ),

          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB), // primary-600
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2563EB), // primary-600
              ),
            ),
          ),

          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFFFFFFFF), // white
            foregroundColor: const Color(0xFF1E293B), // slate-800
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.inter(
              color: const Color(0xFF1E293B), // slate-800
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: const IconThemeData(
              color: Color(0xFF475569), // slate-600
              size: 24,
            ),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
          ),

          cardTheme: CardTheme(
            elevation: 2,
            shadowColor: const Color(0xFF000000).withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0xFFE2E8F0), // slate-200
                width: 1,
              ),
            ),
            color: const Color(0xFFFFFFFF), // white
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFFFFFF), // white
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0), // slate-200
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0), // slate-200
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB), // primary-600
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFDC2626), // error-600
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF94A3B8), // slate-400
              fontSize: 14,
            ),
            labelStyle: GoogleFonts.inter(
              color: const Color(0xFF64748B), // slate-500
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          iconTheme: const IconThemeData(
            color: Color(0xFF64748B), // slate-500
            size: 24,
          ),

          dividerTheme: const DividerThemeData(
            color: Color(0xFFE2E8F0), // slate-200
            thickness: 1,
            space: 16,
          ),

          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFF1F5F9), // slate-100
            labelStyle: GoogleFonts.inter(
              color: const Color(0xFF475569), // slate-600
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
            pressElevation: 1,
          ),

          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFFFFFFFF), // white
            selectedItemColor: Color(0xFF2563EB), // primary-600
            unselectedItemColor: Color(0xFF94A3B8), // slate-400
            elevation: 8,
            type: BottomNavigationBarType.fixed,
          ),

          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF2563EB), // primary-600
            foregroundColor: Color(0xFFFFFFFF), // white
            elevation: 4,
            shape: CircleBorder(),
          ),
        ),
        routes: {
          '/login': (context) => LoginPage(onSignupClicked: () {}),
          '/dashboard': (context) => Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(currentUserProvider);
              if (user == null) {
                return LoginPage(onSignupClicked: () {});
              }
              // Route to correct dashboard based on user type
              if (user.userType == UserType.client) {
                return const ClientDashboard();
              } else {
                return ServiceProviderDashboard(provider: user);
              }
            },
          ),
          // Add other routes as needed
        },
        // home: const PhotographerDashboard(),
        // home: const ClientDashboard(),
        // home: const WelcomeScreen(),
        home: const AuthNavigationWrapper(),
        // If you add AuthStateListener in the future, uncomment the builder below:
        // builder: (context, child) {
        //   return AuthStateListener(child: child!);
        // },
      ),
    );
  }
}

// Example usage in a page
class ExamplePage extends StatelessWidget {
  const ExamplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Swornim Dashboard',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const WelcomeCard(
              userName: 'Nischal',
              subtitle: 'Ready to manage your services?',
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: () {},
              text: 'New Booking',
            ),
            const SizedBox(height: 16),
            GradientContainer(
              gradient: GradientTheme.surfaceGradient,
              padding: const EdgeInsets.all(16),
              child: const Text('Your services content here...'),
            ),
          ],
        ),
      ),
    );
  }
}