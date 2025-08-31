-- File: 20240714010200-create-event-organizers-table.sql

CREATE TABLE event_organizers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    image VARCHAR(500),
    description TEXT,
    rating FLOAT DEFAULT 0.0,
    total_reviews INTEGER DEFAULT 0,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    event_types TEXT[] NOT NULL DEFAULT '{}',
    services TEXT[] NOT NULL DEFAULT '{}',
    package_starting_price FLOAT NOT NULL,
    hourly_consultation_rate FLOAT NOT NULL,
    portfolio TEXT[] NOT NULL DEFAULT '{}',
    experience_years INTEGER NOT NULL DEFAULT 0,
    max_event_size INTEGER NOT NULL DEFAULT 1000,
    preferred_vendors TEXT[] NOT NULL DEFAULT '{}',
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    offers_vendor_coordination BOOLEAN NOT NULL DEFAULT TRUE,
    offers_venue_booking BOOLEAN NOT NULL DEFAULT FALSE,
    offers_full_planning BOOLEAN NOT NULL DEFAULT TRUE,
    available_dates TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_event_organizers_user_id ON event_organizers(user_id);
CREATE INDEX idx_event_organizers_business_name ON event_organizers(business_name);
CREATE INDEX idx_event_organizers_is_available ON event_organizers(is_available);
CREATE INDEX idx_event_organizers_rating ON event_organizers(rating);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_event_organizers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_event_organizers_updated_at ON event_organizers;
CREATE TRIGGER trg_event_organizers_updated_at
BEFORE UPDATE ON event_organizers
FOR EACH ROW
EXECUTE PROCEDURE update_event_organizers_updated_at(); 