import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/providers/bookings/bookings_provider.dart';
import 'package:swornim/pages/serviceprovider_dashboard/dashboard_stats_provider.dart';

class InteractiveRevenueBarChart extends StatefulWidget {
  final List<double> revenueData;
  final List<String> monthLabels;
  final ThemeData theme;
  final ColorScheme colorScheme;
  const InteractiveRevenueBarChart({
    required this.revenueData,
    required this.monthLabels,
    required this.theme,
    required this.colorScheme,
    Key? key,
  }) : super(key: key);

  @override
  State<InteractiveRevenueBarChart> createState() => _InteractiveRevenueBarChartState();
}

class _InteractiveRevenueBarChartState extends State<InteractiveRevenueBarChart> {
  int? hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final maxRevenue = widget.revenueData.isNotEmpty
        ? widget.revenueData.reduce((a, b) => a > b ? a : b)
        : 0.0;
    const double chartHeight = 120.0;

    return Column(
      children: [
        Container(
          height: 40,
          width: double.infinity,
          alignment: Alignment.center,
          child: hoveredIndex != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.colorScheme.inverseSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.monthLabels[hoveredIndex!]}: Rs. ${widget.revenueData[hoveredIndex!].toStringAsFixed(0)}',
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      color: widget.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: widget.revenueData.asMap().entries.map((entry) {
              final index = entry.key;
              final revenue = entry.value;
              double barHeight = (maxRevenue > 0)
                  ? (revenue / maxRevenue) * chartHeight
                  : 20.0;
              if (revenue == 0) barHeight = 6.0;
              final isHovered = hoveredIndex == index;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          hoveredIndex = hoveredIndex == index ? null : index;
                        });
                      },
                      child: MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            hoveredIndex = index;
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            hoveredIndex = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isHovered
                                  ? [
                                      widget.colorScheme.primary.withOpacity(0.9),
                                      widget.colorScheme.primary.withOpacity(0.6),
                                    ]
                                  : [
                                      widget.colorScheme.primary.withOpacity(0.8),
                                      widget.colorScheme.primary.withOpacity(0.5),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isHovered
                                ? [
                                    BoxShadow(
                                      color: widget.colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: isHovered
                                  ? Border.all(
                                      color: widget.colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.monthLabels[index],
                      style: widget.theme.textTheme.labelSmall?.copyWith(
                            color: isHovered
                                ? widget.colorScheme.primary
                                : widget.colorScheme.onSurfaceVariant,
                            fontWeight: isHovered ? FontWeight.w600 : FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class RevenueAnalytics extends ConsumerWidget {
  final User provider;
  
  const RevenueAnalytics({required this.provider, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bookingsState = ref.watch(bookingsProvider);
    final dashboardStats = ref.watch(dashboardStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Overview Cards
          _buildRevenueOverview(theme, colorScheme, dashboardStats, bookingsState.bookings),
          const SizedBox(height: 24),

          // Revenue Chart
          _buildRevenueChart(theme, colorScheme, bookingsState.bookings),
          const SizedBox(height: 24),

          // Payment Status Breakdown with Visual Progress
          _buildEnhancedPaymentBreakdown(theme, colorScheme, dashboardStats),
          const SizedBox(height: 24),

          // Booking Status Overview
          _buildBookingStatusOverview(theme, colorScheme, bookingsState.bookings),
          const SizedBox(height: 24),

          // Time-based Analytics
          _buildTimeBasedAnalytics(theme, colorScheme, bookingsState.bookings),
          const SizedBox(height: 24),

          // Analytics Insights
          _buildEnhancedInsights(theme, colorScheme, bookingsState.bookings),
          const SizedBox(height: 24),

          // Top Performing Packages
          _buildTopPackages(theme, colorScheme, bookingsState.bookings),
          const SizedBox(height: 24),

          // Revenue vs Booking Correlation
          _buildRevenueBookingCorrelation(theme, colorScheme, bookingsState.bookings),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview(ThemeData theme, ColorScheme colorScheme, DashboardStats stats, List<Booking> bookings) {
    final totalBookings = stats.totalBookings;
    final paidBookings = stats.paymentBreakdown[PaymentStatus.paid] ?? 0;
    final pendingBookings = stats.paymentBreakdown[PaymentStatus.pending] ?? 0;
    final partiallyPaidBookings = stats.paymentBreakdown[PaymentStatus.partiallyPaid] ?? 0;
    
    // Calculate additional metrics from existing data
    final monthlyRevenue = stats.monthlyEarnings;
    final avgBookingValue = paidBookings > 0 ? monthlyRevenue / paidBookings : 0.0;
    final paymentSuccessRate = totalBookings > 0 ? (paidBookings / totalBookings * 100) : 0.0;
    final potentialRevenue = _calculatePotentialRevenue(bookings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Overview',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // First row - Main revenue metrics
        Row(
          children: [
            Expanded(
              child: _buildRevenueCard(
                theme,
                colorScheme,
                'Monthly Revenue',
                'Rs. ${monthlyRevenue.toStringAsFixed(0)}',
                Icons.trending_up,
                Colors.green,
                '+${paymentSuccessRate.toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRevenueCard(
                theme,
                colorScheme,
                'Potential Revenue',
                'Rs. ${potentialRevenue.toStringAsFixed(0)}',
                Icons.monetization_on,
                Colors.orange,
                '+${(potentialRevenue - monthlyRevenue).toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row - Booking metrics
        Row(
          children: [
            Expanded(
              child: _buildRevenueCard(
                theme,
                colorScheme,
                'Total Bookings',
                '$totalBookings',
                Icons.calendar_today,
                colorScheme.primary,
                '',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRevenueCard(
                theme,
                colorScheme,
                'Avg. Booking Value',
                'Rs. ${avgBookingValue.toStringAsFixed(0)}',
                Icons.attach_money,
                colorScheme.secondary,
                '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Third row - Payment metrics
        Row(
          children: [
            Expanded(
              child: _buildRevenueCard(
                theme,
                colorScheme,
                'Paid Bookings',
                '$paidBookings',
                Icons.check_circle,
                Colors.green,
                '${paymentSuccessRate.toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRevenueCard(
                theme,
                colorScheme,
                'Pending Payments',
                '${pendingBookings + partiallyPaidBookings}',
                Icons.pending,
                Colors.amber,
                '',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueCard(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    final isPositive = change.startsWith('+');
    final hasChange = change.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (hasChange)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(ThemeData theme, ColorScheme colorScheme, List<Booking> bookings) {
    // Calculate last 6 months' revenue
    final months = List.generate(6, (index) {
      final date = DateTime.now().subtract(Duration(days: 30 * (5 - index)));
      return date;
    });
    final revenueData = months.map((month) {
      final monthBookings = bookings.where((booking) {
        return booking.createdAt.year == month.year &&
               booking.createdAt.month == month.month &&
               booking.paymentStatus == PaymentStatus.paid;
      }).toList();
      return monthBookings.fold(0.0, (sum, booking) => sum + booking.totalAmount);
    }).toList();
    final totalRevenue = revenueData.fold(0.0, (sum, r) => sum + r);
    final monthLabels = months.map((m) => _getMonthAbbreviation(m.month)).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trend (Last 6 Months)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            'Total: Rs. ${totalRevenue.toStringAsFixed(0)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap/Hover for details',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: InteractiveRevenueBarChart(
              revenueData: revenueData,
              monthLabels: monthLabels,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPaymentBreakdown(ThemeData theme, ColorScheme colorScheme, DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Status Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...stats.paymentBreakdown.entries.map((entry) {
            final status = entry.key;
            final count = entry.value;
            final percentage = stats.totalBookings > 0 
                ? (count / stats.totalBookings * 100)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          status.name.toUpperCase(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '$count (${percentage.toStringAsFixed(1)}%)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: colorScheme.outline.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getPaymentStatusColor(status),
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

  Widget _buildBookingStatusOverview(ThemeData theme, ColorScheme colorScheme, List<Booking> bookings) {
    final statusBreakdown = <String, int>{};
    for (final booking in bookings) {
      final status = booking.status.name;
      statusBreakdown[status] = (statusBreakdown[status] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Status Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: statusBreakdown.entries.map((entry) {
              final status = entry.key;
              final count = entry.value;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getBookingStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getBookingStatusColor(status).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getBookingStatusIcon(status),
                      size: 16,
                      color: _getBookingStatusColor(status),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$status ($count)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getBookingStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBasedAnalytics(ThemeData theme, ColorScheme colorScheme, List<Booking> bookings) {
    final timeStats = _calculateTimeBasedStats(bookings);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time-based Analytics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeStatCard(
                  theme,
                  colorScheme,
                  'This Month',
                  '${timeStats['thisMonth']}',
                  Icons.calendar_month,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeStatCard(
                  theme,
                  colorScheme,
                  'This Week',
                  '${timeStats['thisWeek']}',
                  Icons.calendar_view_week,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeStatCard(
                  theme,
                  colorScheme,
                  'Today',
                  '${timeStats['today']}',
                  Icons.today,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStatCard(ThemeData theme, ColorScheme colorScheme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInsights(ThemeData theme, ColorScheme colorScheme, List<Booking> bookings) {
    final insights = _calculateEnhancedInsights(bookings);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics Insights',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (insight['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    insight['icon'] as IconData,
                    color: insight['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        insight['description'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  insight['value'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: insight['color'] as Color,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTopPackages(ThemeData theme, ColorScheme colorScheme, List<Booking> bookings) {
    final paidBookings = bookings.where((b) => b.paymentStatus == PaymentStatus.paid).toList();
    final completedBookings = bookings.where((b) => b.status == BookingStatus.completed && b.paymentStatus == PaymentStatus.paid).toList();
    final packageStats = <String, Map<String, dynamic>>{};
    
    for (final booking in paidBookings) {
      final packageName =
          booking.packageSnapshot?.name ??
          (booking.package != null ? booking.package!['name']?.toString() : null) ??
          'Unknown Package';
      if (packageName == 'Unknown Package') continue;
      
      if (!packageStats.containsKey(packageName)) {
        packageStats[packageName] = {
          'bookings': 0,
          'revenue': 0.0,
          'completed': 0,
          'conversion': 0.0,
        };
      }
      packageStats[packageName]!['bookings'] =
          (packageStats[packageName]!['bookings'] as int) + 1;
      packageStats[packageName]!['revenue'] =
          (packageStats[packageName]!['revenue'] as double) + booking.totalAmount;
    }
    
    for (final booking in completedBookings) {
      final packageName =
          booking.packageSnapshot?.name ??
          (booking.package != null ? booking.package!['name']?.toString() : null) ??
          'Unknown Package';
      if (packageStats.containsKey(packageName)) {
        packageStats[packageName]!['completed'] =
            (packageStats[packageName]!['completed'] as int) + 1;
      }
    }
    
    for (final entry in packageStats.entries) {
      final bookingsCount = entry.value['bookings'] as int;
      final completed = entry.value['completed'] as int;
      entry.value['conversion'] = bookingsCount > 0 ? (completed / bookingsCount * 100).round() : 0;
    }
    
    final topPackages = packageStats.entries
        .toList()
        ..sort((a, b) => b.value['revenue'].compareTo(a.value['revenue']));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Performing Packages',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${topPackages.length} packages',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topPackages.take(5).map((entry) {
            final packageName = entry.key;
            final stats = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.star,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          packageName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${stats['bookings']} bookings • ${stats['completed']} completed',
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
                        'Rs. ${stats['revenue'].toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${stats['conversion']}% completion',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: stats['conversion'] >= 80 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRevenueBookingCorrelation(ThemeData theme, ColorScheme colorScheme, List<Booking> bookings) {
    final correlationData = _calculateRevenueBookingCorrelation(bookings);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue vs Booking Analysis',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCorrelationCard(
                  theme,
                  colorScheme,
                  'High Value Bookings',
                  '${correlationData['highValue']}',
                  'Above Rs. ${correlationData['avgValue'].toStringAsFixed(0)}',
                  Icons.arrow_upward,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCorrelationCard(
                  theme,
                  colorScheme,
                  'Revenue Efficiency',
                  '${correlationData['efficiency'].toStringAsFixed(1)}%',
                  'Paid vs Total Bookings',
                  Icons.speed,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationCard(ThemeData theme, ColorScheme colorScheme, String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for calculations
  double _calculatePotentialRevenue(List<Booking> bookings) {
    return bookings
        .where((b) => b.paymentStatus == PaymentStatus.pending || 
                     b.paymentStatus == PaymentStatus.partiallyPaid)
        .fold(0.0, (sum, booking) => sum + booking.totalAmount);
  }

  double _calculateTotalRevenue(List<Booking> bookings) {
    return bookings
        .where((b) => b.paymentStatus == PaymentStatus.paid)
        .fold(0.0, (sum, booking) => sum + booking.totalAmount);
  }

  Map<String, int> _calculateTimeBasedStats(List<Booking> bookings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = today.subtract(Duration(days: now.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    return {
      'today': bookings.where((b) {
        final bookingDate = DateTime(b.createdAt.year, b.createdAt.month, b.createdAt.day);
        return bookingDate.isAtSameMomentAs(today);
      }).length,
      'thisWeek': bookings.where((b) => b.createdAt.isAfter(thisWeekStart)).length,
      'thisMonth': bookings.where((b) => b.createdAt.isAfter(thisMonthStart)).length,
    };
  }

  List<Map<String, dynamic>> _calculateEnhancedInsights(List<Booking> bookings) {
    final paidBookings = bookings.where((b) => b.paymentStatus == PaymentStatus.paid).toList();
    final totalBookings = bookings.length;
    final completedBookings = bookings.where((b) => b.isCompleted).length;
    final pendingPayments = bookings.where((b) => b.paymentStatus == PaymentStatus.pending).length;
    
    final conversionRate = totalBookings > 0 ? (completedBookings / totalBookings * 100) : 0.0;
    final paymentSuccessRate = totalBookings > 0 ? (paidBookings.length / totalBookings * 100) : 0.0;
    final avgBookingValue = paidBookings.isNotEmpty
        ? paidBookings.fold(0.0, (sum, b) => sum + b.totalAmount) / paidBookings.length
        : 0.0;

    return [
      {
        'title': 'Conversion Rate',
        'description': 'Bookings completed vs total',
        'value': '${conversionRate.toStringAsFixed(1)}%',
        'icon': Icons.trending_up,
        'color': conversionRate >= 70 ? Colors.green : conversionRate >= 50 ? Colors.orange : Colors.red,
      },
      {
        'title': 'Payment Success Rate',
        'description': 'Paid bookings vs total',
        'value': '${paymentSuccessRate.toStringAsFixed(1)}%',
        'icon': Icons.payment,
        'color': paymentSuccessRate >= 80 ? Colors.green : paymentSuccessRate >= 60 ? Colors.orange : Colors.red,
      },
      {
        'title': 'Average Booking Value',
        'description': 'Revenue per paid booking',
        'value': 'Rs. ${avgBookingValue.toStringAsFixed(0)}',
        'icon': Icons.attach_money,
        'color': Colors.blue,
      },
      {
        'title': 'Pending Payments',
        'description': 'Bookings awaiting payment',
        'value': '$pendingPayments',
        'icon': Icons.pending_actions,
        'color': pendingPayments > 0 ? Colors.amber : Colors.green,
      },
    ];
  }

  Map<String, dynamic> _calculateRevenueBookingCorrelation(List<Booking> bookings) {
    final paidBookings = bookings.where((b) => b.paymentStatus == PaymentStatus.paid).toList();
    final avgValue = paidBookings.isNotEmpty 
        ? paidBookings.fold(0.0, (sum, b) => sum + b.totalAmount) / paidBookings.length 
        : 0.0;
    
    final highValueBookings = paidBookings.where((b) => b.totalAmount > avgValue).length;
    final efficiency = bookings.isNotEmpty ? (paidBookings.length / bookings.length * 100) : 0.0;

    return {
      'highValue': highValueBookings,
      'avgValue': avgValue,
      'efficiency': efficiency,
    };
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.partiallyPaid:
        return Colors.blue;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.grey;
    }
  }

  Color _getBookingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'confirmed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'inprogress':
      case 'in_progress':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getBookingStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'confirmed':
        return Icons.verified;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      case 'inprogress':
      case 'in_progress':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }
}