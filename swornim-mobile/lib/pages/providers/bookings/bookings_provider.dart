import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/providers/bookings/booking_manager.dart';
import 'package:swornim/pages/providers/bookings/bookings.dart';

// State definition for the notifier
class BookingsState {
  final List<Booking> bookings;
  final bool isLoading;
  final String? error;

  BookingsState({
    this.bookings = const [],
    this.isLoading = true,
    this.error,
  });

  BookingsState copyWith({
    List<Booking>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// The StateNotifier
class BookingsNotifier extends StateNotifier<BookingsState> {
  final BookingManager _bookingManager;

  BookingsNotifier(this._bookingManager) : super(BookingsState()) {
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final bookings = await _bookingManager.fetchMyBookings();
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason}) async {
    // Store original state for rollback
    final originalState = state;
    
    try {
      // Convert the string to the enum value
      final newStatusEnum = BookingStatus.values.byName(newStatus.toLowerCase());

      // Optimistic UI update
      final originalBookings = state.bookings;
      final updatedBookingIndex = originalBookings.indexWhere((b) => b.id == bookingId);
      if (updatedBookingIndex != -1) {
        final updatedBooking = originalBookings[updatedBookingIndex].copyWith(status: newStatusEnum);
        final updatedList = List<Booking>.from(originalBookings)..[updatedBookingIndex] = updatedBooking;
        state = state.copyWith(bookings: updatedList);
      }

      // Make the actual API call
      final booking = await _bookingManager.updateBookingStatus(bookingId, newStatus, reason: reason);
      
      // Replace the item in the list with the confirmed data from the server
      final finalBookings = List<Booking>.from(state.bookings);
      final index = finalBookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        finalBookings[index] = booking;
        state = state.copyWith(bookings: finalBookings);
      }
    } catch (e) {
      // Revert optimistic update on failure
      print("Failed to update status: $e");
      state = originalState;
      throw e; // Re-throw to let UI handle the error
    }
  }
}

// The Provider
final bookingsProvider = StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  final bookingManager = ref.watch(bookingManagerProvider);
  return BookingsNotifier(bookingManager);
}); 