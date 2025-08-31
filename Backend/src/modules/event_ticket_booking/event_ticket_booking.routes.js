const express = require('express');
const router = express.Router();
const controller = require('./event_ticket_booking.controller');
const auth = require('../../middlewares/auth.middleware');

// Booking endpoints
router.post('/bookings/', auth(), controller.bookTickets);
router.get('/bookings/my/', auth(), controller.getMyBookings);
router.get('/bookings/:bookingId/', auth(), controller.getBooking); // stub
router.patch('/bookings/:bookingId/', auth(), controller.cancelBooking); // stub
router.post('/bookings/:bookingId/payment/', auth(), controller.processPayment); // new
router.get('/bookings/:bookingId/qr-code/', auth(), controller.getQRCode); // updated
router.get('/bookings/organizer/', auth(), controller.getOrganizerBookings); // stub
router.post('/bookings/:bookingId/checkin/', auth(), controller.checkInAttendee); // stub

// Event-level endpoints
router.get('/:eventId/booking-details/', auth(), controller.getEventBookingDetails); // stub
router.get('/:eventId/booking-analytics/', auth(), controller.getBookingAnalytics); // stub

// Event discovery/search
router.get('/available/', controller.getAvailableEvents); // stub

// Discount
router.post('/discount/apply/', auth(), controller.applyDiscountCode); // stub

// Ticket download (PDF)
router.get('/bookings/:bookingId/ticket/', auth(), controller.downloadTicket);

module.exports = router; 