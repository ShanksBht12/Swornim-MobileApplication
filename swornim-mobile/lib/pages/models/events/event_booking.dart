// File: lib/pages/models/events/event_booking.dart

enum EventBookingStatus {
  pending,
  confirmed,
  cancelled,
  attended,
  no_show,
  refunded,
}

enum EventTicketType {
  regular,
  vip,
  student,
  early_bird,
  group,
  complimentary,
}

class EventBooking {
  final String id;
  final String eventId;
  final String clientId; // User who booked the event
  final String organizerId; // Event organizer ID
  final EventBookingStatus status;
  final EventTicketType ticketType;
  final int numberOfTickets;
  final double pricePerTicket;
  final double totalAmount;
  final double? discountAmount;
  final String? discountCode;
  final DateTime bookingDate;
  final DateTime? cancellationDate;
  final String? cancellationReason;
  final String? specialRequests;
  final Map<String, dynamic> ticketHolderDetails; // Name, phone, etc. for each ticket
  final String? paymentId;
  final String paymentMethod; // 'esewa', 'khalti', 'bank_transfer', 'cash'
  final String paymentStatus; // 'pending', 'completed', 'failed', 'refunded'
  final DateTime? paymentDate;
  final String? qrCode; // For event entry
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventBooking({
    required this.id,
    required this.eventId,
    required this.clientId,
    required this.organizerId,
    this.status = EventBookingStatus.pending,
    this.ticketType = EventTicketType.regular,
    required this.numberOfTickets,
    required this.pricePerTicket,
    required this.totalAmount,
    this.discountAmount,
    this.discountCode,
    required this.bookingDate,
    this.cancellationDate,
    this.cancellationReason,
    this.specialRequests,
    this.ticketHolderDetails = const {},
    this.paymentId,
    this.paymentMethod = 'pending',
    this.paymentStatus = 'pending',
    this.paymentDate,
    this.qrCode,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventBooking.fromJson(Map<String, dynamic> json) {
    try {
      print('[EventBooking.fromJson] Incoming JSON: ' + json.toString());
      final id = json['id']?.toString() ?? json['bookingId']?.toString() ?? '';
      print('[EventBooking.fromJson] Parsed id: ' + id);
      return EventBooking(
        id: id,
        eventId: json['event_id']?.toString() ?? json['eventId']?.toString() ?? '',
        clientId: json['client_id']?.toString() ?? json['clientId']?.toString() ?? '',
        organizerId: json['organizer_id']?.toString() ?? json['organizerId']?.toString() ?? '',
        status: _parseBookingStatus(json['status']),
        ticketType: _parseTicketType(json['ticket_type'] ?? json['ticketType']),
        numberOfTickets: _parseInt(json['number_of_tickets'] ?? json['numberOfTickets']),
        pricePerTicket: _parseDouble(json['price_per_ticket'] ?? json['pricePerTicket']) ?? 0.0,
        totalAmount: _parseDouble(json['total_amount'] ?? json['totalAmount']) ?? 0.0,
        discountAmount: _parseDouble(json['discount_amount'] ?? json['discountAmount']),
        discountCode: json['discount_code']?.toString() ?? json['discountCode']?.toString() ?? '',
        bookingDate: _parseDateTime(json['booking_date'] ?? json['bookingDate']) ?? DateTime.now(),
        cancellationDate: _parseDateTime(json['cancellation_date'] ?? json['cancellationDate']),
        cancellationReason: json['cancellation_reason']?.toString() ?? json['cancellationReason']?.toString() ?? '',
        specialRequests: json['special_requests']?.toString() ?? json['specialRequests']?.toString() ?? '',
        ticketHolderDetails: Map<String, dynamic>.from(json['ticket_holder_details'] ?? json['ticketHolderDetails'] ?? {}),
        paymentId: json['payment_id']?.toString() ?? json['paymentId']?.toString() ?? '',
        paymentMethod: json['payment_method']?.toString() ?? json['paymentMethod']?.toString() ?? '',
        paymentStatus: json['payment_status']?.toString() ?? json['paymentStatus']?.toString() ?? 'pending',
        paymentDate: _parseDateTime(json['payment_date'] ?? json['paymentDate']),
        qrCode: json['qr_code']?.toString() ?? json['qrCode']?.toString() ?? '',
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']) ?? DateTime.now(),
      );
    } catch (e, stack) {
      print('Error parsing EventBooking JSON: $e');
      print('Stack trace: $stack');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return value is DateTime ? value : DateTime.parse(value.toString());
    } catch (e) {
      print('Error parsing date: $value');
      return null;
    }
  }

  static EventBookingStatus _parseBookingStatus(dynamic status) {
    if (status == null) return EventBookingStatus.pending;
    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'confirmed':
        return EventBookingStatus.confirmed;
      case 'cancelled':
        return EventBookingStatus.cancelled;
      case 'attended':
        return EventBookingStatus.attended;
      case 'no_show':
        return EventBookingStatus.no_show;
      case 'refunded':
        return EventBookingStatus.refunded;
      default:
        return EventBookingStatus.pending;
    }
  }

  static EventTicketType _parseTicketType(dynamic type) {
    if (type == null) return EventTicketType.regular;
    final typeStr = type.toString().toLowerCase();
    switch (typeStr) {
      case 'vip':
        return EventTicketType.vip;
      case 'student':
        return EventTicketType.student;
      case 'early_bird':
        return EventTicketType.early_bird;
      case 'group':
        return EventTicketType.group;
      case 'complimentary':
        return EventTicketType.complimentary;
      default:
        return EventTicketType.regular;
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'client_id': clientId,
      'organizer_id': organizerId,
      'status': status.name,
      'ticket_type': ticketType.name,
      'number_of_tickets': numberOfTickets,
      'price_per_ticket': pricePerTicket,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'discount_code': discountCode,
      'booking_date': bookingDate.toIso8601String(),
      'cancellation_date': cancellationDate?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'special_requests': specialRequests,
      'ticket_holder_details': ticketHolderDetails,
      'payment_id': paymentId,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_date': paymentDate?.toIso8601String(),
      'qr_code': qrCode,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EventBooking copyWith({
    String? id,
    String? eventId,
    String? clientId,
    String? organizerId,
    EventBookingStatus? status,
    EventTicketType? ticketType,
    int? numberOfTickets,
    double? pricePerTicket,
    double? totalAmount,
    double? discountAmount,
    String? discountCode,
    DateTime? bookingDate,
    DateTime? cancellationDate,
    String? cancellationReason,
    String? specialRequests,
    Map<String, dynamic>? ticketHolderDetails,
    String? paymentId,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? paymentDate,
    String? qrCode,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventBooking(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      clientId: clientId ?? this.clientId,
      organizerId: organizerId ?? this.organizerId,
      status: status ?? this.status,
      ticketType: ticketType ?? this.ticketType,
      numberOfTickets: numberOfTickets ?? this.numberOfTickets,
      pricePerTicket: pricePerTicket ?? this.pricePerTicket,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountCode: discountCode ?? this.discountCode,
      bookingDate: bookingDate ?? this.bookingDate,
      cancellationDate: cancellationDate ?? this.cancellationDate,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      specialRequests: specialRequests ?? this.specialRequests,
      ticketHolderDetails: ticketHolderDetails ?? this.ticketHolderDetails,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      qrCode: qrCode ?? this.qrCode,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isPaid => paymentStatus == 'completed';
  bool get canCancel => status == EventBookingStatus.pending || status == EventBookingStatus.confirmed;
  bool get isActive => status != EventBookingStatus.cancelled && status != EventBookingStatus.refunded;
  
  String get ticketTypeDisplayName {
    switch (ticketType) {
      case EventTicketType.regular:
        return 'Regular';
      case EventTicketType.vip:
        return 'VIP';
      case EventTicketType.student:
        return 'Student';
      case EventTicketType.early_bird:
        return 'Early Bird';
      case EventTicketType.group:
        return 'Group';
      case EventTicketType.complimentary:
        return 'Complimentary';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case EventBookingStatus.pending:
        return 'Pending';
      case EventBookingStatus.confirmed:
        return 'Confirmed';
      case EventBookingStatus.cancelled:
        return 'Cancelled';
      case EventBookingStatus.attended:
        return 'Attended';
      case EventBookingStatus.no_show:
        return 'No Show';
      case EventBookingStatus.refunded:
        return 'Refunded';
    }
  }

  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case 'pending':
        return 'Payment Pending';
      case 'completed':
        return 'Paid';
      case 'failed':
        return 'Payment Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case 'esewa':
        return 'eSewa';
      case 'khalti':
        return 'Khalti';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Cash';
      default:
        return 'Unknown';
    }
  }

  double get finalAmount => totalAmount - (discountAmount ?? 0.0);

  bool get hasDiscount => discountAmount != null && discountAmount! > 0;

  String get bookingReference => 'TKT-${id.substring(0, 8).toUpperCase()}';

  // Calculate savings if early bird or has discount
  double get savings {
    double totalSavings = 0.0;
    
    if (hasDiscount) {
      totalSavings += discountAmount!;
    }
    
    // If early bird, could add early bird savings calculation here
    if (ticketType == EventTicketType.early_bird) {
      // This would typically come from backend calculation
      totalSavings += (metadata['early_bird_savings'] as num?)?.toDouble() ?? 0.0;
    }
    
    return totalSavings;
  }

  bool get canDownloadTicket => isPaid && (status == EventBookingStatus.confirmed || status == EventBookingStatus.attended);

  bool get canShowQR => isPaid && status == EventBookingStatus.confirmed;

  // For Nepal - check if payment method is local
  bool get isLocalPayment => ['esewa', 'khalti', 'cash'].contains(paymentMethod);
}