import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swornim/pages/providers/service_providers/models/base_service_provider.dart';
import 'package:swornim/pages/providers/service_providers/models/makeup_artist.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_factory.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_manager.dart';
import 'makeupartist_detail_page.dart';
import 'package:swornim/main.dart';
import 'package:swornim/pages/providers/bookings/bookings_provider.dart';

class MakeupArtistListPage extends ConsumerStatefulWidget {
  const MakeupArtistListPage({super.key});

  @override
  ConsumerState<MakeupArtistListPage> createState() => _MakeupArtistListPageState();
}

class _MakeupArtistListPageState extends ConsumerState<MakeupArtistListPage>
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
    'All', 'bridal', 'party', 'editorial', 'fashion', 'special_effects', 'airbrush', 'natural', 'glamour'
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final makeupArtistsAsync = ref.watch(serviceProvidersProvider(ServiceProviderType.makeupArtist));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(serviceProvidersProvider(ServiceProviderType.makeupArtist));
        },
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildEnhancedAppBar(theme),
            _buildSearchAndQuickFilters(theme),
            _buildAdvancedFiltersPanel(theme),
            _buildResultsHeader(theme, makeupArtistsAsync),
            _buildMakeupArtistsContent(makeupArtistsAsync, theme),
            // Add extra space at bottom for refresh indicator
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
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
                    Icons.palette_rounded,
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
                  'Makeup Artists',
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
                          hintText: 'Search makeup artists, specializations, locations...',
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
                        Expanded(child: _buildQuickFilterPill('Bridal', 'bridal', Icons.favorite_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildQuickFilterPill('Party', 'party', Icons.celebration_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildQuickFilterPill('Fashion', 'fashion', Icons.style_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildQuickFilterPill('Natural', 'natural', Icons.nature_people_rounded)),
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
    if (!_showFilters) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
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
                      Icons.palette_rounded,
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

  Widget _buildResultsHeader(ThemeData theme, AsyncValue makeupArtistsAsync) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Makeup Artists',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                makeupArtistsAsync.when(
                  data: (providers) {
                    final makeupArtists = providers.whereType<MakeupArtist>().toList();
                    final filteredCount = _filterAndSortMakeupArtists(makeupArtists).length;
                    return Text(
                      '$filteredCount ${filteredCount == 1 ? 'makeup artist' : 'makeup artists'} found',
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
                    'Certified',
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

  Widget _buildMakeupArtistsContent(AsyncValue makeupArtistsAsync, ThemeData theme) {
    return makeupArtistsAsync.when(
      data: (providers) {
        final makeupArtists = providers.whereType<MakeupArtist>().toList();
        final filteredMakeupArtists = _filterAndSortMakeupArtists(makeupArtists);
        
        if (filteredMakeupArtists.isEmpty) {
          return _buildEmptyState(theme);
        }
        
        return _buildMakeupArtistsList(filteredMakeupArtists, theme);
      },
      loading: () => _buildLoadingState(theme),
      error: (error, stack) => _buildErrorState(error, theme),
    );
  }

  Widget _buildMakeupArtistsList(List<MakeupArtist> makeupArtists, ThemeData theme) {
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
                    child: _buildMakeupArtistCard(makeupArtists[index], theme),
                  ),
                ),
              );
            },
          );
        },
        childCount: makeupArtists.length,
      ),
    );
  }

  Widget _buildMakeupArtistCard(MakeupArtist makeupArtist, ThemeData theme) {
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
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MakeupArtistDetailPage(makeupArtistId: makeupArtist.id),
              ),
            );
            print('[DEBUG] MakeupArtistDetailPage result: $result');
            if (result == true) {
              ref.invalidate(bookingsProvider);
              print('[DEBUG] bookingsProvider invalidated from parent');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with profile image and basic info
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
                      child: makeupArtist.image.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                makeupArtist.image,
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
                                  makeupArtist.businessName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (makeupArtist.isAvailable)
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
                                  index < makeupArtist.rating.floor()
                                      ? Icons.star_rounded
                                      : index < makeupArtist.rating
                                          ? Icons.star_half_rounded
                                          : Icons.star_outline_rounded,
                                  color: Colors.amber[600],
                                  size: 16,
                                );
                              }),
                              const SizedBox(width: 6),
                              Text(
                                '${makeupArtist.rating.toStringAsFixed(1)} (${makeupArtist.totalReviews} reviews)',
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
                                makeupArtist.location?.name ?? '',
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
                if (makeupArtist.specializations.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: makeupArtist.specializations.take(4).map((spec) {
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
                          'NPR ${makeupArtist.sessionRate.toStringAsFixed(0)}',
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
                                builder: (context) => MakeupArtistDetailPage(makeupArtistId: makeupArtist.id),
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
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 16),
            Text(
              'No makeup artists found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Try adjusting your filters or search terms',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
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
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading makeup artists...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, ThemeData theme) {
    return SliverFillRemaining(
      child: Container(
        margin: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                ref.invalidate(serviceProvidersProvider(ServiceProviderType.makeupArtist));
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

  List<MakeupArtist> _filterAndSortMakeupArtists(List<MakeupArtist> makeupArtists) {
    var filtered = makeupArtists.where((artist) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = artist.businessName.toLowerCase().contains(query);
        final matchesLocation = (artist.location?.name ?? '').toLowerCase().contains(query);
        final matchesSpecialization = artist.specializations
            .any((spec) => spec.toLowerCase().contains(query));
        
        if (!matchesName && !matchesLocation && !matchesSpecialization) {
          return false;
        }
      }
      
      // Specialization filter
      if (_selectedSpecialization != 'All') {
        if (!artist.specializations.contains(_selectedSpecialization)) {
          return false;
        }
      }
      
      // Location filter
      if (_selectedLocation != 'All') {
        if ((artist.location?.name ?? '') != _selectedLocation) {
          return false;
        }
      }
      
      // Rating filter
      if (artist.rating < _minRating) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort the filtered results
    switch (_sortBy) {
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price_low':
        filtered.sort((a, b) => a.sessionRate.compareTo(b.sessionRate));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.sessionRate.compareTo(a.sessionRate));
        break;
      case 'name':
        filtered.sort((a, b) => a.businessName.compareTo(b.businessName));
        break;
    }
    
    return filtered;
  }
}
