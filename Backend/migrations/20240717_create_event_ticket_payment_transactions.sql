-- Migration: Create event_ticket_payment_transactions table for event ticket payments

CREATE TABLE IF NOT EXISTS event_ticket_payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES event_ticket_bookings(id) ON DELETE CASCADE ON UPDATE CASCADE,
    khalti_transaction_id VARCHAR(255),
    khalti_payment_url TEXT,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'NPR',
    status VARCHAR(16) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    payment_method VARCHAR(50) NOT NULL DEFAULT 'khalti',
    khalti_response JSONB,
    failure_reason TEXT,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_event_ticket_payment_transactions_booking_id ON event_ticket_payment_transactions(booking_id);
CREATE INDEX IF NOT EXISTS idx_event_ticket_payment_transactions_khalti_transaction_id ON event_ticket_payment_transactions(khalti_transaction_id);
CREATE INDEX IF NOT EXISTS idx_event_ticket_payment_transactions_status ON event_ticket_payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_event_ticket_payment_transactions_created_at ON event_ticket_payment_transactions(created_at); 