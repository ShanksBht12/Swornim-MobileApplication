-- Add new enums for status and ticketType
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enum_eventticketbookings_status') THEN
    CREATE TYPE enum_eventticketbookings_status AS ENUM ('pending', 'confirmed', 'cancelled', 'attended', 'no_show', 'refunded');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enum_eventticketbookings_tickettype') THEN
    CREATE TYPE enum_eventticketbookings_tickettype AS ENUM ('regular', 'vip', 'student', 'early_bird', 'group', 'complimentary');
  END IF;
END $$;

-- Add status column
ALTER TABLE event_ticket_bookings
  ADD COLUMN IF NOT EXISTS status enum_eventticketbookings_status DEFAULT 'pending' NOT NULL;

-- Add ticketType column
ALTER TABLE event_ticket_bookings
  ADD COLUMN IF NOT EXISTS ticketType enum_eventticketbookings_tickettype DEFAULT 'regular' NOT NULL; 