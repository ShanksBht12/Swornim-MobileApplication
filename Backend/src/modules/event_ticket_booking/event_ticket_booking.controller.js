const PDFDocument = require('pdfkit');
const QRCode = require('qrcode');
const EventTicketBooking = require('./event_ticket_booking.model');
const Event = require('../event/event.model');
const service = require('./event_ticket_booking.service');
const paymentService = require('../payment/payment.service');
const { v4: uuidv4 } = require('uuid');
const User = require('../user/user.model');
const fs = require('fs');
const path = require('path');

// Simple QR code generator (replace with real QR code logic if needed)
function generateQRCode() {
  return uuidv4();
}

exports.bookTickets = async (req, res, next) => {
  try {
    console.log('=== [DEBUG] bookTickets called ===');
    console.log('Request body:', req.body);
    console.log('User:', req.user);
    const result = await service.createBookingWithPayment(req.body, req.user.id);
    if (result.error) {
      console.log('Booking error:', result.error);
      return res.status(result.status || 400).json({ error: result.error });
    }
    console.log('Booking result:', result);
    res.status(result.status || 201).json(result);
  } catch (err) {
    console.error('Exception in bookTickets:', err);
    next(err);
  }
};

// Payment verification endpoint
exports.verifyPayment = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const result = await service.verifyPaymentAndConfirmBooking(bookingId, req.user.id);
    if (result.error) {
      return res.status(result.status || 400).json({ error: result.error });
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
};

exports.getQRCode = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const booking = await EventTicketBooking.findByPk(bookingId);
    if (!booking || booking.user_id !== req.user.id) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    res.json({ qrCode: booking.qr_code });
  } catch (err) {
    next(err);
  }
};

// Booking history for user
exports.getMyBookings = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const bookings = await EventTicketBooking.findAll({ where: { user_id: userId } });
    res.json({ results: bookings });
  } catch (err) {
    next(err);
  }
};

// Organizer view of ticket sales for an event
exports.getEventBookings = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    // Optionally, check if req.user is the organizer of the event
    const bookings = await EventTicketBooking.findAll({ where: { event_id: eventId } });
    res.json({ success: true, data: bookings });
  } catch (err) {
    next(err);
  }
};

// Enhanced Professional Ticket PDF Generator
exports.downloadTicket = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const booking = await EventTicketBooking.findByPk(bookingId);
    if (!booking || booking.user_id !== req.user.id) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    const event = await Event.findByPk(booking.event_id);

    // Use booking.qr_code if available, else fallback to booking.id
    let qrValue = booking.qr_code;
    if (!qrValue || typeof qrValue !== 'string' || !qrValue.trim()) {
      qrValue = booking.id;
    }
    if (!qrValue || typeof qrValue !== 'string' || !qrValue.trim()) {
      return res.status(400).json({ error: 'No valid QR code data for this ticket.' });
    }
    const qrDataUrl = await QRCode.toDataURL(qrValue, { width: 200, margin: 1 });

    // Create PDF with professional settings
    const doc = new PDFDocument({ 
      size: 'A4', 
      margin: 40,
      bufferPages: true,
      info: {
        Title: `Event Ticket - ${event?.title || 'Event'}`,
        Author: 'Swornim Events',
        Subject: 'Official Event Ticket',
        Keywords: 'ticket, event, admission'
      }
    });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=swornim-ticket-${bookingId}.pdf`);
    doc.pipe(res);

    // Page dimensions
    const pageWidth = doc.page.width;
    const margin = 40;
    const contentWidth = pageWidth - 2 * margin;

    // Professional color palette
    const primaryBlue = '#2563EB';
    const darkText = '#0F172A';
    const grayText = '#64748B';
    const lightGray = '#F8FAFC';
    const successGreen = '#10B981';
    const borderGray = '#E2E8F0';

    let currentY = 40;

    // Header Section
    doc.fillColor(darkText)
       .fontSize(32)
       .font('Helvetica-Bold')
       .text('SWORNIM', margin, currentY);

    doc.fontSize(14)
       .font('Helvetica')
       .fillColor(grayText)
       .text('Your Event Ally', margin, currentY + 35);

    // Confirmed badge
    const badgeX = pageWidth - margin - 130;
    doc.roundedRect(badgeX, currentY, 130, 30, 15)
       .fillAndStroke(successGreen, successGreen);
    
    doc.fillColor('white')
       .fontSize(12)
       .font('Helvetica-Bold')
       .text('CONFIRMED', badgeX + 25, currentY + 8);

    currentY += 80;

    // Horizontal separator
    doc.strokeColor(borderGray)
       .lineWidth(1)
       .moveTo(margin, currentY)
       .lineTo(pageWidth - margin, currentY)
       .stroke();

    currentY += 30;

    // Main ticket container
    const ticketHeight = 580;
    doc.roundedRect(margin, currentY, contentWidth, ticketHeight, 20)
       .fillAndStroke('white', borderGray);

    // Event title section
    const titleY = currentY + 20;
    doc.roundedRect(margin + 10, titleY, contentWidth - 20, 70, 15)
       .fillAndStroke(lightGray, borderGray);

    const eventTitle = event?.title || 'Event Title';
    doc.fillColor(darkText)
       .fontSize(24)
       .font('Helvetica-Bold')
       .text(eventTitle, margin + 25, titleY + 15, {
         width: contentWidth - 50,
         ellipsis: true
       });

    // Event type badge
    const eventType = event?.eventType || 'Event';
    doc.roundedRect(margin + 25, titleY + 45, 100, 20, 10)
       .fillAndStroke(primaryBlue, primaryBlue);
    
    doc.fillColor('white')
       .fontSize(10)
       .font('Helvetica-Bold')
       .text(eventType.toUpperCase(), margin + 35, titleY + 50);

    // Content area - two columns
    const contentY = titleY + 90;
    const leftColumnWidth = (contentWidth - 40) / 2;
    const rightColumnX = margin + 25 + leftColumnWidth + 20;

    // Left column - Event Details
    let leftY = contentY;
    doc.fillColor(grayText)
       .fontSize(12)
       .font('Helvetica-Bold')
       .text('EVENT DETAILS', margin + 25, leftY);

    leftY += 25;

    // Date
    const eventDate = event?.eventDate ? new Date(event.eventDate) : new Date();
    const formattedDate = eventDate.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });

    doc.fillColor(darkText)
       .fontSize(14)
       .font('Helvetica-Bold')
       .text('Date:', margin + 25, leftY);
    
    doc.fontSize(12)
       .font('Helvetica')
       .text(formattedDate, margin + 25, leftY + 18, {
         width: leftColumnWidth
       });

    leftY += 50;

    // Time
    if (event?.eventTime) {
      doc.fontSize(14)
         .font('Helvetica-Bold')
         .text('Time:', margin + 25, leftY);
      
      doc.fontSize(12)
         .font('Helvetica')
         .text(event.eventTime, margin + 25, leftY + 18);

      leftY += 50;
    }

    // Venue
    doc.fontSize(14)
       .font('Helvetica-Bold')
       .text('Venue:', margin + 25, leftY);
    
    doc.fontSize(12)
       .font('Helvetica')
       .text(event?.venue || 'Venue TBA', margin + 25, leftY + 18, {
         width: leftColumnWidth,
         height: 40
       });

    leftY += 70;

    // Ticket Information
    doc.fillColor(grayText)
       .fontSize(12)
       .font('Helvetica-Bold')
       .text('TICKET INFORMATION', margin + 25, leftY);

    leftY += 20;

    const ticketInfo = [
      ['Type:', booking.ticket_type || 'General'],
      ['Quantity:', (booking.quantity || 1).toString()],
      ['Attendee:', req.user.name || 'Guest']
    ];

    ticketInfo.forEach((info) => {
      doc.fillColor(darkText)
         .fontSize(11)
         .font('Helvetica-Bold')
         .text(info[0], margin + 25, leftY);
      
      doc.font('Helvetica')
         .text(info[1], margin + 80, leftY, {
           width: leftColumnWidth - 55
         });
      
      leftY += 18;
    });

    // Right column - QR Code
    let rightY = contentY;
    doc.fillColor(grayText)
       .fontSize(12)
       .font('Helvetica-Bold')
       .text('ADMISSION QR CODE', rightColumnX, rightY);

    rightY += 25;

    // QR Code background
    const qrBoxSize = 160;
    doc.roundedRect(rightColumnX, rightY, qrBoxSize, qrBoxSize, 10)
       .fillAndStroke(lightGray, borderGray);

    // QR Code
    const qrSize = 120;
    const qrX = rightColumnX + (qrBoxSize - qrSize) / 2;
    const qrY = rightY + (qrBoxSize - qrSize) / 2;
    doc.image(qrDataUrl, qrX, qrY, { width: qrSize, height: qrSize });

    rightY += qrBoxSize + 15;

    // QR instruction
    doc.fillColor(grayText)
       .fontSize(10)
       .font('Helvetica')
       .text('Present this code at entrance', rightColumnX, rightY, {
         width: qrBoxSize,
         align: 'center'
       });

    rightY += 30;

    // Booking Reference
    doc.fillColor(grayText)
       .fontSize(12)
       .font('Helvetica-Bold')
       .text('BOOKING REFERENCE', rightColumnX, rightY);

    doc.fillColor(primaryBlue)
       .fontSize(10)
       .font('Helvetica')
       .text(booking.id, rightColumnX, rightY + 20, {
         width: qrBoxSize
       });

    rightY += 50;

    // Verification info
    doc.fillColor(grayText)
       .fontSize(10)
       .font('Helvetica')
       .text(`Issue Date: ${new Date().toLocaleDateString()}`, rightColumnX, rightY)
       .text('Valid for: Single Entry', rightColumnX, rightY + 15);

    // Separator line
    const separatorY = currentY + ticketHeight - 120;
    for (let i = margin + 20; i < pageWidth - margin - 20; i += 8) {
      doc.circle(i, separatorY, 1)
         .fillAndStroke(grayText, grayText);
    }

    // Terms and Conditions
    const termsY = separatorY + 20;
    doc.fillColor(grayText)
       .fontSize(11) // slightly larger font for heading
       .font('Helvetica-Bold')
       .text('TERMS & CONDITIONS', margin + 25, termsY);

    const terms = [
      'This ticket is non-transferable and admits one person only',
      'Please arrive 30 minutes before event start time',
      'Valid photo ID required for entry',
      'No refunds unless event is cancelled by organizer'
    ];

    let termY = termsY + 14; // smaller initial offset
    terms.forEach((term, index) => {
      doc.fillColor(darkText)
         .fontSize(10) // slightly larger font for the terms
         .font('Helvetica')
         .text(`${index + 1}. ${term}`, margin + 25, termY, {
           width: contentWidth - 50
         });
      termY += 10; // less vertical space between terms
    });

    // Watermark
    doc.save();
    doc.translate(pageWidth / 2, doc.page.height / 2);
    doc.rotate(-45);
    doc.fillOpacity(0.05)
       .fillColor(primaryBlue)
       .fontSize(60)
       .font('Helvetica-Bold')
       .text('SWORNIM', -100, -20);
    doc.restore();

    doc.end();

  } catch (err) {
    console.error('Error generating ticket PDF:', err);
    next(err);
  }
};

// GET /events/bookings/:bookingId/ - Get single booking
exports.getBooking = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.id;
    const booking = await EventTicketBooking.findByPk(bookingId);
    if (!booking || booking.user_id !== userId) {
      return res.status(404).json({ data: null, message: 'Booking not found' });
    }
    res.json({ data: booking });
  } catch (err) { next(err); }
};

// PATCH /events/bookings/:bookingId/ - Cancel booking
exports.cancelBooking = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.id;
    const booking = await EventTicketBooking.findByPk(bookingId);
    if (!booking || booking.user_id !== userId) {
      return res.status(404).json({ data: null, message: 'Booking not found' });
    }
    if (booking.status === 'cancelled' || booking.status === 'refunded') {
      return res.status(400).json({ data: booking, message: 'Booking already cancelled or refunded' });
    }
    await booking.update({ status: 'cancelled', booking_status: 'cancelled' });
    res.json({ data: booking, message: 'Booking cancelled' });
  } catch (err) { next(err); }
};

// GET /events/bookings/organizer/ - Organizer bookings
exports.getOrganizerBookings = async (req, res, next) => {
  try {
    const userId = req.user.id;
    // Find all bookings for events organized by this user
    const events = await Event.findAll({ where: { organizerId: userId } });
    const eventIds = events.map(e => e.id);
    const bookings = await EventTicketBooking.findAll({ where: { event_id: eventIds } });
    res.json({ results: bookings });
  } catch (err) { next(err); }
};

// POST /events/bookings/:bookingId/checkin/ - Check-in attendee
exports.checkInAttendee = async (req, res, next) => {
  try {
    const { bookingId } = req.params; // This is actually the scanned QR code value
    const userId = req.user.id;
    
    console.log('Check-in attempt:', { 
      scannedValue: bookingId, 
      organizerId: userId 
    });
    
    // STEP 1: Try to find booking by actual booking ID first
    let booking = await EventTicketBooking.findByPk(bookingId);
    
    // STEP 2: If not found by ID, try to find by QR code (THIS IS THE KEY FIX)
    if (!booking) {
      console.log('Not found by booking ID, trying QR code lookup...');
      booking = await EventTicketBooking.findOne({
        where: { qr_code: bookingId }
      });
      
      if (booking) {
        console.log('Found booking by QR code:', booking.id);
      }
    }
    
    if (!booking) {
      console.log('Booking not found by ID or QR code');
      return res.status(404).json({ 
        data: null, 
        message: 'Booking or event not found or not authorized' 
      });
    }
    
    // STEP 3: Get the event (without associations for now)
    const Event = require('../event/event.model');
    const event = await Event.findByPk(booking.event_id);
    
    if (!event) {
      return res.status(404).json({ 
        data: null, 
        message: 'Booking or event not found or not authorized' 
      });
    }
    
    // STEP 4: Check if user is the organizer (handle both field name possibilities)
    const eventOrganizerId = event.organizer_id || event.organizerId;
    if (eventOrganizerId !== userId) {
      console.log('Authorization failed:', { 
        eventOrganizer: eventOrganizerId, 
        currentUser: userId 
      });
      return res.status(403).json({ 
        data: null, 
        message: 'Booking or event not found or not authorized' 
      });
    }
    
    // STEP 5: Validate booking status
    if (booking.payment_status !== 'paid') {
      return res.status(400).json({ 
        data: booking, 
        message: 'Payment not completed for this ticket' 
      });
    }
    
    if (booking.status === 'attended') {
      return res.status(400).json({ 
        data: booking, 
        message: 'Already checked in',
        alreadyCheckedIn: true
      });
    }
    
    if (['cancelled', 'refunded'].includes(booking.status)) {
      return res.status(400).json({ 
        data: booking, 
        message: `Ticket is ${booking.status}` 
      });
    }
    
    if (!['pending', 'confirmed'].includes(booking.status)) {
      return res.status(400).json({ 
        data: booking, 
        message: `Cannot check-in with status: ${booking.status}` 
      });
    }
    
    // STEP 6: Perform check-in
    await booking.update({ status: 'attended' });
    
    console.log('Check-in successful:', {
      bookingId: booking.id,
      eventTitle: event.title,
      ticketType: booking.ticket_type
    });
    
    res.json({ 
      data: booking, 
      message: 'Check-in successful'
    });
    
  } catch (err) {
    console.error('Check-in error:', err);
    res.status(500).json({
      data: null,
      message: 'Booking or event not found or not authorized'
    });
  }
};

// GET /events/:eventId/booking-details/ - Event booking details (paginated)
exports.getEventBookingDetails = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const { count, rows: bookings } = await EventTicketBooking.findAndCountAll({
      where: { event_id: eventId },
      offset,
      limit,
      order: [['createdAt', 'DESC']],
      include: [
        { model: User, as: 'user', attributes: ['id', 'name', 'email'] }
      ]
    });

    res.json({
      results: bookings,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      }
    });
  } catch (err) { next(err); }
};

// GET /events/:eventId/booking-analytics/ - Analytics
exports.getBookingAnalytics = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    // Example: count bookings by status
    const bookings = await EventTicketBooking.findAll({ where: { event_id: eventId } });
    const analytics = {
      total: bookings.length,
      confirmed: bookings.filter(b => b.status === 'confirmed').length,
      cancelled: bookings.filter(b => b.status === 'cancelled').length,
      attended: bookings.filter(b => b.status === 'attended').length,
      no_show: bookings.filter(b => b.status === 'no_show').length,
      refunded: bookings.filter(b => b.status === 'refunded').length,
    };
    res.json({ data: analytics });
  } catch (err) { next(err); }
};

// GET /events/available/ - Available events
exports.getAvailableEvents = async (req, res, next) => {
  try {
    // For demo: return all published/public events
    const events = await Event.findAll({ where: { status: 'published', visibility: 'public' } });
    res.json({ results: events });
  } catch (err) { next(err); }
};

// GET /events/search/ - Search events
exports.searchEvents = async (req, res, next) => {
  try {
    const { q } = req.query;
    // For demo: search by title or description
    const events = await Event.findAll({
      where: {
        status: 'published',
        visibility: 'public',
        ...(q ? { title: { $iLike: `%${q}%` } } : {})
      }
    });
    res.json({ results: events });
  } catch (err) { next(err); }
};

// POST /events/discount/apply/ - Apply discount code
exports.applyDiscountCode = async (req, res, next) => {
  try {
    // For demo: always return 0 discount
    res.json({ data: { discount: 0, message: 'No discount logic implemented' } });
  } catch (err) { next(err); }
};

// POST /events/bookings/:bookingId/payment/ - Process payment for a booking
exports.processPayment = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const { paymentMethod, paymentDetails } = req.body;
    // Process payment logic here (call service)
    const result = await service.processPaymentForBooking(bookingId, paymentMethod, paymentDetails);
    res.json({ data: result });
  } catch (err) { next(err); }
};