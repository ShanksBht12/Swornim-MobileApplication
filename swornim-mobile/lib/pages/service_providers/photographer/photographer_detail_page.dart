import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swornim/pages/providers/bookings/bookings.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_factory.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_manager.dart';
import 'package:swornim/pages/providers/bookings/package_manager.dart';
import 'package:swornim/pages/models/bookings/service_package.dart';
import 'package:swornim/pages/providers/service_providers/models/photographer.dart';
import 'package:swornim/pages/models/review.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/config/app_config.dart';
import 'package:swornim/pages/models/user/user.dart' as user_model;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:swornim/pages/map/single_provider_map_screen.dart';
import 'package:swornim/pages/providers/payments/payment_provider.dart';
import 'package:swornim/pages/payment/khalti_payment_screen.dart';
import 'package:swornim/pages/providers/reviews/review_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

final photographerDetailProvider = FutureProvider.family<Photographer, String>((ref, photographerId) async {
  final manager = ref.read(serviceProviderManagerProvider);
  final result = await manager.getServiceProvider(ServiceProviderType.photographer, photographerId);
  if (result.isError || result.data == null) throw Exception(result.error ?? 'Not found');
  return result.data as Photographer;
});

final packagesForProviderProvider = FutureProvider.family<List<ServicePackage>, String>((ref, serviceProviderId) async {
  final manager = ref.read(packageManagerProvider);
  return await manager.fetchPackagesForProvider(serviceProviderId);
});

final userDetailsProvider = FutureProvider.family<User, String>((ref, userId) async {
  final authHeaders = ref.read(authProvider.notifier).getAuthHeaders();
  final response = await http.get(
    Uri.parse('${AppConfig.usersUrl}/$userId'),
    headers: authHeaders,
  );
  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    return User.fromJson(jsonData['data'] ?? jsonData);
  } else {
    throw Exception('Failed to load user');
  }
});

class PhotographerDetailPage extends ConsumerStatefulWidget {
  final String photographerId;
  const PhotographerDetailPage({super.key, required this.photographerId});

  @override
  ConsumerState<PhotographerDetailPage> createState() => _PhotographerDetailPageState();
}

class _PhotographerDetailPageState extends ConsumerState<PhotographerDetailPage> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _mainAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _tabAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // UI State
  bool _isFavorite = false;
  bool _isBookingExpanded = false;
  int _selectedTabIndex = 0;
  int _selectedImageIndex = 0;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '';
  String _selectedPackage = '';

  // Page controller for image gallery
  late PageController _imagePageController;

  // Tab controller
  late TabController _tabController;

  // Add state for new booking fields
  String _eventLocation = '';
  String _eventType = '';
  String _specialRequests = '';
  String? _selectedPackageId;
  double? _selectedPackagePrice;
  final List<String> _eventTypes = [
    'Wedding', 'Birthday', 'Corporate', 'Portrait', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupControllers();
    _mainAnimationController.forward();
  }

  void _setupAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.elasticOut),
    );
  }

  void _setupControllers() {
    _imagePageController = PageController();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_selectedTabIndex != _tabController.index) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _fabAnimationController.dispose();
    _tabAnimationController.dispose();
    _imagePageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photographerAsync = ref.watch(photographerDetailProvider(widget.photographerId));
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshPhotographerData();
          // Wait a bit for the refresh to complete
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: theme.colorScheme.primary,
        child: photographerAsync.when(
          data: (photographer) {
            final packagesAsync = ref.watch(packagesForProviderProvider(photographer.userId));
            return SafeArea(
              child: CustomScrollView(
                // Ensure scroll physics allow pull-to-refresh
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeroSection(theme, photographer),
                  _buildQuickInfoSection(theme, photographer),
                  if (photographer.location != null) _buildEnhancedMapSection(theme, photographer),
                  _buildTabSection(theme),
                  _buildCurrentTabContent(theme, photographer, packagesAsync),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshPhotographerData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            labelStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'About'),
              Tab(text: 'Services'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, Photographer photographer) {
    return SliverAppBar(
      expandedHeight: 400,
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {
              // Share functionality
            },
          ),
        ),
        // Add refresh button
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refreshPhotographerData,
            tooltip: 'Refresh',
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image gallery with enhanced loading
            PageView.builder(
              controller: _imagePageController,
              itemCount: _getImageCount(photographer),
              onPageChanged: (index) {
                setState(() {
                  _selectedImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imageUrl = _getImageUrl(photographer, index);
                if (imageUrl == null) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 80),
                    ),
                  );
                }
                return Container(
                  key: ValueKey(imageUrl), // Force rebuild when URL changes
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.3),
                            theme.colorScheme.secondary.withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 80),
                      ),
                    ),
                    // Force network fetch for fresh data
                    cacheManager: null,
                    useOldImageOnUrlChange: false,
                    fadeInDuration: const Duration(milliseconds: 300),
                    fadeOutDuration: const Duration(milliseconds: 100),
                  ),
                );
              },
            ),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black26,
                    Colors.black54,
                  ],
                ),
              ),
            ),
            // Image indicators
            if (_getImageCount(photographer) > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_getImageCount(photographer), (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _selectedImageIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _selectedImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            // Bottom info overlay
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              photographer.businessName,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (photographer.isAvailable)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.verified_rounded,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < (photographer.rating?.floor() ?? 0)
                                  ? Icons.star_rounded
                                  : index < (photographer.rating ?? 0)
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded,
                              color: Colors.amber[600],
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            (photographer.rating != null && photographer.totalReviews > 0)
                                ? '${photographer.rating!.toStringAsFixed(1)} (${photographer.totalReviews} reviews)'
                                : 'No reviews yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoSection(ThemeData theme, Photographer photographer) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _mainAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value * 0.5),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status and location
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: photographer.isAvailable
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: photographer.isAvailable
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                photographer.isAvailable ? 'Available' : 'Busy',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: photographer.isAvailable
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              photographer.location?.name ?? 'Location not specified',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Quick stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Experience',
                            '${photographer.experienceYears} years',
                            Icons.work_history_rounded,
                            theme,
                            margin: const EdgeInsets.only(right: 6),
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Hourly Rate',
                            'Rs. ${photographer.hourlyRate.toStringAsFixed(0)}',
                            Icons.attach_money_rounded,
                            theme,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Video Services',
                            photographer.offersVideoServices ? 'Yes' : 'No',
                            Icons.videocam_rounded,
                            theme,
                            margin: const EdgeInsets.only(left: 6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Specializations
                    if (photographer.specializations.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Specializations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: photographer.specializations.map((spec) {
                          final capSpec = spec.isNotEmpty ? spec[0].toUpperCase() + spec.substring(1) : spec;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.1),
                                  theme.colorScheme.secondary.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              capSpec,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, ThemeData theme, {EdgeInsets margin = EdgeInsets.zero}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'Packages'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(ThemeData theme, Photographer photographer, AsyncValue<List<ServicePackage>> packagesAsync) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAboutContent(theme, photographer);
      case 1:
        return _buildPackagesContent(theme, packagesAsync);
      case 2:
        return _buildReviewsContent(theme, photographer);
      default:
        return _buildAboutContent(theme, photographer);
    }
  }

  Widget _buildAboutContent(ThemeData theme, Photographer photographer) {
    final userAsync = ref.watch(userDetailsProvider(photographer.userId));
    return userAsync.when(
      data: (user) => SliverToBoxAdapter(
        child: Container(
          key: const ValueKey('about'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About ${photographer.businessName}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                photographer.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              // Equipment section
              _buildInfoSection(
                'Equipment & Gear',
                Icons.camera_rounded,
                photographer.equipment,
                theme,
              ),
              const SizedBox(height: 20),
              // Services section
              _buildInfoSection(
                'Services Offered',
                Icons.photo_camera_rounded,
                photographer.specializations,
                theme,
              ),
              const SizedBox(height: 20),
              // Portfolio section
              if (photographer.portfolio.isNotEmpty) ...[
                _buildPortfolioSection(theme, photographer),
                const SizedBox(height: 20),
              ],
              // Contact info
              _buildContactInfo(theme, user),
            ],
          ),
        ),
      ),
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverToBoxAdapter(child: Text('Error loading contact info: $e')),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<String> items, ThemeData theme) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPortfolioSection(ThemeData theme, Photographer photographer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Portfolio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photographer.portfolio.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photographer.portfolio[index],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(ThemeData theme, user_model.User user) {
    final phone = user.phone.isNotEmpty ? user.phone : '+977 98XXXXXXXX';
    final email = user.email.isNotEmpty ? user.email : 'contact@photographer.com';
    final website = 'www.photographer.com'; // Placeholder, update if available
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(Icons.phone_rounded, phone, theme),
          const SizedBox(height: 12),
          _buildContactItem(Icons.email_rounded, email, theme),
          const SizedBox(height: 12),
          _buildContactItem(Icons.language_rounded, website, theme),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPackagesContent(ThemeData theme, AsyncValue<List<ServicePackage>> packagesAsync) {
    return SliverToBoxAdapter(
      child: Container(
        key: const ValueKey('packages'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: packagesAsync.when(
          data: (pkgs) => pkgs.isEmpty
              ? const Text('No packages found.')
              : Column(
                  children: pkgs.map((pkg) => _buildServicePackage(
                    pkg.name,
                    pkg.basePrice,
                    '${pkg.durationHours} hours',
                    pkg.features,
                    theme,
                  )).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading packages: $e'),
        ),
      ),
    );
  }

  Widget _buildReviewsContent(ThemeData theme, Photographer photographer) {
    // Use the integrated ReviewsTab widget
    return ReviewsTab(
      serviceProviderId: photographer.userId,
      serviceProviderName: photographer.businessName,
      serviceProviderType: 'photographer',
    );
  }

  Widget _buildFloatingActionButtons(ThemeData theme) {
    return FloatingActionButton(
      onPressed: () {
        _showBookingDialog(theme);
      },
      child: const Icon(Icons.calendar_today),
      tooltip: 'Book Now',
    );
  }

  void _showBookingDialog(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Text(
                            'Book Session',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    // Booking form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date selection
                            _buildBookingSection(
                              'Select Date',
                              Icons.calendar_today_rounded,
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setModalState(() => _selectedDate = date);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              theme,
                            ),
                            const SizedBox(height: 24),
                            // Time slot selection
                            _buildBookingSection(
                              'Select Time',
                              Icons.access_time_rounded,
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _getTimeSlots().map((time) {
                                  final isSelected = _selectedTimeSlot == time;
                                  return GestureDetector(
                                    onTap: () => setModalState(() => _selectedTimeSlot = time),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.dividerColor,
                                        ),
                                      ),
                                      child: Text(
                                        time,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              theme,
                            ),
                            const SizedBox(height: 24),
                            // Event location
                            _buildBookingSection(
                              'Event Location',
                              Icons.location_on_rounded,
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Enter event location',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onChanged: (val) => setModalState(() => _eventLocation = val),
                              ),
                              theme,
                            ),
                            const SizedBox(height: 24),
                            // Event type
                            _buildBookingSection(
                              'Event Type',
                              Icons.event_rounded,
                              DropdownButtonFormField<String>(
                                value: _eventType.isNotEmpty ? _eventType : null,
                                items: _eventTypes.map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                )).toList(),
                                onChanged: (val) => setModalState(() => _eventType = val ?? ''),
                                decoration: InputDecoration(
                                  hintText: 'Select event type',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              theme,
                            ),
                            const SizedBox(height: 24),
                            // Special requests (optional)
                            _buildBookingSection(
                              'Special Requests (Optional)',
                              Icons.notes_rounded,
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Any special requests?',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onChanged: (val) => setModalState(() => _specialRequests = val),
                                maxLines: 2,
                              ),
                              theme,
                            ),
                            const SizedBox(height: 24),
                            // Package selection (update to store ID and price)
                            Consumer(
                              builder: (context, ref, _) {
                                final photographerAsync = ref.watch(photographerDetailProvider(widget.photographerId));
                                return photographerAsync.when(
                                  data: (photographer) {
                                    final packagesAsync = ref.watch(packagesForProviderProvider(photographer.userId));
                                    return packagesAsync.when(
                                      data: (pkgs) => _buildBookingSection(
                                        'Select Package',
                                        Icons.photo_library_rounded,
                                        Column(
                                          children: pkgs.map((package) {
                                            final isSelected = _selectedPackageId == package.id;
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              decoration: BoxDecoration(
                                                color: theme.scaffoldBackgroundColor,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? theme.colorScheme.primary
                                                      : theme.dividerColor,
                                                ),
                                              ),
                                              child: RadioListTile<String>(
                                                value: package.id,
                                                groupValue: _selectedPackageId,
                                                onChanged: (value) {
                                                  setModalState(() {
                                                    _selectedPackageId = value!;
                                                    _selectedPackage = package.name;
                                                    _selectedPackagePrice = package.basePrice;
                                                  });
                                                },
                                                title: Text(
                                                  package.name,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  'Rs. ${package.basePrice} • ${package.durationHours} hours',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                                activeColor: theme.colorScheme.primary,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        theme,
                                      ),
                                      loading: () => const Center(child: CircularProgressIndicator()),
                                      error: (e, _) => Text('Error loading packages: $e'),
                                    );
                                  },
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (e, _) => Text('Error loading photographer: $e'),
                                );
                              },
                            ),
                            const SizedBox(height: 100), // Space for bottom button
                          ],
                        ),
                      ),
                    ),
                    // Book button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            print('Button pressed!');
                            print('Time slot: "$_selectedTimeSlot"');
                            print('Package ID: "$_selectedPackageId"');
                            print('Event location: "$_eventLocation"');
                            print('Event type: "$_eventType"');
                            
                            final isEnabled = _selectedTimeSlot.isNotEmpty && 
                                             _selectedPackageId != null && 
                                             _eventLocation.isNotEmpty && 
                                             _eventType.isNotEmpty;
                            print('Button enabled: $isEnabled');
                            
                            if (isEnabled) {
                              _handleBookingSubmission(ref, theme);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Confirm Booking',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBookingSubmission(WidgetRef ref, ThemeData theme) async {
    try {
      print('Starting booking submission...');
      
      // Gather all booking data
      final currentUser = ref.read(authProvider).user;
      print('Current user: ${currentUser?.id}');
      
      final photographerAsync = ref.read(photographerDetailProvider(widget.photographerId));
      final photographer = photographerAsync.asData?.value;
      print('Photographer: ${photographer?.userId}');
      
      final packagesAsync = ref.read(packagesForProviderProvider(photographer?.userId ?? ''));
      final selectedPackage = () {
        final pkgs = packagesAsync.asData?.value;
        if (pkgs == null) return null;
        try {
          return pkgs.firstWhere((pkg) => pkg.id == _selectedPackageId);
        } catch (_) {
          return null;
        }
      }();
      print('Selected package: ${selectedPackage?.id}');
      print('Selected package ID: $_selectedPackageId');
      
      if (currentUser == null || photographer == null || selectedPackage == null) {
        print('Missing booking information: user=${currentUser != null}, photographer=${photographer != null}, package=${selectedPackage != null}');
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Missing booking information.')),
        );
        return;
      }
      
      print('Creating booking request...');
      // Create booking request and send to backend
      final bookingRequest = BookingRequest(
        serviceProviderId: photographer.userId,
        packageId: selectedPackage.id,
        eventDate: _selectedDate,
        eventTime: _selectedTimeSlot,
        eventLocation: _eventLocation,
        eventType: _eventType,
        totalAmount: selectedPackage.basePrice,
        specialRequests: _specialRequests.isNotEmpty ? _specialRequests : null,
        serviceType: ServiceType.photography,
      );
      
      print('Booking request created: ${bookingRequest.toJson()}');
      
      final bookingManager = ref.read(bookingManagerProvider);
      
      // Test server connection first
      print('Testing server connection...');
      final isServerReachable = await bookingManager.testServerConnection();
      if (!isServerReachable) {
        throw Exception('Cannot connect to server. Please check if the backend is running and accessible.');
      }
      
      print('Sending booking to backend...');
      final booking = await bookingManager.createBooking(bookingRequest);
      ref.invalidate(bookingsProvider);
      print('Booking created successfully!');
      
      // Only initialize payment if booking is confirmed_awaiting_payment
      if (booking.status == BookingStatus.confirmed_awaiting_payment) {
        await _initializePayment(ref, booking.id, selectedPackage.basePrice);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking request sent! Please wait for provider confirmation before payment.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context); // Close booking dialog
      }
      
    } catch (e) {
      print('Error creating booking: $e');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create booking: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initializePayment(WidgetRef ref, String bookingId, double amount) async {
    try {
      print('Initializing payment for booking: $bookingId');
      
      final paymentNotifier = ref.read(paymentProvider.notifier);
      await paymentNotifier.initializePayment(bookingId);
      
      final paymentState = ref.read(paymentProvider);
      
      if (paymentState.paymentUrl != null) {
        // Navigate to payment screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KhaltiPaymentScreen(
              paymentUrl: paymentState.paymentUrl!,
              bookingId: bookingId,
              amount: amount,
            ),
          ),
        );
        
        if (result == true) {
          // Payment successful
          Navigator.pop(context); // Close booking dialog
          _showPaymentSuccess(amount, bookingId);
        } else {
          // Payment failed or cancelled
          Navigator.pop(context); // Close booking dialog
          _showPaymentFailure();
        }
      } else {
        throw Exception('Failed to get payment URL');
      }
    } catch (e) {
      print('Error initializing payment: $e');
      Navigator.pop(context); // Close booking dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment initialization failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBookingSection(String title, IconData icon, Widget content, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  void _showBookingConfirmation(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Booking Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your booking has been confirmed.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Details:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  Text('Time: $_selectedTimeSlot'),
                  Text('Package: $_selectedPackage'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccess(double amount, String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.payment,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your payment has been processed successfully. Your booking is now confirmed.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('Amount: Rs. ${amount.toStringAsFixed(2)}'),
                  Text('Booking ID: $bookingId'),
                  const Text('Payment Method: Khalti'),
                  const Text('Status: Completed'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailure() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Payment Failed'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your payment could not be processed. Please try again or contact support if the problem persists.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildServicePackage(String name, double price, String subtitle, List<String> features, ThemeData theme, {bool isPopular = false}) {
    final isSelected = _selectedPackage == name;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected 
              ? theme.colorScheme.primary 
              : isPopular 
                  ? theme.colorScheme.secondary.withOpacity(0.3)
                  : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _selectedPackage = name),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[700],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('POPULAR', style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                )),
                              ),
                            if (isPopular) const SizedBox(height: 8),
                            Text(
                              'Rs. ${price.toStringAsFixed(0)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Features list
                    ...features.map<Widget>((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
              // Selection indicator
              if (isSelected)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getTimeSlots() {
    return [
      '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
      '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM'
    ];
  }

  Widget _buildEnhancedMapSection(ThemeData theme, Photographer photographer) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _mainAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value * 0.3),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _EnhancedMapCard(
                  photographer: photographer,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SingleProviderMapScreen(provider: photographer),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _getImageCount(Photographer photographer) {
    int count = 0;
    if (photographer.image.isNotEmpty) count++;
    if (photographer.portfolio.isNotEmpty) count += photographer.portfolio.length;
    return count > 0 ? count : 1; // Return at least 1 for placeholder
  }

  String? _getImageUrl(Photographer photographer, int index) {
    String? url;
    if (index == 0 && photographer.image.isNotEmpty) {
      url = photographer.image;
    } else {
      final portfolioIndex = photographer.image.isNotEmpty ? index - 1 : index;
      if (portfolioIndex >= 0 && portfolioIndex < photographer.portfolio.length) {
        url = photographer.portfolio[portfolioIndex];
      }
    }
    if (url != null && url.isNotEmpty) {
      // Remove any existing cache-busting parameters first
      final baseUrl = url.split('?')[0];
      // Add fresh cache-busting query param to force refresh
      return '$baseUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    }
    return null;
  }

  void _refreshPhotographerData() {
    // Invalidate the provider to fetch fresh data
    ref.invalidate(photographerDetailProvider(widget.photographerId));
    // Clear all image caches
    CachedNetworkImage.evictFromCache('');
    // Force widget rebuild
    if (mounted) {
      setState(() {});
    }
  }
}

// Integrated ReviewsTab widget
class ReviewsTab extends ConsumerStatefulWidget {
  final String serviceProviderId;
  final String serviceProviderName;
  final String serviceProviderType;

  const ReviewsTab({
    Key? key,
    required this.serviceProviderId,
    required this.serviceProviderName,
    required this.serviceProviderType,
  }) : super(key: key);

  @override
  ConsumerState<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<ReviewsTab> {
  int _currentPage = 1;
  final int _pageSize = 5; // Show only 5 reviews initially
  bool _hasMoreReviews = true;

  @override
  void initState() {
    super.initState();
    // Load initial reviews
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewProvider.notifier).getProviderReviews(
        widget.serviceProviderId,
        page: _currentPage,
        limit: _pageSize,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewsState = ref.watch(reviewProvider);

    return SliverToBoxAdapter(
      child: Container(
        key: const ValueKey('reviews'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: reviewsState.isLoading && reviewsState.reviews.isEmpty
            ? _buildLoadingState(theme)
            : reviewsState.error != null && reviewsState.reviews.isEmpty
                ? _buildErrorState(theme, reviewsState.error!)
                : reviewsState.reviews.isEmpty
                    ? _buildEmptyReviews(theme)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reviews Statistics
                          _buildReviewsStatistics(theme, reviewsState.reviews, reviewsState.totalReviews),
                          const SizedBox(height: 24),
                          
                          // Reviews List
                          ...reviewsState.reviews.map((review) => _buildReviewCard(review, theme)).toList(),
                          
                          // Load More Button
                          if (reviewsState.reviews.length < reviewsState.totalReviews) ...[
                            const SizedBox(height: 16),
                            _buildLoadMoreButton(theme, _currentPage, (reviewsState.totalReviews / _pageSize).ceil()),
                          ],
                        ],
                      ),
      ),
    );
  }

  Widget _buildReviewsStatistics(ThemeData theme, List<Review> reviews, int totalReviews) {
    // Calculate average rating
    double averageRating = 0.0;
    if (reviews.isNotEmpty) {
      averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    }

    // Calculate rating distribution
    Map<int, int> ratingDistribution = {};
    for (int i = 1; i <= 5; i++) {
      ratingDistribution[i] = reviews.where((r) => r.rating.floor() == i).length;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rate_review_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Reviews',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Average Rating
          Row(
            children: [
              // Star rating display
              ...List.generate(5, (index) {
                return Icon(
                  index < averageRating.floor()
                      ? Icons.star_rounded
                      : index < averageRating
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded,
                  color: Colors.amber[600],
                  size: 24,
                );
              }),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$totalReviews reviews',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Rating Distribution
          ...ratingDistribution.entries.map((entry) {
            final rating = entry.key;
            final count = entry.value;
            final percentage = totalReviews > 0 ? (count / totalReviews) * 100 : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '$rating',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review Header
          Row(
            children: [
              // Client Profile Image
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: review.clientProfileImage != null && review.clientProfileImage!.isNotEmpty
                      ? Image.network(
                          review.clientProfileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.clientName?.isNotEmpty == true 
                          ? review.clientName! 
                          : 'Client',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatReviewDate(review.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Star Rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating.floor()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber[600],
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Review Comment
          Text(
            review.comment,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          
          // Review Images (if any)
          if (review.images != null && review.images!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review.images![idx],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(ThemeData theme, int currentPage, int totalPages) {
    final remainingReviews = totalPages - currentPage;
    final reviewsToLoad = remainingReviews * _pageSize;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _loadMoreReviews(),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Show ${reviewsToLoad > 0 ? reviewsToLoad : 'more'} reviews',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReviews(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Reviews Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review ${widget.serviceProviderName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading reviews...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Reviews',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load reviews. Please try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _retryLoadingReviews(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _loadMoreReviews() {
    final nextPage = _currentPage + 1;
    ref.read(reviewProvider.notifier).getProviderReviews(
      widget.serviceProviderId,
      page: nextPage,
      limit: _pageSize,
      append: true, // Append to existing reviews instead of replacing
    );
    setState(() {
      _currentPage = nextPage;
    });
  }

  void _retryLoadingReviews() {
    ref.read(reviewProvider.notifier).getProviderReviews(
      widget.serviceProviderId,
      page: 1,
      limit: _pageSize,
    );
    setState(() {
      _currentPage = 1;
    });
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

class _EnhancedMapCard extends StatefulWidget {
  final Photographer photographer;
  final VoidCallback onTap;

  const _EnhancedMapCard({
    required this.photographer,
    required this.onTap,
  });

  @override
  State<_EnhancedMapCard> createState() => _EnhancedMapCardState();
}

class _EnhancedMapCardState extends State<_EnhancedMapCard> with TickerProviderStateMixin {
  late AnimationController _mapAnimationController;
  late AnimationController _markerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  bool _isMapLoaded = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _mapAnimationController.forward();
  }

  void _setupAnimations() {
    _mapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mapAnimationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mapAnimationController, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _mapAnimationController, curve: Curves.easeOutCubic),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _markerAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _mapAnimationController.dispose();
    _markerAnimationController.dispose();
    super.dispose();
  }

  void _onMapReady() {
    setState(() => _isMapLoaded = true);
    _markerAnimationController.forward();
  }

  void _onMapError(String error) {
    setState(() {
      _hasError = true;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = widget.photographer.location!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Map Container
            Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withOpacity(0.95),
                  ],
                ),
              ),
              child: _hasError
                  ? _buildErrorState(theme)
                  : _buildMapContent(theme, location),
            ),
            // Header Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            location.name.isNotEmpty ? location.name : 'Photographer Location',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Action Buttons Overlay
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  _buildActionButton(
                    icon: Icons.directions_rounded,
                    label: 'Directions',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Directions feature coming soon!')),
                      );
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share feature coming soon!')),
                      );
                    },
                    theme: theme,
                  ),
                ],
              ),
            ),
            // Tap Overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent(ThemeData theme, dynamic location) {
    return AnimatedBuilder(
      animation: _mapAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      center: LatLng(location.latitude, location.longitude),
                      zoom: 15,
                      onMapReady: _onMapReady,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: ['a', 'b', 'c', 'd'],
                        retinaMode: true,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(location.latitude, location.longitude),
                            width: 50,
                            height: 50,
                            child: AnimatedBuilder(
                              animation: _bounceAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 0.8 + (_bounceAnimation.value * 0.2),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Loading Overlay
                  if (!_isMapLoaded)
                    Container(
                      color: theme.colorScheme.surface,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading map...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Map Unavailable',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Unable to load map',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = '';
                });
                _mapAnimationController.reset();
                _mapAnimationController.forward();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}