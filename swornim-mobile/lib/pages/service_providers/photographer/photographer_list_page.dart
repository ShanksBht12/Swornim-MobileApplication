import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';
import 'package:swornim/pages/providers/service_providers/models/photographer.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_factory.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_manager.dart';
import 'package:swornim/pages/service_providers/photographer/photographer_detail_page.dart';
import 'package:swornim/main.dart';

class PhotographerListPage extends ConsumerStatefulWidget {
  const PhotographerListPage({super.key});

  @override
  ConsumerState<PhotographerListPage> createState() => _PhotographerListPageState();
}

class _PhotographerListPageState extends ConsumerState<PhotographerListPage>
    with TickerProviderStateMixin {
  // Search and filter state
  String _searchQuery = '';
  String _selectedSpecialization = 'All';
  String _selectedLocation = 'All';
  double _minRating = 0.0;
  bool _showFilters = false;
  String _sortBy = 'rating'; // rating, price, name
  
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _filterAnimationController;
  late AnimationController _staggerController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _filterSlideAnimation;
  
  // Filter options
  static const List<String> _specializations = [
    'All', 'wedding', 'portrait', 'event', 'commercial', 'fashion', 'product', 'nature', 'street'
  ];
  
  static const List<String> _locations = [
    'All', 'Kathmandu', 'Lalitpur', 'Bhaktapur', 'Pokhara', 'Chitwan', 'Butwal', 'Biratnagar'
  ];

  static const List<Map<String, String>> _sortOptions = [
    {'key': 'rating', 'label': 'Highest Rated', 'icon': 'star'},
    {'key': 'price_low', 'label': 'Price: Low to High', 'icon': 'arrow_upward'},
    {'key': 'price_high', 'label': 'Price: High to Low', 'icon': 'arrow_downward'},
    {'key': 'name', 'label': 'Name A-Z', 'icon': 'sort_by_alpha'},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _slideAnimation = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _filterSlideAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _filterAnimationController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedSpecialization = 'All';
      _selectedLocation = 'All';
      _minRating = 0.0;
      _sortBy = 'rating';
    });
  }

  // Helper to clean and validate photographer IDs
  String _cleanPhotographerId(String id) {
    if (id.startsWith('search')) {
      if (id.length > 6) {
        String cleanId = id.substring(6);
        if (cleanId.length >= 32) {
          return cleanId;
        }
      }
      return id;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photographersAsync = ref.watch(serviceProvidersProvider(ServiceProviderType.photographer));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(serviceProvidersProvider(ServiceProviderType.photographer));
        },
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildEnhancedAppBar(theme),
            _buildSearchAndQuickFilters(theme),
            if (_showFilters) _buildAdvancedFiltersPanel(theme),
            _buildResultsHeader(theme, photographersAsync),
            _buildPhotographersContent(photographersAsync, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: GradientTheme.primaryGradient,
          ),
          child: Stack(
            children: [
              // Animated background patterns
              ...List.generate(3, (index) => Positioned(
                right: -30 - (index * 40),
                top: 40 + (index * 30),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 0.1 * (index + 1),
                      child: Container(
                        width: 120 - (index * 20),
                        height: 120 - (index * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05 + (index * 0.03)),
                        ),
                      ),
                    );
                  },
                ),
              )),
              
              // Main icon
              Positioned(
                right: 24,
                top: 70,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
              
              // Title content (always visible)
              Positioned(
                left: 20,
                bottom: 24,
                right: 140,
                child: Text(
                  'Photographers',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: AnimatedRotation(
            turns: _showFilters ? 0.25 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          onPressed: _toggleFilters,
          tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchAndQuickFilters(ThemeData theme) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value * 0.8),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Enhanced Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Search photographers, specializations, locations...',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: theme.iconTheme.color,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Quick Filter Pills
                    Row(
                      children: [
                        Expanded(child: _buildQuickFilterPill('Wedding', 'wedding', Icons.favorite_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildQuickFilterPill('Portrait', 'portrait', Icons.person_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildQuickFilterPill('Event', 'event', Icons.event_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildQuickFilterPill('Fashion', 'fashion', Icons.style_rounded)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickFilterPill(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _selectedSpecialization == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedSpecialization = isSelected ? 'All' : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : theme.dividerColor,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : theme.colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFiltersPanel(ThemeData theme) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _filterSlideAnimation,
        builder: (context, child) {
          return ClipRect(
            child: Align(
              heightFactor: _filterSlideAnimation.value,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Advanced Filters',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _clearAllFilters,
                          child: Text(
                            'Clear All',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Filter sections
                    _buildFilterSection(
                      'Specialization',
                      Icons.camera_rounded,
                      _specializations,
                      _selectedSpecialization,
                      (value) => setState(() => _selectedSpecialization = value),
                      theme,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildFilterSection(
                      'Location',
                      Icons.location_on_rounded,
                      _locations,
                      _selectedLocation,
                      (value) => setState(() => _selectedLocation = value),
                      theme,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Rating filter
                    _buildRatingFilter(theme),
                    
                    const SizedBox(height: 20),
                    
                    // Sort options
                    _buildSortSection(theme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    IconData icon,
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) => _buildFilterChip(option, selectedValue, onChanged, theme)).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String option, String selectedValue, Function(String) onChanged, ThemeData theme) {
    final isSelected = selectedValue == option;
    return GestureDetector(
      onTap: () => onChanged(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          option,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Minimum Rating',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_minRating.toStringAsFixed(1)} ⭐',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.dividerColor,
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            onChanged: (value) => setState(() => _minRating = value),
          ),
        ),
      ],
    );
  }

  Widget _buildSortSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sort_rounded, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Sort By',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sortOptions.map((option) => _buildSortChip(option, theme)).toList(),
        ),
      ],
    );
  }

  Widget _buildSortChip(Map<String, String> option, ThemeData theme) {
    final isSelected = _sortBy == option['key'];
    final iconData = _getIconFromString(option['icon']!);
    
    return GestureDetector(
      onTap: () => setState(() => _sortBy = option['key']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.secondary : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.secondary : theme.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 16,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              option['label']!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'star': return Icons.star_rounded;
      case 'arrow_upward': return Icons.arrow_upward_rounded;
      case 'arrow_downward': return Icons.arrow_downward_rounded;
      case 'sort_by_alpha': return Icons.sort_by_alpha_rounded;
      default: return Icons.sort_rounded;
    }
  }

  Widget _buildResultsHeader(ThemeData theme, AsyncValue photographersAsync) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Photographers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                photographersAsync.when(
                  data: (providers) {
                    final photographers = providers.whereType<Photographer>().toList();
                    final filteredCount = _filterAndSortPhotographers(photographers).length;
                    return Text(
                      '$filteredCount ${filteredCount == 1 ? 'photographer' : 'photographers'} found',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    );
                  },
                  loading: () => Text(
                    'Loading...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  error: (_, __) => Text(
                    'Error loading',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotographersContent(AsyncValue photographersAsync, ThemeData theme) {
    return photographersAsync.when(
      data: (providers) {
        final photographers = providers.whereType<Photographer>().toList();
        final filteredPhotographers = _filterAndSortPhotographers(photographers);
        if (filteredPhotographers.isEmpty) {
          return _buildEmptyState(theme);
        }
        return _buildPhotographersList(filteredPhotographers, theme);
      },
      loading: () => _buildLoadingState(theme),
      error: (error, stack) => _buildErrorState(error, theme),
    );
  }

  Widget _buildPhotographersList(List<Photographer> photographers, ThemeData theme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final delay = index * 0.1;
              final animationValue = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    delay,
                    (delay + 0.4).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              );

              return FadeTransition(
                opacity: animationValue,
                child: Transform.translate(
                  offset: Offset(0, (1 - animationValue.value) * 30),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _buildPhotographerCard(photographers[index], theme),
                  ),
                ),
              );
            },
          );
        },
        childCount: photographers.length,
      ),
    );
  }

  Widget _buildPhotographerCard(Photographer photographer, ThemeData theme) {
    String cleanId = _cleanPhotographerId(photographer.id);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotographerDetailPage(photographerId: cleanId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with image and basic info
                Row(
                  children: [
                    // Profile image
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.8),
                            theme.colorScheme.secondary.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: photographer.image.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                photographer.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(theme),
                              ),
                            )
                          : _buildDefaultAvatar(theme),
                    ),
                    const SizedBox(width: 16),
                    // Name and basic info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  photographer.businessName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (photographer.isAvailable)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
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
                          const SizedBox(height: 6),
                          // Rating and reviews
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < photographer.rating.floor()
                                      ? Icons.star_rounded
                                      : index < photographer.rating
                                          ? Icons.star_half_rounded
                                          : Icons.star_outline_rounded,
                                  color: Colors.amber[600],
                                  size: 16,
                                );
                              }),
                              const SizedBox(width: 6),
                              Text(
                                '${photographer.rating.toStringAsFixed(1)} (${photographer.totalReviews} reviews)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                photographer.location?.name ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Specializations
                if (photographer.specializations.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: photographer.specializations.take(4).map((spec) {
                      final capSpec = spec.isNotEmpty ? spec[0].toUpperCase() + spec.substring(1) : spec;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          capSpec,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // Price and action
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting from',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          'NPR ${photographer.hourlyRate.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Action buttons
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Add to favorites functionality
                            },
                            icon: const Icon(Icons.favorite_border_rounded),
                            iconSize: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GradientButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhotographerDetailPage(photographerId: cleanId),
                              ),
                            );
                          },
                          text: 'Detail',
                          gradient: GradientTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.secondary.withOpacity(0.8),
          ],
        ),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 60,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No photographers found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search terms',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearAllFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 20,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 16,
                            width: 120,
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 36,
                      width: 80,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        childCount: 3,
      ),
    );
  }

  Widget _buildErrorState(Object error, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(serviceProvidersProvider(ServiceProviderType.photographer));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<Photographer> _filterAndSortPhotographers(List<Photographer> photographers) {
    var filtered = photographers.where((photographer) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = photographer.businessName.toLowerCase().contains(query);
        final matchesLocation = (photographer.location?.name ?? '').toLowerCase().contains(query);
        final matchesSpecialization = photographer.specializations
            .any((spec) => spec.toLowerCase().contains(query));
        
        if (!matchesName && !matchesLocation && !matchesSpecialization) {
          return false;
        }
      }
      
      // Specialization filter
      if (_selectedSpecialization != 'All') {
        if (!photographer.specializations.contains(_selectedSpecialization)) {
          return false;
        }
      }
      
      // Location filter
      if (_selectedLocation != 'All') {
        if ((photographer.location?.name ?? '') != _selectedLocation) {
          return false;
        }
      }
      
      // Rating filter
      if (photographer.rating < _minRating) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort photographers
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          return b.rating.compareTo(a.rating);
        case 'price_low':
          return a.hourlyRate.compareTo(b.hourlyRate);
        case 'price_high':
          return b.hourlyRate.compareTo(a.hourlyRate);
        case 'name':
          return a.businessName.compareTo(b.businessName);
        default:
          return b.rating.compareTo(a.rating);
      }
    });
    
    return filtered;
  }
}