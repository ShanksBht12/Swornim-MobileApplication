CREATE TABLE event_ticket_bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL,
    user_id UUID NOT NULL,
    ticket_type VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,
    price_per_ticket FLOAT NOT NULL,
    total_amount FLOAT NOT NULL,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    booking_status VARCHAR(20) NOT NULL DEFAULT 'confirmed' CHECK (booking_status IN ('confirmed', 'cancelled', 'refunded')),
    qr_code VARCHAR(255),
    special_requests TEXT,
    ticket_holder_details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Optional: Add indexes for performance
CREATE INDEX idx_event_ticket_bookings_event_id ON event_ticket_bookings(event_id);
CREATE INDEX idx_event_ticket_bookings_user_id ON event_ticket_bookings(user_id); 