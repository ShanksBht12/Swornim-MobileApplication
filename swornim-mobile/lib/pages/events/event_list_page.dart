import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swornim/pages/services/event_manager.dart';
import 'package:swornim/pages/models/events/event.dart';
import 'package:swornim/pages/events/widgets/event_cart.dart';
import '../QRScreen/qr_ticket_screen.dart';
import 'package:swornim/pages/events/event_detail_page.dart';

class EventListPage extends ConsumerStatefulWidget {
  const EventListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends ConsumerState<EventListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  EventType? _selectedEventType;
  String _searchQuery = '';
  bool _isSearching = false;

  // Cache the parameter objects to prevent unnecessary rebuilds
  Map<String, dynamic>? _cachedPublicEventsParams;
  Map<String, dynamic>? _cachedSearchParams;

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
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    // Initialize the cached parameters
    _updateCachedParams();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCachedParams() {
    print('[DEBUG] _updateCachedParams: _selectedEventType=$_selectedEventType (${_selectedEventType.runtimeType})');
    if (_isSearching) {
      _cachedSearchParams = {
        'query': _searchQuery,
        'eventType': _selectedEventType?.name,
      };
      _cachedPublicEventsParams = null;
    } else {
      _cachedPublicEventsParams = {
        'eventType': _selectedEventType?.name,
      };
      _cachedSearchParams = null;
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
      _updateCachedParams();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
      _updateCachedParams();
    });
  }

  void _onEventTypeSelected(EventType? eventType) {
    assert(eventType == null || eventType is EventType, '[DEFENSIVE] _onEventTypeSelected received a non-enum value: $eventType (${eventType.runtimeType})');
    if (eventType is! EventType && eventType != null) {
      print('[ERROR] _onEventTypeSelected: Tried to assign a non-enum value to _selectedEventType: $eventType (${eventType.runtimeType})');
      return;
    }
    print('[DEBUG] _onEventTypeSelected: eventType=$eventType (${eventType.runtimeType})');
    setState(() {
      _selectedEventType = eventType;
      _updateCachedParams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use the cached parameters to prevent unnecessary provider calls
    final AsyncValue<List<Event>> eventsAsync;
    if (_isSearching && _cachedSearchParams != null) {
      eventsAsync = ref.watch(eventSearchProvider(_cachedSearchParams!));
    } else if (_cachedPublicEventsParams != null) {
      eventsAsync = ref.watch(publicEventsProvider(_cachedPublicEventsParams!));
    } else {
      // Fallback - should not happen with proper initialization
      eventsAsync = ref.watch(publicEventsProvider({'eventType': null}));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Premium App Bar
          _buildSliverAppBar(context, colorScheme),
          
          // Search and Filter Section
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSearchAndFilterSection(context, colorScheme),
              ),
            ),
          ),
          
          // Event Type Filter Chips
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildEventTypeFilters(context, colorScheme),
              ),
            ),
          ),
          
          // Events List
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildEventsList(context, colorScheme, eventsAsync),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
          title: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              Text(
                'Extraordinary Events',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background Pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: PatternPainter(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                
                // Floating Action Elements
                Positioned(
                  top: 40,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search for amazing events...',
          hintStyle: GoogleFonts.inter(
            color: colorScheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(
                    Icons.clear_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.1),
                          colorScheme.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: GoogleFonts.inter(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEventTypeFilters(BuildContext context, ColorScheme colorScheme) {
    final eventTypes = [
      null, // All events
      EventType.concert,
      EventType.musicFestival,
      EventType.theater,
      EventType.corporate,
      EventType.sports_event,
      EventType.cultural_show,
      EventType.party,
    ];
    print('[DEBUG] _buildEventTypeFilters: _selectedEventType=$_selectedEventType (${_selectedEventType.runtimeType})');

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: eventTypes.length,
        itemBuilder: (context, index) {
          final eventType = eventTypes[index];
          final isSelected = _selectedEventType == eventType;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                eventType?.displayName ?? 'All Events',
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                _onEventTypeSelected(selected ? eventType : null);
              },
              backgroundColor: Colors.white,
              selectedColor: colorScheme.primary,
              checkmarkColor: Colors.white,
              elevation: isSelected ? 4 : 0,
              shadowColor: colorScheme.primary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(
                  color: isSelected 
                      ? colorScheme.primary 
                      : colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, ColorScheme colorScheme, AsyncValue<List<Event>> eventsAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: eventsAsync.when(
        data: (events) {
          debugPrint('[EventListPage] Data loaded. Events count: ${events.length}');
          
          if (events.isEmpty) {
            return _buildEmptyState(context, colorScheme);
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              _buildSectionHeader(context, colorScheme, events.length),
              
              const SizedBox(height: 16),
              
              // Events Grid/List
              ...events.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;
                
                return AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  child: EventCard(
                    event: event,
                    onTap: () => _onEventTapped(event),
                  ),
                );
              }).toList(),
              
              // Bottom Spacing
              const SizedBox(height: 80),
            ],
          );
        },
        loading: () {
          debugPrint('[EventListPage] Loading events...');
          return _buildLoadingState(context, colorScheme);
        },
        error: (err, stack) {
          debugPrint('[EventListPage] Error loading events: ${err.toString()}');
          return _buildErrorState(context, colorScheme, err.toString());
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, ColorScheme colorScheme, int eventCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSearching 
                    ? 'Search Results' 
                    : _selectedEventType != null 
                        ? '${_selectedEventType!.displayName} Events'
                        : 'Featured Events',
                style: GoogleFonts.inter(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$eventCount incredible experiences await',
                style: GoogleFonts.inter(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Sort/Filter Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.sort_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        children: [
          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 60,
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            _isSearching 
                ? 'No events found for "$_searchQuery"'
                : 'No events available',
            style: GoogleFonts.inter(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            _isSearching
                ? 'Try adjusting your search terms or explore different event categories'
                : 'Be the first to know when amazing events are announced',
            style: GoogleFonts.inter(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Action Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSearching ? _clearSearch : () {
                  // Navigate to create event or notify me
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Text(
                    _isSearching ? 'Clear Search' : 'Notify Me',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          // Animated Loading Cards
          ...List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildLoadingCard(colorScheme, index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ColorScheme colorScheme, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image Placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceVariant,
                  colorScheme.surfaceVariant.withOpacity(0.5),
                ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          
          // Content Placeholder
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 32,
                      width: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ColorScheme colorScheme, String error) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        children: [
          // Error Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFDC2626).withOpacity(0.1),
                  const Color(0xFFDC2626).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: const Color(0xFFDC2626).withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.inter(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'We encountered an issue while loading events. Please try again.',
            style: GoogleFonts.inter(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Retry Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Clear cache and refresh
                  _updateCachedParams();
                  if (_isSearching && _cachedSearchParams != null) {
                    ref.refresh(eventSearchProvider(_cachedSearchParams!));
                  } else if (_cachedPublicEventsParams != null) {
                    ref.refresh(publicEventsProvider(_cachedPublicEventsParams!));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Try Again',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onEventTapped(Event event) {
    debugPrint('[EventListPage] Event tapped:  [1m${event.title} [0m');
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailPage(event: event),
      ),
    );
  }
}

// Custom Pattern Painter for Background
class PatternPainter extends CustomPainter {
  final Color color;
  
  PatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    const spacing = 30.0;
    
    // Draw diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Extension for EventType display names
extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.concert:
        return 'Concerts';
      case EventType.musicFestival:
        return 'Music Festivals';
      case EventType.dancePerformance:
        return 'Dance Shows';
      case EventType.comedy_show:
        return 'Comedy Shows';
      case EventType.theater:
        return 'Theater';
      case EventType.cultural_show:
        return 'Cultural Shows';
      case EventType.wedding:
        return 'Weddings';
      case EventType.birthday:
        return 'Birthdays';
      case EventType.anniversary:
        return 'Anniversaries';
      case EventType.graduation:
        return 'Graduations';
      case EventType.corporate:
        return 'Corporate';
      case EventType.conference:
        return 'Conferences';
      case EventType.seminar:
        return 'Seminars';
      case EventType.workshop:
        return 'Workshops';
      case EventType.product_launch:
        return 'Product Launches';
      case EventType.sports_event:
        return 'Sports';
      case EventType.charity_event:
        return 'Charity';
      case EventType.exhibition:
        return 'Exhibitions';
      case EventType.trade_show:
        return 'Trade Shows';
      case EventType.festival_celebration:
        return 'Festivals';
      case EventType.religious_ceremony:
        return 'Religious';
      case EventType.party:
        return 'Parties';
      default:
        return 'Other';
    }
  }
}