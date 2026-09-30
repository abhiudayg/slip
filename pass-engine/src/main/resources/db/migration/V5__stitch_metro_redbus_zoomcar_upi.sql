-- Align namma-metro / redBus / Zoomcar / UPI with Stitch wallet templates.
UPDATE brands SET
  display_name = 'Namma Metro',
  optional_fields = '["passenger", "dep", "arr", "time", "duration"]'::jsonb,
  summary = 'Namma Metro QR single-journey tickets with station geofence surfacing.',
  updated_at = NOW()
WHERE id = 'namma-metro';

UPDATE brands SET
  optional_fields = '["passenger", "seat", "pnr", "bus", "dep", "arr", "duration", "time"]'::jsonb,
  summary = 'Intercity bus tickets with seat, PNR, and live boarding window.',
  updated_at = NOW()
WHERE id = 'redbus';

UPDATE brands SET
  optional_fields = '["pickup", "drop_off", "booking_id", "guest"]'::jsonb,
  accent_hint = 'rgb(132, 204, 22)',
  summary = 'Zoomcar keyless self-drive pass with pickup and unlock details.',
  badge = 'Keyless',
  updated_at = NOW()
WHERE id = 'zoomcar';

UPDATE brands SET
  display_name = 'UPI PayPass',
  apple_style = 'storeCard',
  optional_fields = '["vpa", "bank"]'::jsonb,
  accent_hint = 'rgb(249, 115, 22)',
  summary = 'UPI receive/pay QR (Bharat QR / NPCI) for Apple Wallet.',
  updated_at = NOW()
WHERE id = 'upi';
