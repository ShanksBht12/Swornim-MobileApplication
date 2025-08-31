// File: lib/pages/providers/events/client_event_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/events/event.dart';
import 'package:swornim/pages/models/events/event_booking.dart';
import 'package:swornim/pages/services/event_manager.dart';
import 'package:swornim/pages/services/event_booking_manager.dart';

// Simple providers for clients to access events and bookings
// These are just convenient wrappers around the existing managers

// Provider for browsing available events (for clients)
final availableEventsForClientsProvider = FutureProvider.family<List<Event>, Map<String, dynamic>>((ref, params) async {
  final eventManager = ref.read(eventManagerProvider);
  final result = await eventManager.getPublicEvents(
    eventType: params['eventType'],
    location: params['location'],
    fromDate: params['fromDate'],
    toDate: params['toDate'],
    limit: params['limit'] ?? 20,
    offset: params['offset'] ?? 0,
  );
  
  if (result.isError) {
    throw Exception(result.error ?? 'Failed to load events');
  }
  
  return result.data ?? [];
});

// Provider for client's bookings
final clientBookingsProvider = FutureProvider.family<List<EventBooking>, EventBookingStatus?>((ref, status) async {
  final bookingManager = ref.read(eventBookingManagerProvider);
  final result = await bookingManager.getMyBookings(status: status);
  
  if (result.isError) {
    throw Exception(result.error ?? 'Failed to load bookings');
  }
  
  return result.data ?? [];
});

// Provider for searching events (for clients)
final clientEventSearchProvider = FutureProvider.family<List<Event>, String>((ref, query) async {
  final eventManager = ref.read(eventManagerProvider);
  final result = await eventManager.searchEvents(query: query);
  
  if (result.isError) {
    throw Exception(result.error ?? 'Failed to search events');
  }
  
  return result.data ?? [];
});

// Helper providers for specific event types
final upcomingEventsForClientsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final eventsAsync = ref.watch(availableEventsForClientsProvider({}));
  
  return eventsAsync.when(
    data: (events) {
      final now = DateTime.now();
      final upcomingEvents = events
          .where((event) => event.eventDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return AsyncValue.data(upcomingEvents);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final ticketedEventsForClientsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final eventsAsync = ref.watch(availableEventsForClientsProvider({}));
  
  return eventsAsync.when(
    data: (events) {
      final ticketedEvents = events.where((event) => event.isTicketed).toList();
      return AsyncValue.data(ticketedEvents);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final freeEventsForClientsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final eventsAsync = ref.watch(availableEventsForClientsProvider({}));
  
  return eventsAsync.when(
    data: (events) {
      final freeEvents = events
          .where((event) => !event.isTicketed || (event.ticketPrice != null && event.ticketPrice! <= 0))
          .toList();
      return AsyncValue.data(freeEvents);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Provider for events by type
final eventsByTypeProvider = Provider.family<AsyncValue<List<Event>>, EventType>((ref, eventType) {
  final eventsAsync = ref.watch(availableEventsForClientsProvider({'eventType': eventType}));
  
  return eventsAsync.when(
    data: (events) => AsyncValue.data(events),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Provider for client's confirmed bookings
final confirmedBookingsForClientProvider = Provider<AsyncValue<List<EventBooking>>>((ref) {
  final bookingsAsync = ref.watch(clientBookingsProvider(EventBookingStatus.confirmed));
  
  return bookingsAsync.when(
    data: (bookings) => AsyncValue.data(bookings),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Provider for client's pending bookings
final pendingBookingsForClientProvider = Provider<AsyncValue<List<EventBooking>>>((ref) {
  final bookingsAsync = ref.watch(clientBookingsProvider(EventBookingStatus.pending));
  
  return bookingsAsync.when(
    data: (bookings) => AsyncValue.data(bookings),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Simple helper functions for clients
class ClientEventHelper {
  static Future<EventBookingResult<EventBooking?>> bookEventTicket(
    WidgetRef ref, {
    required String eventId,
    required EventTicketType ticketType,
    required int numberOfTickets,
    String? discountCode,
    String? specialRequests,
    Map<String, dynamic>? ticketHolderDetails,
  }) async {
    final bookingManager = ref.read(eventBookingManagerProvider);
    final result = await bookingManager.bookEvent(
      eventId: eventId,
      ticketType: ticketType,
      numberOfTickets: numberOfTickets,
      discountCode: discountCode,
      specialRequests: specialRequests,
      ticketHolderDetails: ticketHolderDetails,
    );
    if (result.success) {
      // Refresh the bookings
      ref.invalidate(clientBookingsProvider);
      return result;
    }
    return result;
  }
  
  static Future<bool> makePayment(
    WidgetRef ref, {
    required String bookingId,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    final bookingManager = ref.read(eventBookingManagerProvider);
    final result = await bookingManager.processPayment(
      bookingId: bookingId,
      paymentMethod: paymentMethod,
      paymentDetails: paymentDetails,
    );
    
    if (result.success) {
      // Refresh the bookings
      ref.invalidate(clientBookingsProvider);
      return true;
    }
    
    return false;
  }
  
  static Future<bool> cancelBooking(
    WidgetRef ref, {
    required String bookingId,
    String? reason,
  }) async {
    final bookingManager = ref.read(eventBookingManagerProvider);
    final result = await bookingManager.cancelBooking(bookingId, reason: reason);
    
    if (result.success) {
      // Refresh the bookings
      ref.invalidate(clientBookingsProvider);
      return true;
    }
    
    return false;
  }
}