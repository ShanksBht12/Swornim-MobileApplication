class PaymentTransaction {
  final String id;
  final String bookingId;
  final String? khaltiTransactionId;
  final String? khaltiPaymentUrl;
  final double amount;
  final String currency;
  final PaymentTransactionStatus status;
  final String paymentMethod;
  final Map<String, dynamic>? khaltiResponse;
  final String? failureReason;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentTransaction({
    required this.id,
    required this.bookingId,
    this.khaltiTransactionId,
    this.khaltiPaymentUrl,
    required this.amount,
    this.currency = 'NPR',
    required this.status,
    this.paymentMethod = 'khalti',
    this.khaltiResponse,
    this.failureReason,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? json['bookingId']?.toString() ?? '',
      khaltiTransactionId: json['khalti_transaction_id']?.toString() ?? json['khaltiTransactionId']?.toString(),
      khaltiPaymentUrl: json['khalti_payment_url']?.toString() ?? json['khaltiPaymentUrl']?.toString(),
      amount: _parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'NPR',
      status: _parseStatus(json['status']),
      paymentMethod: json['payment_method']?.toString() ?? json['paymentMethod']?.toString() ?? 'khalti',
      khaltiResponse: json['khalti_response'] ?? json['khaltiResponse'],
      failureReason: json['failure_reason']?.toString() ?? json['failureReason']?.toString(),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'khalti_transaction_id': khaltiTransactionId,
      'khalti_payment_url': khaltiPaymentUrl,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'payment_method': paymentMethod,
      'khalti_response': khaltiResponse,
      'failure_reason': failureReason,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.parse(value);
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static PaymentTransactionStatus _parseStatus(dynamic value) {
    if (value == null) return PaymentTransactionStatus.pending;
    try {
      return PaymentTransactionStatus.values.byName(value.toString().toLowerCase());
    } catch (e) {
      return PaymentTransactionStatus.pending;
    }
  }

  PaymentTransaction copyWith({
    String? id,
    String? bookingId,
    String? khaltiTransactionId,
    String? khaltiPaymentUrl,
    double? amount,
    String? currency,
    PaymentTransactionStatus? status,
    String? paymentMethod,
    Map<String, dynamic>? khaltiResponse,
    String? failureReason,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      khaltiTransactionId: khaltiTransactionId ?? this.khaltiTransactionId,
      khaltiPaymentUrl: khaltiPaymentUrl ?? this.khaltiPaymentUrl,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      khaltiResponse: khaltiResponse ?? this.khaltiResponse,
      failureReason: failureReason ?? this.failureReason,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PaymentTransaction{id: $id, bookingId: $bookingId, status: $status, amount: $amount}';
  }

  // Helper methods
  bool get isCompleted => status == PaymentTransactionStatus.completed;
  bool get isPending => status == PaymentTransactionStatus.pending;
  bool get isFailed => status == PaymentTransactionStatus.failed;
  bool get isCancelled => status == PaymentTransactionStatus.cancelled;
  
  String get formattedAmount => 'NPR ${amount.toStringAsFixed(2)}';
  String get statusText => status.name.toUpperCase();
}

enum PaymentTransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
} 