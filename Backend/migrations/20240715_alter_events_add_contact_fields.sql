-- Migration: Add contact_email and contact_phone to events table
ALTER TABLE events ADD COLUMN IF NOT EXISTS contact_email VARCHAR(255);
ALTER TABLE events ADD COLUMN IF NOT EXISTS contact_phone VARCHAR(32); 