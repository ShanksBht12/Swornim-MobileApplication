-- Migration: Create events table
-- Run this in your PostgreSQL database

CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizer_id UUID NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    event_type VARCHAR(32) NOT NULL CHECK (event_type IN (
        'concert', 'musicFestival', 'dancePerformance', 'comedy_show', 'theater', 'cultural_show',
        'wedding', 'birthday', 'anniversary', 'graduation',
        'corporate', 'conference', 'seminar', 'workshop', 'product_launch',
        'sports_event', 'charity_event', 'exhibition', 'trade_show',
        'festival_celebration', 'religious_ceremony', 'party', 'other'
    )),
    status VARCHAR(16) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'ongoing', 'completed', 'cancelled')),
    visibility VARCHAR(16) NOT NULL DEFAULT 'private' CHECK (visibility IN ('public', 'private', 'inviteOnly')),
    event_date TIMESTAMP NOT NULL,
    event_end_date TIMESTAMP,
    event_time VARCHAR(10),
    event_end_time VARCHAR(10),
    location JSONB,
    venue VARCHAR(255),
    expected_guests INTEGER DEFAULT 0,
    ticket_price DECIMAL(10,2),
    is_ticketed BOOLEAN DEFAULT FALSE,
    max_capacity INTEGER,
    image_url VARCHAR(500),
    gallery TEXT[],
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    contact_email VARCHAR(255),
    contact_phone VARCHAR(32),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
); 