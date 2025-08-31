import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/providers/bookings/bookings_provider.dart';

class CalendarView extends ConsumerStatefulWidget {
  final User provider;
  
  const CalendarView({required this.provider, Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bookingsState = ref.watch(bookingsProvider);

    return Column(
      children: [
        // Calendar Header
        _buildCalendarHeader(theme, colorScheme),
        
        // Calendar Widget
        Expanded(
          child: bookingsState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : bookingsState.error != null
                  ? _buildErrorState(theme, colorScheme, bookingsState.error!)
                  : _buildCalendar(bookingsState.bookings, theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader(ThemeData theme, ColorScheme colorScheme) {
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
      child: Column(
        children: [
          // Calendar Controls
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  });
                },
                icon: const Icon(Icons.today),
                tooltip: 'Today',
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _getMonthYearString(_focusedDay),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Format Toggle
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  selected: _calendarFormat == CalendarFormat.month,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _calendarFormat = CalendarFormat.month;
                      });
                    }
                  },
                  label: const Text('Month'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  selected: _calendarFormat == CalendarFormat.week,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _calendarFormat = CalendarFormat.week;
                      });
                    }
                  },
                  label: const Text('Week'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  selected: _calendarFormat == CalendarFormat.agenda,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _calendarFormat = CalendarFormat.agenda;
                      });
                    }
                  },
                  label: const Text('Agenda'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<Booking> bookings, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildCustomCalendar(bookings, theme, colorScheme),
    );
  }

  Widget _buildCustomCalendar(List<Booking> bookings, ThemeData theme, ColorScheme colorScheme) {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    
    // Calculate calendar grid
    final totalDays = daysInMonth + firstWeekday - 1;
    final weeks = (totalDays / 7).ceil();

    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        // Calendar grid
        Expanded(
          child: ListView.builder(
            itemCount: weeks,
            itemBuilder: (context, weekIndex) {
              return Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 2;
                  final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
                  final currentDate = isCurrentMonth 
                      ? DateTime(_focusedDay.year, _focusedDay.month, dayNumber)
                      : null;
                  
                  final dayBookings = currentDate != null 
                      ? _getBookingsForDate(bookings, currentDate)
                      : <Booking>[];

                  return Expanded(
                    child: _buildCalendarDay(
                      currentDate,
                      dayBookings,
                      isCurrentMonth,
                      theme,
                      colorScheme,
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarDay(
    DateTime? date,
    List<Booking> bookings,
    bool isCurrentMonth,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isToday = date?.isAtSameMomentAs(DateTime.now()) ?? false;
    final isSelected = date?.isAtSameMomentAs(_selectedDay ?? DateTime(1900)) ?? false;

    return GestureDetector(
      onTap: () {
        if (date != null && isCurrentMonth) {
          setState(() {
            _selectedDay = date;
          });
          _showDayDetails(date, bookings);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.1)
              : isToday
                  ? colorScheme.primary.withOpacity(0.05)
                  : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Day number
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                date?.day.toString() ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCurrentMonth 
                      ? (isToday ? colorScheme.primary : colorScheme.onSurface)
                      : colorScheme.onSurfaceVariant.withOpacity(0.3),
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            
            // Booking indicators
            if (bookings.isNotEmpty) ...[
              Expanded(
                child: Column(
                  children: bookings.take(3).map((booking) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                      height: 4,
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (bookings.length > 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '+${bookings.length - 3}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 8,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading calendar',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(bookingsProvider.notifier).fetchBookings();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<Booking> _getBookingsForDate(List<Booking> bookings, DateTime date) {
    return bookings.where((booking) {
      return booking.eventDate.year == date.year &&
             booking.eventDate.month == date.month &&
             booking.eventDate.day == date.day;
    }).toList();
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending_provider_confirmation:
      case BookingStatus.pending_modification:
      case BookingStatus.modification_requested:
        return Colors.orange;
      case BookingStatus.confirmed_awaiting_payment:
      case BookingStatus.confirmed_paid:
        return Colors.blue;
      case BookingStatus.in_progress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled_by_client:
      case BookingStatus.cancelled_by_provider:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.dispute_raised:
        return Colors.orange;
      case BookingStatus.dispute_resolved:
      case BookingStatus.refunded:
        return Colors.grey;
    }
  }

  void _showDayDetails(DateTime date, List<Booking> bookings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildDayDetailsSheet(date, bookings),
    );
  }

  Widget _buildDayDetailsSheet(DateTime date, List<Booking> bookings) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                '${date.day} ${_getMonthYearString(date)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Bookings for the day
          if (bookings.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No bookings for this day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            ...bookings.map((booking) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildDayBookingCard(booking, theme, colorScheme),
            )),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDayBookingCard(Booking booking, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(booking.status).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status),
              borderRadius: BorderRadius.circular(2),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${booking.eventTime} • ${booking.eventLocation}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                booking.formattedAmount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking.status.name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(booking.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum CalendarFormat { month, week, agenda } 