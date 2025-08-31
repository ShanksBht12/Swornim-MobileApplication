-- Migration: Alter event_organizers table to match new model/logic

ALTER TABLE event_organizers
  ADD COLUMN IF NOT EXISTS contact_email VARCHAR(255),
  ADD COLUMN IF NOT EXISTS contact_phone VARCHAR(50),
  ADD COLUMN IF NOT EXISTS offers_vendor_coordination BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS offers_venue_booking BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS offers_full_planning BOOLEAN NOT NULL DEFAULT TRUE;

-- Rename columns for consistency with frontend/backend model
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='event_organizers' AND column_name='offers_vendor_management') THEN
    ALTER TABLE event_organizers RENAME COLUMN offers_vendor_management TO offers_vendor_coordination;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='event_organizers' AND column_name='offers_event_coordination') THEN
    ALTER TABLE event_organizers RENAME COLUMN offers_event_coordination TO offers_full_planning;
  END IF;
END $$; 