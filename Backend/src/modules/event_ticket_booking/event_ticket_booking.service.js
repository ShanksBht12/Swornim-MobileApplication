// event_ticket_booking.service.js
// Placeholder for business logic (e.g., ticket availability, QR code, etc.)
// You can move logic from the controller here as needed. 
const EventTicketBooking = require('./event_ticket_booking.model');
const Event = require('../event/event.model');
const paymentService = require('../payment/payment.service');
const { v4: uuidv4 } = require('uuid');

function generateQRCode() {
  return uuidv4();
}

exports.createBookingWithPayment = async (body, userId) => {
  // Accept both camelCase and snake_case
  const event_id = body.event_id || body.eventId;
  const ticket_type = body.ticket_type || body.ticketType;
  const quantity = body.quantity || body.number_of_tickets;
  const payment_method = body.payment_method || body.paymentMethod;
  const ticket_holder_details = body.ticket_holder_details || body.ticketHolderDetails;
  const special_requests = body.special_requests || body.specialRequests;

  // 1. Validate event
  const event = await Event.findByPk(event_id);
  if (!event || event.status !== 'published' || event.visibility !== 'public') {
    return { error: 'Event not available for booking', status: 400 };
  }

  // 2. Check ticket availability (implement logic as needed)
  // TODO: Check event.maxCapacity - ticketsSold >= quantity

  // 3. Calculate price
  const price_per_ticket = event.ticketPrice;
  const total_amount = price_per_ticket * quantity;

  // 4. Create booking with payment_status: 'pending'
  const booking = await EventTicketBooking.create({
    event_id, user_id: userId, ticket_type, quantity, price_per_ticket, total_amount,
    payment_status: 'pending', booking_status: 'confirmed',
    ticket_holder_details, special_requests,
  });

  // 5. Initiate payment with real payment service (e.g., Khalti/eSewa)
  // This should return a payment URL/token for the frontend
  const paymentInit = await paymentService.initializeKhaltiPayment(booking.id, userId);
  if (!paymentInit || !paymentInit.paymentUrl) {
    return { error: 'Failed to initiate payment', status: 500 };
  }

  // 6. Return booking ID and payment URL/token to frontend
  return { success: true, bookingId: booking.id, paymentUrl: paymentInit.paymentUrl, status: 201 };
};

exports.verifyPaymentAndConfirmBooking = async (bookingId, userId) => {
  // Call payment service to verify payment
  const paymentVerified = await paymentService.verifyKhaltiPayment(bookingId, userId);
  if (!paymentVerified || !paymentVerified.success) {
    return { error: 'Payment not verified', status: 402 };
  }
  // Update booking to paid and generate QR code
  const booking = await EventTicketBooking.findByPk(bookingId);
  if (!booking) {
    return { error: 'Booking not found', status: 404 };
  }
  const qr_code = generateQRCode();
  await booking.update({ payment_status: 'paid', qr_code });
  return { success: true, data: booking, qrCode: qr_code };
};

exports.processPaymentForBooking = async (bookingId, paymentMethod, paymentDetails) => {
  const booking = await EventTicketBooking.findByPk(bookingId);
  if (!booking) {
    return { error: 'Booking not found', status: 404 };
  }

  // Process payment with the specified method (call your real payment service)
  const paymentResult = await paymentService.processPayment(bookingId, paymentMethod, paymentDetails);

  if (paymentResult.success) {
    await booking.update({
      payment_status: 'paid',
      payment_method: paymentMethod,
      payment_date: new Date(),
      qr_code: generateQRCode()
    });
  }

  return paymentResult;
}; 