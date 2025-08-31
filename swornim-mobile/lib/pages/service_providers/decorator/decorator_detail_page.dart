import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swornim/pages/models/bookings/service_package.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/config/app_config.dart';
import 'package:swornim/pages/providers/bookings/bookings.dart';
import 'package:swornim/pages/providers/bookings/package_manager.dart';
import 'package:swornim/pages/providers/service_providers/models/decorator.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_factory.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:swornim/pages/map/single_provider_map_screen.dart';
import 'package:swornim/pages/providers/payments/payment_provider.dart';
import 'package:swornim/pages/payment/khalti_payment_screen.dart';
import 'package:swornim/pages/service_providers/common/reviews_tab.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Provider to fetch a single decorator by their ID
final decoratorDetailProvider = FutureProvider.family<Decorator, String>((ref, decoratorId) async {
  final manager = ref.read(serviceProviderManagerProvider);
  final result = await manager.getServiceProvider(ServiceProviderType.decorator, decoratorId);
  if (result.isError || result.data == null) throw Exception(result.error ?? 'Decorator not found');
  final decorator = result.data as Decorator;
  // Clear any cached images for this decorator to ensure fresh data
  if (decorator.image.isNotEmpty) {
    final baseImageUrl = decorator.image.split('?')[0];
    // Clear various cached versions
    CachedNetworkImage.evictFromCache(decorator.image);
    CachedNetworkImage.evictFromCache(baseImageUrl);
    // Clear cache-busted versions from the last hour
    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 3600; i += 60) { // Every minute for the last hour
      final timestamp = now - (i * 1000);
      CachedNetworkImage.evictFromCache('$baseImageUrl?v=$timestamp');
      CachedNetworkImage.evictFromCache('$baseImageUrl?t=$timestamp');
    }
  }
  return decorator;
});

// Using the global packages provider from bookings.dart

// Add userDetailsProvider for fetching real user info
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

class DecoratorDetailPage extends ConsumerStatefulWidget {
  final String decoratorId;
  
  const DecoratorDetailPage({
    super.key,
    required this.decoratorId,
  });

  @override
  ConsumerState<DecoratorDetailPage> createState() => _DecoratorDetailPageState();
}

class _DecoratorDetailPageState extends ConsumerState<DecoratorDetailPage>
    with TickerProviderStateMixin {
  
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
  
  // New state variables
  String? _selectedPackageId;
  String _selectedPackageName = '';
  double? _selectedPackagePrice;
  String _eventLocation = '';
  String _eventType = '';
  String _specialRequests = '';
  
  // Sample data (replace with actual data from your models)
  final List<String> _portfolioImages = [
    'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800',
    'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=800',
    'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=800',
    'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=800',
    'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800',
  ];
  
  final List<String> _timeSlots = [
    '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM'
  ];
  
  final List<Map<String, dynamic>> _packages = [
    {
      'name': 'Basic Event Package',
      'price': 25000,
      'duration': 'Full Event',
      'features': ['Basic theme decoration', 'Welcome gate', 'Stage background'],
    },
    {
      'name': 'Premium Wedding Package',
      'price': 75000,
      'duration': 'Full Event',
      'features': ['Full venue decoration', 'Custom theme', 'Lighting', 'Floral arrangements'],
      'popular': true,
    },
    {
      'name': 'Hourly Consultation',
      'price': 5000,
      'duration': 'Per Hour',
      'features': ['Get expert advice', 'Plan your event theme', 'Budgeting assistance'],
    },
  ];
  
  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Sita Sharma',
      'rating': 5.0,
      'date': '2 weeks ago',
      'comment': 'Absolutely amazing decoration work! The venue looked stunning. Professional and creative service.',
      'images': ['https://images.unsplash.com/photo-1494790108755-2616c27e208e?w=100'],
    },
    {
      'name': 'Ram Thapa',
      'rating': 5.0,
      'date': '1 month ago',
      'comment': 'Perfect for our wedding! The decoration was beyond our expectations. Highly recommended!',
      'images': [],
    },
    {
      'name': 'Maya Gurung',
      'rating': 4.0,
      'date': '2 months ago',
      'comment': 'Great decoration for our corporate event. Very professional and delivered on time.',
      'images': ['https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=100'],
    },
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
    final decoratorAsync = ref.watch(decoratorDetailProvider(widget.decoratorId));
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshDecoratorData();
          // Wait a bit for the refresh to complete
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: theme.colorScheme.primary,
        child: decoratorAsync.when(
          data: (decorator) {
            final packagesAsync = ref.watch(packagesProvider(decorator.userId));
            return SafeArea(
              child: CustomScrollView(
                // Ensure scroll physics allow pull-to-refresh
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeroSection(theme, decorator),
                  _buildQuickInfoSection(theme, decorator),
                  if (decorator.location != null) _buildEnhancedMapSection(theme, decorator),
                  _buildTabSection(theme),
                  _buildCurrentTabContent(theme, decorator, packagesAsync),
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
                  onPressed: _refreshDecoratorData,
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

  Widget _buildHeroSection(ThemeData theme, Decorator decorator) {
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
            onPressed: _refreshDecoratorData,
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
              itemCount: _getImageCount(decorator),
              onPageChanged: (index) {
                setState(() {
                  _selectedImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imageUrl = _getImageUrl(decorator, index);
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
                      child: Icon(Icons.celebration_rounded, color: Colors.white, size: 80),
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
                        child: Icon(Icons.celebration_rounded, color: Colors.white, size: 80),
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
            if (_getImageCount(decorator) > 0)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_getImageCount(decorator), (index) {
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
                              decorator.businessName,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (decorator.isAvailable)
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
                              index < (decorator.rating?.floor() ?? 0)
                                  ? Icons.star_rounded
                                  : index < (decorator.rating ?? 0)
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded,
                              color: Colors.amber[600],
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            (decorator.rating != null && decorator.totalReviews > 0)
                                ? '${decorator.rating.toStringAsFixed(1)} (${decorator.totalReviews} reviews)'
                                : 'No reviews yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
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

  Widget _buildQuickInfoSection(ThemeData theme, Decorator decorator) {
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
                            color: decorator.isAvailable
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
                                  color: decorator.isAvailable
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                decorator.isAvailable ? 'Available' : 'Busy',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: decorator.isAvailable
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
                              decorator.location?.name ?? 'Location not specified',
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
                            '${decorator.experienceYears} years',
                            Icons.work_history_rounded,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Starts From',
                            'Rs. ${decorator.packageStartingPrice.toStringAsFixed(0)}',
                            Icons.attach_money_rounded,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Lighting',
                            decorator.offersLighting ? 'Yes' : 'No',
                            Icons.lightbulb_rounded,
                            theme,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Specializations (Themes)
                    if (decorator.themes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Decoration Themes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: decorator.themes.map((themeName) {
                          final capTheme = themeName.isNotEmpty ? themeName[0].toUpperCase() + themeName.substring(1) : themeName;
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
                              capTheme,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, ThemeData theme) {
    return Container(
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
    );
  }

  Widget _buildCurrentTabContent(ThemeData theme, Decorator decorator, AsyncValue<List<ServicePackage>> packagesAsync) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAboutContent(theme, decorator);
      case 1:
        return _buildServicesContent(theme, packagesAsync);
      case 2:
        return _buildReviewsContent(theme, decorator);
      default:
        return _buildAboutContent(theme, decorator);
    }
  }

  Widget _buildAboutContent(ThemeData theme, Decorator decorator) {
    final userAsync = ref.watch(userDetailsProvider(decorator.userId));
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
                'About ${decorator.businessName}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                decorator.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              if(decorator.availableItems.isNotEmpty) ...[
                _buildInfoSection(
                  'Available Items for Rent',
                  Icons.inventory_2_rounded,
                  decorator.availableItems,
                  theme,
                ),
                const SizedBox(height: 20),
              ],
              _buildInfoSection(
                'Specializations',
                Icons.design_services_rounded,
                decorator.specializations,
                theme,
              ),
              const SizedBox(height: 20),
              // Portfolio section
              if (decorator.portfolio.isNotEmpty) ...[
                _buildPortfolioSection(theme, decorator),
                const SizedBox(height: 20),
              ],
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

  Widget _buildContactInfo(ThemeData theme, User user) {
    final phone = user.phone.isNotEmpty ? user.phone : '+977 98XXXXXXXX';
    final email = user.email.isNotEmpty ? user.email : 'contact@decorator.com';
    final website = 'www.decorator.com'; // Placeholder, update if available
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

  Widget _buildServicesContent(ThemeData theme, AsyncValue<List<ServicePackage>> packagesAsync) {
    return packagesAsync.when(
      data: (packages) {
        if (packages.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('No services or packages have been added yet.')),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final package = packages[index];
                return _buildServicePackage(
                  package.name,
                  package.basePrice,
                  '${package.durationHours} hours',
                  package.features,
                  theme,
                );
              },
              childCount: packages.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(child: Text('Error loading packages: $e')),
      ),
    );
  }
  
  Widget _buildReviewsContent(ThemeData theme, Decorator decorator) {
    // Use the ReviewsTab component for consistent review functionality
    return ReviewsTab(
      serviceProviderId: decorator.userId,
      serviceProviderName: decorator.businessName,
      serviceProviderType: 'decorator',
    );
  }

  Widget _buildFloatingActionButtons(ThemeData theme) {
    return FloatingActionButton.extended(
      heroTag: 'book',
      onPressed: () => _showBookingDialog(theme),
      backgroundColor: theme.colorScheme.primary,
      icon: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
      label: const Text(
        'Book Now',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  void _showBookingDialog(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final decoratorAsync = ref.watch(decoratorDetailProvider(widget.decoratorId));
          final decorator = decoratorAsync.asData?.value;
          if (decorator == null) {
            return const Center(child: CircularProgressIndicator());
          }
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
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Text(
                            'Book Decorator',
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
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            _buildBookingSection(
                              'Select Time',
                              Icons.access_time_rounded,
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _timeSlots.map((time) {
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
                            _buildBookingSection(
                              'Event Type',
                              Icons.event_rounded,
                              DropdownButtonFormField<String>(
                                value: _eventType.isNotEmpty ? _eventType : null,
                                items: ['Wedding', 'Corporate', 'Birthday', 'Other'].map((type) => DropdownMenuItem(
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
                            Consumer(
                              builder: (context, ref, _) {
                                final packagesAsync = ref.watch(packagesProvider(decorator.userId));
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
                                            color: Theme.of(context).scaffoldBackgroundColor,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                                            ),
                                          ),
                                          child: RadioListTile<String>(
                                            value: package.id,
                                            groupValue: _selectedPackageId,
                                            onChanged: (value) {
                                              setModalState(() {
                                                _selectedPackageId = value;
                                                _selectedPackageName = package.name;
                                                _selectedPackagePrice = package.basePrice;
                                              });
                                            },
                                            title: Text(package.name),
                                            subtitle: Text('Rs. ${package.basePrice} • ${package.durationHours} hours'),
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
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
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
                          onPressed: _selectedTimeSlot.isNotEmpty && _selectedPackageId != null && _eventLocation.isNotEmpty && _eventType.isNotEmpty
                              ? () {
                                  Navigator.pop(context);
                                  _handleBookingSubmission(ref, theme);
                                }
                              : null,
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
    // Check if widget is still mounted before proceeding
    if (!_isMounted) return;
    
    try {
      final currentUser = ref.read(authProvider).user;
      final decoratorResult = ref.read(decoratorDetailProvider(widget.decoratorId));
      
      // Check if decorator data is available
      if (!decoratorResult.hasValue) {
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Decorator information not available.')),
          );
        }
        return;
      }
      
      final decorator = decoratorResult.asData!.value;
      final packagesResult = ref.read(packagesProvider(decorator.userId));
      
      // Check if packages data is available
      if (!packagesResult.hasValue) {
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Package information not available.')),
          );
        }
        return;
      }
      
      final packages = packagesResult.asData!.value;
      ServicePackage? selectedPackage;
      
      try {
        selectedPackage = packages.firstWhere((pkg) => pkg.id == _selectedPackageId);
      } catch (_) {
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Selected package not found.')),
          );
        }
        return;
      }
      
      if (currentUser == null) {
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not authenticated.')),
          );
        }
        return;
      }
      
      final bookingRequest = BookingRequest(
        serviceProviderId: decorator.userId,
        packageId: selectedPackage.id,
        eventDate: _selectedDate,
        eventTime: _selectedTimeSlot,
        eventLocation: _eventLocation,
        eventType: _eventType,
        totalAmount: selectedPackage.basePrice,
        specialRequests: _specialRequests.isNotEmpty ? _specialRequests : null,
        serviceType: ServiceType.decoration,
      );
      
      final bookingManager = ref.read(bookingManagerProvider);
      
      // Test server connection first
      final isServerReachable = await bookingManager.testServerConnection();
      if (!isServerReachable) {
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot connect to server. Please check your internet connection.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Check if widget is still mounted before creating booking
      if (!_isMounted) return;
      
      final booking = await bookingManager.createBooking(bookingRequest);
      
      // Check if widget is still mounted after async operation
      if (!_isMounted) return;
      
      // Invalidate bookings provider to refresh data
      ref.invalidate(bookingsProvider);
      
      // Handle different booking statuses
      if (booking.status == BookingStatus.confirmed_awaiting_payment) {
        await _initializePayment(ref, booking.id, selectedPackage.basePrice);
      } else {
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking request sent! Please wait for provider confirmation before payment.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Only show error message if widget is still mounted
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create booking:  [${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Log the error for debugging
      print('Booking creation error: $e');
    }
  }

  Future<void> _initializePayment(WidgetRef ref, String bookingId, double amount) async {
    // Check if widget is still mounted before proceeding
    if (!_isMounted) return;
    
    try {
      print('Initializing payment for booking: $bookingId');
      
      final paymentNotifier = ref.read(paymentProvider.notifier);
      await paymentNotifier.initializePayment(bookingId);
      
      // Check if widget is still mounted after async operation
      if (!_isMounted) return;
      
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
        
        // Check if widget is still mounted after navigation
        if (!_isMounted) return;
        
        if (result == true) {
          // Payment successful
          _showPaymentSuccess(amount, bookingId);
        } else {
          // Payment failed or cancelled
          _showPaymentFailure();
        }
      } else {
        throw Exception('Failed to get payment URL');
      }
    } catch (e) {
      print('Error initializing payment: $e');
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initialization failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBookingConfirmation(ThemeData theme, Decorator decorator) {
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
              'Your booking has been confirmed with ${decorator.businessName}.',
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
                  Text('Package: $_selectedPackageName'),
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
    if (!_isMounted) return;
    
    _safeShowDialog(
      AlertDialog(
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
            onPressed: () {
              if (_isMounted) Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailure() {
    if (!_isMounted) return;
    
    _safeShowDialog(
      AlertDialog(
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
            onPressed: () {
              if (_isMounted) Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  Widget _buildServicePackage(String name, double price, String subtitle, List<String> features, ThemeData theme, {bool isPopular = false}) {
    final isSelected = _selectedPackageId == name;
    
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
          onTap: () => setState(() => _selectedPackageId = name),
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
                              price > 0 ? 'Rs. ${price.toStringAsFixed(0)}' : 'Inquire for Price',
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

  Widget _buildEnhancedMapSection(ThemeData theme, Decorator decorator) {
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
                  decorator: decorator,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SingleProviderMapScreen(provider: decorator),
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

  Widget _buildPortfolioSection(ThemeData theme, Decorator decorator) {
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
            itemCount: decorator.portfolio.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  decorator.portfolio[index],
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

  int _getImageCount(Decorator decorator) {
    int count = 0;
    if (decorator.image.isNotEmpty) count++;
    if (decorator.portfolio.isNotEmpty) count += decorator.portfolio.length;
    return count > 0 ? count : 1; // Return at least 1 for placeholder
  }

  // 1. Update _getImageUrl to force cache refresh
  String? _getImageUrl(Decorator decorator, int index) {
    String? url;
    if (index == 0 && decorator.image.isNotEmpty) {
      url = decorator.image;
    } else {
      final portfolioIndex = decorator.image.isNotEmpty ? index - 1 : index;
      if (portfolioIndex >= 0 && portfolioIndex < decorator.portfolio.length) {
        url = decorator.portfolio[portfolioIndex];
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

  // 3. Add this method to _DecoratorDetailPageState to force refresh
  void _refreshDecoratorData() {
    // Invalidate the provider to fetch fresh data
    ref.invalidate(decoratorDetailProvider(widget.decoratorId));
    // Clear all image caches
    CachedNetworkImage.evictFromCache('');
    // Force widget rebuild
    if (mounted) {
      setState(() {});
    }
  }

  // Add this method to check if widget is still mounted
  bool get _isMounted => mounted;

  // Additional helper method to safely show dialogs
  void _safeShowDialog(Widget dialog) {
    if (_isMounted) {
      showDialog(
        context: context,
        builder: (context) => dialog,
      );
    }
  }
}

class _EnhancedMapCard extends StatefulWidget {
  final Decorator decorator;
  final VoidCallback onTap;

  const _EnhancedMapCard({
    required this.decorator,
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
    final location = widget.decorator.location!;

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
                            location.name.isNotEmpty ? location.name : 'Decorator Location',
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