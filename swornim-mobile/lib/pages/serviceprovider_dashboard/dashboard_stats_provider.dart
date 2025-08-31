import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/providers/bookings/bookings_provider.dart';

class DashboardStats {
  final int totalBookings;
  final int pendingRequests;
  final double monthlyEarnings;
  final int upcomingEvents;
  final Map<BookingStatus, int> statusBreakdown;
  final Map<PaymentStatus, int> paymentBreakdown;

  DashboardStats({
    required this.totalBookings,
    required this.pendingRequests,
    required this.monthlyEarnings,
    required this.upcomingEvents,
    required this.statusBreakdown,
    required this.paymentBreakdown,
  });

  factory DashboardStats.fromBookings(List<Booking> bookings) {
    final now = DateTime.now();
    return DashboardStats(
      totalBookings: bookings.length,
      pendingRequests: bookings.where((b) => b.isPending).length,
      monthlyEarnings: bookings
          .where((b) => b.createdAt.month == now.month && b.isPaid)
          .fold(0.0, (sum, b) => sum + b.totalAmount),
      upcomingEvents: bookings.where((b) => b.isUpcoming).length,
      statusBreakdown: _groupByStatus(bookings),
      paymentBreakdown: _groupByPaymentStatus(bookings),
    );
  }
}

Map<BookingStatus, int> _groupByStatus(List<Booking> bookings) {
  final map = <BookingStatus, int>{};
  for (final b in bookings) {
    map[b.status] = (map[b.status] ?? 0) + 1;
  }
  return map;
}

Map<PaymentStatus, int> _groupByPaymentStatus(List<Booking> bookings) {
  final map = <PaymentStatus, int>{};
  for (final b in bookings) {
    map[b.paymentStatus] = (map[b.paymentStatus] ?? 0) + 1;
  }
  return map;
}

// The dashboardStatsProvider is now a simple Provider that derives its state
// from the bookingsProvider. It no longer needs to be a FutureProvider or a .family.
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  // Watch the state of the new bookings provider
  final bookingsState = ref.watch(bookingsProvider);
  
  // Create stats from the list of bookings held in the state.
  // If bookings are loading, this will correctly return stats for an empty list.
  return DashboardStats.fromBookings(bookingsState.bookings);
}); 