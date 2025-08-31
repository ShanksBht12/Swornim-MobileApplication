class Earnings {
  final String id;
  final String serviceProviderId;
  final double totalEarnings;
  final double monthlyEarnings;
  final double weeklyEarnings;
  final int totalBookings;
  final int completedBookings;
  final int pendingBookings;
  final List<EarningTransaction> transactions;
  final DateTime lastUpdated;

  Earnings({
    required this.id,
    required this.serviceProviderId,
    required this.totalEarnings,
    required this.monthlyEarnings,
    required this.weeklyEarnings,
    required this.totalBookings,
    required this.completedBookings,
    required this.pendingBookings,
    this.transactions = const [],
    required this.lastUpdated,
  });

  factory Earnings.fromJson(Map<String, dynamic> json) {
    return Earnings(
      id: json['id'],
      serviceProviderId: json['service_provider_id'],
      totalEarnings: json['total_earnings'].toDouble(),
      monthlyEarnings: json['monthly_earnings'].toDouble(),
      weeklyEarnings: json['weekly_earnings'].toDouble(),
      totalBookings: json['total_bookings'],
      completedBookings: json['completed_bookings'],
      pendingBookings: json['pending_bookings'],
      transactions: (json['transactions'] as List?)
          ?.map((t) => EarningTransaction.fromJson(t))
          .toList() ?? [],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class EarningTransaction {
  final String id;
  final String bookingId;
  final double amount;
  final DateTime date;
  final String description;

  EarningTransaction({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.date,
    required this.description,
  });

  factory EarningTransaction.fromJson(Map<String, dynamic> json) {
    return EarningTransaction(
      id: json['id'],
      bookingId: json['booking_id'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
    );
  }
}