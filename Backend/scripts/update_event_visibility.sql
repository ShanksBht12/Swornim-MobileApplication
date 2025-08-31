UPDATE events
SET visibility = 'public', status = 'published'
WHERE visibility != 'public' OR status != 'published'; 