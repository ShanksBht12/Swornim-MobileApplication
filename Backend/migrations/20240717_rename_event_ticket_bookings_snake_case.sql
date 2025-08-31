ALTER TABLE event_ticket_bookings RENAME COLUMN paymentmethod TO payment_method;
ALTER TABLE event_ticket_bookings RENAME COLUMN paymentdate TO payment_date;
ALTER TABLE event_ticket_bookings RENAME COLUMN discountamount TO discount_amount;
ALTER TABLE event_ticket_bookings RENAME COLUMN discountcode TO discount_code;
ALTER TABLE event_ticket_bookings RENAME COLUMN cancellationreason TO cancellation_reason;
ALTER TABLE event_ticket_bookings RENAME COLUMN tickettype TO ticket_type; 