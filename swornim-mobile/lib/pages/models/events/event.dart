// File: lib/pages/models/events/event.dart
import 'package:swornim/pages/models/location.dart';

enum EventStatus {
  draft,
  published,
  ongoing,
  completed,
  cancelled,
}

enum EventType {
  // Entertainment Events
  concert, // Live concerts
  musicFestival, // Music festivals
  dancePerformance, // Dance shows
  comedy_show, // Stand-up comedy
  theater, // Drama/Theater
  cultural_show, // Cultural programs
  
  // Celebrations
  wedding,
  birthday,
  anniversary,
  graduation,
  
  // Corporate Events
  corporate,
  conference,
  seminar,
  workshop,
  product_launch,
  
  // Community Events
  sports_event,
  charity_event,
  exhibition,
  trade_show,
  
  // Religious/Traditional
  festival_celebration,
  religious_ceremony,
  
  // Others
  party,
  other,
}

enum EventVisibility {
  public,
  private,
  inviteOnly,
}

class Event {
  final String id;
  final String organizerId; // Event organizer ID
  final String title;
  final String description;
  final EventType eventType;
  final EventStatus status;
  final EventVisibility visibility;
  final DateTime eventDate;
  final DateTime? eventEndDate;
  final String? eventTime;
  final String? eventEndTime;
  final Location? location;
  final String? venue; // Venue name/address
  final int expectedGuests;
  final double? ticketPrice; // For paid events
  final String? imageUrl;
  final List<String> gallery;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Contact information
  final String? contactEmail;
  final String? contactPhone;
  
  // Event specific fields
  final bool isTicketed; // Whether tickets are required
  final int? maxCapacity; // Maximum attendees
  final int? availableTickets;
  final Map<String, dynamic> metadata;

  const Event({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.eventType,
    this.status = EventStatus.draft,
    this.visibility = EventVisibility.private,
    required this.eventDate,
    this.eventEndDate,
    this.eventTime,
    this.eventEndTime,
    this.location,
    this.venue,
    this.expectedGuests = 0,
    this.ticketPrice,
    this.imageUrl,
    this.gallery = const [],
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.contactEmail,
    this.contactPhone,
    this.isTicketed = false,
    this.maxCapacity,
    this.availableTickets,
    this.metadata = const {},
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    try {
      // Robustly parse availableTickets
      dynamic rawAvailableTickets = json['availableTickets'] ?? json['available_tickets'];
      int parsedAvailableTickets;
      if (rawAvailableTickets == null || rawAvailableTickets == 'null') {
        parsedAvailableTickets = 0;
      } else if (rawAvailableTickets is int) {
        parsedAvailableTickets = rawAvailableTickets;
      } else if (rawAvailableTickets is String) {
        parsedAvailableTickets = int.tryParse(rawAvailableTickets) ?? 0;
      } else {
        parsedAvailableTickets = 0;
      }
      print('Event JSON: $json');
      print('Parsed availableTickets: $parsedAvailableTickets');
      return Event(
        id: json['id']?.toString() ?? '',
        organizerId: json['organizer_id']?.toString() ?? json['organizerId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        eventType: _parseEventType(json['event_type'] ?? json['eventType']),
        status: _parseEventStatus(json['status']),
        visibility: _parseEventVisibility(json['visibility']),
        eventDate: _parseDateTime(json['event_date'] ?? json['eventDate']) ?? DateTime.now(),
        eventEndDate: _parseDateTime(json['event_end_date'] ?? json['eventEndDate']),
        eventTime: json['event_time']?.toString() ?? json['eventTime']?.toString(),
        eventEndTime: json['event_end_time']?.toString() ?? json['eventEndTime']?.toString(),
        location: json['location'] != null ? Location.fromJson(json['location']) : null,
        venue: json['venue']?.toString(),
        expectedGuests: _parseInt(json['expected_guests'] ?? json['expectedGuests']),
        ticketPrice: _parseDouble(json['ticket_price'] ?? json['ticketPrice']),
        imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
        gallery: _parseStringList(json['gallery']),
        tags: _parseStringList(json['tags']),
        createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']) ?? DateTime.now(),
        contactEmail: json['contact_email']?.toString() ?? json['contactEmail']?.toString(),
        contactPhone: json['contact_phone']?.toString() ?? json['contactPhone']?.toString(),
        isTicketed: json['is_ticketed'] ?? json['isTicketed'] ?? false,
        maxCapacity: _parseInt(json['max_capacity'] ?? json['maxCapacity']),
        availableTickets: parsedAvailableTickets,
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );
    } catch (e, stack) {
      print('Error parsing Event JSON: $e');
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

  static EventType _parseEventType(dynamic type) {
    if (type == null) return EventType.other;
    final typeStr = type.toString().toLowerCase().replaceAll(' ', '_');
    
    switch (typeStr) {
      case 'concert':
        return EventType.concert;
      case 'music_festival':
      case 'musicfestival':
        return EventType.musicFestival;
      case 'dance_performance':
      case 'danceperformance':
        return EventType.dancePerformance;
      case 'comedy_show':
      case 'comedyshow':
        return EventType.comedy_show;
      case 'theater':
        return EventType.theater;
      case 'cultural_show':
      case 'culturalshow':
        return EventType.cultural_show;
      case 'wedding':
        return EventType.wedding;
      case 'birthday':
        return EventType.birthday;
      case 'anniversary':
        return EventType.anniversary;
      case 'graduation':
        return EventType.graduation;
      case 'corporate':
        return EventType.corporate;
      case 'conference':
        return EventType.conference;
      case 'seminar':
        return EventType.seminar;
      case 'workshop':
        return EventType.workshop;
      case 'product_launch':
      case 'productlaunch':
        return EventType.product_launch;
      case 'sports_event':
      case 'sportsevent':
        return EventType.sports_event;
      case 'charity_event':
      case 'charityevent':
        return EventType.charity_event;
      case 'exhibition':
        return EventType.exhibition;
      case 'trade_show':
      case 'tradeshow':
        return EventType.trade_show;
      case 'festival_celebration':
      case 'festivalcelebration':
        return EventType.festival_celebration;
      case 'religious_ceremony':
      case 'religiousceremony':
        return EventType.religious_ceremony;
      case 'party':
        return EventType.party;
      default:
        return EventType.other;
    }
  }

  static EventStatus _parseEventStatus(dynamic status) {
    if (status == null) return EventStatus.draft;
    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'published':
        return EventStatus.published;
      case 'ongoing':
        return EventStatus.ongoing;
      case 'completed':
        return EventStatus.completed;
      case 'cancelled':
        return EventStatus.cancelled;
      default:
        return EventStatus.draft;
    }
  }

  static EventVisibility _parseEventVisibility(dynamic visibility) {
    if (visibility == null) return EventVisibility.private;
    final visibilityStr = visibility.toString().toLowerCase();
    switch (visibilityStr) {
      case 'public':
        return EventVisibility.public;
      case 'invite_only':
      case 'inviteonly':
        return EventVisibility.inviteOnly;
      default:
        return EventVisibility.private;
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

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizer_id': organizerId,
      'title': title,
      'description': description,
      'event_type': eventType.name,
      'status': status.name,
      'visibility': visibility.name,
      'event_date': eventDate.toIso8601String(),
      'event_end_date': eventEndDate?.toIso8601String(),
      'event_time': eventTime,
      'event_end_time': eventEndTime,
      'location': location?.toJson(),
      'venue': venue,
      'expected_guests': expectedGuests,
      'ticket_price': ticketPrice,
      'image_url': imageUrl,
      'gallery': gallery,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'is_ticketed': isTicketed,
      'max_capacity': maxCapacity,
      'availableTickets': availableTickets,
      'metadata': metadata,
    };
  }

  Event copyWith({
    String? id,
    String? organizerId,
    String? title,
    String? description,
    EventType? eventType,
    EventStatus? status,
    EventVisibility? visibility,
    DateTime? eventDate,
    DateTime? eventEndDate,
    String? eventTime,
    String? eventEndTime,
    Location? location,
    String? venue,
    int? expectedGuests,
    double? ticketPrice,
    String? imageUrl,
    List<String>? gallery,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contactEmail,
    String? contactPhone,
    bool? isTicketed,
    int? maxCapacity,
    int? availableTickets,
    Map<String, dynamic>? metadata,
  }) {
    return Event(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      eventDate: eventDate ?? this.eventDate,
      eventEndDate: eventEndDate ?? this.eventEndDate,
      eventTime: eventTime ?? this.eventTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      location: location ?? this.location,
      venue: venue ?? this.venue,
      expectedGuests: expectedGuests ?? this.expectedGuests,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      gallery: gallery ?? this.gallery,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      isTicketed: isTicketed ?? this.isTicketed,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      availableTickets: availableTickets ?? this.availableTickets,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods for event organizers
  String get displayName {
    switch (eventType) {
      case EventType.concert:
        return 'Live Concert';
      case EventType.musicFestival:
        return 'Music Festival';
      case EventType.dancePerformance:
        return 'Dance Performance';
      case EventType.comedy_show:
        return 'Comedy Show';
      case EventType.theater:
        return 'Theater';
      case EventType.cultural_show:
        return 'Cultural Show';
      case EventType.wedding:
        return 'Wedding';
      case EventType.birthday:
        return 'Birthday';
      case EventType.anniversary:
        return 'Anniversary';
      case EventType.graduation:
        return 'Graduation';
      case EventType.corporate:
        return 'Corporate Event';
      case EventType.conference:
        return 'Conference';
      case EventType.seminar:
        return 'Seminar';
      case EventType.workshop:
        return 'Workshop';
      case EventType.product_launch:
        return 'Product Launch';
      case EventType.sports_event:
        return 'Sports Event';
      case EventType.charity_event:
        return 'Charity Event';
      case EventType.exhibition:
        return 'Exhibition';
      case EventType.trade_show:
        return 'Trade Show';
      case EventType.festival_celebration:
        return 'Festival Celebration';
      case EventType.religious_ceremony:
        return 'Religious Ceremony';
      case EventType.party:
        return 'Party';
      default:
        return 'Other Event';
    }
  }

  // Helper methods for clients to view and book tickets
  bool get isSoldOut => (availableTickets ?? 0) <= 0;

  bool get canBeBooked {
    print('canBeBooked debug: eventDate: ${eventDate.toIso8601String()}, now: ${DateTime.now().toIso8601String()}, isAfter: ${eventDate.isAfter(DateTime.now())}');
    return status == EventStatus.published && 
           visibility == EventVisibility.public && 
           eventDate.isAfter(DateTime.now()) &&
           !isSoldOut;
  }

  String get ticketPriceDisplayText {
    if (!isTicketed) return 'Free';
    if (ticketPrice == null || ticketPrice! <= 0) return 'Free';
    return 'Rs. ${ticketPrice!.toStringAsFixed(0)}';
  }

  DateTime get bookingDeadline {
    return eventDate.subtract(const Duration(hours: 24));
  }

  bool get isBookingOpen {
    return canBeBooked && DateTime.now().isBefore(bookingDeadline);
  }

  // Helper methods for event organizers to track revenue
  double get maxRevenue {
    if (!isTicketed || ticketPrice == null) return 0.0;
    return (maxCapacity ?? expectedGuests).toDouble() * ticketPrice!;
  }

  double get currentRevenue {
    if (!isTicketed || ticketPrice == null) return 0.0;
    final bookedTickets = metadata['booked_tickets'] as int? ?? 0;
    return bookedTickets.toDouble() * ticketPrice!;
  }

  double get bookingPercentage {
    if (maxCapacity == null || maxCapacity! <= 0) return 0.0;
    final bookedTickets = metadata['booked_tickets'] as int? ?? 0;
    return (bookedTickets / maxCapacity!) * 100;
  }
}