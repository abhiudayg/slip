UPDATE brands SET
  required_fields = '["vehicle", "booking_id"]'::jsonb,
  optional_fields = '["pickup", "drop_off", "guest", "qr_data"]'::jsonb,
  summary = 'Zoomcar keyless self-drive pass with pickup, drop-off, and unlock details.',
  badge = 'Keyless',
  updated_at = NOW()
WHERE id = 'zoomcar';
