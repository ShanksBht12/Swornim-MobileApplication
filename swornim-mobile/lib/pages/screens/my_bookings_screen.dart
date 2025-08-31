import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/events/event_booking.dart';
import '../services/event_booking_manager.dart';
import '../QRScreen/qr_ticket_screen.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  Future<void> _refreshBookings(WidgetRef ref) async {
    // This will depend on your provider's implementation
    // For FutureProvider, use ref.refresh
    ref.refresh(myBookingsProvider({'status': null, 'limit': 50, 'offset': 0}));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider({'status': null, 'limit': 50, 'offset': 0}));
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        data: (bookings) => RefreshIndicator(
          onRefresh: () => _refreshBookings(ref),
          child: bookings.isEmpty
              ? Center(child: Text('No bookings found.'))
              : ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Booking Ref: ${booking.bookingReference}'),
                        subtitle: Text('Status: ${booking.statusDisplayName}'),
                        trailing: booking.canShowQR
                            ? ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => QRTicketScreen(booking: booking),
                                    ),
                                  );
                                },
                                child: const Text('View Ticket'),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load bookings'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(myBookingsProvider({'status': null, 'limit': 50, 'offset': 0})),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 