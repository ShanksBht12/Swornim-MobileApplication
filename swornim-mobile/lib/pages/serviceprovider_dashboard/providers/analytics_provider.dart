import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/providers/bookings/bookings_provider.dart';

class AnalyticsData {
  final double totalRevenue;
  final double monthlyRevenue;
  final double averageBookingValue;
  final int totalBookings;
  final int completedBookings;
  final double conversionRate;
  final Map<String, double> monthlyRevenueData;
  final Map<String, int> bookingTrends;
  final Map<String, double> serviceTypeRevenue;

  AnalyticsData({
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.averageBookingValue,
    required this.totalBookings,
    required this.completedBookings,
    required this.conversionRate,
    required this.monthlyRevenueData,
    required this.bookingTrends,
    required this.serviceTypeRevenue,
  });

  factory AnalyticsData.fromBookings(List<Booking> bookings) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Calculate total revenue
    final totalRevenue = bookings
        .where((booking) => booking.isPaid)
        .fold(0.0, (sum, booking) => sum + booking.totalAmount);

    // Calculate monthly revenue
    final monthlyRevenue = bookings
        .where((booking) => 
            booking.createdAt.month == currentMonth &&
            booking.createdAt.year == currentYear &&
            booking.isPaid)
        .fold(0.0, (sum, booking) => sum + booking.totalAmount);

    // Calculate average booking value
    final paidBookings = bookings.where((booking) => booking.isPaid).toList();
    final averageBookingValue = paidBookings.isNotEmpty 
        ? totalRevenue / paidBookings.length 
        : 0.0;

    // Calculate conversion rate
    final completedBookings = bookings.where((booking) => booking.isCompleted).length;
    final conversionRate = bookings.isNotEmpty 
        ? (completedBookings / bookings.length) * 100 
        : 0.0;

    // Generate monthly revenue data for last 6 months
    final monthlyRevenueData = <String, double>{};
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(currentYear, currentMonth - i, 1);
      final monthKey = '${date.month}/${date.year}';
      
      final monthRevenue = bookings
          .where((booking) => 
              booking.createdAt.month == date.month &&
              booking.createdAt.year == date.year &&
              booking.isPaid)
          .fold(0.0, (sum, booking) => sum + booking.totalAmount);
      
      monthlyRevenueData[monthKey] = monthRevenue;
    }

    // Generate booking trends
    final bookingTrends = <String, int>{};
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(currentYear, currentMonth - i, 1);
      final monthKey = '${date.month}/${date.year}';
      
      final monthBookings = bookings
          .where((booking) => 
              booking.createdAt.month == date.month &&
              booking.createdAt.year == date.year)
          .length;
      
      bookingTrends[monthKey] = monthBookings;
    }

    // Calculate revenue by service type
    final serviceTypeRevenue = <String, double>{};
    for (final serviceType in ServiceType.values) {
      final typeRevenue = bookings
          .where((booking) => 
              booking.serviceType == serviceType &&
              booking.isPaid)
          .fold(0.0, (sum, booking) => sum + booking.totalAmount);
      
      serviceTypeRevenue[serviceType.name] = typeRevenue;
    }

    return AnalyticsData(
      totalRevenue: totalRevenue,
      monthlyRevenue: monthlyRevenue,
      averageBookingValue: averageBookingValue,
      totalBookings: bookings.length,
      completedBookings: completedBookings,
      conversionRate: conversionRate,
      monthlyRevenueData: monthlyRevenueData,
      bookingTrends: bookingTrends,
      serviceTypeRevenue: serviceTypeRevenue,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsData> {
  final Ref ref;

  AnalyticsNotifier(this.ref) : super(AnalyticsData.fromBookings([])) {
    _loadAnalytics();
  }

  void _loadAnalytics() {
    final bookingsState = ref.read(bookingsProvider);
    state = AnalyticsData.fromBookings(bookingsState.bookings);
  }

  void refreshAnalytics() {
    _loadAnalytics();
  }

  double getRevenueGrowth() {
    // Calculate month-over-month growth
    final currentMonth = DateTime.now().month;
    final lastMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final currentYear = DateTime.now().year;
    final lastYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    final bookings = ref.read(bookingsProvider).bookings;
    
    final currentMonthRevenue = bookings
        .where((booking) => 
            booking.createdAt.month == currentMonth &&
            booking.createdAt.year == currentYear &&
            booking.isPaid)
        .fold(0.0, (sum, booking) => sum + booking.totalAmount);

    final lastMonthRevenue = bookings
        .where((booking) => 
            booking.createdAt.month == lastMonth &&
            booking.createdAt.year == lastYear &&
            booking.isPaid)
        .fold(0.0, (sum, booking) => sum + booking.totalAmount);

    if (lastMonthRevenue == 0) return 0.0;
    return ((currentMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;
  }

  Map<String, dynamic> getTopPerformingPackages() {
    final bookings = ref.read(bookingsProvider).bookings;
    final packageStats = <String, Map<String, dynamic>>{};

    for (final booking in bookings) {
      final packageName = booking.packageName;
      
      if (!packageStats.containsKey(packageName)) {
        packageStats[packageName] = {
          'bookings': 0,
          'revenue': 0.0,
          'completed': 0,
        };
      }

      packageStats[packageName]!['bookings'] = 
          (packageStats[packageName]!['bookings'] as int) + 1;
      packageStats[packageName]!['revenue'] = 
          (packageStats[packageName]!['revenue'] as double) + booking.totalAmount;
      
      if (booking.isCompleted) {
        packageStats[packageName]!['completed'] = 
            (packageStats[packageName]!['completed'] as int) + 1;
      }
    }

    // Calculate conversion rates and sort by revenue
    final sortedPackages = packageStats.entries.toList()
      ..sort((a, b) => b.value['revenue'].compareTo(a.value['revenue']));

    return Map.fromEntries(sortedPackages.take(5));
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsData>((ref) {
  return AnalyticsNotifier(ref);
});

// Additional providers for specific analytics data
final revenueGrowthProvider = Provider<double>((ref) {
  final analyticsNotifier = ref.read(analyticsProvider.notifier);
  return analyticsNotifier.getRevenueGrowth();
});

final topPackagesProvider = Provider<Map<String, dynamic>>((ref) {
  final analyticsNotifier = ref.read(analyticsProvider.notifier);
  return analyticsNotifier.getTopPerformingPackages();
}); 