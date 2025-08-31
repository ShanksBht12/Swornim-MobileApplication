// pages/client/client_dashboard.dart (Enhanced complete version)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/components/common/common/profile/profile_panel.dart';
import 'package:swornim/pages/introduction/slider.dart';
import 'package:swornim/pages/layouts/main_layout.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/providers/bookings/bookings_provider.dart';
import 'package:swornim/pages/service_providers/decorator/decorator_list_page.dart';
import 'package:swornim/pages/service_providers/makeupartist/makeupartist_list_page.dart';
import 'package:swornim/pages/service_providers/photographer/photographer_list_page.dart';
import 'package:swornim/pages/service_providers/venues/venuelistpage.dart';
import 'package:swornim/pages/widgets/client/dashboard/service_grid.dart';
import 'package:swornim/pages/widgets/client/dashboard/welcome_section.dart';
import 'package:swornim/pages/widgets/common/booking_card.dart';
import 'package:swornim/pages/service_providers/caterer/caterer_list_page.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/main.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();

    // Always fetch latest bookings when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsProvider.notifier).fetchBookings();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return MainLayout(
      showFooter: true,
      showAppBar: true,
      onNotificationTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifications clicked'),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      onProfileTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ProfilePanel(),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Welcome Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: const WelcomeSection(),
                ),
              ),
              
              // Carousel Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: const HomeCarousel(),
                ),
              ),

              // Services Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ServiceGrid(),
                ),
              ),
              
              // Spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),

              // My Bookings Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildBookingsSectionHeader(theme, colorScheme),
                ),
              ),
              
              // My Bookings Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildMyBookings(),
                ),
              ),
              
              // Bottom padding

              
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsSectionHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => GradientTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'My Bookings',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your event bookings and status',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Consumer(
            builder: (context, ref, child) {
              final bookingsState = ref.watch(bookingsProvider);
              final upcomingCount = bookingsState.bookings
                  .where((booking) => 
                      booking.status == BookingStatus.pending_provider_confirmation ||
                      booking.status == BookingStatus.confirmed_awaiting_payment ||
                      booking.status == BookingStatus.confirmed_paid ||
                      booking.status == BookingStatus.in_progress)
                  .length;
              
              if (upcomingCount > 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$upcomingCount Upcoming',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyBookings() {
    final bookingsState = ref.watch(bookingsProvider);
    final currentUser = ref.watch(authProvider).user;

    if (currentUser == null) {
      return _buildEmptyState(
        icon: Icons.account_circle_outlined,
        title: 'Please log in',
        subtitle: 'Log in to see your bookings and manage your events',
        actionLabel: 'Log In',
        onAction: () {
          // Navigate to login page
        },
      );
    }

    if (bookingsState.isLoading) {
      return _buildLoadingState();
    }

    if (bookingsState.error != null) {
      return _buildErrorState(bookingsState.error!);
    }

    if (bookingsState.bookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No bookings yet',
        subtitle: 'Start by booking one of our amazing services for your next event',
        actionLabel: 'Browse Services',
        onAction: () {
          // Scroll to services section or navigate
        },
      );
    }

    // Updated: Only pending_provider_confirmation is pending
    final pendingBookings = bookingsState.bookings
        .where((booking) => booking.status == BookingStatus.pending_provider_confirmation)
        .toList();

    // Updated: confirmed_awaiting_payment, confirmed_paid, in_progress are upcoming/confirmed
    final confirmedBookings = bookingsState.bookings
        .where((booking) =>
            booking.status == BookingStatus.confirmed_awaiting_payment ||
            booking.status == BookingStatus.confirmed_paid ||
            booking.status == BookingStatus.in_progress)
        .toList();

    final pastBookings = bookingsState.bookings
        .where((booking) =>
            booking.status == BookingStatus.completed ||
            booking.status == BookingStatus.cancelled_by_client ||
            booking.status == BookingStatus.cancelled_by_provider ||
            booking.status == BookingStatus.rejected ||
            booking.status == BookingStatus.refunded)
        .toList();

    // You can now display pendingBookings, confirmedBookings, and pastBookings as needed
    // For demonstration, let's show confirmedBookings as 'Upcoming Events'
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pendingBookings.isNotEmpty) ...[
          _buildBookingGroupHeader('Pending Confirmation', pendingBookings.length),
          const SizedBox(height: 16),
          ...pendingBookings.take(2).map((booking) =>
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (pendingBookings.indexOf(booking) * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: BookingCard(booking: booking, currentUser: currentUser),
                  ),
                );
              },
            ),
          ),
          if (pendingBookings.length > 2) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to full pending bookings page
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text('View All ${pendingBookings.length} Pending Bookings'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (confirmedBookings.isNotEmpty) const SizedBox(height: 32),
        ],
        if (confirmedBookings.isNotEmpty) ...[
          _buildBookingGroupHeader('Upcoming/Confirmed Events', confirmedBookings.length),
          const SizedBox(height: 16),
          ...confirmedBookings.take(2).map((booking) =>
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (confirmedBookings.indexOf(booking) * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: BookingCard(booking: booking, currentUser: currentUser),
                  ),
                );
              },
            ),
          ),
          if (confirmedBookings.length > 2) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to full confirmed bookings page
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text('View All ${confirmedBookings.length} Confirmed Bookings'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (pastBookings.isNotEmpty) const SizedBox(height: 32),
        ],
        if (pastBookings.isNotEmpty) ...[
          _buildBookingGroupHeader('Past Events', pastBookings.length),
          const SizedBox(height: 16),
          ...pastBookings.take(2).map((booking) => // Show only first 2 past bookings
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (pastBookings.indexOf(booking) * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: BookingCard(booking: booking, currentUser: currentUser),
                  ),
                );
              },
            ),
          ),
          if (pastBookings.length > 2) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to full past bookings page
                },
                icon: const Icon(Icons.history_rounded, size: 18),
                label: Text('View All ${pastBookings.length} Past Bookings'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBookingGroupHeader(String title, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => GradientTheme.primaryGradient.createShader(bounds),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your bookings...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.refresh(bookingsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleFeatureTap(String label, BuildContext context) {
    switch (label) {
      case 'Book Venue':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VenueListPage()),
        );
        break;
      case 'Photographers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PhotographerListPage()),
        );
        break;
      case 'Makeup Artists':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MakeupArtistListPage()),
        );
        break;
      case 'Decorators':
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const DecoratorListPage()),
        );
        break;
      case 'Caterers':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CatererListPage()));
        break;
    }
  }
}