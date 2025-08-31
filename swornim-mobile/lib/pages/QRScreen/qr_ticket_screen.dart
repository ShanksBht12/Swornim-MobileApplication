import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:swornim/pages/QRScreen/qr_providers.dart';
import 'package:swornim/pages/QRScreen/qr_ticket_widget.dart';
import '../models/events/event_booking.dart';
import '../models/events/event.dart';

import '../services/event_booking_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../services/event_manager.dart';
import 'package:swornim/pages/Client_Dashboard/ClientDashboard.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../providers/auth/auth_provider.dart';
import 'package:swornim/config/app_config.dart';
import 'dart:io';

final singleEventProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final manager = ref.read(eventManagerProvider);
  final result = await manager.getEvent(eventId);
  if (result.isError) throw Exception(result.error ?? 'Unknown error');
  return result.data;
});

class QRTicketScreen extends ConsumerStatefulWidget {
  final EventBooking booking;
  const QRTicketScreen({Key? key, required this.booking}) : super(key: key);

  @override
  ConsumerState<QRTicketScreen> createState() => _QRTicketScreenState();
}

class _QRTicketScreenState extends ConsumerState<QRTicketScreen> {
  double? _previousBrightness;

  @override
  void initState() {
    super.initState();
    _setMaxBrightness();
  }

  Future<void> _setMaxBrightness() async {
    try {
      _previousBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_previousBrightness != null) {
      ScreenBrightness().setScreenBrightness(_previousBrightness!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrCodeAsync = ref.watch(qrCodeProvider(widget.booking.id));
    final eventAsync = ref.watch(singleEventProvider(widget.booking.eventId));
    final authState = ref.watch(authProvider);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => ClientDashboard()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Your Ticket'),
          actions: [
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () async {
                final event = eventAsync.asData?.value;
                await Share.share(
                  'Event: \\${event?.title ?? 'Event'}\\nDate: \\${event?.eventDate.toString().split(' ')[0] ?? widget.booking.bookingDate.toString().split(' ')[0]}\\nVenue: \\${event?.venue ?? 'Venue'}\\nRef: \\${widget.booking.bookingReference}',
                );
              },
            ),
          ],
        ),
        body: qrCodeAsync.when(
          data: (qrData) => eventAsync.when(
            data: (event) => SingleChildScrollView(
              child: Column(
                children: [
                  QRTicketWidget(booking: widget.booking, event: event, qrData: qrData),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.download),
                        label: Text('Download PDF'),
                        onPressed: () async {
                          try {
                            await _downloadTicketPdf(context, widget.booking.id, authState.accessToken);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ticket downloaded!')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to download ticket: \\${e.toString()}')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: Icon(Icons.home),
                    label: Text('Back to Dashboard'),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => ClientDashboard()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            loading: () => Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Failed to load event details')),
          ),
          loading: () => Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 12),
                Text('Failed to load ticket'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.refresh(qrCodeProvider(widget.booking.id)),
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadTicketPdf(BuildContext context, String bookingId, String? authToken) async {
    if (authToken == null) throw Exception('Not authenticated');
    final dio = Dio();
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/ticket-$bookingId.pdf';
    final url = '${AppConfig.baseUrl}/events/bookings/$bookingId/ticket/';
    final response = await dio.get(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      ),
    );
    final file = File(filePath);
    await file.writeAsBytes(response.data);
    await OpenFile.open(filePath);
  }
} 