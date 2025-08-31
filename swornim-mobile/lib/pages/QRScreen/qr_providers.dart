import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/event_booking_manager.dart';
import '../models/events/event_booking.dart';
import 'package:flutter/material.dart';

final qrCodeProvider = FutureProvider.family<String, String>((ref, bookingId) async {
  final manager = ref.read(eventBookingManagerProvider);
  final result = await manager.getTicketQRCode(bookingId);
  if (result.isError) throw Exception(result.error ?? 'Failed to fetch QR code');
  return result.data!;
});

final qrCodeCacheProvider = StateProvider<Map<String, String>>((ref) => {}); 