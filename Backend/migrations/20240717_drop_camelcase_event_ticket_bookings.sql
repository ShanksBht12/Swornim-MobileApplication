ALTER TABLE event_ticket_bookings
  DROP COLUMN IF EXISTS paymentMethod,
  DROP COLUMN IF EXISTS paymentDate,
  DROP COLUMN IF EXISTS discountAmount,
  DROP COLUMN IF EXISTS discountCode,
  DROP COLUMN IF EXISTS cancellationReason,
  DROP COLUMN IF EXISTS ticketType; 