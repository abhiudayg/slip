-- District festival / nightlife NFC wristband (Stitch wallet templates).
INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint) VALUES
('district', 'District', 'entertainment', 'eventTicket',
 '["event", "qr_data"]'::jsonb, '["venue", "tier", "gate", "zone", "passholder", "booking_id", "time"]'::jsonb,
 TRUE, TRUE, 'rgb(124, 58, 237)', NULL,
 'District festival and nightlife NFC wristband passes (Sunburn, Boiler Room, arena events).', 'Festival', 'bolt.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name=EXCLUDED.display_name, category=EXCLUDED.category, apple_style=EXCLUDED.apple_style,
  required_fields=EXCLUDED.required_fields, optional_fields=EXCLUDED.optional_fields,
  supports_locations=EXCLUDED.supports_locations, supports_relevant_date=EXCLUDED.supports_relevant_date,
  accent_hint=EXCLUDED.accent_hint, station_catalog=EXCLUDED.station_catalog,
  summary=EXCLUDED.summary, badge=EXCLUDED.badge, icon_hint=EXCLUDED.icon_hint, updated_at=NOW();

-- Align EazyDiner with Stitch VIP Store Card.
UPDATE brands SET
  apple_style = 'storeCard',
  badge = 'VIP',
  summary = 'EazyDiner Prime VIP store card for restaurant reservations.',
  updated_at = NOW()
WHERE id = 'easydiner';
