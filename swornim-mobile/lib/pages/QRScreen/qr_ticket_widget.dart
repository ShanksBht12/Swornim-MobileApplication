import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/events/event_booking.dart';
import '../models/events/event.dart';

class QRTicketWidget extends StatelessWidget {
  final EventBooking booking;
  final Event? event;
  final String qrData;

  const QRTicketWidget({
    Key? key,
    required this.booking,
    required this.qrData,
    this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventName = event?.title ?? 'Event';
    final venueName = event?.venue ?? event?.location?.address ?? 'Venue';
    final eventDate = event?.eventDate ?? booking.bookingDate;
    final eventDateString = '${eventDate.day}/${eventDate.month}/${eventDate.year}';
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [Color(0xFF6D5FFD), Color(0xFF46A6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              eventName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              venueName,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              eventDateString,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF6D5FFD),
              gapless: false,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusBadge(booking.statusDisplayName),
                const SizedBox(width: 12),
                Text(
                  'Ref: ${booking.bookingReference}',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = status;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'attended':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}