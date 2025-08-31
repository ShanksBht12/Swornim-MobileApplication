-- Migration: Add location column to event_organizers
ALTER TABLE event_organizers
ADD COLUMN location JSONB; 