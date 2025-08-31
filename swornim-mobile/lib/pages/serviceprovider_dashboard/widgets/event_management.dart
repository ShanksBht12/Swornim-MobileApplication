import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/events/event.dart';
import 'package:swornim/pages/services/event_manager.dart';
import 'event_form_dialog.dart';
import 'dart:io';
import 'package:swornim/pages/serviceprovider_dashboard/event_bookings_page.dart';

class EventManagement extends ConsumerStatefulWidget {
  final User provider;
  const EventManagement({required this.provider, Key? key}) : super(key: key);

  @override
  ConsumerState<EventManagement> createState() => _EventManagementState();
}

class _EventManagementState extends ConsumerState<EventManagement>
    with SingleTickerProviderStateMixin {
  late Future<List<Event>> _eventsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedStatus;
  int _selectedChipIndex = 0;
  
  final List<Map<String, dynamic>> statusFilters = [
    {'label': 'All', 'status': null, 'icon': Icons.apps},
    {'label': 'Draft', 'status': 'draft', 'icon': Icons.edit_note},
    {'label': 'Published', 'status': 'published', 'icon': Icons.public},
    {'label': 'Ongoing', 'status': 'ongoing', 'icon': Icons.play_circle},
    {'label': 'Completed', 'status': 'completed', 'icon': Icons.check_circle},
    {'label': 'Cancelled', 'status': 'cancelled', 'icon': Icons.cancel},
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = _fetchEvents();
    });
  }

  Future<List<Event>> _fetchEvents() async {
    final eventManager = ref.read(eventManagerProvider);
    final result = await eventManager.getMyEvents();
    if (result.success && result.data != null) {
      return result.data!;
    } else {
      throw Exception(result.error ?? 'Failed to load events');
    }
  }

  Future<void> _showEventForm({Event? event}) async {
    final eventManager = ref.read(eventManagerProvider);
    await showDialog(
      context: context,
      builder: (context) => EventFormDialog(
        initialEvent: event,
        isEdit: event != null,
        onSubmit: (eventData) async {
          setState(() => _isLoading = true);
          try {
            // Prepare multipart data for backend
            final Map<String, dynamic> data = Map.of(eventData);
            File? imageFile = data.remove('imageFile');
            List<File> galleryFiles = List<File>.from(data.remove('galleryFiles') ?? []);
            
            if (event == null) {
              await eventManager.createEventMultipart(
                data, 
                imageFile: imageFile, 
                galleryFiles: galleryFiles
              );
            } else {
              await eventManager.updateEventMultipart(
                event.id, 
                data, 
                imageFile: imageFile, 
                galleryFiles: galleryFiles
              );
            }
            
            if (mounted) {
              Navigator.pop(context);
              _loadEvents();
              _showSuccessSnackBar(event == null ? 'Event created successfully!' : 'Event updated successfully!');
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context);
              _showErrorSnackBar('Failed to save event: $e');
            }
          } finally {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    final eventManager = ref.read(eventManagerProvider);
    final confirmed = await _showDeleteConfirmation(event);
    
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final result = await eventManager.deleteEvent(event.id);
        if (result.success) {
          _loadEvents();
          _showSuccessSnackBar('Event deleted successfully!');
        } else {
          throw Exception(result.error ?? 'Failed to delete event');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Failed to delete event: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(Event event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
                Icons.delete_forever,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Event',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to delete "${event.title}"?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. All associated bookings and data will be permanently removed.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
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
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Delete Event'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.error, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.background,
                colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Enhanced Header Section
                  _buildEnhancedHeader(theme, colorScheme),
                  
                  // Search and Filter Bar
                  _buildSearchAndFilterBar(theme, colorScheme),
                  
                  // Status Filter Chips
                  _buildStatusFilterChips(theme, colorScheme),
                  
                  // Events List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _loadEvents();
                      },
                      color: colorScheme.primary,
                      child: FutureBuilder<List<Event>>(
                        future: _eventsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildLoadingState(theme, colorScheme);
                          } else if (snapshot.hasError) {
                            return _buildErrorState(theme, colorScheme, snapshot.error.toString());
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildEmptyState(theme, colorScheme);
                          }
                          
                          final filteredEvents = _getFilteredEvents(snapshot.data!);
                          return _buildEventsList(theme, colorScheme, filteredEvents);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Enhanced Loading Overlay
        if (_isLoading) _buildLoadingOverlay(theme, colorScheme),
      ],
    );
  }

  Widget _buildEnhancedHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB), // primary-600
            Color(0xFF7C3AED), // violet-600
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Compact Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Title Only
            Expanded(
              child: Text(
                'Events',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Compact New Event Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showEventForm(),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'New',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search events by title, type, or venue...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChips(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = statusFilters[index];
          final isSelected = _selectedChipIndex == index;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FilterChip(
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedChipIndex = index;
                  _selectedStatus = filter['status'];
                });
              },
              avatar: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2)
                      : colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  filter['icon'],
                  size: 16,
                  color: isSelected ? Colors.white : colorScheme.primary,
                ),
              ),
              label: Text(
                filter['label'],
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              backgroundColor: isSelected ? null : colorScheme.surface,
              selectedColor: colorScheme.primary,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected 
                    ? colorScheme.primary 
                    : colorScheme.outline.withOpacity(0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your events...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme, String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.error.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.error.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load events',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _loadEvents,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.event_note,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No events found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Get started by creating your first event.\nThis will help you showcase your services to potential clients.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showEventForm(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Create Your First Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(ThemeData theme, ColorScheme colorScheme, List<Event> events) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEnhancedEventCard(theme, colorScheme, event, index);
      },
    );
  }

  Widget _buildEnhancedEventCard(ThemeData theme, ColorScheme colorScheme, Event event, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: Event Image/Icon
                Container(
                  width: 80,
                  height: 80,
                  color: colorScheme.primary.withOpacity(0.08),
                  alignment: Alignment.center,
                  child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            event.imageUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.event,
                              color: colorScheme.primary,
                              size: 40,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.event,
                          color: colorScheme.primary,
                          size: 40,
                        ),
                ),
                
                // Right: Event Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title and Status Row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildCompactStatusBadge(theme, colorScheme, event.status),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Event Details
                        _buildCompactEventDetails(theme, colorScheme, event),
                        
                        const SizedBox(height: 12),
                        
                        // Tags (if any)
                        if (event.tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            children: event.tags.take(2).map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tag,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        // Bottom Row: Price and Actions
                        Row(
                          children: [
                            if (event.ticketPrice != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatTicketPrice(event.ticketPrice),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Spacer(),
                            _buildCompactActions(theme, colorScheme, event),
                          ],
                        ),
                      ],
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

  Widget _buildEventCardHeader(ThemeData theme, ColorScheme colorScheme, Event event) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: event.imageUrl != null && event.imageUrl!.isNotEmpty
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF7C3AED),
                ],
              ),
      ),
      child: Stack(
        children: [
          // Background Image or Gradient
          if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                event.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
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
                ),
              ),
            ),
          
          // Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getEventTypeIcon(event.eventType),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.eventType.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (event.venue != null && event.venue!.isNotEmpty)
                        Text(
                          event.venue!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ),
                if (event.ticketPrice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _formatTicketPrice(event.ticketPrice),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusBadge(ThemeData theme, ColorScheme colorScheme, dynamic status) {
    Color statusColor;
    String statusText;
    
    // Handle different status types more safely
    String statusName = status.toString().toLowerCase();
    if (statusName.contains('draft')) {
      statusColor = Colors.orange;
      statusText = 'Draft';
    } else if (statusName.contains('published')) {
      statusColor = Colors.green;
      statusText = 'Live';
    } else if (statusName.contains('ongoing')) {
      statusColor = Colors.blue;
      statusText = 'Active';
    } else if (statusName.contains('completed')) {
      statusColor = Colors.purple;
      statusText = 'Done';
    } else if (statusName.contains('cancelled')) {
      statusColor = Colors.red;
      statusText = 'Cancelled';
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildCompactEventDetails(ThemeData theme, ColorScheme colorScheme, Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event Type and Venue
        Row(
          children: [
            Icon(
              Icons.category,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                (event.eventType.name ?? event.eventType.toString().split('.').last),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Date and Time
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                event.eventDate != null 
                    ? _formatDate(event.eventDate!)
                    : 'Date not set',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (event.eventTime != null && event.eventTime!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                event.eventTime!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        
        // Venue and Guests
        if (event.venue != null && event.venue!.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.venue!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (event.expectedGuests > 0) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.group,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text(
                  '${event.expectedGuests}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (event.availableTickets != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.confirmation_number,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Available Tickets: ${event.availableTickets}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem(ThemeData theme, ColorScheme colorScheme, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActions(ThemeData theme, ColorScheme colorScheme, Event event) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Bookings - More compact
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventBookingsPage(eventId: event.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_seat, color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      'View',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        
        // More Actions - Smaller
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEventForm(event: event);
                break;
              case 'delete':
                _deleteEvent(event);
                break;
              case 'publish':
                _publishEvent(event);
                break;
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.more_vert,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            if ((event.status.name ?? event.status.toString().split('.').last) == 'draft')
              PopupMenuItem(
                value: 'publish',
                child: Row(
                  children: [
                    Icon(Icons.publish, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Publish'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Processing...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we save your changes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods
  List<Event> _getFilteredEvents(List<Event> events) {
    List<Event> filtered = events;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        final query = _searchQuery.toLowerCase();
        return event.title.toLowerCase().contains(query) ||
               (event.eventType.name ?? event.eventType.toString().split('.').last).toLowerCase().contains(query) ||
               (event.venue?.toLowerCase().contains(query) ?? false) ||
               event.description.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((event) => 
          event.status.toString().toLowerCase().contains(_selectedStatus!.toLowerCase())).toList();
    }

    // Sort by creation date (most recent first)
    filtered.sort((a, b) => b.eventDate?.compareTo(a.eventDate ?? DateTime.now()) ?? 0);

    return filtered;
  }

  IconData _getEventTypeIcon(dynamic eventType) {
    String typeName = eventType.toString().toLowerCase();
    if (typeName.contains('wedding')) {
      return Icons.favorite;
    } else if (typeName.contains('conference')) {
      return Icons.business;
    } else if (typeName.contains('party')) {
      return Icons.celebration;
    } else if (typeName.contains('concert')) {
      return Icons.music_note;
    } else if (typeName.contains('workshop')) {
      return Icons.school;
    } else if (typeName.contains('exhibition')) {
      return Icons.museum;
    } else if (typeName.contains('sports')) {
      return Icons.sports;
    } else if (typeName.contains('festival')) {
      return Icons.festival;
    } else {
      return Icons.event;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTicketPrice(double? price) {
    if (price == null || price <= 0) return 'Free';
    if (price == price.roundToDouble()) {
      return 'Rs. ${price.toStringAsFixed(0)}';
    }
    return 'Rs. ${price.toStringAsFixed(2)}';
  }

  Future<void> _publishEvent(Event event) async {
    final eventManager = ref.read(eventManagerProvider);
    setState(() => _isLoading = true);
    try {
      final result = await eventManager.publishEvent(event.id);
      if (result.success) {
        _loadEvents();
        _showSuccessSnackBar('Event published successfully!');
      } else {
        throw Exception(result.error ?? 'Failed to publish event');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to publish event: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}