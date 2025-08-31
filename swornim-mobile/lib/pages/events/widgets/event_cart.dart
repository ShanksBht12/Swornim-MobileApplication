import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swornim/pages/models/events/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/services/event_manager.dart' as event_manager;
import '../../providers/events/client_event_provider.dart';
import '../../QRScreen/qr_ticket_screen.dart';
import '../../models/events/event_booking.dart';
import '../../payment/khalti_payment_screen.dart';
import '../../providers/payments/payment_provider.dart';
import '../../services/event_booking_manager.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final bool isCompact;

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
    this.isCompact = false,
  }) : super(key: key);

  Widget _buildEventImage(BuildContext context, ColorScheme colorScheme) {
    final event = this.event;
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.8),
            colorScheme.primary.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                image: DecorationImage(
                  image: NetworkImage(event.imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.multiply,
                  ),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getEventIcon(event.eventType),
                color: colorScheme.primary,
                size: 24,
              ),
            ),
          ),
          if (event.isTicketed)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF059669),
                      const Color(0xFF10B981),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  event.ticketPriceDisplayText,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatEventDate(event.eventDate),
                    style: GoogleFonts.inter(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventHeader(BuildContext context, ColorScheme colorScheme) {
    final event = this.event;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            event.displayName,
            style: GoogleFonts.inter(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        if (event.status != EventStatus.published)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(event.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              event.status.name.toUpperCase(),
              style: GoogleFonts.inter(
                color: _getStatusColor(event.status),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEventTitle(BuildContext context, ColorScheme colorScheme) {
    final event = this.event;
    return Text(
      event.title,
      style: GoogleFonts.inter(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventDescription(BuildContext context, ColorScheme colorScheme) {
    final event = this.event;
    return Text(
      event.description,
      style: GoogleFonts.inter(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventDetails(BuildContext context, ColorScheme colorScheme) {
    final event = this.event;
    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.location_on_rounded,
          text: event.venue ?? event.location?.address ?? 'Venue to be announced',
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.schedule_rounded,
          text: _formatEventTime(event),
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        if (event.maxCapacity != null)
          _buildDetailRow(
            icon: Icons.people_rounded,
            text: '${event.availableTickets} spots available',
            color: (event.availableTickets ?? 0) > 10 
                ? colorScheme.onSurfaceVariant 
                : const Color(0xFFDC2626),
          ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getEventIcon(EventType eventType) {
    switch (eventType) {
      case EventType.concert:
        return Icons.music_note_rounded;
      case EventType.musicFestival:
        return Icons.festival_rounded;
      case EventType.dancePerformance:
        return Icons.directions_run_rounded;
      case EventType.comedy_show:
        return Icons.theater_comedy_rounded;
      case EventType.theater:
        return Icons.theaters_rounded;
      case EventType.cultural_show:
        return Icons.palette_rounded;
      case EventType.wedding:
        return Icons.favorite_rounded;
      case EventType.birthday:
        return Icons.cake_rounded;
      case EventType.anniversary:
        return Icons.celebration_rounded;
      case EventType.graduation:
        return Icons.school_rounded;
      case EventType.corporate:
        return Icons.business_rounded;
      case EventType.conference:
        return Icons.groups_rounded;
      case EventType.seminar:
        return Icons.record_voice_over_rounded;
      case EventType.workshop:
        return Icons.build_rounded;
      case EventType.product_launch:
        return Icons.rocket_launch_rounded;
      case EventType.sports_event:
        return Icons.sports_soccer_rounded;
      case EventType.charity_event:
        return Icons.volunteer_activism_rounded;
      case EventType.exhibition:
        return Icons.museum_rounded;
      case EventType.trade_show:
        return Icons.store_rounded;
      case EventType.festival_celebration:
        return Icons.festival_rounded;
      case EventType.religious_ceremony:
        return Icons.temple_buddhist_rounded;
      case EventType.party:
        return Icons.party_mode_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.draft:
        return const Color(0xFF64748B); // slate-500
      case EventStatus.published:
        return const Color(0xFF059669); // emerald-600
      case EventStatus.ongoing:
        return const Color(0xFF2563EB); // blue-600
      case EventStatus.completed:
        return const Color(0xFF7C3AED); // violet-600
      case EventStatus.cancelled:
        return const Color(0xFFDC2626); // red-600
    }
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    if (difference < 0) {
      return 'Event Passed';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  String _formatEventTime(Event event) {
    final date = event.eventDate;
    final endDate = event.eventEndDate;
    final time = event.eventTime;
    final endTime = event.eventEndTime;
    String result = '';
    if (time != null) {
      result = time;
      if (endTime != null && endTime != time) {
        result += ' - $endTime';
      }
    }
    if (endDate != null && endDate != date) {
      final duration = endDate.difference(date).inDays;
      result += ' • ${duration + 1} days';
    }
    return result.isNotEmpty ? result : 'Time TBA';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventImage(context, colorScheme),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventHeader(context, colorScheme),
                      const SizedBox(height: 12),
                      _buildEventTitle(context, colorScheme),
                      const SizedBox(height: 8),
                      _buildEventDescription(context, colorScheme),
                      const SizedBox(height: 16),
                      _buildEventDetails(context, colorScheme),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onTap,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View Details',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}