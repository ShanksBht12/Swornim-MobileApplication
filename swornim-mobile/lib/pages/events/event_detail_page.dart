import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swornim/pages/models/events/event.dart';
import '../QRScreen/qr_ticket_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/events/event_booking.dart';
import 'package:swornim/pages/payment/khalti_payment_screen.dart';
import 'package:swornim/pages/providers/payments/payment_provider.dart';
import 'package:swornim/pages/services/event_booking_manager.dart';
import 'package:swornim/pages/models/events/event_booking.dart';
import 'package:swornim/pages/providers/events/client_event_provider.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final Event event;
  const EventDetailPage({required this.event, Key? key}) : super(key: key);

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _ticketQuantity = 1;
  bool _isBooking = false;
  String? _error;
  int get _maxTickets => widget.event.availableTickets ?? 1;
  double get _totalPrice => (widget.event.ticketPrice ?? 0) * _ticketQuantity;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image or Gradient
            if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty)
              Image.network(
                widget.event.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildGradientBackground(),
              )
            else
              _buildGradientBackground(),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Title and Event Type
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.event.eventType.name ?? widget.event.eventType.toString().split('.').last,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.event.title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Add share functionality
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB),
            Color(0xFF7C3AED),
            Color(0xFF9333EA),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event,
          size: 80,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventInfoCards(),
          const SizedBox(height: 24),
          if (widget.event.description.isNotEmpty) ...[
            _buildDescriptionCard(),
            const SizedBox(height: 20),
          ],
          _buildDetailsGrid(),
          const SizedBox(height: 20),
          if (widget.event.tags.isNotEmpty) _buildTagsSection(),
          const SizedBox(height: 30),
          _buildTicketQuantitySelector(),
          if (_isBooking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!, style: TextStyle(color: Colors.red)),
            ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEventInfoCards() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Date',
              value: '${widget.event.eventDate.day.toString().padLeft(2, '0')}/${widget.event.eventDate.month.toString().padLeft(2, '0')}/${widget.event.eventDate.year}',
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (widget.event.eventTime != null && widget.event.eventTime!.isNotEmpty)
            Expanded(
              child: _buildInfoCard(
                icon: Icons.access_time,
                title: 'Time',
                value: widget.event.eventTime!,
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Description',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.event.description,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid() {
    List<Widget> cards = [
      _buildDetailCard(
        icon: Icons.confirmation_number,
        title: 'Available Tickets',
        value: '${widget.event.availableTickets ?? 'N/A'}',
        color: const Color(0xFF2563EB),
      ),
      _buildDetailCard(
        icon: Icons.local_offer,
        title: 'Ticket Price',
        value: widget.event.ticketPrice == null || widget.event.ticketPrice == 0 
            ? 'Free' 
            : 'Rs. ${widget.event.ticketPrice!.toStringAsFixed(0)}',
        color: const Color(0xFF059669),
      ),
      _buildDetailCard(
        icon: Icons.people,
        title: 'Expected Guests',
        value: '${widget.event.expectedGuests}',
        color: const Color(0xFF7C3AED),
      ),
      if (widget.event.venue != null && widget.event.venue!.isNotEmpty)
        _buildDetailCard(
          icon: Icons.location_on,
          title: 'Venue',
          value: widget.event.venue!,
          color: const Color(0xFFD97706),
          isLocation: true,
        ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4, // Better balance - not too tall, not too short
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLocation = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28, // Smaller icon container
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16, // Smaller icon
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing
          Flexible( // Use Flexible to prevent overflow
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10, // Smaller font
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible( // Use Flexible to prevent overflow
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: isLocation ? 11 : 13, // Adjusted font sizes
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              maxLines: isLocation ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Tags',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.event.tags.map((tag) => _buildTag(tag)).toList(),
        ),
      ],
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2563EB).withOpacity(0.1),
            const Color(0xFF7C3AED).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _buildTicketQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Tickets:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(width: 4),
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            icon: const Icon(Icons.remove, size: 16),
            padding: EdgeInsets.zero,
            onPressed: _ticketQuantity > 1 ? () => setState(() => _ticketQuantity--) : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('$_ticketQuantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
            onPressed: _ticketQuantity < _maxTickets ? () => setState(() => _ticketQuantity++) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text('Total: NPR ${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Future<void> _bookAndPay() async {
    setState(() {
      _isBooking = true;
      _error = null;
    });
    try {
      if (_ticketQuantity > _maxTickets) {
        setState(() {
          _error = 'Not enough tickets available.';
          _isBooking = false;
        });
        return;
      }
      // 1. Book the event
      final bookingResult = await ClientEventHelper.bookEventTicket(
        ref,
        eventId: widget.event.id,
        ticketType: EventTicketType.regular,
        numberOfTickets: _ticketQuantity,
      );
      if (bookingResult == null || bookingResult.isError) {
        setState(() {
          _error = bookingResult?.error ?? 'Failed to book event';
          _isBooking = false;
        });
        return;
      }
      EventBooking? booking = bookingResult.data;
      String? bookingId = bookingResult.bookingId;
      if (booking == null && bookingId != null) {
        final fetchResult = await ref.read(eventBookingManagerProvider).getBooking(bookingId);
        if (!fetchResult.isError && fetchResult.data != null) {
          booking = fetchResult.data!;
        }
      }
      if (booking != null) {
        await _handleBookingWithFullData(booking);
      } else if (bookingId != null) {
        await _handleBookingWithIdOnly(bookingId);
      } else {
        setState(() {
          _error = 'Booking was created but we could not retrieve the details';
          _isBooking = false;
        });
      }
      if (mounted) {
        setState(() {
          _ticketQuantity = 1;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isBooking = false;
      });
    }
  }

  Future<void> _handleBookingWithFullData(EventBooking booking) async {
    if (booking.paymentStatus == 'pending' && booking.totalAmount > 0) {
      await _processPayment(booking);
    } else {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QRTicketScreen(booking: booking),
          ),
        );
      }
    }
  }

  Future<void> _handleBookingWithIdOnly(String bookingId) async {
    if (widget.event.isTicketed && widget.event.ticketPrice != null && widget.event.ticketPrice! > 0) {
      final paymentNotifier = ref.read(paymentProvider.notifier);
      await paymentNotifier.initializePayment(bookingId);
      final paymentState = ref.read(paymentProvider);
      if (paymentState.paymentUrl == null || bookingId == null || widget.event.ticketPrice == null) {
        setState(() {
          _error = 'Missing payment information. Please try again.';
          _isBooking = false;
        });
        return;
      }
      if (paymentState.paymentUrl != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KhaltiPaymentScreen(
              paymentUrl: paymentState.paymentUrl!,
              bookingId: bookingId,
              amount: widget.event.ticketPrice!,
            ),
          ),
        );
        setState(() {
          _isBooking = false;
        });
        if (result == true) {
          final updatedBookingResult = await ref.read(eventBookingManagerProvider).getBooking(bookingId);
          if (!updatedBookingResult.isError && updatedBookingResult.data != null) {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QRTicketScreen(booking: updatedBookingResult.data!),
                ),
              );
            }
          }
        } else {
          setState(() {
            _error = 'Payment was cancelled or failed';
          });
        }
      } else {
        setState(() {
          _error = paymentState.error ?? 'Failed to get payment URL';
          _isBooking = false;
        });
      }
    } else {
      setState(() {
        _isBooking = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking successful! Check your bookings page.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _processPayment(EventBooking booking) async {
    final paymentNotifier = ref.read(paymentProvider.notifier);
    await paymentNotifier.initializePayment(booking.id);
    final paymentState = ref.read(paymentProvider);
    if (paymentState.paymentUrl == null || booking.id == null || booking.totalAmount == null) {
      setState(() {
        _error = 'Missing payment information. Please try again.';
        _isBooking = false;
      });
      return;
    }
    if (paymentState.paymentUrl != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KhaltiPaymentScreen(
            paymentUrl: paymentState.paymentUrl!,
            bookingId: booking.id,
            amount: booking.totalAmount,
          ),
        ),
      );
      setState(() {
        _isBooking = false;
      });
      if (result == true) {
        final updatedBookingResult = await ref.read(eventBookingManagerProvider).getBooking(booking.id);
        if (!updatedBookingResult.isError && updatedBookingResult.data != null) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QRTicketScreen(booking: updatedBookingResult.data!),
              ),
            );
          }
        }
      } else {
        setState(() {
          _error = 'Payment was cancelled or failed';
        });
      }
    } else {
      setState(() {
        _error = paymentState.error ?? 'Failed to get payment URL';
        _isBooking = false;
      });
    }
  }

  Widget _buildActionButtons() {
    final now = DateTime.now();
    final canBeBooked = widget.event.eventDate.isAfter(now);
    
    debugPrint('canBeBooked debug: eventDate: ${widget.event.eventDate.toIso8601String()}, now: ${now.toIso8601String()}, isAfter: ${widget.event.eventDate.isAfter(now)}');

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: canBeBooked 
                ? const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: canBeBooked 
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: canBeBooked ? _bookAndPay : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        canBeBooked ? Icons.confirmation_number : Icons.event_busy,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        canBeBooked ? 'Book Ticket' : 'Event Passed',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Add to favorites functionality
                },
                icon: const Icon(Icons.favorite_border, size: 18),
                label: Text(
                  'Add to Favorites',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Add to calendar functionality
                },
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(
                  'Add to Calendar',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}