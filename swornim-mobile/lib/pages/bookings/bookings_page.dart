import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookings/bookings_provider.dart';
import '../models/bookings/booking.dart';
import '../serviceprovider_dashboard/widgets/booking_detail_page.dart';
import '../models/user/user.dart';
import '../models/user/user_types.dart';
import 'package:swornim/main.dart';

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> 
    with SingleTickerProviderStateMixin {
  String selectedFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> filterOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Paid',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsProvider.notifier).fetchBookings();
      _animationController.forward();
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
    final bookingsState = ref.watch(bookingsProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: GradientButton(
              onPressed: () {
                ref.read(bookingsProvider.notifier).fetchBookings();
              },
              text: '⟳', // Unicode for refresh, or use a short label
              gradient: GradientTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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
                        Icons.tune_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Filter by Status',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.map((filter) {
                      final isSelected = selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(filter, isSelected, theme, colorScheme, isDark),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Bookings List
          Expanded(
            child: bookingsState.isLoading
                ? _buildLoadingState(theme, colorScheme, isDark)
                : bookingsState.bookings.isEmpty
                    ? _buildEmptyState(theme, colorScheme, isDark)
                    : _buildBookingsList(bookingsState.bookings, theme, colorScheme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, bool isSelected, ThemeData theme, 
      ColorScheme colorScheme, bool isDark) {
    if (isSelected) {
      return GradientButton(
        onPressed: () {
          setState(() {
            selectedFilter = filter;
          });
        },
        text: filter,
        gradient: GradientTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      );
    } else {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedFilter = filter;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Text(
              filter,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading bookings...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.event_note_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              selectedFilter == 'All' ? 'No bookings yet' : 'No $selectedFilter bookings',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedFilter == 'All' 
                  ? 'Your bookings will appear here'
                  : 'Try a different filter to see more bookings',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, ThemeData theme, 
      ColorScheme colorScheme, bool isDark) {
    List<Booking> filteredBookings = bookings;
    if (selectedFilter != 'All') {
      if (selectedFilter == 'Completed') {
        filteredBookings = bookings.where((booking) => booking.status == BookingStatus.completed).toList();
      } else if (selectedFilter == 'Cancelled') {
        filteredBookings = bookings.where((booking) => booking.status == BookingStatus.cancelled_by_client || booking.status == BookingStatus.cancelled_by_provider).toList();
      } else {
        filteredBookings = bookings.where((booking) {
          final statusString = _getStatusDisplayName(booking.status);
          return statusString.toLowerCase() == selectedFilter.toLowerCase();
        }).toList();
      }
    }

    if (filteredBookings.isEmpty) {
      return _buildEmptyState(theme, colorScheme, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildBookingCard(booking, theme, colorScheme, isDark),
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking, ThemeData theme, 
      ColorScheme colorScheme, bool isDark) {
    final statusData = _getStatusData(booking.status);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailPage(
                  booking: booking,
                  provider: User(
                    id: 'current-user',
                    name: 'Current User',
                    email: 'user@example.com',
                    userType: UserType.client,
                    phone: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getServiceIcon(booking.packageName),
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.eventType,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.serviceProvider?['name'] ?? 'Unknown Provider',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusData['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusData['name'].toUpperCase(),
                        style: TextStyle(
                          color: statusData['color'],
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Details Section
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Event Date',
                        value: booking.formattedEventDate,
                        theme: theme,
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.attach_money_rounded,
                        label: 'Amount',
                        value: booking.formattedAmount,
                        theme: theme,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        isAmount: true,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Bottom Section
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF2A2A2A) 
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark 
                                ? const Color(0xFF3A3A3A) 
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'ID: ${booking.id}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      child: GradientButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingDetailPage(
                                booking: booking,
                                provider: User(
                                  id: 'current-user',
                                  name: 'Current User',
                                  email: 'user@example.com',
                                  userType: UserType.client,
                                  phone: '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                              ),
                            ),
                          );
                        },
                        text: 'View  ›',
                        gradient: GradientTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    bool isAmount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF2A2A2A) 
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF3A3A3A) 
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isAmount ? Colors.green.shade600 : colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isAmount ? Colors.green.shade700 : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String packageName) {
    final name = packageName.toLowerCase();
    if (name.contains('wedding')) return Icons.favorite_rounded;
    if (name.contains('birthday')) return Icons.cake_rounded;
    if (name.contains('corporate')) return Icons.business_rounded;
    if (name.contains('party')) return Icons.celebration_rounded;
    if (name.contains('photo')) return Icons.camera_alt_rounded;
    if (name.contains('catering')) return Icons.restaurant_rounded;
    if (name.contains('music')) return Icons.music_note_rounded;
    if (name.contains('decoration')) return Icons.auto_awesome_rounded;
    return Icons.event_rounded;
  }

  Map<String, dynamic> _getStatusData(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
      case BookingStatus.pending_modification:
        return {
          'name': 'Pending',
          'color': Colors.orange.shade600,
          'icon': Icons.schedule_rounded,
        };
      case BookingStatus.confirmed_awaiting_payment:
        return {
          'name': 'Confirmed',
          'color': Colors.blue.shade600,
          'icon': Icons.payment_rounded,
        };
      case BookingStatus.confirmed_paid:
        return {
          'name': 'Paid',
          'color': Colors.green.shade600,
          'icon': Icons.check_circle_rounded,
        };
      case BookingStatus.in_progress:
        return {
          'name': 'In Progress',
          'color': Colors.purple.shade600,
          'icon': Icons.work_rounded,
        };
      case BookingStatus.completed:
        return {
          'name': 'Completed',
          'color': Colors.green.shade700,
          'icon': Icons.done_all_rounded,
        };
      case BookingStatus.cancelled_by_client:
      case BookingStatus.cancelled_by_provider:
        return {
          'name': 'Cancelled',
          'color': Colors.red.shade600,
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'name': 'Unknown',
          'color': Colors.grey.shade600,
          'icon': Icons.help_outline_rounded,
        };
    }
  }

  String _getStatusDisplayName(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
      case BookingStatus.pending_modification:
        return 'Pending';
      case BookingStatus.confirmed_awaiting_payment:
        return 'Confirmed';
      case BookingStatus.confirmed_paid:
        return 'Paid';
      case BookingStatus.in_progress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled_by_client:
      case BookingStatus.cancelled_by_provider:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}