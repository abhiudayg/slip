-- Expand default brand pack; retire cult from marketplace catalog.
DELETE FROM brands WHERE id = 'cult';

UPDATE brands SET
  display_name = 'Metro',
  badge = 'Metro',
  summary = 'Metro QR tickets with station geofence surfacing (Namma Metro catalog).',
  updated_at = NOW()
WHERE id = 'namma-metro';

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint) VALUES
('easydiner', 'EazyDiner', 'dining', 'eventTicket',
 '["restaurant", "qr_data"]'::jsonb, '["time", "party_size", "booking_id"]'::jsonb,
 TRUE, TRUE, 'rgb(255, 107, 0)', NULL,
 'Restaurant table reservations with booking QR.', 'Dining', 'fork.knife')
ON CONFLICT (id) DO UPDATE SET
  display_name=EXCLUDED.display_name, category=EXCLUDED.category, apple_style=EXCLUDED.apple_style,
  required_fields=EXCLUDED.required_fields, optional_fields=EXCLUDED.optional_fields,
  supports_locations=EXCLUDED.supports_locations, supports_relevant_date=EXCLUDED.supports_relevant_date,
  accent_hint=EXCLUDED.accent_hint, station_catalog=EXCLUDED.station_catalog,
  summary=EXCLUDED.summary, badge=EXCLUDED.badge, icon_hint=EXCLUDED.icon_hint, updated_at=NOW();

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint) VALUES
('zomato-dineout', 'Zomato Dineout', 'dining', 'eventTicket',
 '["restaurant", "qr_data"]'::jsonb, '["time", "party_size", "booking_id"]'::jsonb,
 TRUE, TRUE, 'rgb(226, 55, 68)', NULL,
 'Zomato Dineout restaurant reservations and offers.', 'Dining', 'fork.knife.circle.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name=EXCLUDED.display_name, category=EXCLUDED.category, apple_style=EXCLUDED.apple_style,
  required_fields=EXCLUDED.required_fields, optional_fields=EXCLUDED.optional_fields,
  supports_locations=EXCLUDED.supports_locations, supports_relevant_date=EXCLUDED.supports_relevant_date,
  accent_hint=EXCLUDED.accent_hint, station_catalog=EXCLUDED.station_catalog,
  summary=EXCLUDED.summary, badge=EXCLUDED.badge, icon_hint=EXCLUDED.icon_hint, updated_at=NOW();

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint) VALUES
('swiggy-dineout', 'Swiggy Dineout', 'dining', 'eventTicket',
 '["restaurant", "qr_data"]'::jsonb, '["time", "party_size", "booking_id"]'::jsonb,
 TRUE, TRUE, 'rgb(252, 128, 25)', NULL,
 'Swiggy Dineout table bookings and deals.', 'Dining', 'fork.knife')
ON CONFLICT (id) DO UPDATE SET
  display_name=EXCLUDED.display_name, category=EXCLUDED.category, apple_style=EXCLUDED.apple_style,
  required_fields=EXCLUDED.required_fields, optional_fields=EXCLUDED.optional_fields,
  supports_locations=EXCLUDED.supports_locations, supports_relevant_date=EXCLUDED.supports_relevant_date,
  accent_hint=EXCLUDED.accent_hint, station_catalog=EXCLUDED.station_catalog,
  summary=EXCLUDED.summary, badge=EXCLUDED.badge, icon_hint=EXCLUDED.icon_hint, updated_at=NOW();

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint) VALUES
('airbnb', 'Airbnb', 'travel', 'generic',
 '["property", "qr_data"]'::jsonb, '["guest", "check_in", "check_out", "booking_id"]'::jsonb,
 TRUE, TRUE, 'rgb(255, 56, 92)', NULL,
 'Airbnb stay confirmations with check-in details.', 'Stay', 'house.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name=EXCLUDED.display_name, category=EXCLUDED.category, apple_style=EXCLUDED.apple_style,
  required_fields=EXCLUDED.required_fields, optional_fields=EXCLUDED.optional_fields,
  supports_locations=EXCLUDED.supports_locations, supports_relevant_date=EXCLUDED.supports_relevant_date,
  accent_hint=EXCLUDED.accent_hint, station_catalog=EXCLUDED.station_catalog,
  summary=EXCLUDED.summary, badge=EXCLUDED.badge, icon_hint=EXCLUDED.icon_hint, updated_at=NOW();

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint) VALUES
('redbus', 'redBus', 'transit', 'boardingPass',
 '["origin", "destination", "qr_data"]'::jsonb, '["passenger", "seat", "pnr", "bus"]'::jsonb,
 TRUE, TRUE, 'rgb(216, 67, 21)', NULL,
 'Intercity bus tickets with seat and PNR.', 'Bus', 'bus.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name=EXCLUDED.display_name, category=EXCLUDED.category, apple_style=EXCLUDED.apple_style,
  required_fields=EXCLUDED.required_fields, optional_fields=EXCLUDED.optional_fields,
  supports_locations=EXCLUDED.supports_locations, supports_relevant_date=EXCLUDED.supports_relevant_date,
  accent_hint=EXCLUDED.accent_hint, station_catalog=EXCLUDED.station_catalog,
  summary=EXCLUDED.summary, badge=EXCLUDED.badge, icon_hint=EXCLUDED.icon_hint, updated_at=NOW();

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint) VALUES
('zoomcar', 'Zoomcar', 'travel', 'generic',
 '["vehicle", "qr_data"]'::jsonb, '["pickup", "booking_id", "guest"]'::jsonb,
 TRUE, TRUE, 'rgb(16, 185, 129)', NULL,
 'Self-drive car reservations with pickup details.', 'Car', 'car.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name=EXCLUDED.display_name, category=EXCLUDED.category, apple_style=EXCLUDED.apple_style,
  required_fields=EXCLUDED.required_fields, optional_fields=EXCLUDED.optional_fields,
  supports_locations=EXCLUDED.supports_locations, supports_relevant_date=EXCLUDED.supports_relevant_date,
  accent_hint=EXCLUDED.accent_hint, station_catalog=EXCLUDED.station_catalog,
  summary=EXCLUDED.summary, badge=EXCLUDED.badge, icon_hint=EXCLUDED.icon_hint, updated_at=NOW();
